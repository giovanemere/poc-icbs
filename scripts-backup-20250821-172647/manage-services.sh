#!/bin/bash
#
# Script de gestión completa para los servicios Docker
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
COMPOSE_FILE="$PROJECT_DIR/config/docker-compose.yml"

# Función para mostrar el banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Gestor de Servicios WebLogic + HAProxy         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para mostrar ayuda
show_help() {
    show_banner
    echo -e "${YELLOW}Uso: $0 [COMANDO] [OPCIONES]${NC}"
    echo ""
    echo -e "${BLUE}Comandos disponibles:${NC}"
    echo "  start           Iniciar todos los servicios con auto-actualización"
    echo "  stop            Detener todos los servicios"
    echo "  restart         Reiniciar todos los servicios"
    echo "  status          Mostrar estado de los servicios"
    echo "  logs            Mostrar logs de los servicios"
    echo "  update-haproxy  Actualizar solo la configuración de HAProxy"
    echo "  clean           Limpiar completamente (¡CUIDADO: Borra datos!)"
    echo ""
    echo -e "${BLUE}Opciones para stop:${NC}"
    echo "  --force, -f     Forzar detención"
    echo ""
    echo -e "${BLUE}Opciones para logs:${NC}"
    echo "  --follow, -f    Seguir logs en tiempo real"
    echo "  [servicio]      Ver logs de un servicio específico (weblogic-a, weblogic-b, haproxy, orcldb)"
    echo ""
    echo -e "${BLUE}Ejemplos:${NC}"
    echo "  $0 start                    # Iniciar servicios"
    echo "  $0 stop                     # Detener servicios"
    echo "  $0 stop --force             # Detener con fuerza"
    echo "  $0 logs --follow            # Ver todos los logs en tiempo real"
    echo "  $0 logs haproxy             # Ver logs solo de HAProxy"
    echo "  $0 status                   # Ver estado actual"
}

# Función para mostrar el estado de los servicios
show_status() {
    echo -e "${BLUE}=== Estado de los Servicios ===${NC}"
    echo ""
    
    # Verificar contenedores
    containers=("weblogic-a" "weblogic-b" "haproxy" "orcldb")
    
    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "$container"; then
            info=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$container")
            echo -e "  ${GREEN}✓ RUNNING${NC} $info"
        elif docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -q "$container"; then
            status=$(docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep "$container" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}')
            echo -e "  ${RED}✗ STOPPED${NC} $container: $status"
        else
            echo -e "  ${YELLOW}? NOT FOUND${NC} $container"
        fi
    done
    
    echo ""
    echo -e "${BLUE}=== URLs de Acceso ===${NC}"
    if docker ps | grep -q haproxy; then
        echo -e "  ${GREEN}✓${NC} Load Balancer:     http://localhost:8080"
        echo -e "  ${GREEN}✓${NC} HAProxy Stats:     http://localhost:8404/stats"
        echo -e "  ${GREEN}✓${NC} HAProxy Admin:     http://localhost:8082"
    else
        echo -e "  ${RED}✗${NC} HAProxy no está ejecutándose"
    fi
    
    if docker ps | grep -q weblogic-a; then
        echo -e "  ${GREEN}✓${NC} WebLogic A:        http://localhost:7001/console"
    else
        echo -e "  ${RED}✗${NC} WebLogic A no está ejecutándose"
    fi
    
    if docker ps | grep -q weblogic-b; then
        echo -e "  ${GREEN}✓${NC} WebLogic B:        http://localhost:7002/console"
    else
        echo -e "  ${RED}✗${NC} WebLogic B no está ejecutándose"
    fi
    
    if docker ps | grep -q orcldb; then
        echo -e "  ${GREEN}✓${NC} Oracle DB:         localhost:1521 (XE)"
        echo -e "  ${GREEN}✓${NC} Oracle EM Express: https://localhost:5500/em"
    else
        echo -e "  ${RED}✗${NC} Oracle DB no está ejecutándose"
    fi
}

# Función para iniciar servicios
start_services() {
    show_banner
    echo -e "${BLUE}=== Iniciando Servicios ===${NC}"
    
    if [ -f "$PROJECT_DIR/start-with-auto-update.sh" ]; then
        "$PROJECT_DIR/start-with-auto-update.sh"
    else
        echo -e "${RED}Error: Script de inicio no encontrado${NC}"
        exit 1
    fi
}

# Función para detener servicios
stop_services() {
    show_banner
    echo -e "${BLUE}=== Deteniendo Servicios ===${NC}"
    
    if [ -f "$PROJECT_DIR/stop-all-services.sh" ]; then
        if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
            "$PROJECT_DIR/stop-all-services.sh" --force
        else
            "$PROJECT_DIR/stop-all-services.sh"
        fi
    else
        echo -e "${RED}Error: Script de parada no encontrado${NC}"
        exit 1
    fi
}

# Función para mostrar logs
show_logs() {
    local service="$1"
    local follow="$2"
    
    cd "$PROJECT_DIR" || {
        echo -e "${RED}Error: No se puede acceder al directorio del proyecto${NC}"
        exit 1
    }
    
    if [ "$follow" = "--follow" ] || [ "$follow" = "-f" ]; then
        if [ -n "$service" ] && [ "$service" != "--follow" ] && [ "$service" != "-f" ]; then
            echo -e "${YELLOW}Siguiendo logs de $service (Ctrl+C para salir)...${NC}"
            docker-compose -f "$COMPOSE_FILE" logs -f "$service"
        else
            echo -e "${YELLOW}Siguiendo logs de todos los servicios (Ctrl+C para salir)...${NC}"
            docker-compose -f "$COMPOSE_FILE" logs -f
        fi
    else
        if [ -n "$service" ]; then
            echo -e "${YELLOW}Logs de $service:${NC}"
            docker-compose -f "$COMPOSE_FILE" logs "$service"
        else
            echo -e "${YELLOW}Logs de todos los servicios:${NC}"
            docker-compose -f "$COMPOSE_FILE" logs
        fi
    fi
}

# Función para actualizar HAProxy
update_haproxy() {
    show_banner
    echo -e "${BLUE}=== Actualizando HAProxy ===${NC}"
    
    if [ -f "$PROJECT_DIR/scripts/auto-update-haproxy.sh" ]; then
        "$PROJECT_DIR/scripts/auto-update-haproxy.sh"
    else
        echo -e "${RED}Error: Script de actualización de HAProxy no encontrado${NC}"
        exit 1
    fi
}

# Función para limpiar completamente
clean_all() {
    show_banner
    echo -e "${BLUE}=== Limpieza Completa ===${NC}"
    
    if [ -f "$PROJECT_DIR/stop-all-services.sh" ]; then
        "$PROJECT_DIR/stop-all-services.sh" --clean
    else
        echo -e "${RED}Error: Script de limpieza no encontrado${NC}"
        exit 1
    fi
}

# Función principal
main() {
    case "${1:-}" in
        start)
            start_services
            ;;
        stop)
            stop_services "$2"
            ;;
        restart)
            echo -e "${YELLOW}Reiniciando servicios...${NC}"
            stop_services
            sleep 3
            start_services
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$2" "$3"
            ;;
        update-haproxy)
            update_haproxy
            ;;
        clean)
            clean_all
            ;;
        --help|-h|help|"")
            show_help
            ;;
        *)
            echo -e "${RED}Comando no reconocido: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
