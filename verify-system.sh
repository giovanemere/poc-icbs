#!/bin/bash

# =============================================================================
# Script de Verificación Final del Sistema Actualizado
# =============================================================================

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}🔍 Verificación Final del Sistema WebLogic Actualizado${NC}"
echo ""

# Verificar archivos principales
echo -e "${YELLOW}📋 Verificando archivos principales:${NC}"

files=(
    "start.sh"
    "stop.sh"
    "start-unified-system.sh"
    "verify-urls.sh"
    "check-images.sh"
    "config/docker-compose.yml"
    ".env"
    "README.md"
    "INSTRUCCIONES-UNIFICADAS.md"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "   ${GREEN}✅ $file${NC}"
    else
        echo -e "   ${RED}❌ $file (FALTANTE)${NC}"
    fi
done

echo ""

# Verificar scripts ejecutables
echo -e "${YELLOW}🔧 Verificando permisos de ejecución:${NC}"

executable_files=(
    "start.sh"
    "stop.sh"
    "start-unified-system.sh"
    "verify-urls.sh"
    "check-images.sh"
)

for file in "${executable_files[@]}"; do
    if [ -x "$file" ]; then
        echo -e "   ${GREEN}✅ $file (ejecutable)${NC}"
    else
        echo -e "   ${RED}❌ $file (no ejecutable)${NC}"
    fi
done

echo ""

# Verificar puertos actualizados
echo -e "${YELLOW}🌐 Verificando puertos actualizados:${NC}"

if grep -q "EXTERNAL_HTTP_PORT=8100" .env 2>/dev/null; then
    echo -e "   ${GREEN}✅ Puerto 8100 configurado en .env${NC}"
else
    echo -e "   ${RED}❌ Puerto 8100 NO configurado en .env${NC}"
fi

if grep -q "EXTERNAL_HTTP_PORT:-8100" config/docker-compose.yml 2>/dev/null; then
    echo -e "   ${GREEN}✅ Puerto 8100 configurado en docker-compose.yml${NC}"
else
    echo -e "   ${RED}❌ Puerto 8100 NO configurado en docker-compose.yml${NC}"
fi

echo ""

# Verificar imágenes locales
echo -e "${YELLOW}🐳 Verificando imágenes Docker locales:${NC}"

images=(
    "weblogic-version-a:latest"
    "weblogic-version-b:latest"
    "haproxy-advanced:latest"
    "edissonz8809/oracle-express-db:latest"
)

for image in "${images[@]}"; do
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
        echo -e "   ${GREEN}✅ $image${NC}"
    else
        echo -e "   ${RED}❌ $image (NO ENCONTRADA)${NC}"
    fi
done

echo ""

# Mostrar comandos principales
echo -e "${PURPLE}🚀 Comandos Principales Actualizados:${NC}"
echo ""
echo -e "${YELLOW}Build WAR Files:${NC}"
echo -e "   ${BLUE}cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./scripts/build/build-wars.sh${NC}"
echo ""
echo -e "${YELLOW}Build Docker Images:${NC}"
echo -e "   ${BLUE}cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./build-latest.sh${NC}"
echo ""
echo -e "${YELLOW}Iniciar Sistema Completo:${NC}"
echo -e "   ${BLUE}cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh${NC}"
echo ""
echo -e "${YELLOW}Parar Sistema:${NC}"
echo -e "   ${BLUE}cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./stop.sh${NC}"
echo ""
echo -e "${YELLOW}MkDocs Desarrollo:${NC}"
echo -e "   ${BLUE}cd /path/to/mkdocs-project && mkdocs serve --dev-addr=0.0.0.0:8000${NC}"
echo ""

# URLs principales
echo -e "${PURPLE}🌐 URLs Principales (Puerto 8100 Actualizado):${NC}"
echo ""
echo -e "   🎛️ Dashboard Principal: ${YELLOW}http://localhost:8085/unified-dashboard-fixed.html${NC}"
echo -e "   📊 Dashboard de Tráfico: ${YELLOW}http://localhost:8084/${NC}"
echo -e "   🌐 Frontend Principal: ${YELLOW}http://localhost:8100/${NC}"
echo -e "   🚀 Version A: ${YELLOW}http://localhost:8100/version-a/${NC}"
echo -e "   🚀 Version B: ${YELLOW}http://localhost:8100/version-b/${NC}"
echo -e "   🚀 Feature Flags: ${YELLOW}http://localhost:8100/feature-flags/${NC}"
echo -e "   📈 HAProxy Stats: ${YELLOW}http://localhost:8404/stats${NC}"
echo -e "   📚 MkDocs (desarrollo): ${YELLOW}http://localhost:8000${NC}"
echo ""

echo -e "${GREEN}✨ Verificación completada${NC}"
echo -e "${BLUE}💡 Para iniciar todo: ./start.sh${NC}"
