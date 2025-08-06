#!/bin/bash
# Script para detener todos los servicios de forma segura

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}=== Deteniendo servicios Docker ===${NC}"

# Función para mostrar ayuda
show_help() {
    echo -e "${YELLOW}Uso: $0 [OPCIÓN]${NC}"
    echo ""
    echo "Opciones:"
    echo "  --help, -h          Mostrar esta ayuda"
    echo "  --force, -f         Forzar detención (docker-compose down --remove-orphans)"
    echo "  --clean, -c         Detener y limpiar volúmenes (¡CUIDADO: Borra datos!)"
    echo "  --status, -s        Solo mostrar el estado de los servicios"
    echo ""
    echo "Sin opciones: Detención normal de servicios"
}

# Función para cargar variables de entorno
load_environment() {
    echo -e "${YELLOW}Cargando variables de entorno...${NC}"
    source "$PROJECT_ROOT/scripts/core/load-env.sh"
    load_env > /dev/null 2>&1
}

# Función para mostrar el estado de los servicios
show_status() {
    load_environment
    
    echo -e "${YELLOW}Estado actual de los servicios:${NC}"
    echo ""
    
    # Verificar contenedores
    containers=("weblogic-a" "weblogic-b" "haproxy" "orcldb")
    
    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container"; then
            status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$container" | awk '{print $2, $3, $4}')
            echo -e "  ${GREEN}✓${NC} $container: $status"
        elif docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -q "$container"; then
            status=$(docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep "$container" | awk '{print $2, $3, $4}')
            echo -e "  ${RED}✗${NC} $container: $status"
        else
            echo -e "  ${YELLOW}?${NC} $container: No encontrado"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}Puertos configurados:${NC}"
    echo -e "  WebLogic A:        ${WEBLOGIC_A_EXTERNAL_PORT:-7001}"
    echo -e "  WebLogic B:        ${WEBLOGIC_B_EXTERNAL_PORT:-7002}"
    echo -e "  HAProxy HTTP:      ${HAPROXY_HTTP_EXTERNAL_PORT:-8083}"
    echo -e "  HAProxy HTTPS:     ${HAPROXY_HTTPS_EXTERNAL_PORT:-8444}"
    echo -e "  HAProxy Stats:     ${HAPROXY_STATS_EXTERNAL_PORT:-8404}"
    echo -e "  HAProxy Admin UI:  ${HAPROXY_UI_EXTERNAL_PORT:-8082}"
    echo -e "  Oracle DB:         ${ORACLE_EXTERNAL_PORT:-1521}"
    echo -e "  Oracle EM:         ${ORACLE_EM_EXTERNAL_PORT:-5500}"
    echo -e "  Documentación:     ${MKDOCS_EXTERNAL_PORT:-8000}"
    
    echo ""
    echo -e "${YELLOW}Puertos en uso:${NC}"
    ports_to_check="${WEBLOGIC_A_EXTERNAL_PORT:-7001} ${WEBLOGIC_B_EXTERNAL_PORT:-7002} ${HAPROXY_HTTP_EXTERNAL_PORT:-8083} ${HAPROXY_STATS_EXTERNAL_PORT:-8404} ${HAPROXY_UI_EXTERNAL_PORT:-8082} ${ORACLE_EXTERNAL_PORT:-1521} ${ORACLE_EM_EXTERNAL_PORT:-5500} ${MKDOCS_EXTERNAL_PORT:-8000}"
    
    for port in $ports_to_check; do
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            echo -e "  Puerto $port: ${GREEN}En uso${NC}"
        else
            echo -e "  Puerto $port: ${YELLOW}Libre${NC}"
        fi
    done
}

