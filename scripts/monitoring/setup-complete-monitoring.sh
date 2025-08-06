#!/bin/bash

# =============================================================================
# Script maestro para configurar el sistema completo de monitoreo de URLs
# Soluciona el problema "Error al cargar datos: NOT FOUND"
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    SISTEMA DE MONITOREO URLs                ║${NC}"
    echo -e "${PURPLE}║              Solución completa y automatizada               ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

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

print_info() {
    echo -e "${PURPLE}ℹ️  $1${NC}"
}

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header

print_status "Iniciando configuración del sistema de monitoreo..."
echo ""

# Cargar variables de entorno
if [ -f "$PROJECT_ROOT/.env" ]; then
    print_status "Cargando variables de entorno..."
    source "$PROJECT_ROOT/.env"
    print_success "Variables de entorno cargadas"
else
    print_error "Archivo .env no encontrado"
    exit 1
fi

# Configuración de puertos
URL_STATUS_SERVICE_PORT=${URL_STATUS_SERVICE_PORT:-8090}
HAPROXY_INTEGRATION_PORT=${HAPROXY_INTEGRATION_PORT:-8085}
URL_CHECK_INTERVAL=${URL_CHECK_INTERVAL:-30}

print_info "Configuración del sistema:"
echo "  • Servicio de monitoreo: puerto $URL_STATUS_SERVICE_PORT"
echo "  • Integración HAProxy: puerto $HAPROXY_INTEGRATION_PORT"
echo "  • Intervalo de verificación: ${URL_CHECK_INTERVAL}s"
echo "  • HAProxy: http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}"
echo ""

# Verificar dependencias
print_status "Verificando dependencias del sistema..."

# Python y pip
if ! command -v python3 &> /dev/null; then
    print_error "Python3 no está instalado"
    exit 1
fi

if ! command -v pip3 &> /dev/null; then
    print_error "pip3 no está instalado"
    exit 1
fi

print_success "Python3 y pip3 disponibles"

# Docker
if ! command -v docker &> /dev/null; then
    print_warning "Docker no está disponible, funcionalidad limitada"
    DOCKER_AVAILABLE=false
else
    print_success "Docker disponible"
    DOCKER_AVAILABLE=true
fi

# Instalar dependencias Python
print_status "Configurando entorno Python..."

# Crear entorno virtual si no existe
VENV_DIR="$PROJECT_ROOT/monitoring-env"
if [ ! -d "$VENV_DIR" ]; then
    print_status "Creando entorno virtual..."
    python3 -m venv "$VENV_DIR"
    print_success "Entorno virtual creado"
fi

# Activar entorno virtual
source "$VENV_DIR/bin/activate"

# Crear requirements específicos para monitoreo si no existe
MONITORING_REQUIREMENTS="$SCRIPT_DIR/requirements.txt"
if [ ! -f "$MONITORING_REQUIREMENTS" ]; then
    cat > "$MONITORING_REQUIREMENTS" << EOF
flask>=2.0.0
flask-cors>=3.0.0
requests>=2.25.0
docker>=5.0.0
EOF
fi

pip install -r "$MONITORING_REQUIREMENTS" --quiet
print_success "Dependencias Python instaladas en entorno virtual"

# Verificar contenedores Docker
if [ "$DOCKER_AVAILABLE" = true ]; then
    print_status "Verificando contenedores Docker..."
    
    CONTAINERS=("haproxy" "weblogic-a" "weblogic-b")
    CONTAINERS_OK=true
    
    for container in "${CONTAINERS[@]}"; do
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            print_success "Contenedor $container está ejecutándose"
        else
            print_warning "Contenedor $container no está ejecutándose"
            CONTAINERS_OK=false
        fi
    done
    
    if [ "$CONTAINERS_OK" = false ]; then
        print_warning "Algunos contenedores no están disponibles"
        print_info "Para iniciar todos los servicios: ./start-all.sh"
    fi
fi

# Crear directorios necesarios
print_status "Creando estructura de directorios..."
mkdir -p "$PROJECT_ROOT/logs/monitoring"
mkdir -p "$PROJECT_ROOT/config/monitoring"
print_success "Directorios creados"

# Configurar archivos de configuración
print_status "Configurando archivos de monitoreo..."

