#!/bin/bash

# =============================================================================
# Script de Estado - WebLogic System
# Muestra información detallada del estado de todos los servicios
# =============================================================================

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
echo "📊 ESTADO DEL SISTEMA WEBLOGIC"
echo "============================================================================="
echo -e "${NC}"

# Cambiar al directorio correcto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# =============================================================================
# ESTADO DE CONTENEDORES DOCKER
# =============================================================================
log "Estado de Contenedores Docker:"
echo ""

if [ -f "config/docker-compose.yml" ]; then
    # Obtener información de contenedores
    CONTAINERS=$(docker-compose -f config/docker-compose.yml ps -q 2>/dev/null || echo "")
    RUNNING_CONTAINERS=$(docker-compose -f config/docker-compose.yml ps -q --filter "status=running" 2>/dev/null || echo "")
    
    TOTAL_COUNT=$(echo "$CONTAINERS" | grep -v '^$' | wc -l)
    RUNNING_COUNT=$(echo "$RUNNING_CONTAINERS" | grep -v '^$' | wc -l)
    
    echo -e "${CYAN}📦 Contenedores Totales: $TOTAL_COUNT${NC}"
    echo -e "${GREEN}▶️  Contenedores Corriendo: $RUNNING_COUNT${NC}"
    echo ""
    
    if [ "$TOTAL_COUNT" -gt 0 ]; then
        echo -e "${CYAN}Estado detallado de contenedores:${NC}"
        docker-compose -f config/docker-compose.yml ps
        echo ""
    else
        warning "No hay contenedores definidos o docker-compose no está disponible"
    fi
else
    error "Archivo docker-compose.yml no encontrado"
fi

# =============================================================================
# ESTADO DE PUERTOS
# =============================================================================
log "Estado de Puertos:"
echo ""

PORTS_TO_CHECK="8085:Dashboard-Unificado 8084:Dashboard-Tráfico 8092:Panel-HAProxy 8093:API-Admin 8100:Frontend-Principal 8404:HAProxy-Stats 7001:WebLogic-A 7002:WebLogic-B 1521:Oracle-DB 5500:Oracle-EM"

echo -e "${CYAN}Puerto  | Servicio              | Estado${NC}"
echo -e "${CYAN}--------|----------------------|--------${NC}"

for port_service in $PORTS_TO_CHECK; do
    port=$(echo $port_service | cut -d':' -f1)
    service=$(echo $port_service | cut -d':' -f2)
    
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}$port    | $service | ✅ ACTIVO${NC}"
    else
        echo -e "${RED}$port    | $service | ❌ INACTIVO${NC}"
    fi
done

echo ""

# =============================================================================
# VERIFICACIÓN DE URLs
# =============================================================================
log "Verificación de URLs Principales:"
echo ""

# Función para verificar URL
check_url() {
    local url=$1
    local name=$2
    local timeout=5
    
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout $timeout "$url" | grep -q "200\|301\|302"; then
        echo -e "${GREEN}✅ $name${NC} - $url"
    else
        echo -e "${RED}❌ $name${NC} - $url"
    fi
}

echo -e "${CYAN}🎛️ Dashboards Principales:${NC}"
check_url "http://localhost:8085/unified-dashboard-fixed.html" "Dashboard Unificado"
check_url "http://localhost:8084/" "Dashboard de Tráfico"
check_url "http://localhost:8092/index-functional.html" "Panel HAProxy"
check_url "http://localhost:8093/api/health" "API Admin"

echo ""
echo -e "${CYAN}🌐 Frontend y Aplicaciones:${NC}"
check_url "http://localhost:8100/" "Frontend Principal"
check_url "http://localhost:8100/version-a/" "Version A"
check_url "http://localhost:8100/version-b/" "Version B"
check_url "http://localhost:8100/feature-flags/" "Feature Flags"

echo ""
echo -e "${CYAN}📈 Administración:${NC}"
check_url "http://localhost:8404/stats" "HAProxy Stats"
check_url "http://localhost:7001/console" "WebLogic A Console"
check_url "http://localhost:7002/console" "WebLogic B Console"

echo ""

