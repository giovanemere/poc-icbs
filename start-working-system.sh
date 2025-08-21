#!/bin/bash

# =============================================================================
# Script para Iniciar el Sistema que FUNCIONABA
# Basado en la configuración del backup que ya estaba probada
# =============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "============================================================================="
echo "🚀 INICIANDO SISTEMA WEBLOGIC - CONFIGURACIÓN QUE FUNCIONABA"
echo "============================================================================="
echo -e "${NC}"

# Limpiar contenedores existentes
echo -e "${BLUE}🧹 Limpiando contenedores existentes...${NC}"
docker-compose -f config/docker-compose.yml down --remove-orphans 2>/dev/null || true
docker stop haproxy weblogic-a weblogic-b orcldb 2>/dev/null || true
docker rm haproxy weblogic-a weblogic-b orcldb 2>/dev/null || true

# Verificar imágenes
echo -e "${BLUE}🔍 Verificando imágenes...${NC}"
./check-images.sh

# Iniciar servicios Docker
echo -e "${BLUE}🚀 Iniciando servicios Docker...${NC}"
if docker-compose -f config/docker-compose.yml up -d; then
    echo -e "${GREEN}✅ Servicios Docker iniciados${NC}"
else
    echo -e "${RED}❌ Error al iniciar servicios Docker${NC}"
    exit 1
fi

# Esperar un poco para que los servicios se inicialicen
echo -e "${BLUE}⏳ Esperando inicialización de servicios...${NC}"
sleep 10

# Iniciar dashboards independientes (los que SÍ funcionaban)
echo -e "${BLUE}🎛️ Iniciando dashboards independientes...${NC}"
./manage-admin-panel.sh start

# Mostrar estado
echo -e "${BLUE}📊 Estado de contenedores:${NC}"
docker-compose -f config/docker-compose.yml ps

echo ""
echo -e "${PURPLE}=============================================================================${NC}"
echo -e "${GREEN}🎉 SISTEMA INICIADO - URLs QUE FUNCIONABAN${NC}"
echo -e "${PURPLE}=============================================================================${NC}"
echo ""

echo -e "${GREEN}🎛️ Dashboard Unificado (RECOMENDADO):${NC}"
echo -e "  ${PURPLE}http://localhost:8085/unified-dashboard-fixed.html${NC}  ⭐ Dashboard Principal"
echo -e "  ${CYAN}📊 Control A/B Testing + Canary + URLs Activas + Métricas${NC}"
echo ""

echo -e "${GREEN}📊 Dashboard de Tráfico WebLogic:${NC}"
echo -e "  ${PURPLE}http://localhost:8084/${NC}                    📊 Dashboard de Tráfico"
echo -e "  ${CYAN}http://localhost:8084/api/stats${NC}            📊 API de Estadísticas"
echo -e "  ${CYAN}http://localhost:8084/api/health${NC}           🔍 Health Check"
echo -e "  ${CYAN}http://localhost:8084/api/ab/enable${NC}        🎯 A/B Testing API"
echo -e "  ${CYAN}http://localhost:8084/api/canary/enable${NC}    🚀 Canary Deployment API"
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
echo "  http://localhost:8100/ff4j-simple/"
echo ""

echo -e "${GREEN}🔧 Consolas WebLogic:${NC}"
echo "  http://localhost:7001/console (weblogic/welcome1)"
echo "  http://localhost:7002/console (weblogic/welcome1)"
echo ""

echo -e "${CYAN}💡 Tip: Los dashboards independientes (8084, 8085, 8092, 8093) funcionan${NC}"
echo -e "${CYAN}    independientemente de HAProxy y son los más confiables.${NC}"
echo ""

echo -e "${GREEN}✨ ¡Sistema listo para usar!${NC}"
