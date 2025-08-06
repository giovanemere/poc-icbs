#!/bin/bash
#
# Script para actualizar todos los puertos en los scripts del proyecto ICBS
# Actualiza referencias de puertos antiguos a los nuevos puertos definidos
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

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          Actualizador de Puertos - Servicio ICBS            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}=== Configuración de Puertos ICBS ===${NC}"
echo -e "${YELLOW}HAProxy Load Balancer:${NC} 8083 (dinámico)"
echo -e "${YELLOW}HAProxy API Admin:${NC} 8081"
echo -e "${YELLOW}HAProxy UI Admin:${NC} 8082"
echo -e "${YELLOW}HAProxy Stats:${NC} 8404"
echo -e "${YELLOW}HAProxy HTTPS:${NC} 8444"
echo -e "${YELLOW}WebLogic A Console:${NC} 7001"
echo -e "${YELLOW}WebLogic B Console:${NC} 7002"
echo -e "${YELLOW}Oracle Database:${NC} 1521"
echo -e "${YELLOW}Oracle EM Express:${NC} 5500"
echo -e "${YELLOW}MkDocs Server:${NC} 8000"
echo -e "${YELLOW}MkDocs Dev Server:${NC} 8001"
echo -e "${YELLOW}MkDocs V1 Server:${NC} 8002"
echo ""

# Función para hacer backup de un archivo
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${GREEN}✓ Backup creado: $file.backup.$(date +%Y%m%d_%H%M%S)${NC}"
    fi
}

# Función para actualizar un archivo
update_file() {
    local file="$1"
    local description="$2"
    
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}⚠ Archivo no encontrado: $file${NC}"
        return
    fi
    
    echo -e "${BLUE}Actualizando: $description${NC}"
    backup_file "$file"
    
    # Actualizar referencias de puertos antiguos
    sed -i 's/localhost:8080/localhost:8083/g' "$file"
    sed -i 's/:8080/:8083/g' "$file"
    sed -i 's/puerto 8080/puerto 8083/g' "$file"
    sed -i 's/Puerto 8080/Puerto 8083/g' "$file"
    sed -i 's/port 8080/port 8083/g' "$file"
    sed -i 's/Port 8080/Port 8083/g' "$file"
    
    # Actualizar referencias específicas de HAProxy
    sed -i 's/8443:443/8444:443/g' "$file"
    sed -i 's/puerto 8443/puerto 8444/g' "$file"
    sed -i 's/Puerto 8443/Puerto 8444/g' "$file"
    
    echo -e "${GREEN}✓ Actualizado: $file${NC}"
}

# Función para actualizar scripts con lógica de puerto dinámico
update_dynamic_port_script() {
    local file="$1"
    local description="$2"
    
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}⚠ Archivo no encontrado: $file${NC}"
        return
    fi
    
    echo -e "${BLUE}Actualizando con puerto dinámico: $description${NC}"
    backup_file "$file"
    
    # Buscar y reemplazar referencias estáticas de puerto 8080 con lógica dinámica
    if grep -q "localhost:8080" "$file"; then
        # Agregar lógica para obtener puerto dinámico al inicio del script
        if ! grep -q "HAPROXY_PORT=" "$file"; then
            sed -i '/^#!/a\\n# Obtener puerto dinámico de HAProxy\nHAPROXY_PORT=$(grep -E "^\\s*-\\s*\"[0-9]+:80\"" config/docker-compose.yml | sed '\''s/.*\"\\([0-9]*\\):80\".*/\\1/'\'' 2>/dev/null || echo "8083")' "$file"
        fi
        
        # Reemplazar referencias estáticas con variable dinámica
        sed -i 's/localhost:8080/localhost:$HAPROXY_PORT/g' "$file"
        sed -i 's/puerto 8080/puerto $HAPROXY_PORT/g' "$file"
    fi
    
    echo -e "${GREEN}✓ Actualizado con puerto dinámico: $file${NC}"
}