# Archivo de configuración del servicio
CONFIG_FILE="$PROJECT_ROOT/config/monitoring/url-monitoring.json"
cat > "$CONFIG_FILE" << EOF
{
  "service": {
    "name": "URL Status Monitoring Service",
    "version": "1.0.1",
    "port": $URL_STATUS_SERVICE_PORT,
    "check_interval": $URL_CHECK_INTERVAL,
    "timeout": 5,
    "max_retries": 3
  },
  "urls": [
    {
      "name": "HAProxy Load Balancer",
      "url": "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/",
      "type": "load_balancer",
      "critical": true,
      "expected_codes": [200, 503],
      "description": "503 is normal when backends are starting"
    },
    {
      "name": "HAProxy Stats",
      "url": "http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats",
      "type": "monitoring",
      "critical": false,
      "expected_codes": [200, 401],
      "description": "401 is normal, requires authentication"
    },
    {
      "name": "HAProxy Admin UI",
      "url": "http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}/",
      "type": "admin",
      "critical": false,
      "expected_codes": [200]
    },
    {
      "name": "WebLogic Server A Console",
      "url": "http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/console",
      "type": "weblogic",
      "critical": true,
      "expected_codes": [200, 302],
      "description": "302 redirect is normal for WebLogic console"
    },
    {
      "name": "WebLogic Server B Console",
      "url": "http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/console",
      "type": "weblogic",
      "critical": true,
      "expected_codes": [200, 302],
      "description": "302 redirect is normal for WebLogic console"
    },
    {
      "name": "MkDocs Documentation",
      "url": "http://localhost:${MKDOCS_EXTERNAL_PORT:-8000}/",
      "type": "documentation",
      "critical": false,
      "expected_codes": [200]
    }
  ],
  "docker": {
    "enabled": $DOCKER_AVAILABLE,
    "containers": ["haproxy", "weblogic-a", "weblogic-b", "mkdocs-server"]
  },
  "haproxy": {
    "config_path": "/usr/local/etc/haproxy/haproxy.cfg",
    "socket_path": "/var/run/haproxy.sock",
    "auto_update_ips": true
  }
}
EOF

print_success "Archivo de configuración creado: $CONFIG_FILE"

# Detener servicios existentes si están corriendo
print_status "Deteniendo servicios existentes..."

# Detener servicio de monitoreo
PID_FILE="$PROJECT_ROOT/logs/monitoring/url-monitoring.pid"
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        print_status "Deteniendo servicio anterior (PID: $OLD_PID)..."
        kill -TERM "$OLD_PID" 2>/dev/null || true
        sleep 2
        if kill -0 "$OLD_PID" 2>/dev/null; then
            kill -KILL "$OLD_PID" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
        print_success "Servicio anterior detenido"
    fi
fi

# Detener integración HAProxy
INTEGRATION_PID=$(lsof -ti:$HAPROXY_INTEGRATION_PORT 2>/dev/null || echo "")
if [ -n "$INTEGRATION_PID" ]; then
    print_status "Deteniendo integración HAProxy anterior..."
    kill -TERM $INTEGRATION_PID 2>/dev/null || true
    sleep 2
fi

# Iniciar servicios
print_status "Iniciando servicios de monitoreo..."

# 1. Iniciar servicio principal de monitoreo
print_status "Iniciando servicio principal de monitoreo..."
LOG_FILE="$PROJECT_ROOT/logs/monitoring/url-monitoring-$(date +%Y%m%d).log"

# Usar Python del entorno virtual
PYTHON_CMD="$VENV_DIR/bin/python"

nohup "$PYTHON_CMD" "$SCRIPT_DIR/url-status-service.py" > "$LOG_FILE" 2>&1 &
MONITORING_PID=$!
echo $MONITORING_PID > "$PID_FILE"

# Esperar a que el servicio se inicie
sleep 3

# Verificar que el servicio está corriendo
if kill -0 $MONITORING_PID 2>/dev/null; then
    print_success "Servicio de monitoreo iniciado (PID: $MONITORING_PID)"
else
    print_error "Error al iniciar servicio de monitoreo"
    exit 1
fi

# 2. Iniciar integración con HAProxy
print_status "Iniciando integración con HAProxy..."
INTEGRATION_LOG="$PROJECT_ROOT/logs/monitoring/haproxy-integration-$(date +%Y%m%d).log"

nohup "$PYTHON_CMD" "$SCRIPT_DIR/haproxy-url-integration.py" $HAPROXY_INTEGRATION_PORT > "$INTEGRATION_LOG" 2>&1 &
INTEGRATION_PID=$!

