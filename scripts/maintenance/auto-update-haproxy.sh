#!/bin/bash
#
# Script mejorado para actualizar automáticamente las IPs de HAProxy
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
HAPROXY_CONFIG="$PROJECT_DIR/haproxy/config/haproxy.cfg"
HAPROXY_CONTAINER="haproxy"

echo -e "${GREEN}=== Auto-actualización de HAProxy iniciada ===${NC}"

# Función para obtener la IP de un contenedor
get_container_ip() {
    local container_name=$1
    local ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name" 2>/dev/null)
    echo "$ip"
}

# Función para verificar si un contenedor está corriendo
is_container_running() {
    local container_name=$1
    docker ps --format "{{.Names}}" | grep -q "^${container_name}$"
}

# Función para esperar a que los contenedores estén listos
wait_for_containers() {
    local max_attempts=30
    local attempt=1
    
    echo -e "${YELLOW}Esperando a que los contenedores estén listos...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        local all_ready=true
        
        # Verificar WebLogic A
        if is_container_running "weblogic-a"; then
            weblogic_a_ip=$(get_container_ip "weblogic-a")
            if [ -z "$weblogic_a_ip" ]; then
                all_ready=false
            fi
        else
            all_ready=false
        fi
        
        # Verificar WebLogic B
        if is_container_running "weblogic-b"; then
            weblogic_b_ip=$(get_container_ip "weblogic-b")
            if [ -z "$weblogic_b_ip" ]; then
                all_ready=false
            fi
        else
            all_ready=false
        fi
        
        if [ "$all_ready" = true ]; then
            echo -e "${GREEN}Contenedores listos:${NC}"
            echo -e "  weblogic-a: $weblogic_a_ip"
            echo -e "  weblogic-b: $weblogic_b_ip"
            return 0
        fi
        
        echo -e "${YELLOW}Intento $attempt/$max_attempts - Esperando contenedores...${NC}"
        sleep 3
        ((attempt++))
    done
    
    echo -e "${RED}Timeout: Los contenedores no están listos después de $max_attempts intentos${NC}"
    return 1
}

# Función para hacer backup de la configuración
backup_config() {
    local backup_file="${HAPROXY_CONFIG}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$HAPROXY_CONFIG" "$backup_file"
    echo -e "${BLUE}Backup creado: $backup_file${NC}"
}

# Función para actualizar la configuración de HAProxy
update_haproxy_config() {
    local weblogic_a_ip=$1
    local weblogic_b_ip=$2
    
    echo -e "${YELLOW}Actualizando configuración de HAProxy...${NC}"
    
    # Hacer backup
    backup_config
    
    # Crear configuración temporal
    local temp_config="/tmp/haproxy_temp.cfg"
    cp "$HAPROXY_CONFIG" "$temp_config"
    
    # Actualizar las IPs en la configuración temporal
    sed -i "s/server weblogic-a [0-9.]*:7001/server weblogic-a $weblogic_a_ip:7001/g" "$temp_config"
    sed -i "s/server weblogic-b [0-9.]*:7001/server weblogic-b $weblogic_b_ip:7001/g" "$temp_config"
    
    # Validar la configuración antes de aplicarla
    echo -e "${BLUE}Validando configuración temporal...${NC}"
    
    # Copiar archivo temporal al contenedor para validación
    docker cp "$temp_config" "$HAPROXY_CONTAINER:/tmp/haproxy_validation.cfg"
    
    # Validar configuración con manejo de errores mejorado
    validation_output=$(docker exec "$HAPROXY_CONTAINER" haproxy -f /tmp/haproxy_validation.cfg -c 2>&1)
    validation_result=$?
    
    # Mostrar warnings pero no fallar por ellos
    if echo "$validation_output" | grep -q "WARNING"; then
        echo -e "${YELLOW}Advertencias encontradas (no críticas):${NC}"
        echo "$validation_output" | grep "WARNING" | head -5
    fi
    
    # Solo fallar si hay errores ALERT o FATAL
    if [ $validation_result -eq 0 ] || ! echo "$validation_output" | grep -qE "(ALERT|FATAL)"; then
        # Configuración válida o solo con warnings, aplicar cambios
        cp "$temp_config" "$HAPROXY_CONFIG"
        echo -e "${GREEN}Configuración actualizada correctamente${NC}"
        
        # Limpiar archivo temporal del contenedor
        docker exec "$HAPROXY_CONTAINER" rm -f /tmp/haproxy_validation.cfg
        
        # Recargar HAProxy
        reload_haproxy
    else
        echo -e "${RED}Error: Configuración inválida, no se aplicaron cambios${NC}"
        echo -e "${RED}Errores encontrados:${NC}"
        echo "$validation_output" | grep -E "(ALERT|FATAL)"
        docker exec "$HAPROXY_CONTAINER" rm -f /tmp/haproxy_validation.cfg
        rm -f "$temp_config"
        return 1
    fi
    
    rm -f "$temp_config"
}