echo -e "${BLUE}=== Iniciando actualización de scripts ===${NC}"
echo ""

# Actualizar scripts principales
echo -e "${YELLOW}📁 Actualizando scripts principales...${NC}"

update_file "$PROJECT_DIR/manage-services.sh" "Gestor principal de servicios"
update_file "$PROJECT_DIR/start-with-auto-update.sh" "Script de inicio con auto-actualización"
update_file "$PROJECT_DIR/stop-all-services.sh" "Script de parada de servicios"

# Actualizar scripts de verificación
echo -e "${YELLOW}📁 Actualizando scripts de verificación...${NC}"

update_dynamic_port_script "$PROJECT_DIR/scripts/check-urls.sh" "Verificador de URLs"
update_file "$PROJECT_DIR/scripts/check-direct-urls.sh" "Verificador directo de URLs"
update_file "$PROJECT_DIR/scripts/utils/health-check.sh" "Verificador de salud del sistema"

# Actualizar scripts de HAProxy
echo -e "${YELLOW}📁 Actualizando scripts de HAProxy...${NC}"

update_file "$PROJECT_DIR/scripts/maintenance/auto-update-haproxy.sh" "Auto-actualizador de HAProxy"
update_file "$PROJECT_DIR/scripts/manage-haproxy-dynamic.sh" "Gestor dinámico de HAProxy"
update_file "$PROJECT_DIR/scripts/update-haproxy-config.sh" "Actualizador de configuración HAProxy"
update_file "$PROJECT_DIR/scripts/debug-haproxy.sh" "Depurador de HAProxy"

# Actualizar scripts de deploy
echo -e "${YELLOW}📁 Actualizando scripts de deploy...${NC}"

update_file "$PROJECT_DIR/scripts/deploy/deploy-war.sh" "Desplegador de WAR"
update_file "$PROJECT_DIR/scripts/deploy/deploy-complete.sh" "Deploy completo"
update_file "$PROJECT_DIR/scripts/deploy/clear-haproxy-cache.sh" "Limpiador de caché HAProxy"

# Actualizar documentación
echo -e "${YELLOW}📁 Actualizando documentación...${NC}"

update_file "$PROJECT_DIR/README.md" "README principal"
update_file "$PROJECT_DIR/SETUP_COMPLETE.md" "Documentación de setup"
update_file "$PROJECT_DIR/HAPROXY_MKDOCS_INTEGRATION.md" "Documentación HAProxy-MkDocs"

# Actualizar archivos de configuración
echo -e "${YELLOW}📁 Actualizando archivos de configuración...${NC}"

# Verificar si hay archivos de configuración que necesiten actualización
if [ -f "$PROJECT_DIR/.env.example" ]; then
    update_file "$PROJECT_DIR/.env.example" "Archivo de ejemplo de variables de entorno"
fi

# Actualizar scripts de Minikube
echo -e "${YELLOW}📁 Actualizando scripts de Minikube...${NC}"

update_file "$PROJECT_DIR/scripts/services/minikube-port-forwards.sh" "Gestor de port-forwards Minikube"

# Crear script de verificación de puertos actualizados
echo -e "${YELLOW}📁 Creando script de verificación de puertos...${NC}"

cat > "$PROJECT_DIR/scripts/verify-icbs-ports.sh" << 'EOF'
#!/bin/bash
#
# Script para verificar que todos los puertos ICBS estén funcionando correctamente
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Verificación de Puertos ICBS ===${NC}"
echo ""

# Obtener puerto dinámico de HAProxy
HAPROXY_PORT=$(grep -E '^\s*-\s*"[0-9]+:80"' ../config/docker-compose.yml | sed 's/.*"\([0-9]*\):80".*/\1/' 2>/dev/null || echo "8083")

