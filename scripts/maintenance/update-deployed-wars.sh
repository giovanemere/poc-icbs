#!/bin/bash
#
# Script para actualizar archivos WAR desplegados con las nuevas URLs
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        Actualizador de WAR Desplegados - Feature Flags      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}=== Actualización de archivos WAR desplegados ===${NC}"
echo ""

# Función para actualizar un archivo WAR
update_war_file() {
    local war_path="$1"
    local war_name=$(basename "$war_path" .war)
    local temp_dir="/tmp/update_war_$$"
    
    if [ ! -f "$war_path" ]; then
        echo -e "${YELLOW}⚠ Archivo WAR no encontrado: $war_path${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📦 Actualizando WAR: $war_name${NC}"
    
    # Crear directorio temporal
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Extraer WAR
    echo -e "${YELLOW}  → Extrayendo WAR...${NC}"
    jar -xf "$war_path"
    
    # Actualizar URLs en archivos HTML
    echo -e "${YELLOW}  → Actualizando URLs en archivos HTML...${NC}"
    find . -name "*.html" -type f -exec sed -i 's/localhost:8080/localhost:8083/g' {} \;
    
    # Actualizar URLs en archivos JavaScript
    echo -e "${YELLOW}  → Actualizando URLs en archivos JavaScript...${NC}"
    find . -name "*.js" -type f -exec sed -i 's/localhost:8080/localhost:8083/g' {} \;
    
    # Actualizar URLs en archivos JSP
    echo -e "${YELLOW}  → Actualizando URLs en archivos JSP...${NC}"
    find . -name "*.jsp" -type f -exec sed -i 's/localhost:8080/localhost:8083/g' {} \;
    
    # Crear backup del WAR original
    cp "$war_path" "$war_path.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}  ✓ Backup creado: $(basename "$war_path").backup.$(date +%Y%m%d_%H%M%S)${NC}"
    
    # Recrear WAR
    echo -e "${YELLOW}  → Recreando WAR...${NC}"
    jar -cf "$war_path" *
    
    # Limpiar directorio temporal
    cd "$PROJECT_DIR"
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}  ✓ WAR actualizado: $war_name${NC}"
    echo ""
}

# Actualizar archivos WAR en deploy/
echo -e "${YELLOW}📁 Actualizando archivos WAR en deploy/...${NC}"
if [ -f "$PROJECT_DIR/deploy/feature-flags.war" ]; then
    update_war_file "$PROJECT_DIR/deploy/feature-flags.war"
fi

if [ -f "$PROJECT_DIR/deploy/ff4j-simple.war" ]; then
    update_war_file "$PROJECT_DIR/deploy/ff4j-simple.war"
fi

# Actualizar archivos WAR en autodeploy/
echo -e "${YELLOW}📁 Actualizando archivos WAR en autodeploy/...${NC}"
if [ -f "$PROJECT_DIR/autodeploy/feature-flags.war" ]; then
    update_war_file "$PROJECT_DIR/autodeploy/feature-flags.war"
fi

if [ -f "$PROJECT_DIR/autodeploy/ff4j-simple.war" ]; then
    update_war_file "$PROJECT_DIR/autodeploy/ff4j-simple.war"
fi

echo -e "${YELLOW}🔄 Reiniciando servicios para aplicar cambios...${NC}"
./manage-services.sh restart

echo ""
echo -e "${GREEN}=== Actualización de WAR completada ===${NC}"
echo ""
echo -e "${BLUE}📋 Próximos pasos:${NC}"
echo -e "${YELLOW}1. Verificar URLs actualizadas:${NC} ${CYAN}./scripts/verify-feature-flags-urls.sh${NC}"
echo -e "${YELLOW}2. Probar funcionalidad:${NC} ${CYAN}curl -s http://localhost:8083/feature-flags/ | grep localhost${NC}"
echo ""
echo -e "${GREEN}✅ Archivos WAR actualizados con los nuevos puertos ICBS${NC}"
