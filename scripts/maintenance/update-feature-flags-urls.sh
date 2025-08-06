#!/bin/bash
#
# Script para actualizar URLs en el desarrollo de feature-flags
# Actualiza todas las referencias de localhost:8080 a localhost:8083 (puerto dinámico HAProxy)
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
FEATURE_FLAGS_DIR="$PROJECT_DIR/war-projects/feature-flags"
FF4J_SIMPLE_DIR="$PROJECT_DIR/war-projects/ff4j-simple"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        Actualizador de URLs - Feature Flags ICBS            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}=== Actualización de URLs en Feature Flags ===${NC}"
echo -e "${YELLOW}Cambiando localhost:8080 → localhost:8083 (HAProxy dinámico)${NC}"
echo ""

# Función para hacer backup de un archivo
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${GREEN}✓ Backup creado: $(basename "$file").backup.$(date +%Y%m%d_%H%M%S)${NC}"
    fi
}

# Función para actualizar URLs en un archivo
update_urls_in_file() {
    local file="$1"
    local description="$2"
    
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}⚠ Archivo no encontrado: $file${NC}"
        return
    fi
    
    echo -e "${BLUE}Actualizando: $description${NC}"
    backup_file "$file"
    
    # Contar ocurrencias antes de la actualización
    local count_before=$(grep -c "localhost:8080" "$file" 2>/dev/null || echo "0")
    
    # Actualizar URLs de localhost:8080 a localhost:8083
    sed -i 's/localhost:8080/localhost:8083/g' "$file"
    
    # Contar ocurrencias después de la actualización
    local count_after=$(grep -c "localhost:8083" "$file" 2>/dev/null || echo "0")
    
    if [ "$count_before" -gt 0 ]; then
        echo -e "${GREEN}✓ Actualizado: $file ($count_before URLs cambiadas)${NC}"
    else
        echo -e "${YELLOW}ℹ Sin cambios necesarios: $file${NC}"
    fi
}

# Función para actualizar URLs con lógica dinámica en JavaScript
update_js_dynamic_urls() {
    local file="$1"
    local description="$2"
    
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}⚠ Archivo no encontrado: $file${NC}"
        return
    fi
    
    echo -e "${BLUE}Actualizando con puerto dinámico: $description${NC}"
    backup_file "$file"
    
    # Actualizar la configuración en JavaScript para usar puerto dinámico
    if grep -q "localhost:8080" "$file"; then
        # Reemplazar URLs estáticas con puerto dinámico
        sed -i 's/localhost:8080/localhost:8083/g' "$file"
        
        # Agregar comentario sobre puerto dinámico
        if ! grep -q "Puerto dinámico HAProxy" "$file"; then
            sed -i '/const CONFIG = {/i\
// Puerto dinámico HAProxy - configurado automáticamente' "$file"
        fi
        
        echo -e "${GREEN}✓ JavaScript actualizado con puerto dinámico: $file${NC}"
    else
        echo -e "${YELLOW}ℹ Sin cambios necesarios en JavaScript: $file${NC}"
    fi
}

echo -e "${YELLOW}📁 Actualizando proyecto feature-flags...${NC}"

# Actualizar archivos HTML del proyecto feature-flags
update_urls_in_file "$FEATURE_FLAGS_DIR/index.html" "Feature Flags - Página principal"
update_urls_in_file "$FEATURE_FLAGS_DIR/admin.html" "Feature Flags - Administración"
update_urls_in_file "$FEATURE_FLAGS_DIR/info.html" "Feature Flags - Información"

# Actualizar archivo JavaScript con lógica dinámica
update_js_dynamic_urls "$FEATURE_FLAGS_DIR/js/feature-flags.js" "Feature Flags - JavaScript"

echo ""
echo -e "${YELLOW}📁 Actualizando proyecto ff4j-simple...${NC}"