# Función para recargar HAProxy
reload_haproxy() {
    if is_container_running "$HAPROXY_CONTAINER"; then
        echo -e "${YELLOW}Recargando configuración de HAProxy...${NC}"
        
        # Método 1: Reload suave usando socket
        if docker exec "$HAPROXY_CONTAINER" test -S /var/run/haproxy.sock; then
            docker exec "$HAPROXY_CONTAINER" sh -c "echo 'reload' | socat stdio /var/run/haproxy.sock" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}HAProxy recargado exitosamente (socket)${NC}"
                return 0
            fi
        fi
        
        # Método 2: Reload usando señal
        local haproxy_pid=$(docker exec "$HAPROXY_CONTAINER" cat /var/run/haproxy.pid 2>/dev/null)
        if [ -n "$haproxy_pid" ]; then
            docker exec "$HAPROXY_CONTAINER" haproxy -f /usr/local/etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -sf "$haproxy_pid" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}HAProxy recargado exitosamente (señal)${NC}"
                return 0
            fi
        fi
        
        # Método 3: Reiniciar contenedor como último recurso
        echo -e "${YELLOW}Reiniciando contenedor HAProxy...${NC}"
        docker restart "$HAPROXY_CONTAINER" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}HAProxy reiniciado exitosamente${NC}"
            return 0
        fi
        
        echo -e "${RED}Error: No se pudo recargar HAProxy${NC}"
        return 1
    else
        echo -e "${YELLOW}HAProxy no está ejecutándose${NC}"
        return 1
    fi
}

# Función para verificar el estado de HAProxy
check_haproxy_status() {
    echo -e "${BLUE}=== Verificando estado de HAProxy ===${NC}"
    
    # Verificar puertos
    local ports=("8080" "8081" "8404" "8444")
    for port in "${ports[@]}"; do
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            echo -e "${GREEN}✓${NC} Puerto $port: Activo"
        else
            echo -e "${RED}✗${NC} Puerto $port: Inactivo"
        fi
    done
    
    # Verificar endpoints
    echo ""
    echo -e "${BLUE}Verificando endpoints:${NC}"
    
    # Health check
    if curl -s -f http://localhost:8083/health >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Health check: OK"
    else
        echo -e "${RED}✗${NC} Health check: Error"
    fi
    
    # Stats
    if curl -s -f http://localhost:8404/stats >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Stats: OK"
    else
        echo -e "${RED}✗${NC} Stats: Error"
    fi
}

# Función principal
main() {
    # Verificar que HAProxy esté corriendo
    if ! is_container_running "$HAPROXY_CONTAINER"; then
        echo -e "${RED}Error: Contenedor HAProxy no está corriendo${NC}"
        exit 1
    fi
    
    # Esperar a que los contenedores estén listos
    if ! wait_for_containers; then
        echo -e "${RED}Error: Los contenedores WebLogic no están listos${NC}"
        exit 1
    fi
    
    # Obtener las IPs actuales
    weblogic_a_ip=$(get_container_ip "weblogic-a")
    weblogic_b_ip=$(get_container_ip "weblogic-b")
    
    if [ -z "$weblogic_a_ip" ] || [ -z "$weblogic_b_ip" ]; then
        echo -e "${RED}Error: No se pudieron obtener las IPs de los contenedores${NC}"
        exit 1
    fi
    
    # Actualizar la configuración
    if update_haproxy_config "$weblogic_a_ip" "$weblogic_b_ip"; then
        # Esperar un momento para que HAProxy se estabilice
        sleep 3
        
        # Verificar estado
        check_haproxy_status
        
        echo ""
        echo -e "${GREEN}=== Auto-actualización completada exitosamente ===${NC}"
        echo -e "${BLUE}URLs disponibles:${NC}"
        echo -e "  • Load Balancer: http://localhost:8083"
        echo -e "  • HAProxy Stats: http://localhost:8404/stats"
        echo -e "  • HAProxy Admin: http://localhost:8082"
        echo -e "  • HAProxy API: http://localhost:8081"
        echo -e "  • HAProxy HTTPS: https://localhost:8444"
    else
        echo -e "${RED}Error en la actualización de HAProxy${NC}"
        exit 1
    fi
}

# Ejecutar función principal
main "$@"