# =============================================================================
# RECURSOS DEL SISTEMA
# =============================================================================
log "Recursos del Sistema:"
echo ""

# Uso de CPU y memoria de contenedores Docker
if command -v docker &> /dev/null && [ "$RUNNING_COUNT" -gt 0 ]; then
    echo -e "${CYAN}📊 Uso de recursos por contenedor:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" $(docker-compose -f config/docker-compose.yml ps -q 2>/dev/null) 2>/dev/null || echo "No se pudo obtener estadísticas de recursos"
    echo ""
fi

# Espacio en disco
echo -e "${CYAN}💾 Espacio en disco:${NC}"
df -h . | tail -1 | awk '{print "Disponible: " $4 " de " $2 " (" $5 " usado)"}'
echo ""

# =============================================================================
# LOGS RECIENTES
# =============================================================================
log "Logs Recientes (últimas 5 líneas por servicio):"
echo ""

if [ "$RUNNING_COUNT" -gt 0 ]; then
    SERVICES="unified-dashboard traffic-dashboard haproxy-admin-panel admin-api haproxy-integrated weblogic-a-integrated weblogic-b-integrated orcldb-integrated"
    
    for service in $SERVICES; do
        if docker ps --format "{{.Names}}" | grep -q "^$service$"; then
            echo -e "${CYAN}📋 $service:${NC}"
            docker logs --tail 3 "$service" 2>/dev/null | sed 's/^/  /' || echo "  No hay logs disponibles"
            echo ""
        fi
    done
else
    warning "No hay contenedores corriendo para mostrar logs"
fi

# =============================================================================
# RESUMEN Y RECOMENDACIONES
# =============================================================================
echo -e "${PURPLE}=============================================================================${NC}"
echo -e "${CYAN}📋 RESUMEN DEL ESTADO${NC}"
echo -e "${PURPLE}=============================================================================${NC}"

if [ "$RUNNING_COUNT" -eq "$TOTAL_COUNT" ] && [ "$RUNNING_COUNT" -gt 0 ]; then
    success "Sistema completamente operativo ($RUNNING_COUNT/$TOTAL_COUNT servicios corriendo)"
    echo ""
    echo -e "${GREEN}🎯 URLs principales para acceder:${NC}"
    echo -e "   🎛️ ${YELLOW}http://localhost:8085/unified-dashboard-fixed.html${NC} ⭐"
    echo -e "   📊 ${YELLOW}http://localhost:8084/${NC}"
    echo -e "   🌐 ${YELLOW}http://localhost:8100/${NC}"
elif [ "$RUNNING_COUNT" -gt 0 ]; then
    warning "Sistema parcialmente operativo ($RUNNING_COUNT/$TOTAL_COUNT servicios corriendo)"
    echo ""
    echo -e "${YELLOW}🔧 Comandos recomendados:${NC}"
    echo -e "   Reinicio inteligente: ${CYAN}./start.sh${NC}"
    echo -e "   Reinicio forzado: ${CYAN}./force-restart.sh${NC}"
    echo -e "   Ver logs: ${CYAN}docker-compose -f config/docker-compose.yml logs -f${NC}"
else
    error "Sistema no operativo (0/$TOTAL_COUNT servicios corriendo)"
    echo ""
    echo -e "${RED}🚀 Comandos para iniciar:${NC}"
    echo -e "   Inicio inteligente: ${CYAN}./start.sh${NC}"
    echo -e "   Inicio completo: ${CYAN}./start-unified-system.sh${NC}"
fi

echo ""
echo -e "${CYAN}🔧 Comandos útiles:${NC}"
echo -e "   Estado: ${YELLOW}./status.sh${NC}"
echo -e "   Inicio inteligente: ${YELLOW}./start.sh${NC}"
echo -e "   Reinicio forzado: ${YELLOW}./force-restart.sh${NC}"
echo -e "   Parar todo: ${YELLOW}./stop.sh${NC}"
echo -e "   Verificar URLs: ${YELLOW}./verify-updated-urls.sh${NC}"
echo ""

echo -e "${GREEN}✨ Estado verificado completamente${NC}"
