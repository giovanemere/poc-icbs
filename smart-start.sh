#!/bin/bash

# =============================================================================
# Script Inteligente de Inicio/Reinicio - WebLogic System
# Detecta si los servicios están corriendo y decide si iniciar o reiniciar
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
echo "🧠 INICIO INTELIGENTE - SISTEMA WEBLOGIC"
echo "============================================================================="
echo -e "${NC}"

# Cambiar al directorio correcto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# =============================================================================
# FASE 1: DETECTAR ESTADO DE LOS SERVICIOS
# =============================================================================
log "FASE 1: Detectando estado de los servicios..."

# Verificar si docker-compose está disponible
if ! command -v docker-compose &> /dev/null; then
    error "docker-compose no está instalado"
    exit 1
fi

# Verificar si el archivo docker-compose existe
if [ ! -f "config/docker-compose.yml" ]; then
    error "Archivo docker-compose.yml no encontrado"
    exit 1
fi

# Obtener lista de contenedores del proyecto
CONTAINERS=$(docker-compose -f config/docker-compose.yml ps -q 2>/dev/null || echo "")
RUNNING_CONTAINERS=$(docker-compose -f config/docker-compose.yml ps -q --filter "status=running" 2>/dev/null || echo "")

# Contar contenedores
TOTAL_CONTAINERS=$(echo "$CONTAINERS" | grep -v '^$' | wc -l)
RUNNING_COUNT=$(echo "$RUNNING_CONTAINERS" | grep -v '^$' | wc -l)

log "Contenedores totales definidos: $TOTAL_CONTAINERS"
log "Contenedores corriendo: $RUNNING_COUNT"

# =============================================================================
# FASE 2: DECIDIR ACCIÓN BASADA EN EL ESTADO
# =============================================================================

if [ "$TOTAL_CONTAINERS" -eq 0 ]; then
    # No hay contenedores, inicio completo
    log "DECISIÓN: Inicio completo (no hay contenedores existentes)"
    ACTION="FULL_START"
elif [ "$RUNNING_COUNT" -eq 0 ]; then
    # Hay contenedores pero ninguno corriendo, inicio normal
    log "DECISIÓN: Inicio normal (contenedores parados)"
    ACTION="START"
elif [ "$RUNNING_COUNT" -lt "$TOTAL_CONTAINERS" ]; then
    # Algunos contenedores corriendo, reinicio parcial
    warning "DECISIÓN: Reinicio parcial (algunos servicios caídos: $RUNNING_COUNT/$TOTAL_CONTAINERS)"
    ACTION="PARTIAL_RESTART"
else
    # Todos los contenedores corriendo, reinicio completo
    success "DECISIÓN: Reinicio rápido (todos los servicios corriendo: $RUNNING_COUNT/$TOTAL_CONTAINERS)"
    ACTION="RESTART"
fi

# =============================================================================
# FASE 3: EJECUTAR ACCIÓN CORRESPONDIENTE
# =============================================================================

case $ACTION in
    "FULL_START")
        log "FASE 3: Ejecutando inicio completo..."
        echo -e "${CYAN}🚀 Iniciando sistema desde cero...${NC}"
        
        # Limpiar cualquier resto
        docker-compose -f config/docker-compose.yml down --remove-orphans 2>/dev/null || true
        
        # Inicio completo
        docker-compose -f config/docker-compose.yml up -d
        ;;
        
    "START")
        log "FASE 3: Ejecutando inicio normal..."
        echo -e "${CYAN}▶️  Iniciando contenedores parados...${NC}"
        
        docker-compose -f config/docker-compose.yml up -d
        ;;
        
    "PARTIAL_RESTART")
        log "FASE 3: Ejecutando reinicio parcial..."
        echo -e "${YELLOW}🔄 Reiniciando servicios parcialmente...${NC}"
        
        # Parar todos y reiniciar
        docker-compose -f config/docker-compose.yml down
        sleep 2
        docker-compose -f config/docker-compose.yml up -d
        ;;
        
    "RESTART")
        log "FASE 3: Ejecutando reinicio rápido..."
        echo -e "${GREEN}⚡ Reiniciando servicios (modo rápido)...${NC}"
        
        # Reinicio rápido sin parar completamente
        docker-compose -f config/docker-compose.yml restart
        ;;
esac

# =============================================================================
# FASE 4: VERIFICAR ESTADO FINAL
# =============================================================================
log "FASE 4: Verificando estado final..."

sleep 5

# Verificar contenedores finales
FINAL_RUNNING=$(docker-compose -f config/docker-compose.yml ps -q --filter "status=running" 2>/dev/null | wc -l)
FINAL_TOTAL=$(docker-compose -f config/docker-compose.yml ps -q 2>/dev/null | wc -l)

