#!/bin/bash

# =============================================================================
# Script para Verificar que las URLs estén Actualizadas Correctamente
# =============================================================================

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔍 Verificando URLs actualizadas en archivos de configuración...${NC}"
echo ""

# Función para verificar archivo
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        echo -e "${YELLOW}📄 $description ($file):${NC}"
        
        # Buscar puerto 8100
        if grep -q "localhost:8100" "$file"; then
            echo -e "${GREEN}   ✅ Puerto 8100 encontrado${NC}"
            grep -n "localhost:8100" "$file" | head -3 | sed 's/^/      /'
        else
            echo -e "${RED}   ❌ Puerto 8100 NO encontrado${NC}"
        fi
        
        # Buscar puerto 8080 (debería estar solo en comentarios)
        if grep -q "localhost:8080" "$file" && ! grep -q "#.*localhost:8080" "$file"; then
            echo -e "${RED}   ⚠️  Puerto 8080 aún presente (debería ser 8100)${NC}"
            grep -n "localhost:8080" "$file" | head -2 | sed 's/^/      /'
        fi
        
        echo ""
    else
        echo -e "${RED}❌ Archivo no encontrado: $file${NC}"
        echo ""
    fi
}

# Verificar archivos principales
check_file "config/docker-compose.yml" "Docker Compose"
check_file ".env" "Variables de Entorno"
check_file "start-working-system.sh" "Script Principal"
check_file "start-complete-system.sh" "Script Completo"
check_file "manage-admin-panel.sh" "Panel de Administración"

echo -e "${BLUE}📊 Resumen de Puertos Configurados:${NC}"
echo ""

# Verificar .env
if [ -f ".env" ]; then
    echo -e "${YELLOW}Variables de entorno (.env):${NC}"
    grep "EXTERNAL.*PORT" .env | sed 's/^/   /'
    echo ""
fi

# Verificar docker-compose
if [ -f "config/docker-compose.yml" ]; then
    echo -e "${YELLOW}Puertos en docker-compose.yml:${NC}"
    grep -A 5 "ports:" config/docker-compose.yml | grep -E "^\s*-\s*\".*:.*\"" | sed 's/^/   /'
    echo ""
fi

echo -e "${GREEN}🎯 URLs Finales que Deberían Funcionar:${NC}"
echo -e "   🌐 Frontend Principal: ${YELLOW}http://localhost:8100/${NC}"
echo -e "   🚀 Version A: ${YELLOW}http://localhost:8100/version-a/${NC}"
echo -e "   🚀 Version B: ${YELLOW}http://localhost:8100/version-b/${NC}"
echo -e "   🚀 Feature Flags: ${YELLOW}http://localhost:8100/feature-flags/${NC}"
echo -e "   📈 HAProxy Stats: ${YELLOW}http://localhost:8404/stats${NC}"
echo ""

echo -e "${BLUE}✨ Verificación completada${NC}"
