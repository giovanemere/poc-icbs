#!/bin/bash
"""
Script para actualizar automáticamente las IPs de los backends en HAProxy
Soluciona el problema de servicios DOWN por IPs desactualizadas
"""

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuración
PROJECT_ROOT="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
HAPROXY_CONFIG="$PROJECT_ROOT/applications/haproxy-advanced/config/haproxy.cfg"
BACKUP_DIR="$PROJECT_ROOT/backups/haproxy"
COMPOSE_FILE="$PROJECT_ROOT/config/docker-compose.yml"

echo -e "${BLUE}🔄 Actualizando IPs de Backends HAProxy${NC}"
echo "========================================"

# Crear directorio de backups
mkdir -p "$BACKUP_DIR"

# Función para obtener IP de contenedor
get_container_ip() {
    local container_name="$1"
    local ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name" 2>/dev/null)
    if [ -n "$ip" ]; then
        echo "$ip"
    else
        echo ""
    fi
}

# Función para hacer backup
backup_config() {
    local backup_name="haproxy.cfg.ip-update.$(date +%Y%m%d_%H%M%S)"
    cp "$HAPROXY_CONFIG" "$BACKUP_DIR/$backup_name"
    echo -e "${GREEN}✅ Backup creado: $backup_name${NC}"
}

# Función para actualizar IPs
update_ips() {
    echo -e "\n${YELLOW}🔍 Detectando IPs actuales...${NC}"
    
    # Obtener IPs actuales
    local weblogic_a_ip=$(get_container_ip "weblogic-a")
    local weblogic_b_ip=$(get_container_ip "weblogic-b")
    local mkdocs_ip=$(get_container_ip "mkdocs-server")
    
    if [ -z "$weblogic_a_ip" ] || [ -z "$weblogic_b_ip" ] || [ -z "$mkdocs_ip" ]; then
        echo -e "${RED}❌ Error: No se pudieron obtener todas las IPs${NC}"
        echo "WebLogic A: $weblogic_a_ip"
        echo "WebLogic B: $weblogic_b_ip"
        echo "MkDocs: $mkdocs_ip"
        exit 1
    fi
    
    echo "• WebLogic A: $weblogic_a_ip"
    echo "• WebLogic B: $weblogic_b_ip"
    echo "• MkDocs: $mkdocs_ip"
    
    echo -e "\n${YELLOW}🔧 Actualizando configuración...${NC}"
    
    # Hacer backup antes de modificar
    backup_config
    
    # Actualizar IPs en la configuración
    # Buscar y reemplazar todas las referencias a IPs antiguas
    sed -i.tmp \
        -e "s/server weblogic-a [0-9.]*:7001/server weblogic-a $weblogic_a_ip:7001/g" \
        -e "s/server weblogic-b [0-9.]*:7001/server weblogic-b $weblogic_b_ip:7001/g" \
        -e "s/server weblogic-a-ff4j [0-9.]*:7001/server weblogic-a-ff4j $weblogic_a_ip:7001/g" \
        -e "s/server weblogic-b-ff4j [0-9.]*:7001/server weblogic-b-ff4j $weblogic_b_ip:7001/g" \
        -e "s/server weblogic-features-a [0-9.]*:7001/server weblogic-features-a $weblogic_a_ip:7001/g" \
        -e "s/server weblogic-features-b [0-9.]*:7001/server weblogic-features-b $weblogic_b_ip:7001/g" \
        -e "s/server mkdocs-[a-z]* [0-9.]*:8000/server mkdocs-server $mkdocs_ip:8000/g" \
        -e "s/mkdocs-server:[0-9]*/mkdocs-server:8000/g" \
        "$HAPROXY_CONFIG"
    
    # Limpiar archivo temporal
    rm -f "$HAPROXY_CONFIG.tmp"
    
    echo -e "${GREEN}✅ IPs actualizadas en configuración${NC}"
}

# Función para validar configuración
validate_config() {
    echo -e "\n${YELLOW}🔍 Validando configuración...${NC}"
    
    if docker run --rm -v "$HAPROXY_CONFIG:/tmp/haproxy.cfg:ro" haproxy:2.6 haproxy -c -f /tmp/haproxy.cfg >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Configuración válida${NC}"
        return 0
    else
        echo -e "${RED}❌ Configuración inválida${NC}"
        return 1
    fi
}

