#!/bin/bash
#
# Script para actualizar automáticamente las IPs de HAProxy después del docker-compose up
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Auto-actualización de HAProxy iniciada ===${NC}"

# Función para obtener la IP de un contenedor
get_container_ip() {
    local container_name=$1
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name" 2>/dev/null
}

# Función para esperar a que los contenedores estén listos
wait_for_containers() {
    local max_attempts=30
    local attempt=1
    
    echo -e "${YELLOW}Esperando a que los contenedores estén listos...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        weblogic_a_ip=$(get_container_ip "weblogic-a")
        weblogic_b_ip=$(get_container_ip "weblogic-b")
        
        if [ -n "$weblogic_a_ip" ] && [ -n "$weblogic_b_ip" ]; then
            echo -e "${GREEN}Contenedores listos:${NC}"
            echo -e "  weblogic-a: $weblogic_a_ip"
            echo -e "  weblogic-b: $weblogic_b_ip"
            return 0
        fi
        
        echo -e "${YELLOW}Intento $attempt/$max_attempts - Esperando contenedores...${NC}"
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}Timeout: Los contenedores no están listos después de $max_attempts intentos${NC}"
    return 1
}

# Función para actualizar la configuración de HAProxy
update_haproxy_config() {
    local weblogic_a_ip=$1
    local weblogic_b_ip=$2
    
    echo -e "${YELLOW}Actualizando configuración de HAProxy...${NC}"
    
    # Hacer backup de la configuración actual
    cp /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/config/haproxy.cfg \
       /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/config/haproxy.cfg.bak.$(date +%Y%m%d_%H%M%S)
    
    # Actualizar las IPs en la configuración
    sed -i "s/server weblogic-a [0-9.]*:7001/server weblogic-a $weblogic_a_ip:7001/g" \
        /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/config/haproxy.cfg
    
    sed -i "s/server weblogic-b [0-9.]*:7001/server weblogic-b $weblogic_b_ip:7001/g" \
        /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/config/haproxy.cfg
    
    # Recargar la configuración de HAProxy
    if docker ps | grep -q haproxy; then
        echo -e "${YELLOW}Recargando configuración de HAProxy...${NC}"
        docker exec haproxy haproxy -f /usr/local/etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -sf $(docker exec haproxy cat /var/run/haproxy.pid 2>/dev/null || echo "")
    else
        echo -e "${YELLOW}HAProxy no está ejecutándose, se actualizará en el próximo inicio${NC}"
    fi
}

# Función principal
main() {
    # Esperar a que los contenedores estén listos
    if ! wait_for_containers; then
        exit 1
    fi
    
    # Obtener las IPs actuales
    weblogic_a_ip=$(get_container_ip "weblogic-a")
    weblogic_b_ip=$(get_container_ip "weblogic-b")
    
    # Actualizar la configuración
    update_haproxy_config "$weblogic_a_ip" "$weblogic_b_ip"
    
    echo -e "${GREEN}=== Auto-actualización completada ===${NC}"
    echo -e "${YELLOW}Dashboard HAProxy: http://localhost:8082${NC}"
}

# Ejecutar función principal
main "$@"
