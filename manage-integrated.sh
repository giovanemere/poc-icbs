#!/bin/bash

# Script de gestión integrado que usa Docker Compose para ejecutar comandos
# Reemplaza la necesidad de ejecutar manualmente: cd /path && ./run-integrated-command.sh

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuración
COMPOSE_FILE="config/docker-compose-integrated.yml"
PROJECT_NAME="weblogic-integrated"

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Gestión Integrada Docker para Oracle WebLogic ===${NC}"
    echo
    echo -e "${YELLOW}Uso:${NC} $0 [COMANDO] [OPCIONES]"
    echo
    echo -e "${YELLOW}Comandos disponibles:${NC}"
    echo -e "  ${GREEN}start${NC}           - Iniciar todos los servicios con gestión integrada"
    echo -e "  ${GREEN}stop${NC}            - Detener todos los servicios"
    echo -e "  ${GREEN}restart${NC}         - Reiniciar todos los servicios"
    echo -e "  ${GREEN}status${NC}          - Ver estado de todos los servicios"
    echo -e "  ${GREEN}logs${NC}            - Ver logs de todos los servicios"
    echo -e "  ${GREEN}run-integrated${NC}  - Ejecutar comando integrado (limpieza + inicio)"
    echo -e "  ${GREEN}exec${NC}            - Ejecutar comando en el contenedor de gestión"
    echo -e "  ${GREEN}cleanup${NC}         - Limpiar entorno y volúmenes"
    echo -e "  ${GREEN}update-ips${NC}      - Actualizar IPs de HAProxy"
    echo -e "  ${GREEN}dashboard${NC}       - Abrir dashboard en navegador"
    echo -e "  ${GREEN}help${NC}            - Mostrar esta ayuda"
    echo
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo -e "  $0 start                    # Iniciar todo el entorno"
    echo -e "  $0 run-integrated           # Ejecutar comando integrado completo"
    echo -e "  $0 exec ./cleanup-environment.sh light"
    echo -e "  $0 logs haproxy             # Ver logs de HAProxy"
    echo -e "  $0 status                   # Ver estado de servicios"
    echo
    echo -e "${BLUE}URLs importantes (ENTORNO INTEGRADO):${NC}"
    echo -e "  HAProxy Frontend:     http://localhost:8090"
    echo -e "  HAProxy Stats:        http://localhost:8414/stats"
    echo -e "  Panel Admin:          http://localhost:8092"
    echo -e "  Dashboard:            http://localhost:8011"
    echo -e "  WebLogic A Console:   http://localhost:7003/console"
    echo -e "  WebLogic B Console:   http://localhost:7004/console"
    echo
    echo -e "${YELLOW}NOTA: Este entorno usa puertos diferentes para evitar conflictos${NC}"
}

# Función para verificar prerequisitos
check_prerequisites() {
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Error: docker-compose no está instalado${NC}"
        exit 1
    fi
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo -e "${RED}❌ Error: Archivo $COMPOSE_FILE no encontrado${NC}"
        exit 1
    fi
}

# Función para iniciar servicios
start_services() {
    echo -e "${BLUE}=== Iniciando Servicios Integrados ===${NC}"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d
    
    echo -e "${GREEN}✓ Servicios iniciados${NC}"
    echo -e "${YELLOW}Esperando que los servicios estén listos...${NC}"
    sleep 10
    
    show_status
}

# Función para detener servicios
stop_services() {
    echo -e "${BLUE}=== Deteniendo Servicios ===${NC}"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down
    echo -e "${GREEN}✓ Servicios detenidos${NC}"
}

# Función para reiniciar servicios
restart_services() {
    echo -e "${BLUE}=== Reiniciando Servicios ===${NC}"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" restart
    echo -e "${GREEN}✓ Servicios reiniciados${NC}"
}

# Función para mostrar estado
show_status() {
    echo -e "${BLUE}=== Estado de Servicios ===${NC}"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps
    echo
    echo -e "${BLUE}=== URLs de Acceso (ENTORNO INTEGRADO) ===${NC}"
    echo -e "${GREEN}✓ HAProxy Frontend:${NC}     http://localhost:8090"
    echo -e "${GREEN}✓ HAProxy Stats:${NC}        http://localhost:8414/stats"
    echo -e "${GREEN}✓ Panel Admin:${NC}          http://localhost:8092"
    echo -e "${GREEN}✓ Dashboard:${NC}            http://localhost:8011"
    echo -e "${GREEN}✓ WebLogic A Console:${NC}   http://localhost:7003/console"
    echo -e "${GREEN}✓ WebLogic B Console:${NC}   http://localhost:7004/console"
    echo
    echo -e "${YELLOW}NOTA: Puertos diferentes para evitar conflictos con el entorno original${NC}"
}

# Función para ver logs
show_logs() {
    local service="$1"
    if [ -n "$service" ]; then
        echo -e "${BLUE}=== Logs de $service ===${NC}"
        docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs -f "$service"
    else
        echo -e "${BLUE}=== Logs de Todos los Servicios ===${NC}"
        docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs -f
    fi
}

# Función para ejecutar comando integrado
run_integrated_command() {
    echo -e "${BLUE}=== Ejecutando Comando Integrado ===${NC}"
    echo -e "${YELLOW}Equivalente a: cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./run-integrated-command.sh${NC}"
    echo
    
    # Asegurar que los servicios estén ejecutándose
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d
    
    # Esperar a que el integrated-manager esté listo
    echo -e "${YELLOW}Esperando que el integrated-manager esté listo...${NC}"
    sleep 15
    
    # Ejecutar el comando integrado en el contenedor de gestión
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" exec integrated-manager ./run-integrated-command.sh
    
    echo -e "${GREEN}✓ Comando integrado completado${NC}"
}

# Función para ejecutar comando personalizado
exec_command() {
    shift # Remover 'exec' del array de argumentos
    echo -e "${BLUE}=== Ejecutando Comando: $* ===${NC}"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" exec integrated-manager "$@"
}

# Función para limpiar entorno
cleanup_environment() {
    echo -e "${BLUE}=== Limpiando Entorno ===${NC}"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down -v --remove-orphans
    docker system prune -f
    echo -e "${GREEN}✓ Entorno limpiado${NC}"
}

# Función para actualizar IPs
update_ips() {
    echo -e "${BLUE}=== Actualizando IPs de HAProxy ===${NC}"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" exec integrated-manager ./update-haproxy-ips.sh
    echo -e "${GREEN}✓ IPs actualizadas${NC}"
}

# Función para abrir dashboard
open_dashboard() {
    echo -e "${BLUE}=== Abriendo Dashboard ===${NC}"
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:8011
    elif command -v open &> /dev/null; then
        open http://localhost:8011
    else
        echo -e "${YELLOW}Abrir manualmente: http://localhost:8011${NC}"
    fi
}

# Función principal
main() {
    check_prerequisites
    
    case "${1:-help}" in
        "start")
            start_services
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            restart_services
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "$2"
            ;;
        "run-integrated")
            run_integrated_command
            ;;
        "exec")
            exec_command "$@"
            ;;
        "cleanup")
            cleanup_environment
            ;;
        "update-ips")
            update_ips
            ;;
        "dashboard")
            open_dashboard
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Ejecutar función principal con todos los argumentos
main "$@"
