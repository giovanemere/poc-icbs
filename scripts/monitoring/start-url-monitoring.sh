#!/bin/bash

# =============================================================================
# Script para iniciar el servicio de monitoreo de URLs
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🚀 Iniciando Servicio de Monitoreo de URLs${NC}"
echo ""

# Cargar variables de entorno
if [ -f "$PROJECT_ROOT/.env" ]; then
    print_status "Cargando variables de entorno..."
    source "$PROJECT_ROOT/.env"
    print_success "Variables de entorno cargadas"
else
    print_warning "Archivo .env no encontrado, usando valores por defecto"
fi

# Verificar dependencias
print_status "Verificando dependencias..."

# Verificar Python
if ! command -v python3 &> /dev/null; then
    print_error "Python3 no está instalado"
    exit 1
fi

# Verificar pip
if ! command -v pip3 &> /dev/null; then
    print_error "pip3 no está instalado"
    exit 1
fi

# Configurar entorno virtual
VENV_DIR="$PROJECT_ROOT/monitoring-env"
if [ ! -d "$VENV_DIR" ]; then
    print_status "Creando entorno virtual..."
    python3 -m venv "$VENV_DIR"
    print_success "Entorno virtual creado"
fi

# Activar entorno virtual
source "$VENV_DIR/bin/activate"

# Instalar dependencias Python si es necesario
REQUIREMENTS_FILE="$PROJECT_ROOT/requirements.txt"
if [ -f "$REQUIREMENTS_FILE" ]; then
    print_status "Instalando dependencias Python..."
    pip install -r "$REQUIREMENTS_FILE" --quiet
    print_success "Dependencias instaladas"
fi

# Verificar Docker
if ! command -v docker &> /dev/null; then
    print_warning "Docker no está disponible, algunas funciones estarán limitadas"
else
    print_success "Docker disponible"
fi

# Configurar puerto del servicio
URL_STATUS_SERVICE_PORT=${URL_STATUS_SERVICE_PORT:-8090}
URL_CHECK_INTERVAL=${URL_CHECK_INTERVAL:-30}

print_status "Configuración del servicio:"
echo "  • Puerto: $URL_STATUS_SERVICE_PORT"
echo "  • Intervalo de verificación: ${URL_CHECK_INTERVAL}s"
echo "  • HAProxy: http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}"
echo "  • WebLogic A: http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}"
echo "  • WebLogic B: http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}"
echo ""

# Verificar si el puerto está disponible
if netstat -tuln 2>/dev/null | grep -q ":$URL_STATUS_SERVICE_PORT "; then
    print_warning "Puerto $URL_STATUS_SERVICE_PORT ya está en uso"
    
    # Intentar detener proceso existente
    PID=$(lsof -ti:$URL_STATUS_SERVICE_PORT 2>/dev/null || echo "")
    if [ -n "$PID" ]; then
        print_status "Deteniendo proceso existente (PID: $PID)..."
        kill -TERM $PID 2>/dev/null || true
        sleep 2
        
        # Forzar si es necesario
        if kill -0 $PID 2>/dev/null; then
            kill -KILL $PID 2>/dev/null || true
            sleep 1
        fi
        print_success "Proceso anterior detenido"
    fi
fi

# Crear directorio de logs
LOG_DIR="$PROJECT_ROOT/logs/monitoring"
mkdir -p "$LOG_DIR"

# Archivo de log
LOG_FILE="$LOG_DIR/url-monitoring-$(date +%Y%m%d).log"

print_status "Iniciando servicio de monitoreo..."
print_status "Logs: $LOG_FILE"

# Función para manejar señales
cleanup() {
    print_status "Deteniendo servicio de monitoreo..."
    if [ -n "$SERVICE_PID" ]; then
        kill -TERM $SERVICE_PID 2>/dev/null || true
        wait $SERVICE_PID 2>/dev/null || true
    fi
    print_success "Servicio detenido"
    exit 0
}

# Configurar manejo de señales
trap cleanup SIGTERM SIGINT

# Iniciar el servicio
if [ "$1" = "--daemon" ] || [ "$1" = "-d" ]; then
    # Modo demonio
    print_status "Iniciando en modo demonio..."
    
    nohup "$VENV_DIR/bin/python" "$SCRIPT_DIR/url-status-service.py" > "$LOG_FILE" 2>&1 &
    SERVICE_PID=$!
    
    # Guardar PID
    echo $SERVICE_PID > "$LOG_DIR/url-monitoring.pid"
    
    print_success "Servicio iniciado en modo demonio (PID: $SERVICE_PID)"
    print_status "Para detener: kill $SERVICE_PID"
    print_status "Para ver logs: tail -f $LOG_FILE"
    
else
    # Modo interactivo
    print_status "Iniciando en modo interactivo..."
    print_status "Presiona Ctrl+C para detener"
    echo ""
    
    "$VENV_DIR/bin/python" "$SCRIPT_DIR/url-status-service.py" 2>&1 | tee "$LOG_FILE"
fi

echo ""
print_success "🎉 Servicio de monitoreo configurado!"
echo ""
print_status "URLs de la API:"
echo "  • Estado del servicio: http://localhost:$URL_STATUS_SERVICE_PORT/api/status"
echo "  • Estado de URLs: http://localhost:$URL_STATUS_SERVICE_PORT/api/url-status"
echo "  • Actualizar IPs: http://localhost:$URL_STATUS_SERVICE_PORT/api/containers/update-ips"
echo "  • Recargar config: http://localhost:$URL_STATUS_SERVICE_PORT/api/config/reload"
echo ""
print_status "Para probar:"
echo "  curl http://localhost:$URL_STATUS_SERVICE_PORT/api/url-status"
echo ""
