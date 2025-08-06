#!/bin/bash

# =============================================================================
# Script para detener el sistema de monitoreo de URLs
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

echo -e "${BLUE}🛑 Deteniendo Sistema de Monitoreo de URLs${NC}"
echo ""

# Cargar variables de entorno para obtener puertos
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
fi

URL_STATUS_SERVICE_PORT=${URL_STATUS_SERVICE_PORT:-8090}
HAPROXY_INTEGRATION_PORT=${HAPROXY_INTEGRATION_PORT:-8085}

# Detener servicio principal de monitoreo
print_status "Deteniendo servicio principal de monitoreo..."

PID_FILE="$PROJECT_ROOT/logs/monitoring/url-monitoring.pid"
if [ -f "$PID_FILE" ]; then
    MONITORING_PID=$(cat "$PID_FILE")
    if kill -0 "$MONITORING_PID" 2>/dev/null; then
        print_status "Enviando señal TERM al proceso $MONITORING_PID..."
        kill -TERM "$MONITORING_PID" 2>/dev/null || true
        
        # Esperar hasta 10 segundos para que termine gracefully
        for i in {1..10}; do
            if ! kill -0 "$MONITORING_PID" 2>/dev/null; then
                break
            fi
            sleep 1
        done
        
        # Si aún está corriendo, forzar terminación
        if kill -0 "$MONITORING_PID" 2>/dev/null; then
            print_warning "Forzando terminación del proceso $MONITORING_PID..."
            kill -KILL "$MONITORING_PID" 2>/dev/null || true
        fi
        
        print_success "Servicio de monitoreo detenido"
    else
        print_warning "Proceso de monitoreo no estaba corriendo"
    fi
    
    rm -f "$PID_FILE"
else
    print_warning "Archivo PID no encontrado"
fi

# Detener integración HAProxy
print_status "Deteniendo integración HAProxy..."

INTEGRATION_PID=$(lsof -ti:$HAPROXY_INTEGRATION_PORT 2>/dev/null || echo "")
if [ -n "$INTEGRATION_PID" ]; then
    print_status "Enviando señal TERM al proceso $INTEGRATION_PID..."
    kill -TERM $INTEGRATION_PID 2>/dev/null || true
    
    # Esperar hasta 10 segundos
    for i in {1..10}; do
        if ! kill -0 "$INTEGRATION_PID" 2>/dev/null; then
            break
        fi
        sleep 1
    done
    
    # Forzar si es necesario
    if kill -0 "$INTEGRATION_PID" 2>/dev/null; then
        print_warning "Forzando terminación del proceso $INTEGRATION_PID..."
        kill -KILL $INTEGRATION_PID 2>/dev/null || true
    fi
    
    print_success "Integración HAProxy detenida"
else
    print_warning "Integración HAProxy no estaba corriendo"
fi

# Verificar que los puertos están libres
print_status "Verificando que los puertos están libres..."

if netstat -tuln 2>/dev/null | grep -q ":$URL_STATUS_SERVICE_PORT "; then
    print_warning "Puerto $URL_STATUS_SERVICE_PORT aún está en uso"
    
    # Intentar encontrar y matar el proceso
    REMAINING_PID=$(lsof -ti:$URL_STATUS_SERVICE_PORT 2>/dev/null || echo "")
    if [ -n "$REMAINING_PID" ]; then
        print_status "Matando proceso restante en puerto $URL_STATUS_SERVICE_PORT (PID: $REMAINING_PID)..."
        kill -KILL $REMAINING_PID 2>/dev/null || true
    fi
else
    print_success "Puerto $URL_STATUS_SERVICE_PORT liberado"
fi

if netstat -tuln 2>/dev/null | grep -q ":$HAPROXY_INTEGRATION_PORT "; then
    print_warning "Puerto $HAPROXY_INTEGRATION_PORT aún está en uso"
    
    REMAINING_PID=$(lsof -ti:$HAPROXY_INTEGRATION_PORT 2>/dev/null || echo "")
    if [ -n "$REMAINING_PID" ]; then
        print_status "Matando proceso restante en puerto $HAPROXY_INTEGRATION_PORT (PID: $REMAINING_PID)..."
        kill -KILL $REMAINING_PID 2>/dev/null || true
    fi
else
    print_success "Puerto $HAPROXY_INTEGRATION_PORT liberado"
fi

# Limpiar archivos temporales
print_status "Limpiando archivos temporales..."

# Rotar logs si son muy grandes (>10MB)
LOG_DIR="$PROJECT_ROOT/logs/monitoring"
if [ -d "$LOG_DIR" ]; then
    find "$LOG_DIR" -name "*.log" -size +10M -exec gzip {} \; 2>/dev/null || true
    print_success "Logs rotados si era necesario"
fi

echo ""
print_success "🎉 Sistema de monitoreo detenido completamente"
echo ""

print_status "Estado final:"
echo "  • Puerto $URL_STATUS_SERVICE_PORT: $(netstat -tuln 2>/dev/null | grep -q ":$URL_STATUS_SERVICE_PORT " && echo "En uso" || echo "Libre")"
echo "  • Puerto $HAPROXY_INTEGRATION_PORT: $(netstat -tuln 2>/dev/null | grep -q ":$HAPROXY_INTEGRATION_PORT " && echo "En uso" || echo "Libre")"
echo ""

print_status "Para reiniciar el sistema:"
echo "  ./scripts/monitoring/setup-complete-monitoring.sh"
echo ""
