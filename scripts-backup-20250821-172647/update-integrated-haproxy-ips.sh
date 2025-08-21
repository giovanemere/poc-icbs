#!/bin/bash

# Script personalizado para actualizar IPs de HAProxy integrado
# Específicamente diseñado para contenedores con sufijo "-integrated"

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Actualizador de IPs para HAProxy Integrado ===${NC}"
echo

# Función para mostrar estado
show_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        return 1
    fi
}

# Función para obtener IP de contenedor
get_container_ip() {
    local container_name=$1
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name" 2>/dev/null
}

# Función para mostrar IPs actuales
show_current_ips() {
    echo -e "${BLUE}IPs actuales de contenedores integrados:${NC}"
    
    for container in weblogic-a-integrated weblogic-b-integrated haproxy-integrated; do
        local ip=$(get_container_ip "$container")
        if [ -n "$ip" ]; then
            echo -e "  $container: ${GREEN}$ip${NC}"
        else
            echo -e "  $container: ${RED}No disponible${NC}"
        fi
    done
    echo
}

# Función para verificar contenedores
check_containers() {
    echo -e "${BLUE}Verificando contenedores integrados...${NC}"
    
    local containers_ready=true
    for container in weblogic-a-integrated weblogic-b-integrated haproxy-integrated; do
        if ! docker ps | grep -q "$container"; then
            echo -e "${RED}✗ Contenedor $container no está ejecutándose${NC}"
            containers_ready=false
        else
            show_status 0 "Contenedor $container está ejecutándose"
        fi
    done
    
    if [ "$containers_ready" = false ]; then
        echo -e "${RED}Error: No todos los contenedores están ejecutándose${NC}"
        return 1
    fi
    
    return 0
}

# Función para actualizar configuración de HAProxy
update_haproxy_config() {
    local weblogic_a_ip=$1
    local weblogic_b_ip=$2
    
    echo -e "${BLUE}Actualizando configuración de HAProxy integrado...${NC}"
    
    # Hacer backup de la configuración actual
    local backup_file="haproxy/config/haproxy-integrated.cfg.bak.$(date +%Y%m%d_%H%M%S)"
    docker exec haproxy-integrated cp /usr/local/etc/haproxy/haproxy.cfg "/usr/local/etc/haproxy/$backup_file"
    show_status 0 "Backup creado: $backup_file"
    
    # Actualizar las IPs en la configuración dentro del contenedor
    docker exec haproxy-integrated sed -i "s/server weblogic-a-integrated [0-9.]*:7001/server weblogic-a-integrated $weblogic_a_ip:7001/g" /usr/local/etc/haproxy/haproxy.cfg
    docker exec haproxy-integrated sed -i "s/server weblogic-b-integrated [0-9.]*:7001/server weblogic-b-integrated $weblogic_b_ip:7001/g" /usr/local/etc/haproxy/haproxy.cfg
    
    # También actualizar referencias en otros backends
    docker exec haproxy-integrated sed -i "s/server weblogic-a-[a-z]* $weblogic_a_ip:7001/server weblogic-a-integrated $weblogic_a_ip:7001/g" /usr/local/etc/haproxy/haproxy.cfg
    docker exec haproxy-integrated sed -i "s/server weblogic-b-[a-z]* $weblogic_b_ip:7001/server weblogic-b-integrated $weblogic_b_ip:7001/g" /usr/local/etc/haproxy/haproxy.cfg
    
    show_status 0 "Configuración actualizada con nuevas IPs"
}

# Función para recargar HAProxy
reload_haproxy() {
    echo -e "${BLUE}Recargando HAProxy integrado...${NC}"
    
    # Obtener el PID actual de HAProxy
    local old_pid=$(docker exec haproxy-integrated cat /var/run/haproxy.pid 2>/dev/null || echo "")
    
    # Recargar HAProxy con graceful restart
    local reload_cmd="haproxy -f /usr/local/etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid"
    if [ -n "$old_pid" ]; then
        reload_cmd="$reload_cmd -sf $old_pid"
    fi
    
    if docker exec haproxy-integrated $reload_cmd; then
        show_status 0 "HAProxy recargado exitosamente"
        return 0
    else
        show_status 1 "Error recargando HAProxy"
        return 1
    fi
}

# Función para verificar la actualización
verify_update() {
    echo -e "${BLUE}Verificando actualización...${NC}"
    
    # Verificar que la configuración contiene las nuevas IPs
    local config_check=$(docker exec haproxy-integrated grep -E "server weblogic-[ab]-integrated [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:7001" /usr/local/etc/haproxy/haproxy.cfg)
    
    if [ -n "$config_check" ]; then
        show_status 0 "Configuración actualizada correctamente"
        echo -e "${BLUE}Configuración actual:${NC}"
        echo "$config_check" | sed 's/^/  /'
        return 0
    else
        show_status 1 "La configuración no se actualizó correctamente"
        return 1
    fi
}

# Función principal
main() {
    # Verificar contenedores
    if ! check_containers; then
        exit 1
    fi
    
    # Mostrar IPs actuales
    show_current_ips
    
    # Obtener las IPs de los contenedores WebLogic
    local weblogic_a_ip=$(get_container_ip "weblogic-a-integrated")
    local weblogic_b_ip=$(get_container_ip "weblogic-b-integrated")
    
    if [ -z "$weblogic_a_ip" ] || [ -z "$weblogic_b_ip" ]; then
        echo -e "${RED}Error: No se pudieron obtener las IPs de los contenedores WebLogic${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}IPs a configurar:${NC}"
    echo -e "  weblogic-a-integrated: ${GREEN}$weblogic_a_ip${NC}"
    echo -e "  weblogic-b-integrated: ${GREEN}$weblogic_b_ip${NC}"
    echo
    
    # Actualizar configuración
    if ! update_haproxy_config "$weblogic_a_ip" "$weblogic_b_ip"; then
        echo -e "${RED}Error: No se pudo actualizar la configuración${NC}"
        exit 1
    fi
    
    # Recargar HAProxy
    if ! reload_haproxy; then
        echo -e "${RED}Error: No se pudo recargar HAProxy${NC}"
        exit 1
    fi
    
    # Verificar la actualización
    if ! verify_update; then
        echo -e "${RED}Error: La verificación falló${NC}"
        exit 1
    fi
    
    echo
    echo -e "${GREEN}=== Actualización de IPs completada exitosamente ===${NC}"
    echo -e "${BLUE}URLs de acceso:${NC}"
    echo -e "  HAProxy Stats: ${YELLOW}http://localhost:8414/stats${NC}"
    echo -e "  HAProxy Frontend: ${YELLOW}http://localhost:8090${NC}"
    echo -e "  Panel de Administración: ${YELLOW}http://localhost:8092${NC}"
    echo -e "  API de Administración: ${YELLOW}http://localhost:8091${NC}"
}

# Ejecutar función principal
main "$@"
