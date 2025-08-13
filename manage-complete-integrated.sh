#!/bin/bash

# Script de gestión completo que integra Docker Compose con el comando run-integrated-command.sh
# Proporciona una solución completa para reemplazar: cd /path && ./run-integrated-command.sh

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuración
COMPOSE_FILE="config/docker-compose-with-manager.yml"
PROJECT_NAME="weblogic-integrated"
PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║        🚀 GESTIÓN COMPLETA INTEGRADA - DOCKER COMPOSE       ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Uso:${NC} $0 [COMANDO] [OPCIONES]"
    echo
    echo -e "${YELLOW}Comandos principales:${NC}"
    echo -e "  ${GREEN}start${NC}                - Iniciar todos los servicios con gestión integrada"
    echo -e "  ${GREEN}stop${NC}                 - Detener todos los servicios"
    echo -e "  ${GREEN}restart${NC}              - Reiniciar todos los servicios"
    echo -e "  ${GREEN}status${NC}               - Ver estado de todos los servicios"
    echo -e "  ${GREEN}logs${NC} [servicio]      - Ver logs de servicios"
    echo
    echo -e "${YELLOW}Comandos integrados:${NC}"
    echo -e "  ${GREEN}run-integrated${NC}       - Ejecutar comando integrado original"
    echo -e "  ${GREEN}run-integrated-dc${NC}    - Ejecutar versión Docker Compose"
    echo -e "  ${GREEN}cleanup-light${NC}        - Ejecutar limpieza ligera"
    echo -e "  ${GREEN}update-ips${NC}           - Actualizar IPs de HAProxy"
    echo -e "  ${GREEN}start-dashboard${NC}      - Iniciar dashboard integrado"
    echo
    echo -e "${YELLOW}Comandos de gestión:${NC}"
    echo -e "  ${GREEN}exec${NC} [comando]       - Ejecutar comando en el contenedor de gestión"
    echo -e "  ${GREEN}shell${NC}                - Abrir shell en el contenedor de gestión"
    echo -e "  ${GREEN}cleanup${NC}              - Limpiar entorno completo"
    echo -e "  ${GREEN}dashboard${NC}            - Abrir dashboard en navegador"
    echo -e "  ${GREEN}help${NC}                 - Mostrar esta ayuda"
    echo
    echo -e "${BLUE}URLs importantes:${NC}"
    echo -e "  HAProxy Frontend:     http://localhost:8080"
    echo -e "  HAProxy Stats:        http://localhost:8404/stats"
    echo -e "  Panel Admin:          http://localhost:8082"
    echo -e "  Dashboard:            http://localhost:8001"
    echo -e "  WebLogic A Console:   http://localhost:7001/console"
    echo -e "  WebLogic B Console:   http://localhost:7002/console"
    echo
    echo -e "${YELLOW}Equivalencias:${NC}"
    echo -e "  ${BLUE}$0 run-integrated${NC}     ≡  ${YELLOW}cd $PROJECT_DIR && ./run-integrated-command.sh${NC}"
    echo -e "  ${BLUE}$0 run-integrated-dc${NC}  ≡  ${YELLOW}Versión mejorada con Docker Compose${NC}"
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
    
    # Cambiar al directorio del proyecto
    if [ "$(pwd)" != "$PROJECT_DIR" ]; then
        echo -e "${YELLOW}⚠️  Cambiando al directorio del proyecto: $PROJECT_DIR${NC}"
        cd "$PROJECT_DIR"
    fi
}

# Función para iniciar servicios
start_services() {
    echo -e "${BLUE}=== Iniciando Servicios Integrados ===${NC}"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d
    
    echo -e "${GREEN}✓ Servicios iniciados${NC}"
    echo -e "${YELLOW}Esperando que los servicios estén listos...${NC}"
    sleep 15
    
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
    echo -e "${BLUE}=== URLs de Acceso ===${NC}"
    echo -e "${GREEN}✓ HAProxy Frontend:${NC}     http://localhost:8080"
    echo -e "${GREEN}✓ HAProxy Stats:${NC}        http://localhost:8404/stats"
    echo -e "${GREEN}✓ Panel Admin:${NC}          http://localhost:8082"
    echo -e "${GREEN}✓ Dashboard:${NC}            http://localhost:8001"
    echo -e "${GREEN}✓ WebLogic A Console:${NC}   http://localhost:7001/console"
    echo -e "${GREEN}✓ WebLogic B Console:${NC}   http://localhost:7002/console"
}