# Función para detener servicios normalmente
stop_services() {
    load_environment
    
    echo -e "${YELLOW}Deteniendo servicios...${NC}"
    
    # Primero detener port-forwards de Minikube si existen
    if [ -f "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" ]; then
        echo -e "${YELLOW}Deteniendo port-forwards de Minikube...${NC}"
        "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" stop 2>/dev/null || true
    fi
    
    # Detener servicios Docker
    "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" down
    
    # Verificar y limpiar contenedores huérfanos
    echo -e "${YELLOW}Verificando contenedores huérfanos...${NC}"
    orphan_containers=$(docker ps -a --filter "label=com.docker.compose.project=weblogic-haproxy" --format "{{.Names}}" | grep -v -E "^(weblogic-a|weblogic-b|haproxy|orcldb|mkdocs-server)$" || true)
    
    if [ -n "$orphan_containers" ]; then
        echo -e "${YELLOW}Limpiando contenedores huérfanos: $orphan_containers${NC}"
        echo "$orphan_containers" | xargs -r docker stop 2>/dev/null || true
        echo "$orphan_containers" | xargs -r docker rm 2>/dev/null || true
    fi
    
    # Limpiar redes huérfanas
    echo -e "${YELLOW}Limpiando redes no utilizadas...${NC}"
    docker network prune -f >/dev/null 2>&1 || true
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Servicios detenidos correctamente${NC}"
    else
        echo -e "${RED}Error al detener algunos servicios${NC}"
        return 1
    fi
}

# Función para detener servicios con fuerza
stop_services_force() {
    load_environment
    
    echo -e "${YELLOW}Deteniendo servicios con fuerza...${NC}"
    
    # Detener port-forwards de Minikube primero
    if [ -f "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" ]; then
        echo -e "${YELLOW}Deteniendo port-forwards de Minikube...${NC}"
        "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" stop 2>/dev/null || true
    fi
    
    # Usar docker-compose down con opciones adicionales
    "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" down --remove-orphans --timeout 30
    
    # Detener contenedores individuales si aún están corriendo
    containers=("weblogic-a" "weblogic-b" "haproxy" "orcldb" "mkdocs-server")
    for container in "${containers[@]}"; do
        if docker ps -q -f name="$container" | grep -q .; then
            echo -e "${YELLOW}Forzando detención de $container...${NC}"
            docker stop "$container" --time 10 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
        fi
    done
    
    # Limpiar contenedores con etiquetas del proyecto
    echo -e "${YELLOW}Limpiando contenedores del proyecto...${NC}"
    docker ps -a --filter "label=com.docker.compose.project=weblogic-haproxy" -q | xargs -r docker rm -f 2>/dev/null || true
    
    # Limpiar redes del proyecto
    echo -e "${YELLOW}Limpiando redes del proyecto...${NC}"
    docker network ls --filter "name=weblogic-haproxy" -q | xargs -r docker network rm 2>/dev/null || true
    
    # Limpiar redes huérfanas
    docker network prune -f >/dev/null 2>&1 || true
    
    echo -e "${GREEN}Servicios detenidos con fuerza${NC}"
}

# Función para limpiar completamente (incluyendo volúmenes)
clean_all() {
    echo -e "${RED}¡ADVERTENCIA!${NC}"
    echo -e "${YELLOW}Esta opción eliminará TODOS los datos de la base de datos y logs.${NC}"
    echo -e "${YELLOW}¿Estás seguro? (escriba 'SI' para confirmar):${NC}"
    read -r confirmation
    
    if [ "$confirmation" = "SI" ]; then
        load_environment
        
        echo -e "${YELLOW}Limpiando todos los servicios y volúmenes...${NC}"
        
        # Usar el wrapper para detener con volúmenes
        "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" down --volumes --remove-orphans
        
        # Limpiar imágenes huérfanas relacionadas
        echo -e "${YELLOW}Limpiando imágenes no utilizadas...${NC}"
        docker image prune -f
        
        echo -e "${GREEN}Limpieza completa realizada${NC}"
    else
        echo -e "${YELLOW}Operación cancelada${NC}"
    fi
}

# Función principal
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --status|-s)
            show_status
            ;;
        --force|-f)
            stop_services_force
            ;;
        --clean|-c)
            clean_all
            ;;
        "")
            stop_services
            ;;
        *)
            echo -e "${RED}Opción no reconocida: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"

# Mostrar estado final
echo ""
echo -e "${BLUE}Estado final:${NC}"
show_status
