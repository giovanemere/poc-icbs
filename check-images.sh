#!/bin/bash

# =============================================================================
# Script para Verificar Imágenes Docker Disponibles
# =============================================================================

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Verificando imágenes Docker disponibles...${NC}"
echo ""

# Función para verificar imagen
check_image() {
    local image_name=$1
    local service_name=$2
    
    if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^${image_name}$"; then
        local created=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedSince}}" | grep "^${image_name}" | awk '{print $2, $3}')
        echo -e "${GREEN}✅ $service_name: $image_name (Creada: $created)${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name: $image_name (NO ENCONTRADA)${NC}"
        return 1
    fi
}

# Verificar imágenes requeridas
echo -e "${YELLOW}📋 Imágenes requeridas por docker-compose:${NC}"
check_image "weblogic-version-a:latest" "WebLogic A"
check_image "weblogic-version-b:latest" "WebLogic B"
check_image "haproxy-advanced:latest" "HAProxy"
check_image "edissonz8809/oracle-express-db:latest" "Oracle DB"

echo ""
echo -e "${YELLOW}📊 Todas las imágenes WebLogic disponibles:${NC}"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedSince}}\t{{.Size}}" | grep -E "(weblogic|oracle|haproxy)" | head -10

echo ""
echo -e "${BLUE}ℹ️  Si alguna imagen no está disponible, puedes construirla con:${NC}"
echo -e "   ${YELLOW}docker build -t weblogic-version-a:latest .${NC}"
echo -e "   ${YELLOW}docker build -t weblogic-version-b:latest .${NC}"