# Función para ver logs
show_logs() {
    local service="$1"
    if [ -n "$service" ]; then
        echo -e "${BLUE}=== Logs de $service ===${NC}"
        docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs -f "$service"
    else
        echo -e "${BLUE}=== Logs de Todos los Servicios ===${NC}"
        docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs --tail=50
    fi
}

# Función para ejecutar comando integrado original
run_integrated_original() {
    echo -e "${BLUE}=== Ejecutando Comando Integrado Original ===${NC}"
    echo -e "${YELLOW}Equivalente a: cd $PROJECT_DIR && ./run-integrated-command.sh${NC}"
    echo
    
    # Asegurar que el servicio de gestión esté ejecutándose
    ensure_management_service
    
    # Ejecutar el comando integrado original
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" exec management-service ./run-integrated-command.sh
    
    echo -e "${GREEN}✓ Comando integrado original completado${NC}"
}

# Función para ejecutar versión Docker Compose
run_integrated_docker_compose() {
    echo -e "${BLUE}=== Ejecutando Comando Integrado Docker Compose ===${NC}"
    echo -e "${YELLOW}Versión mejorada con gestión completa de Docker Compose${NC}"
    echo
    
    # Asegurar que el servicio de gestión esté ejecutándose
    ensure_management_service
    
    # Ejecutar la versión Docker Compose
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" exec management-service ./run-integrated-docker-compose.sh
    
    echo -e "${GREEN}✓ Comando integrado Docker Compose completado${NC}"
}

# Función para asegurar que el servicio de gestión esté ejecutándose
ensure_management_service() {
    if ! docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps management-service | grep -q "Up"; then
        echo -e "${YELLOW}Iniciando servicio de gestión...${NC}"
        docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d management-service
        sleep 10
    fi
}

# Función para ejecutar limpieza ligera
cleanup_light() {
    echo -e "${BLUE}=== Ejecutando Limpieza Ligera ===${NC}"
    ensure_management_service
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" exec management-service ./cleanup-environment.sh light
    echo -e "${GREEN}✓ Limpieza ligera completada${NC}"
}

# Función para actualizar IPs
update_ips() {
    echo -e "${BLUE}=== Actualizando IPs de HAProxy ===${NC}"
    ensure_management_service
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" exec management-service ./update-haproxy-ips.sh
    echo -e "${GREEN}✓ IPs actualizadas${NC}"
}

# Función para iniciar dashboard
start_dashboard() {
    echo -e "${BLUE}=== Iniciando Dashboard Integrado ===${NC}"
    ensure_management_service
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" exec management-service ./start-dashboard-with-ip-update.sh
    echo -e "${GREEN}✓ Dashboard iniciado${NC}"
}

# Función para ejecutar comando personalizado
exec_command() {
    shift # Remover 'exec' del array de argumentos
    echo -e "${BLUE}=== Ejecutando Comando: $* ===${NC}"
    ensure_management_service
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" exec management-service "$@"
}

# Función para abrir shell
open_shell() {
    echo -e "${BLUE}=== Abriendo Shell en Contenedor de Gestión ===${NC}"
    ensure_management_service
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" exec management-service /bin/bash
}

# Función para limpiar entorno completo
cleanup_environment() {
    echo -e "${BLUE}=== Limpiando Entorno Completo ===${NC}"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down -v --remove-orphans
    docker system prune -f
    echo -e "${GREEN}✓ Entorno limpiado completamente${NC}"
}

# Función para abrir dashboard
open_dashboard() {
    echo -e "${BLUE}=== Abriendo Dashboard ===${NC}"
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:8001
    elif command -v open &> /dev/null; then
        open http://localhost:8001
    else
        echo -e "${YELLOW}Abrir manualmente: http://localhost:8001${NC}"
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
            run_integrated_original
            ;;
        "run-integrated-dc")
            run_integrated_docker_compose
            ;;
        "cleanup-light")
            cleanup_light
            ;;
        "update-ips")
            update_ips
            ;;
        "start-dashboard")
            start_dashboard
            ;;
        "exec")
            exec_command "$@"
            ;;
        "shell")
            open_shell
            ;;
        "cleanup")
            cleanup_environment
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
