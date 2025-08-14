#!/bin/bash

# Script integrado para actualizar IPs de HAProxy usando ambos métodos
# Utiliza el script automático como método principal y Python como fallback

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Actualizador Integrado de IPs de HAProxy ===${NC}"
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
    echo -e "${BLUE}IPs actuales de contenedores:${NC}"
    
    for container in weblogic-a weblogic-b weblogic-ff; do
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
    echo -e "${BLUE}Verificando contenedores...${NC}"
    
    local containers_ready=true
    for container in weblogic-a weblogic-b; do
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

# Función principal
main() {
    # Verificar que estamos en el directorio correcto
    if [ ! -f "scripts/auto-update-haproxy.sh" ] || [ ! -f "scripts/haproxy-ip-updater.py" ]; then
        echo -e "${RED}Error: Scripts de actualización no encontrados${NC}"
        echo -e "${YELLOW}Asegúrate de ejecutar desde el directorio raíz del proyecto${NC}"
        exit 1
    fi
    
    # Verificar contenedores
    if ! check_containers; then
        exit 1
    fi
    
    # Mostrar IPs actuales
    show_current_ips
    
    # Método 1: Script automático (recomendado)
    echo -e "${BLUE}=== Método 1: Script Automático (Recomendado) ===${NC}"
    if ./scripts/auto-update-haproxy.sh; then
        show_status 0 "Actualización con script automático exitosa"
        
        # Verificar que la actualización funcionó
        echo -e "${BLUE}Verificando actualización...${NC}"
        if docker exec haproxy grep -E "server weblogic-[ab] [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:7001" /usr/local/etc/haproxy/haproxy.cfg >/dev/null 2>&1; then
            show_status 0 "Configuración de HAProxy actualizada correctamente"
            echo -e "${BLUE}Configuración actual:${NC}"
            docker exec haproxy grep -E "server weblogic-[ab] [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:7001" /usr/local/etc/haproxy/haproxy.cfg | sed 's/^/  /'
            echo
            echo -e "${GREEN}=== Actualización de IPs completada exitosamente ===${NC}"
            return 0
        else
            show_status 1 "La configuración no se actualizó correctamente"
        fi
    else
        show_status 1 "Error con script automático"
    fi
    
    # Método 2: Script Python (fallback)
    echo
    echo -e "${BLUE}=== Método 2: Script Python Avanzado (Fallback) ===${NC}"
    if python3 scripts/haproxy-ip-updater.py; then
        show_status 0 "Actualización con script Python exitosa"
        
        # Verificar que la actualización funcionó
        echo -e "${BLUE}Verificando actualización...${NC}"
        if docker exec haproxy grep -E "server weblogic-[ab] [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:7001" /usr/local/etc/haproxy/haproxy.cfg >/dev/null 2>&1; then
            show_status 0 "Configuración de HAProxy actualizada correctamente"
            echo -e "${BLUE}Configuración actual:${NC}"
            docker exec haproxy grep -E "server weblogic-[ab] [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:7001" /usr/local/etc/haproxy/haproxy.cfg | sed 's/^/  /'
            echo
            echo -e "${GREEN}=== Actualización de IPs completada exitosamente ===${NC}"
            return 0
        else
            show_status 1 "La configuración no se actualizó correctamente"
        fi
    else
        show_status 1 "Error con script Python"
    fi
    
    # Si ambos métodos fallan
    echo
    echo -e "${RED}=== Error: Ambos métodos de actualización fallaron ===${NC}"
    echo
    echo -e "${YELLOW}Diagnóstico:${NC}"
    echo -e "1. Verificar que HAProxy esté ejecutándose: ${BLUE}docker ps | grep haproxy${NC}"
    echo -e "2. Verificar logs de HAProxy: ${BLUE}docker logs haproxy${NC}"
    echo -e "3. Verificar IPs de contenedores manualmente:"
    for container in weblogic-a weblogic-b; do
        local ip=$(get_container_ip "$container")
        echo -e "   docker inspect $container | grep IPAddress"
    done
    echo -e "4. Verificar configuración actual: ${BLUE}docker exec haproxy cat /usr/local/etc/haproxy/haproxy.cfg | grep 'server weblogic'${NC}"
    
    return 1
}

# Ejecutar función principal
main "$@"
