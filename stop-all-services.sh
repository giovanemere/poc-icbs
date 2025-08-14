#!/bin/bash
#
# Script para detener todos los servicios de forma segura
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
COMPOSE_FILE="$PROJECT_DIR/config/docker-compose.yml"

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

# Función para mostrar el estado de los servicios
show_status() {
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
    echo -e "${YELLOW}Puertos en uso:${NC}"
    netstat -tlnp 2>/dev/null | grep -E ":(7001|7002|8080|8404|8081|8082|1521|5500)" | while read line; do
        port=$(echo "$line" | awk '{print $4}' | cut -d':' -f2)
        echo -e "  Puerto $port: En uso"
    done
}

# Función para detener servicios normalmente
stop_services() {
    echo -e "${YELLOW}Deteniendo servicios...${NC}"
    
    cd "$PROJECT_DIR" || {
        echo -e "${RED}Error: No se puede acceder al directorio del proyecto${NC}"
        exit 1
    }
    
    if [ -f "$COMPOSE_FILE" ]; then
        docker-compose -f "$COMPOSE_FILE" down
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Servicios detenidos correctamente${NC}"
        else
            echo -e "${RED}Error al detener algunos servicios${NC}"
            return 1
        fi
    else
        echo -e "${RED}Error: No se encuentra el archivo docker-compose.yml${NC}"
        return 1
    fi
}

# Función para detener servicios con fuerza
stop_services_force() {
    echo -e "${YELLOW}Deteniendo servicios con fuerza...${NC}"
    
    cd "$PROJECT_DIR" || {
        echo -e "${RED}Error: No se puede acceder al directorio del proyecto${NC}"
        exit 1
    }
    
    if [ -f "$COMPOSE_FILE" ]; then
        docker-compose -f "$COMPOSE_FILE" down --remove-orphans
        
        # Detener contenedores individuales si aún están corriendo
        containers=("weblogic-a" "weblogic-b" "haproxy" "orcldb")
        for container in "${containers[@]}"; do
            if docker ps -q -f name="$container" | grep -q .; then
                echo -e "${YELLOW}Forzando detención de $container...${NC}"
                docker stop "$container" 2>/dev/null
                docker rm "$container" 2>/dev/null
            fi
        done
        
        echo -e "${GREEN}Servicios detenidos con fuerza${NC}"
    else
        echo -e "${RED}Error: No se encuentra el archivo docker-compose.yml${NC}"
        return 1
    fi
}

# Función para limpiar completamente (incluyendo volúmenes)
clean_all() {
    echo -e "${RED}¡ADVERTENCIA!${NC}"
    echo -e "${YELLOW}Esta opción eliminará TODOS los datos de la base de datos y logs.${NC}"
    echo -e "${YELLOW}¿Estás seguro? (escriba 'SI' para confirmar):${NC}"
    read -r confirmation
    
    if [ "$confirmation" = "SI" ]; then
        echo -e "${YELLOW}Limpiando todos los servicios y volúmenes...${NC}"
        
        cd "$PROJECT_DIR" || {
            echo -e "${RED}Error: No se puede acceder al directorio del proyecto${NC}"
            exit 1
        }
        
        if [ -f "$COMPOSE_FILE" ]; then
            docker-compose -f "$COMPOSE_FILE" down --volumes --remove-orphans
            
            # Limpiar imágenes huérfanas relacionadas
            echo -e "${YELLOW}Limpiando imágenes no utilizadas...${NC}"
            docker image prune -f
            
            echo -e "${GREEN}Limpieza completa realizada${NC}"
        else
            echo -e "${RED}Error: No se encuentra el archivo docker-compose.yml${NC}"
            return 1
        fi
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