# Puertos a verificar
declare -A PORTS=(
    ["HAProxy Load Balancer"]="$HAPROXY_PORT"
    ["HAProxy API Admin"]="8081"
    ["HAProxy UI Admin"]="8082"
    ["HAProxy Stats"]="8404"
    ["HAProxy HTTPS"]="8444"
    ["WebLogic A Console"]="7001"
    ["WebLogic B Console"]="7002"
    ["Oracle Database"]="1521"
    ["Oracle EM Express"]="5500"
    ["MkDocs Server"]="8000"
    ["MkDocs Dev Server"]="8001"
    ["MkDocs V1 Server"]="8002"
)

# URLs a verificar
declare -A URLS=(
    ["HAProxy Load Balancer"]="http://localhost:$HAPROXY_PORT"
    ["HAProxy API Admin"]="http://localhost:8081"
    ["HAProxy UI Admin"]="http://localhost:8082"
    ["HAProxy Stats"]="http://localhost:8404/stats"
    ["WebLogic A Console"]="http://localhost:7001/console"
    ["WebLogic B Console"]="http://localhost:7002/console"
    ["Oracle EM Express"]="https://localhost:5500/em"
    ["MkDocs Server"]="http://localhost:8000"
    ["MkDocs Dev Server"]="http://localhost:8001"
    ["MkDocs V1 Server"]="http://localhost:8002"
)

echo -e "${YELLOW}Puerto dinámico de HAProxy detectado: $HAPROXY_PORT${NC}"
echo ""

# Verificar puertos
echo -e "${BLUE}🔌 Verificando puertos en uso:${NC}"
for service in "${!PORTS[@]}"; do
    port="${PORTS[$service]}"
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}✓ $service (puerto $port) - ACTIVO${NC}"
    else
        echo -e "${RED}✗ $service (puerto $port) - INACTIVO${NC}"
    fi
done

echo ""

# Verificar URLs
echo -e "${BLUE}🌐 Verificando URLs de servicios:${NC}"
for service in "${!URLS[@]}"; do
    url="${URLS[$service]}"
    if timeout 5 curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302\|401"; then
        echo -e "${GREEN}✓ $service - ACCESIBLE${NC}"
        echo -e "  ${CYAN}→ $url${NC}"
    else
        echo -e "${RED}✗ $service - NO ACCESIBLE${NC}"
        echo -e "  ${CYAN}→ $url${NC}"
    fi
done

echo ""
echo -e "${BLUE}=== Verificación completada ===${NC}"
echo -e "${YELLOW}Para más detalles, consulta: PUERTOS_CONFIGURACION.md${NC}"
EOF

chmod +x "$PROJECT_DIR/scripts/verify-icbs-ports.sh"
echo -e "${GREEN}✓ Creado: scripts/verify-icbs-ports.sh${NC}"

echo ""
echo -e "${GREEN}=== Actualización completada ===${NC}"
echo ""
echo -e "${BLUE}📋 Resumen de cambios realizados:${NC}"
echo -e "${YELLOW}• Actualizados puertos 8080 → 8083 (HAProxy Load Balancer)${NC}"
echo -e "${YELLOW}• Actualizados puertos 8443 → 8444 (HAProxy HTTPS)${NC}"
echo -e "${YELLOW}• Implementada lógica de puerto dinámico en scripts de verificación${NC}"
echo -e "${YELLOW}• Creados backups de todos los archivos modificados${NC}"
echo -e "${YELLOW}• Creado script de verificación de puertos ICBS${NC}"
echo ""
echo -e "${BLUE}🚀 Próximos pasos:${NC}"
echo -e "${YELLOW}1. Verificar configuración: ./scripts/verify-icbs-ports.sh${NC}"
echo -e "${YELLOW}2. Reiniciar servicios: ./manage-services.sh restart${NC}"
echo -e "${YELLOW}3. Verificar funcionamiento: ./scripts/check-urls.sh${NC}"
echo ""
echo -e "${GREEN}✅ Todos los scripts han sido actualizados con los nuevos puertos ICBS${NC}"