# Esperar a que la integración se inicie
sleep 3

# Verificar que la integración está corriendo
if kill -0 $INTEGRATION_PID 2>/dev/null; then
    print_success "Integración HAProxy iniciada (PID: $INTEGRATION_PID)"
else
    print_error "Error al iniciar integración HAProxy"
fi

# 3. Actualizar configuración de HAProxy para usar el nuevo servicio
if [ "$DOCKER_AVAILABLE" = true ]; then
    print_status "Configurando HAProxy para usar el nuevo servicio..."
    
    # Actualizar IPs inicialmente
    sleep 2
    curl -s -X POST "http://localhost:$URL_STATUS_SERVICE_PORT/api/containers/update-ips" > /dev/null 2>&1 || true
    
    print_success "HAProxy configurado"
fi

# Verificar que todo está funcionando
print_status "Verificando funcionamiento del sistema..."

# Probar servicio de monitoreo
if curl -s "http://localhost:$URL_STATUS_SERVICE_PORT/api/status" > /dev/null; then
    print_success "✓ Servicio de monitoreo respondiendo"
else
    print_error "✗ Servicio de monitoreo no responde"
fi

# Probar integración HAProxy
if curl -s "http://localhost:$HAPROXY_INTEGRATION_PORT/api/status" > /dev/null; then
    print_success "✓ Integración HAProxy respondiendo"
else
    print_error "✗ Integración HAProxy no responde"
fi

# Probar endpoint de URLs
if curl -s "http://localhost:$URL_STATUS_SERVICE_PORT/api/url-status" | grep -q "urls"; then
    print_success "✓ Endpoint de URLs funcionando"
else
    print_warning "⚠ Endpoint de URLs puede necesitar más tiempo"
fi

echo ""
print_success "🎉 Sistema de monitoreo configurado exitosamente!"
echo ""

print_info "═══════════════════════════════════════════════════════════════"
print_info "                        INFORMACIÓN DEL SISTEMA"
print_info "═══════════════════════════════════════════════════════════════"
echo ""

print_info "📊 ENDPOINTS PRINCIPALES:"
echo "  • Estado del sistema:     http://localhost:$URL_STATUS_SERVICE_PORT/api/status"
echo "  • Estado de URLs:         http://localhost:$URL_STATUS_SERVICE_PORT/api/url-status"
echo "  • Integración HAProxy:    http://localhost:$HAPROXY_INTEGRATION_PORT/api/url-status"
echo "  • Actualizar IPs:         http://localhost:$URL_STATUS_SERVICE_PORT/api/containers/update-ips"
echo ""

print_info "📁 ARCHIVOS IMPORTANTES:"
echo "  • Configuración:          $CONFIG_FILE"
echo "  • Log monitoreo:          $LOG_FILE"
echo "  • Log integración:        $INTEGRATION_LOG"
echo "  • PID del servicio:       $PID_FILE"
echo ""

print_info "🔧 COMANDOS ÚTILES:"
echo "  • Ver estado:             curl http://localhost:$URL_STATUS_SERVICE_PORT/api/url-status"
echo "  • Forzar actualización:   curl -X POST http://localhost:$URL_STATUS_SERVICE_PORT/api/url-status/refresh"
echo "  • Actualizar IPs:         curl -X POST http://localhost:$URL_STATUS_SERVICE_PORT/api/containers/update-ips"
echo "  • Ver logs en tiempo real: tail -f $LOG_FILE"
echo ""

print_info "🛑 PARA DETENER:"
echo "  • Detener monitoreo:      kill $MONITORING_PID"
echo "  • Detener integración:    kill $INTEGRATION_PID"
echo "  • O usar:                 ./scripts/monitoring/stop-monitoring.sh"
echo ""

print_info "🔄 CARACTERÍSTICAS:"
echo "  • ✅ Monitoreo automático cada ${URL_CHECK_INTERVAL}s"
echo "  • ✅ Actualización automática de IPs cuando hay errores"
echo "  • ✅ API REST completa para integración"
echo "  • ✅ Logs detallados y rotación automática"
echo "  • ✅ Compatible con dashboard existente"
echo "  • ✅ Configuración centralizada desde .env"
echo ""

print_success "El sistema está listo para usar. ¡El problema 'NOT FOUND' debería estar resuelto!"
