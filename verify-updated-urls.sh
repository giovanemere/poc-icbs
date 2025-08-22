#!/bin/bash

# =============================================================================
# Script de Verificación de URLs Actualizadas
# =============================================================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}=============================================================================${NC}"
echo -e "${GREEN}🔍 VERIFICACIÓN DE URLs ACTUALIZADAS${NC}"
echo -e "${PURPLE}=============================================================================${NC}"
echo ""

# Función para verificar URL
check_url() {
    local url=$1
    local description=$2
    local expected_code=${3:-200}
    
    echo -n -e "Verificando ${CYAN}$description${NC}... "
    
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" | grep -q "$expected_code"; then
        echo -e "${GREEN}✅ OK${NC} - $url"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC} - $url"
        return 1
    fi
}

echo -e "${YELLOW}🎯 DASHBOARD PRINCIPAL:${NC}"
echo -e "${CYAN}=================================${NC}"
check_url "http://localhost:8085/unified-dashboard-fixed.html" "🎛️ Dashboard Unificado Principal"
check_url "http://localhost:8084/" "📊 Dashboard de Tráfico"
echo ""

echo -e "${YELLOW}🌐 URLs del Sistema Completo${NC}"
echo ""

echo -e "${CYAN}🎛️ Dashboard Unificado (RECOMENDADO):${NC}"
check_url "http://localhost:8085/unified-dashboard-fixed.html" "Dashboard Principal ⭐"
echo -e "  ${CYAN}📊 Control A/B Testing + Canary + URLs Activas + Métricas${NC}"
echo ""

echo -e "${CYAN}📊 Dashboard de Tráfico WebLogic:${NC}"
check_url "http://localhost:8084/" "📊 Dashboard de Tráfico"
check_url "http://localhost:8084/api/stats" "📊 API de Estadísticas"
check_url "http://localhost:8084/api/health" "🔍 Health Check"
echo -e "  ${CYAN}🎯 A/B Testing API: http://localhost:8084/api/ab/apply (POST)${NC}"
echo -e "  ${CYAN}🚀 Canary Deployment API: http://localhost:8084/api/canary/apply (POST)${NC}"
echo -e "  ${CYAN}🔄 Reset Stats API: http://localhost:8084/api/reset (POST)${NC}"
echo ""

echo -e "${CYAN}🎛️ Panel de Administración HAProxy:${NC}"
check_url "http://localhost:8092/index-functional.html" "Panel HAProxy Funcional"
check_url "http://localhost:8092/" "Panel HAProxy Principal"
echo ""

echo -e "${CYAN}📡 API de Administración:${NC}"
check_url "http://localhost:8093/api/health" "API Health Check"
check_url "http://localhost:8093/api/status" "API Status"
echo ""

echo -e "${CYAN}📈 Estadísticas HAProxy:${NC}"
check_url "http://localhost:8404/stats" "HAProxy Stats (admin/admin123)"
echo ""

echo -e "${CYAN}🌐 Frontend Principal:${NC}"
check_url "http://localhost:8100/" "Frontend Principal"
echo ""

echo -e "${CYAN}🚀 Aplicaciones de Prueba:${NC}"
check_url "http://localhost:8100/version-a/" "Version A"
check_url "http://localhost:8100/version-b/" "Version B"
check_url "http://localhost:8100/feature-flags/" "Feature Flags"
echo ""

echo -e "${CYAN}🔧 Consolas WebLogic:${NC}"
check_url "http://localhost:7001/console" "WebLogic A Console (weblogic/welcome1)"
check_url "http://localhost:7002/console" "WebLogic B Console (weblogic/welcome1)"
echo ""

echo -e "${PURPLE}=============================================================================${NC}"
echo -e "${GREEN}✨ Verificación completada${NC}"
echo -e "${PURPLE}=============================================================================${NC}"
echo ""

echo -e "${CYAN}💡 URLs Principales para Acceso Rápido:${NC}"
echo -e "   🎛️ ${YELLOW}http://localhost:8085/unified-dashboard-fixed.html${NC} ⭐"
echo -e "   📊 ${YELLOW}http://localhost:8084/${NC}"
echo -e "   🌐 ${YELLOW}http://localhost:8100/${NC}"
echo ""
