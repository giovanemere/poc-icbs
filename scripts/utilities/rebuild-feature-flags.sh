#!/bin/bash
#
# Script para recompilar proyectos de feature-flags después de actualizar URLs
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"

echo -e "${BLUE}=== Recompilación de Proyectos Feature Flags ===${NC}"
echo ""

# Función para compilar un proyecto
compile_project() {
    local project_name="$1"
    local project_dir="$PROJECT_DIR/war-projects/$project_name"
    
    if [ ! -d "$project_dir" ]; then
        echo -e "${RED}✗ Directorio no encontrado: $project_dir${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}📦 Compilando $project_name...${NC}"
    cd "$project_dir"
    
    if [ -f "pom.xml" ]; then
        # Proyecto Maven
        if mvn clean package -q; then
            echo -e "${GREEN}✓ $project_name compilado exitosamente${NC}"
            
            # Mostrar ubicación del WAR
            if [ -f "target/$project_name.war" ]; then
                echo -e "${CYAN}  → WAR generado: target/$project_name.war${NC}"
            fi
        else
            echo -e "${RED}✗ Error compilando $project_name${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}ℹ $project_name no tiene pom.xml, omitiendo compilación${NC}"
    fi
    
    cd "$PROJECT_DIR"
}

# Compilar proyectos
compile_project "feature-flags"
compile_project "ff4j-simple"

echo ""
echo -e "${BLUE}📋 Próximos pasos:${NC}"
echo -e "${YELLOW}1. Desplegar WAR actualizados:${NC}"
echo -e "${CYAN}   ./scripts/deploy/deploy-war.sh --all${NC}"
echo ""
echo -e "${YELLOW}2. Verificar URLs actualizadas:${NC}"
echo -e "${CYAN}   ./scripts/verify-feature-flags-urls.sh${NC}"
echo ""
echo -e "${YELLOW}3. Verificar funcionamiento general:${NC}"
echo -e "${CYAN}   ./scripts/check-urls.sh${NC}"

echo ""
echo -e "${GREEN}✅ Recompilación completada${NC}"
