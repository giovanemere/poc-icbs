#!/bin/bash
# Script para limpieza completa del entorno Docker

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}=== Limpieza Completa del Entorno ===${NC}"

# Función para mostrar ayuda
show_help() {
    echo -e "${YELLOW}Uso: $0 [OPCIÓN]${NC}"
    echo ""
    echo "Opciones:"
    echo "  --help, -h          Mostrar esta ayuda"
    echo "  --dry-run, -d       Mostrar qué se haría sin ejecutar"
    echo "  --force, -f         Ejecutar sin confirmación"
    echo ""
    echo "Sin opciones: Solicitar confirmación antes de limpiar"
}

# Función para limpieza con dry-run
dry_run_cleanup() {
    echo -e "${YELLOW}=== DRY RUN - Acciones que se ejecutarían ===${NC}"
    echo ""
    
    echo -e "${BLUE}1. Detener port-forwards de Minikube${NC}"
    if [ -f "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" ]; then
        echo "   - Ejecutar: minikube-port-forwards.sh stop"
    else
        echo "   - Script no encontrado"
    fi
    
    echo ""
    echo -e "${BLUE}2. Detener y eliminar contenedores del proyecto${NC}"
    containers=$(docker ps -a --filter "label=com.docker.compose.project=weblogic-haproxy" --format "{{.Names}}" 2>/dev/null || true)
    if [ -n "$containers" ]; then
        echo "   - Contenedores a eliminar: $containers"
    else
        echo "   - No hay contenedores del proyecto"
    fi
    
    echo ""
    echo -e "${BLUE}3. Eliminar redes del proyecto${NC}"
    networks=$(docker network ls --filter "name=weblogic-haproxy" --format "{{.Name}}" 2>/dev/null || true)
    if [ -n "$networks" ]; then
        echo "   - Redes a eliminar: $networks"
    else
        echo "   - No hay redes del proyecto"
    fi
    
    echo ""
    echo -e "${BLUE}4. Eliminar volúmenes del proyecto${NC}"
    volumes=$(docker volume ls --filter "name=weblogic-haproxy" --format "{{.Name}}" 2>/dev/null || true)
    if [ -n "$volumes" ]; then
        echo "   - Volúmenes a eliminar: $volumes"
    else
        echo "   - No hay volúmenes del proyecto"
    fi
    
    echo ""
    echo -e "${BLUE}5. Limpiar imágenes no utilizadas${NC}"
    echo "   - Ejecutar: docker image prune -f"
    
    echo ""
    echo -e "${BLUE}6. Limpiar sistema Docker${NC}"
    echo "   - Ejecutar: docker system prune -f"
    
    echo ""
    echo -e "${YELLOW}Para ejecutar la limpieza real: $0 --force${NC}"
}

# Función para limpieza real
execute_cleanup() {
    echo -e "${YELLOW}Iniciando limpieza completa...${NC}"
    
    # 1. Detener port-forwards
    echo -e "${BLUE}1. Deteniendo port-forwards de Minikube...${NC}"
    if [ -f "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" ]; then
        "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" stop 2>/dev/null || true
        echo -e "${GREEN}✓ Port-forwards detenidos${NC}"
    else
        echo -e "${YELLOW}⚠ Script de port-forwards no encontrado${NC}"
    fi
    
    # 2. Detener y eliminar contenedores
    echo -e "${BLUE}2. Eliminando contenedores del proyecto...${NC}"
    containers=$(docker ps -a --filter "label=com.docker.compose.project=weblogic-haproxy" -q 2>/dev/null || true)
    if [ -n "$containers" ]; then
        echo "$containers" | xargs -r docker stop --time 10 2>/dev/null || true
        echo "$containers" | xargs -r docker rm -f 2>/dev/null || true
        echo -e "${GREEN}✓ Contenedores eliminados${NC}"
    else
        echo -e "${YELLOW}⚠ No hay contenedores del proyecto${NC}"
    fi
    
    # 3. Eliminar redes
    echo -e "${BLUE}3. Eliminando redes del proyecto...${NC}"
    networks=$(docker network ls --filter "name=weblogic-haproxy" -q 2>/dev/null || true)
    if [ -n "$networks" ]; then
        echo "$networks" | xargs -r docker network rm 2>/dev/null || true
        echo -e "${GREEN}✓ Redes eliminadas${NC}"
    else
        echo -e "${YELLOW}⚠ No hay redes del proyecto${NC}"
    fi
    
    # 4. Eliminar volúmenes
    echo -e "${BLUE}4. Eliminando volúmenes del proyecto...${NC}"
    volumes=$(docker volume ls --filter "name=weblogic-haproxy" -q 2>/dev/null || true)
    if [ -n "$volumes" ]; then
        echo "$volumes" | xargs -r docker volume rm 2>/dev/null || true
        echo -e "${GREEN}✓ Volúmenes eliminados${NC}"
    else
        echo -e "${YELLOW}⚠ No hay volúmenes del proyecto${NC}"
    fi
    
    # 5. Limpiar imágenes no utilizadas
    echo -e "${BLUE}5. Limpiando imágenes no utilizadas...${NC}"
    docker image prune -f >/dev/null 2>&1 || true
    echo -e "${GREEN}✓ Imágenes limpiadas${NC}"
    
    # 6. Limpiar sistema Docker
    echo -e "${BLUE}6. Limpiando sistema Docker...${NC}"
    docker system prune -f >/dev/null 2>&1 || true
    echo -e "${GREEN}✓ Sistema Docker limpiado${NC}"
    
    echo ""
    echo -e "${GREEN}=== Limpieza completa finalizada ===${NC}"
}

# Función para solicitar confirmación
confirm_cleanup() {
    echo -e "${RED}¡ADVERTENCIA!${NC}"
    echo -e "${YELLOW}Esta operación eliminará:${NC}"
    echo "  • Todos los contenedores del proyecto"
    echo "  • Todas las redes del proyecto"
    echo "  • Todos los volúmenes del proyecto (¡DATOS DE LA BASE DE DATOS!)"
    echo "  • Imágenes Docker no utilizadas"
    echo ""
    echo -e "${YELLOW}¿Estás seguro de que quieres continuar? (escriba 'SI' para confirmar):${NC}"
    read -r confirmation
    
    if [ "$confirmation" = "SI" ]; then
        execute_cleanup
    else
        echo -e "${YELLOW}Operación cancelada${NC}"
        exit 0
    fi
}

# Función principal
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --dry-run|-d)
            dry_run_cleanup
            ;;
        --force|-f)
            execute_cleanup
            ;;
        "")
            confirm_cleanup
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
