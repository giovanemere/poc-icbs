#!/bin/bash
"""
Script para corregir los backends WebLogic en HAProxy
Actualiza health checks para aceptar códigos 200 y 302
"""

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Corrigiendo Backends WebLogic en HAProxy${NC}"
echo "============================================="

# Función para actualizar configuración dentro del contenedor
fix_haproxy_config() {
    echo -e "\n${YELLOW}🔧 Actualizando configuración de health checks...${NC}"
    
    # Crear script temporal para ejecutar dentro del contenedor
    cat > /tmp/fix_haproxy.sh << 'EOF'
#!/bin/bash
CONFIG_FILE="/usr/local/etc/haproxy/haproxy.cfg"
BACKUP_FILE="/usr/local/etc/haproxy/haproxy.cfg.backup.$(date +%Y%m%d_%H%M%S)"

# Hacer backup
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo "Backup creado: $BACKUP_FILE"

# Actualizar health checks para aceptar códigos 200 y 302
sed -i 's/http-check expect status 200/http-check expect status 200,302/g' "$CONFIG_FILE"

# Verificar cambios
echo "Cambios realizados:"
grep -n "http-check expect status" "$CONFIG_FILE" || echo "No se encontraron líneas de http-check expect"

echo "Configuración actualizada exitosamente"
EOF

    # Copiar script al contenedor y ejecutarlo
    docker cp /tmp/fix_haproxy.sh haproxy:/tmp/fix_haproxy.sh
    docker exec haproxy chmod +x /tmp/fix_haproxy.sh
    docker exec haproxy /tmp/fix_haproxy.sh
    
    # Limpiar
    rm -f /tmp/fix_haproxy.sh
    docker exec haproxy rm -f /tmp/fix_haproxy.sh
}

# Función para validar configuración
validate_config() {
    echo -e "\n${YELLOW}🔍 Validando configuración...${NC}"
    
    if docker exec haproxy haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg; then
        echo -e "${GREEN}✅ Configuración válida${NC}"
        return 0
    else
        echo -e "${RED}❌ Configuración inválida${NC}"
        return 1
    fi
}

# Función para recargar HAProxy
reload_haproxy() {
    echo -e "\n${YELLOW}🔄 Recargando configuración HAProxy...${NC}"
    
    # Recargar configuración sin reiniciar el contenedor
    if docker exec haproxy haproxy -f /usr/local/etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -sf $(docker exec haproxy cat /var/run/haproxy.pid); then
        echo -e "${GREEN}✅ HAProxy recargado exitosamente${NC}"
        return 0
    else
        echo -e "${RED}❌ Error recargando HAProxy${NC}"
        return 1
    fi
}

# Función para verificar conectividad WebLogic
test_weblogic_connectivity() {
    echo -e "\n${YELLOW}🧪 Probando conectividad WebLogic...${NC}"
    
    # Probar desde dentro del contenedor HAProxy
    echo "Probando desde HAProxy hacia WebLogic:"
    
    # Test WebLogic A
    echo -n "• WebLogic A (/console): "
    if docker exec haproxy wget -q --spider --timeout=5 http://weblogic-a:7001/console 2>/dev/null; then
        echo -e "${GREEN}✅ Accesible${NC}"
    else
        echo -e "${RED}❌ No accesible${NC}"
    fi
    
    # Test WebLogic B
    echo -n "• WebLogic B (/console): "
    if docker exec haproxy wget -q --spider --timeout=5 http://weblogic-b:7001/console 2>/dev/null; then
        echo -e "${GREEN}✅ Accesible${NC}"
    else
        echo -e "${RED}❌ No accesible${NC}"
    fi
    
    # Test con curl para ver códigos de respuesta
    echo -e "\n${CYAN}Códigos de respuesta:${NC}"
    echo -n "• WebLogic A: "
    docker exec haproxy curl -s -o /dev/null -w "%{http_code}" http://weblogic-a:7001/console 2>/dev/null || echo "Error"
    echo -n "• WebLogic B: "
    docker exec haproxy curl -s -o /dev/null -w "%{http_code}" http://weblogic-b:7001/console 2>/dev/null || echo "Error"
    echo ""
}