# Función para reiniciar HAProxy
restart_haproxy() {
    echo -e "\n${YELLOW}🔄 Reiniciando HAProxy...${NC}"
    
    cd "$PROJECT_ROOT"
    if docker-compose -f "$COMPOSE_FILE" restart haproxy; then
        echo -e "${GREEN}✅ HAProxy reiniciado exitosamente${NC}"
        return 0
    else
        echo -e "${RED}❌ Error reiniciando HAProxy${NC}"
        return 1
    fi
}

# Función para verificar estado de backends
check_backend_status() {
    echo -e "\n${YELLOW}🧪 Verificando estado de backends...${NC}"
    
    # Esperar a que HAProxy esté listo
    sleep 10
    
    # Obtener estado de backends WebLogic
    local stats_data=$(curl -s -u admin:admin123 "http://localhost:8404/stats;csv" 2>/dev/null)
    
    if [ -n "$stats_data" ]; then
        echo -e "\n${CYAN}Estado de servidores WebLogic:${NC}"
        
        # Verificar weblogic-a
        local weblogic_a_status=$(echo "$stats_data" | grep "weblogic_main,weblogic-a," | cut -d',' -f18)
        echo -n "• weblogic-a: "
        if [ "$weblogic_a_status" = "UP" ]; then
            echo -e "${GREEN}✅ UP${NC}"
        else
            echo -e "${RED}❌ $weblogic_a_status${NC}"
        fi
        
        # Verificar weblogic-b
        local weblogic_b_status=$(echo "$stats_data" | grep "weblogic_main,weblogic-b," | cut -d',' -f18)
        echo -n "• weblogic-b: "
        if [ "$weblogic_b_status" = "UP" ]; then
            echo -e "${GREEN}✅ UP${NC}"
        else
            echo -e "${RED}❌ $weblogic_b_status${NC}"
        fi
        
        # Verificar otros backends si existen
        for backend in "weblogic-features-a" "weblogic-features-b"; do
            local backend_status=$(echo "$stats_data" | grep "$backend," | cut -d',' -f18 | head -1)
            if [ -n "$backend_status" ]; then
                echo -n "• $backend: "
                if [ "$backend_status" = "UP" ]; then
                    echo -e "${GREEN}✅ UP${NC}"
                else
                    echo -e "${RED}❌ $backend_status${NC}"
                fi
            fi
        done
        
        # Contar servidores UP
        local up_count=$(echo "$stats_data" | grep -c ",UP,")
        local total_servers=$(echo "$stats_data" | grep "server," | wc -l)
        
        echo -e "\n${BLUE}📊 Resumen: $up_count servidores UP de $total_servers totales${NC}"
        
        if [ "$up_count" -ge 2 ]; then
            return 0
        else
            return 1
        fi
    else
        echo -e "${RED}❌ No se pudieron obtener estadísticas de HAProxy${NC}"
        return 1
    fi
}

# Función para mostrar URLs de acceso
show_access_urls() {
    echo -e "\n${YELLOW}🔗 URLs de acceso actualizadas:${NC}"
    echo "================================"
    echo "• HAProxy Stats: http://localhost:8404/stats (admin/admin123)"
    echo "• Load Balancer: http://localhost:8083/"
    echo "• WebLogic A: http://localhost:7001/console"
    echo "• WebLogic B: http://localhost:7002/console"
    echo "• MkDocs: http://localhost:8000/"
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
    
    # Actualizar IPs
    update_ips
    
    # Validar configuración
    if ! validate_config; then
        echo -e "${RED}❌ Error en la configuración - restaurando backup${NC}"
        # Restaurar último backup si existe
        local latest_backup=$(ls -t "$BACKUP_DIR"/haproxy.cfg.ip-update.* 2>/dev/null | head -1)
        if [ -n "$latest_backup" ]; then
            cp "$latest_backup" "$HAPROXY_CONFIG"
            echo -e "${YELLOW}🔄 Backup restaurado${NC}"
        fi
        exit 1
    fi
    
    # Reiniciar HAProxy
    if ! restart_haproxy; then
        echo -e "${RED}❌ Error reiniciando HAProxy${NC}"
        exit 1
    fi
    
    # Verificar estado de backends
    if check_backend_status; then
        echo -e "\n${GREEN}🎉 ¡Actualización exitosa!${NC}"
        echo "=========================="
        echo -e "${GREEN}✅ Todos los backends WebLogic están funcionando correctamente${NC}"
        show_access_urls
    else
        echo -e "\n${YELLOW}⚠️  Actualización parcial${NC}"
        echo "========================"
        echo -e "${YELLOW}Algunos backends pueden necesitar más tiempo para estar disponibles${NC}"
        show_access_urls
    fi
}

# Ejecutar función principal
main "$@"