# Actualizar archivos HTML del proyecto ff4j-simple
update_urls_in_file "$FF4J_SIMPLE_DIR/index.html" "FF4J Simple - Página principal"
update_urls_in_file "$FF4J_SIMPLE_DIR/info.html" "FF4J Simple - Información"

echo ""
echo -e "${YELLOW}📁 Buscando otros archivos con URLs a actualizar...${NC}"

# Buscar otros archivos que puedan contener URLs
echo -e "${BLUE}Buscando archivos adicionales con localhost:8080...${NC}"

# Buscar en archivos JSP
if find "$PROJECT_DIR/war-projects" -name "*.jsp" -type f 2>/dev/null | head -1 >/dev/null; then
    echo -e "${BLUE}Archivos JSP encontrados:${NC}"
    find "$PROJECT_DIR/war-projects" -name "*.jsp" -type f -exec grep -l "localhost:8080" {} \; 2>/dev/null | while read file; do
        update_urls_in_file "$file" "JSP - $(basename "$file")"
    done
fi

# Buscar en archivos XML (configuración)
if find "$PROJECT_DIR/war-projects" -name "*.xml" -type f 2>/dev/null | head -1 >/dev/null; then
    echo -e "${BLUE}Archivos XML encontrados:${NC}"
    find "$PROJECT_DIR/war-projects" -name "*.xml" -type f -exec grep -l "localhost:8080" {} \; 2>/dev/null | while read file; do
        update_urls_in_file "$file" "XML - $(basename "$file")"
    done
fi

# Buscar en archivos de propiedades
if find "$PROJECT_DIR/war-projects" -name "*.properties" -type f 2>/dev/null | head -1 >/dev/null; then
    echo -e "${BLUE}Archivos de propiedades encontrados:${NC}"
    find "$PROJECT_DIR/war-projects" -name "*.properties" -type f -exec grep -l "localhost:8080" {} \; 2>/dev/null | while read file; do
        update_urls_in_file "$file" "Properties - $(basename "$file")"
    done
fi

echo ""
echo -e "${YELLOW}📁 Verificando archivos WAR compilados...${NC}"

# Verificar si hay archivos WAR que necesiten recompilación
WAR_FILES_FOUND=false
for project in feature-flags ff4j-simple; do
    if [ -d "$PROJECT_DIR/war-projects/$project/target" ]; then
        if find "$PROJECT_DIR/war-projects/$project/target" -name "*.war" -type f 2>/dev/null | head -1 >/dev/null; then
            WAR_FILES_FOUND=true
            echo -e "${YELLOW}⚠ Archivos WAR encontrados en $project/target/${NC}"
        fi
    fi
done

if [ "$WAR_FILES_FOUND" = true ]; then
    echo -e "${YELLOW}📦 Se recomienda recompilar los proyectos para aplicar los cambios:${NC}"
    echo -e "${CYAN}  cd $PROJECT_DIR/war-projects/feature-flags && mvn clean package${NC}"
    echo -e "${CYAN}  cd $PROJECT_DIR/war-projects/ff4j-simple && mvn clean package${NC}"
    echo ""
fi

echo -e "${YELLOW}📁 Creando script de verificación de URLs...${NC}"

# Crear script de verificación específico para feature-flags
cat > "$PROJECT_DIR/scripts/verify-feature-flags-urls.sh" << 'EOF'
#!/bin/bash
#
# Script para verificar URLs de feature-flags después de la actualización
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Verificación de URLs Feature Flags ===${NC}"
echo ""

# Obtener puerto dinámico de HAProxy
HAPROXY_PORT=$(grep -E '^\s*-\s*"[0-9]+:80"' ../config/docker-compose.yml | sed 's/.*"\([0-9]*\):80".*/\1/' 2>/dev/null || echo "8083")

echo -e "${YELLOW}Puerto dinámico de HAProxy detectado: $HAPROXY_PORT${NC}"
echo ""

