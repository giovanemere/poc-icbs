#!/bin/bash

# =============================================================================
# Script de Reinicio Forzado - WebLogic System
# Fuerza un reinicio completo independientemente del estado actual
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Banner
echo -e "${PURPLE}"
echo "============================================================================="
echo "🔄 REINICIO FORZADO - SISTEMA WEBLOGIC"
echo "============================================================================="
echo -e "${NC}"

# Cambiar al directorio correcto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# =============================================================================
# FASE 1: PARAR TODOS LOS SERVICIOS
# =============================================================================
log "FASE 1: Parando todos los servicios..."

echo -e "${YELLOW}🛑 Parando contenedores Docker...${NC}"
docker-compose -f config/docker-compose.yml down --remove-orphans 2>/dev/null || true

echo -e "${YELLOW}🧹 Limpiando recursos...${NC}"
# Limpiar contenedores huérfanos
docker container prune -f 2>/dev/null || true

# Verificar que no queden contenedores del proyecto corriendo
REMAINING=$(docker ps -q --filter "name=weblogic\|haproxy\|oracle\|unified-dashboard\|traffic-dashboard\|admin-api" 2>/dev/null || echo "")
if [ ! -z "$REMAINING" ]; then
    warning "Forzando parada de contenedores restantes..."
    echo "$REMAINING" | xargs docker stop 2>/dev/null || true
    echo "$REMAINING" | xargs docker rm -f 2>/dev/null || true
fi

success "Todos los servicios parados"

# =============================================================================
# FASE 2: VERIFICAR PUERTOS LIBRES
# =============================================================================
log "FASE 2: Verificando puertos..."

PORTS_TO_CHECK="8084 8085 8092 8093 8100 8404 7001 7002 1521 5500"
BUSY_PORTS=""

for port in $PORTS_TO_CHECK; do
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        BUSY_PORTS="$BUSY_PORTS $port"
    fi
done

if [ ! -z "$BUSY_PORTS" ]; then
    warning "Puertos ocupados:$BUSY_PORTS"
    info "Intentando liberar puertos..."
    
    # Intentar matar procesos que usan los puertos
    for port in $BUSY_PORTS; do
        PID=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | head -1)
        if [ ! -z "$PID" ] && [ "$PID" != "-" ]; then
            warning "Terminando proceso $PID que usa puerto $port"
            kill -9 "$PID" 2>/dev/null || true
        fi
    done
    
    sleep 2
else
    success "Todos los puertos están libres"
fi

# =============================================================================
# FASE 3: INICIAR SERVICIOS
# =============================================================================
log "FASE 3: Iniciando servicios..."

echo -e "${GREEN}🚀 Iniciando todos los servicios...${NC}"
docker-compose -f config/docker-compose.yml up -d

# =============================================================================
# FASE 4: VERIFICAR ESTADO
# =============================================================================
log "FASE 4: Verificando estado de los servicios..."

# Esperar un poco para que los servicios se inicien
sleep 10

# Verificar contenedores
RUNNING_COUNT=$(docker-compose -f config/docker-compose.yml ps -q --filter "status=running" 2>/dev/null | wc -l)
TOTAL_COUNT=$(docker-compose -f config/docker-compose.yml ps -q 2>/dev/null | wc -l)

if [ "$RUNNING_COUNT" -eq "$TOTAL_COUNT" ] && [ "$RUNNING_COUNT" -gt 0 ]; then
    success "Reinicio forzado completado exitosamente ($RUNNING_COUNT/$TOTAL_COUNT servicios corriendo)"
else
    warning "Algunos servicios pueden no estar corriendo ($RUNNING_COUNT/$TOTAL_COUNT)"
    echo ""
    log "Estado detallado:"
    docker-compose -f config/docker-compose.yml ps
fi

# =============================================================================
# MOSTRAR URLs
# =============================================================================
echo ""
echo -e "${PURPLE}=============================================================================${NC}"
echo -e "${GREEN}🎉 REINICIO FORZADO COMPLETADO${NC}"
echo -e "${PURPLE}=============================================================================${NC}"
echo ""

echo -e "${CYAN}📋 URLs Principales:${NC}"
echo -e "   🎛️ Dashboard Principal: ${YELLOW}http://localhost:8085/unified-dashboard-fixed.html${NC}"
echo -e "   📊 Dashboard de Tráfico: ${YELLOW}http://localhost:8084/${NC}"
echo -e "   🌐 Frontend Principal: ${YELLOW}http://localhost:8100/${NC}"
echo -e "   📈 HAProxy Stats: ${YELLOW}http://localhost:8404/stats${NC} (admin/admin123)"
echo ""

echo -e "${CYAN}🔧 Comandos útiles:${NC}"
echo -e "   Ver logs: ${YELLOW}docker-compose -f config/docker-compose.yml logs -f${NC}"
echo -e "   Parar todo: ${YELLOW}./stop.sh${NC}"
echo -e "   Inicio inteligente: ${YELLOW}./start.sh${NC}"
echo -e "   Reinicio forzado: ${YELLOW}./force-restart.sh${NC}"
echo ""

echo -e "${GREEN}✨ ¡Sistema reiniciado completamente!${NC}"
info "Acción ejecutada: Reinicio forzado completo (parada total + inicio limpio)"
