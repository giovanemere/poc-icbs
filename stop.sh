#!/bin/bash

# =============================================================================
# Script para Parar Todo el Sistema WebLogic
# =============================================================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🛑 Parando Sistema WebLogic Completo...${NC}"
echo ""

# Cambiar al directorio correcto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Parar servicios Docker
echo -e "${YELLOW}📦 Parando contenedores Docker...${NC}"
docker-compose -f config/docker-compose.yml down --remove-orphans

# Parar dashboards independientes
echo -e "${YELLOW}🎛️ Parando dashboards independientes...${NC}"
if [ -f "./manage-admin-panel.sh" ]; then
    ./manage-admin-panel.sh stop > /dev/null 2>&1 || true
fi

# Limpiar contenedores huérfanos
echo -e "${YELLOW}🧹 Limpiando contenedores huérfanos...${NC}"
docker stop haproxy weblogic-a weblogic-b orcldb haproxy-integrated weblogic-a-integrated weblogic-b-integrated orcldb-integrated 2>/dev/null || true
docker rm haproxy weblogic-a weblogic-b orcldb haproxy-integrated weblogic-a-integrated weblogic-b-integrated orcldb-integrated 2>/dev/null || true

# Mostrar estado final
echo -e "${BLUE}📊 Estado final:${NC}"
docker ps -a | grep -E "(weblogic|haproxy|oracle)" || echo "No hay contenedores relacionados corriendo"

echo ""
echo -e "${GREEN}✅ Sistema WebLogic parado completamente${NC}"
echo ""
echo -e "${YELLOW}💡 Para reiniciar, ejecuta: ./start.sh${NC}"