# URLs de feature-flags a verificar
declare -A FEATURE_URLS=(
    ["Feature Flags Principal"]="http://localhost:$HAPROXY_PORT/feature-flags/"
    ["Feature Flags Admin"]="http://localhost:$HAPROXY_PORT/feature-flags/admin.html"
    ["Feature Flags Info"]="http://localhost:$HAPROXY_PORT/feature-flags/info.html"
    ["FF4J Simple Principal"]="http://localhost:$HAPROXY_PORT/ff4j-simple/"
    ["FF4J Simple Info"]="http://localhost:$HAPROXY_PORT/ff4j-simple/info.html"
    ["Version A"]="http://localhost:$HAPROXY_PORT/version-a/"
    ["Version B"]="http://localhost:$HAPROXY_PORT/version-b/"
)

echo -e "${BLUE}🌐 Verificando URLs de Feature Flags:${NC}"
success_count=0
total_count=${#FEATURE_URLS[@]}

for service in "${!FEATURE_URLS[@]}"; do
    url="${FEATURE_URLS[$service]}"
    if timeout 10 curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302"; then
        echo -e "${GREEN}✓ $service - ACCESIBLE${NC}"
        echo -e "  ${CYAN}→ $url${NC}"
        ((success_count++))
    else
        echo -e "${RED}✗ $service - NO ACCESIBLE${NC}"
        echo -e "  ${CYAN}→ $url${NC}"
    fi
done

echo ""
echo -e "${BLUE}📊 Resumen de verificación:${NC}"
echo -e "${GREEN}✓ URLs accesibles: $success_count/$total_count${NC}"

if [ $success_count -eq $total_count ]; then
    echo -e "${GREEN}🎉 Todas las URLs de Feature Flags están funcionando correctamente${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Algunas URLs no están accesibles. Verifica que los servicios estén corriendo.${NC}"
    echo -e "${CYAN}Ejecuta: ./manage-services.sh start${NC}"
    exit 1
fi
EOF

chmod +x "$PROJECT_DIR/scripts/verify-feature-flags-urls.sh"
echo -e "${GREEN}✓ Creado: scripts/verify-feature-flags-urls.sh${NC}"

echo ""
echo -e "${YELLOW}📁 Creando script de recompilación de proyectos...${NC}"

# Crear script para recompilar proyectos
cat > "$PROJECT_DIR/scripts/rebuild-feature-flags.sh" << 'EOF'
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
EOF

chmod +x "$PROJECT_DIR/scripts/rebuild-feature-flags.sh"
echo -e "${GREEN}✓ Creado: scripts/rebuild-feature-flags.sh${NC}"

echo ""
echo -e "${GREEN}=== Actualización de URLs completada ===${NC}"
echo ""
echo -e "${BLUE}📋 Resumen de cambios realizados:${NC}"
echo -e "${YELLOW}• Actualizadas URLs localhost:8080 → localhost:8083 en archivos HTML${NC}"
echo -e "${YELLOW}• Actualizado JavaScript con puerto dinámico${NC}"
echo -e "${YELLOW}• Creados backups de todos los archivos modificados${NC}"
echo -e "${YELLOW}• Creado script de verificación específico para feature-flags${NC}"
echo -e "${YELLOW}• Creado script de recompilación de proyectos${NC}"
echo ""
echo -e "${BLUE}🚀 Próximos pasos recomendados:${NC}"
echo -e "${YELLOW}1. Recompilar proyectos:${NC} ${CYAN}./scripts/rebuild-feature-flags.sh${NC}"
echo -e "${YELLOW}2. Desplegar cambios:${NC} ${CYAN}./scripts/deploy/deploy-war.sh --all${NC}"
echo -e "${YELLOW}3. Verificar URLs:${NC} ${CYAN}./scripts/verify-feature-flags-urls.sh${NC}"
echo -e "${YELLOW}4. Reiniciar servicios:${NC} ${CYAN}./manage-services.sh restart${NC}"
echo ""
echo -e "${GREEN}✅ Todas las URLs de feature-flags han sido actualizadas con los nuevos puertos ICBS${NC}"