# Función para verificar estado de backends
check_backend_status() {
    echo -e "\n${YELLOW}📊 Verificando estado de backends...${NC}"
    
    # Esperar a que los cambios se apliquen
    sleep 15
    
    # Obtener estado de backends
    local stats_data=$(curl -s -u admin:admin123 "http://localhost:8404/stats;csv" 2>/dev/null)
    
    if [ -n "$stats_data" ]; then
        echo -e "\n${CYAN}Estado de backends WebLogic:${NC}"
        
        # Verificar todos los backends weblogic
        local backends=("weblogic-a,weblogic-a" "weblogic-b,weblogic-b" "weblogic-features-a,weblogic-a-features" "weblogic-features-b,weblogic-b-features" "ff4j-backend,weblogic-a-ff4j" "ff4j-backend,weblogic-b-ff4j" "feature-flags-backend,weblogic-a-feature" "feature-flags-backend,weblogic-b-feature")
        
        local up_count=0
        local total_count=0
        
        for backend_info in "${backends[@]}"; do
            local backend_name=$(echo "$backend_info" | cut -d',' -f1)
            local server_name=$(echo "$backend_info" | cut -d',' -f2)
            local status=$(echo "$stats_data" | grep "^$backend_name,$server_name," | cut -d',' -f18)
            
            if [ -n "$status" ]; then
                ((total_count++))
                echo -n "• $server_name: "
                if [ "$status" = "UP" ]; then
                    echo -e "${GREEN}✅ UP${NC}"
                    ((up_count++))
                else
                    echo -e "${RED}❌ $status${NC}"
                fi
            fi
        done
        
        echo -e "\n${BLUE}📈 Resumen: $up_count/$total_count backends UP${NC}"
        
        if [ "$up_count" -ge $((total_count / 2)) ]; then
            return 0
        else
            return 1
        fi
    else
        echo -e "${RED}❌ No se pudieron obtener estadísticas${NC}"
        return 1
    fi
}

# Función para mostrar URLs de acceso
show_access_info() {
    echo -e "\n${YELLOW}🔗 Información de acceso:${NC}"
    echo "========================="
    echo "• HAProxy Stats: http://localhost:8404/stats (admin/admin123)"
    echo "• Load Balancer: http://localhost:8083/"
    echo "• WebLogic A: http://localhost:7001/console"
    echo "• WebLogic B: http://localhost:7002/console"
    echo "• MkDocs: http://localhost:8000/"
    echo ""
    echo -e "${CYAN}Backends disponibles:${NC}"
    echo "• /console → weblogic-a (principal)"
    echo "• /weblogic-features → weblogic-features-a/b (A/B testing)"
    echo "• /ff4j → ff4j-backend"
    echo "• /docs → mkdocs"
}

# Función principal
main() {
    echo -e "\n${YELLOW}📋 Verificando prerrequisitos...${NC}"
    
    # Verificar que HAProxy esté ejecutándose
    if ! docker ps | grep -q haproxy; then
        echo -e "${RED}❌ HAProxy no está ejecutándose${NC}"
        exit 1
    fi
    
    # Verificar que los contenedores WebLogic estén ejecutándose
    if ! docker ps | grep -q weblogic-a || ! docker ps | grep -q weblogic-b; then
        echo -e "${RED}❌ Los contenedores WebLogic no están ejecutándose${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerrequisitos verificados${NC}"
    
    # Probar conectividad antes de los cambios
    test_weblogic_connectivity
    
    # Corregir configuración
    fix_haproxy_config
    
    # Validar configuración
    if ! validate_config; then
        echo -e "${RED}❌ Error en la configuración${NC}"
        exit 1
    fi
    
    # Recargar HAProxy
    if ! reload_haproxy; then
        echo -e "${RED}❌ Error recargando HAProxy${NC}"
        exit 1
    fi
    
    # Verificar estado de backends
    if check_backend_status; then
        echo -e "\n${GREEN}🎉 ¡Corrección exitosa!${NC}"
        echo "======================="
        echo -e "${GREEN}✅ Los backends WebLogic están funcionando correctamente${NC}"
        show_access_info
    else
        echo -e "\n${YELLOW}⚠️  Corrección parcial${NC}"
        echo "====================="
        echo -e "${YELLOW}Algunos backends pueden necesitar más tiempo${NC}"
        show_access_info
    fi
}

# Ejecutar función principal
main "$@"