if [ "$FINAL_RUNNING" -eq "$FINAL_TOTAL" ] && [ "$FINAL_RUNNING" -gt 0 ]; then
    success "Todos los servicios están corriendo ($FINAL_RUNNING/$FINAL_TOTAL)"
    
    # Mostrar estado de los servicios
    echo ""
    log "Estado de los servicios:"
    docker-compose -f config/docker-compose.yml ps
    
else
    warning "Algunos servicios pueden no estar corriendo correctamente ($FINAL_RUNNING/$FINAL_TOTAL)"
    
    # Mostrar estado detallado
    echo ""
    log "Estado detallado de los servicios:"
    docker-compose -f config/docker-compose.yml ps
    
    echo ""
    warning "Puedes ver los logs con: docker-compose -f config/docker-compose.yml logs -f"
fi

# =============================================================================
# FASE 5: MOSTRAR URLs
# =============================================================================
echo ""
echo -e "${PURPLE}=============================================================================${NC}"
echo -e "${GREEN}🎉 SISTEMA INICIADO/REINICIADO CORRECTAMENTE${NC}"
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
echo -e "   Parar todo: ${YELLOW}docker-compose -f config/docker-compose.yml down${NC}"
echo -e "   Reiniciar inteligente: ${YELLOW}./smart-start.sh${NC}"
echo -e "   Estado: ${YELLOW}docker-compose -f config/docker-compose.yml ps${NC}"
echo ""

echo -e "${GREEN}🎯 URLs Completas del Sistema:${NC}"
echo ""
echo -e "${GREEN}🎛️ Dashboard Unificado (RECOMENDADO):${NC}"
echo -e "  ${PURPLE}http://localhost:8085/unified-dashboard-fixed.html${NC}  ⭐ Dashboard Principal"
echo -e "  ${CYAN}📊 Control A/B Testing + Canary + URLs Activas + Métricas${NC}"
echo ""
echo -e "${GREEN}📊 Dashboard de Tráfico WebLogic:${NC}"
echo -e "  ${PURPLE}http://localhost:8084/${NC}                    📊 Dashboard de Tráfico"
echo -e "  ${CYAN}http://localhost:8084/api/stats${NC}            📊 API de Estadísticas"
echo -e "  ${CYAN}http://localhost:8084/api/health${NC}           🔍 Health Check"
echo -e "  ${CYAN}http://localhost:8084/api/ab/apply${NC}         🎯 A/B Testing API"
echo -e "  ${CYAN}http://localhost:8084/api/canary/apply${NC}     🚀 Canary Deployment API"
echo -e "  ${CYAN}http://localhost:8084/api/reset${NC}            🔄 Reset Stats API"
echo ""
echo -e "${GREEN}🎛️ Panel de Administración HAProxy:${NC}"
echo "  http://localhost:8092/index-functional.html"
echo "  http://localhost:8092/"
echo ""
echo -e "${GREEN}📡 API de Administración:${NC}"
echo "  http://localhost:8093/api/health"
echo "  http://localhost:8093/api/status"
echo ""
echo -e "${GREEN}📈 Estadísticas HAProxy:${NC}"
echo "  http://localhost:8404/stats (admin/admin123)"
echo ""
echo -e "${GREEN}🌐 Frontend Principal:${NC}"
echo "  http://localhost:8100/"
echo ""
echo -e "${GREEN}🚀 Aplicaciones de Prueba:${NC}"
echo "  http://localhost:8100/version-a/"
echo "  http://localhost:8100/version-b/"
echo "  http://localhost:8100/feature-flags/"
echo ""
echo -e "${GREEN}🔧 Consolas WebLogic:${NC}"
echo "  http://localhost:7001/console (weblogic/welcome1)"
echo "  http://localhost:7002/console (weblogic/welcome1)"
echo ""

echo -e "${CYAN}💡 Tip: Este script detecta automáticamente el estado de los servicios${NC}"
echo -e "${CYAN}    y ejecuta la acción más eficiente (inicio, reinicio parcial o completo).${NC}"
echo ""

echo -e "${GREEN}✨ ¡Sistema listo para usar!${NC}"

# Mostrar resumen de la acción ejecutada
case $ACTION in
    "FULL_START")
        info "Acción ejecutada: Inicio completo desde cero"
        ;;
    "START")
        info "Acción ejecutada: Inicio de contenedores parados"
        ;;
    "PARTIAL_RESTART")
        info "Acción ejecutada: Reinicio parcial (algunos servicios caídos)"
        ;;
    "RESTART")
        info "Acción ejecutada: Reinicio rápido (todos los servicios estaban corriendo)"
        ;;
esac
