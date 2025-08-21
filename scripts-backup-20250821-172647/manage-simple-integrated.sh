#!/bin/bash

# Script de gestión integrado simplificado que usa el entorno Docker existente
# Reemplaza la necesidad de ejecutar manualmente: cd /path && ./run-integrated-command.sh

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuración
COMPOSE_FILE_MAIN="config/docker-compose.yml"
COMPOSE_FILE_MANAGER="config/docker-compose-simple-integrated.yml"
PROJECT_NAME="weblogic-integrated"

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Gestión Integrada Simplificada - Oracle WebLogic ===${NC}"
    echo
    echo -e "${YELLOW}Uso:${NC} $0 [COMANDO] [OPCIONES]"
    echo
    echo -e "${YELLOW}Comandos disponibles:${NC}"
    echo -e "  ${GREEN}start${NC}           - Iniciar entorno completo (original + gestión)"
    echo -e "  ${GREEN}stop${NC}            - Detener todos los servicios"
    echo -e "  ${GREEN}restart${NC}         - Reiniciar todos los servicios"
    echo -e "  ${GREEN}status${NC}          - Ver estado de todos los servicios"
    echo -e "  ${GREEN}logs${NC}            - Ver logs de servicios"
    echo -e "  ${GREEN}run-integrated${NC}  - Ejecutar comando integrado completo"
    echo -e "  ${GREEN}exec${NC}            - Ejecutar comando personalizado"
    echo -e "  ${GREEN}cleanup${NC}         - Limpiar entorno"
    echo -e "  ${GREEN}dashboard${NC}       - Abrir dashboard en navegador"
    echo -e "  ${GREEN}help${NC}            - Mostrar esta ayuda"
    echo
    echo -e "${BLUE}URLs importantes (ENTORNO ORIGINAL):${NC}"
    echo -e "  HAProxy Frontend:     http://localhost:8080"
    echo -e "  HAProxy Stats:        http://localhost:8404/stats"
    echo -e "  Panel Admin:          http://localhost:8082"
    echo -e "  Dashboard:            http://localhost:8001"
    echo -e "  WebLogic A Console:   http://localhost:7001/console"
    echo -e "  WebLogic B Console:   http://localhost:7002/console"
}

# Función para verificar prerequisitos
check_prerequisites() {
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Error: docker-compose no está instalado${NC}"
        exit 1
    fi
    
    if [ ! -f "$COMPOSE_FILE_MAIN" ]; then
        echo -e "${RED}❌ Error: Archivo $COMPOSE_FILE_MAIN no encontrado${NC}"
        exit 1
    fi
    
    if [ ! -f "$COMPOSE_FILE_MANAGER" ]; then
        echo -e "${RED}❌ Error: Archivo $COMPOSE_FILE_MANAGER no encontrado${NC}"
        exit 1
    fi
}

# Función para iniciar servicios
start_services() {
    echo -e "${BLUE}=== Iniciando Entorno Completo ===${NC}"
    
    # Iniciar servicios principales
    echo -e "${YELLOW}Iniciando servicios principales...${NC}"
    docker-compose -f "$COMPOSE_FILE_MAIN" up -d
    
    # Iniciar gestor integrado
    echo -e "${YELLOW}Iniciando gestor integrado...${NC}"
    docker-compose -f "$COMPOSE_FILE_MANAGER" -p "$PROJECT_NAME" up -d
    
    echo -e "${GREEN}✓ Todos los servicios iniciados${NC}"
    echo -e "${YELLOW}Esperando que los servicios estén listos...${NC}"
    sleep 10
    
    show_status
}

# Función para detener servicios
stop_services() {
    echo -e "${BLUE}=== Deteniendo Todos los Servicios ===${NC}"
    docker-compose -f "$COMPOSE_FILE_MANAGER" -p "$PROJECT_NAME" down
    docker-compose -f "$COMPOSE_FILE_MAIN" down
    echo -e "${GREEN}✓ Todos los servicios detenidos${NC}"
}

# Función para reiniciar servicios
restart_services() {
    echo -e "${BLUE}=== Reiniciando Servicios ===${NC}"
    stop_services
    sleep 5
    start_services
}

# Función para mostrar estado
show_status() {
    echo -e "${BLUE}=== Estado de Servicios Principales ===${NC}"
    docker-compose -f "$COMPOSE_FILE_MAIN" ps
    echo
    echo -e "${BLUE}=== Estado del Gestor Integrado ===${NC}"
    docker-compose -f "$COMPOSE_FILE_MANAGER" -p "$PROJECT_NAME" ps
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
        if docker-compose -f "$COMPOSE_FILE_MAIN" ps | grep -q "$service"; then
            docker-compose -f "$COMPOSE_FILE_MAIN" logs -f "$service"
        else
            docker-compose -f "$COMPOSE_FILE_MANAGER" -p "$PROJECT_NAME" logs -f "$service"
        fi
    else
        echo -e "${BLUE}=== Logs de Servicios Principales ===${NC}"
        docker-compose -f "$COMPOSE_FILE_MAIN" logs --tail=50
        echo -e "${BLUE}=== Logs del Gestor Integrado ===${NC}"
        docker-compose -f "$COMPOSE_FILE_MANAGER" -p "$PROJECT_NAME" logs --tail=50
    fi
}

# Función para ejecutar comando integrado
run_integrated_command() {
    echo -e "${BLUE}=== Ejecutando Comando Integrado ===${NC}"
    echo -e "${YELLOW}Equivalente a: cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./run-integrated-command.sh${NC}"
    echo
    
    # Verificar que el gestor integrado esté ejecutándose
    if ! docker-compose -f "$COMPOSE_FILE_MANAGER" -p "$PROJECT_NAME" ps | grep -q "integrated-manager"; then
        echo -e "${YELLOW}Iniciando gestor integrado...${NC}"
        docker-compose -f "$COMPOSE_FILE_MANAGER" -p "$PROJECT_NAME" up -d
        sleep 10
    fi
    
    # Ejecutar el comando integrado
    echo -e "${YELLOW}Ejecutando comando integrado...${NC}"
    docker-compose -f "$COMPOSE_FILE_MANAGER" -p "$PROJECT_NAME" exec integrated-manager ./run-integrated-command.sh
    
    echo -e "${GREEN}✓ Comando integrado completado${NC}"
}

# Función para ejecutar comando personalizado
exec_command() {
    shift # Remover 'exec' del array de argumentos
    echo -e "${BLUE}=== Ejecutando Comando: $* ===${NC}"
    
    # Verificar que el gestor integrado esté ejecutándose
    if ! docker-compose -f "$COMPOSE_FILE_MANAGER" -p "$PROJECT_NAME" ps | grep -q "integrated-manager"; then
        echo -e "${YELLOW}Iniciando gestor integrado...${NC}"
        docker-compose -f "$COMPOSE_FILE_MANAGER" -p "$PROJECT_NAME" up -d
        sleep 10
    fi
    
    docker-compose -f "$COMPOSE_FILE_MANAGER" -p "$PROJECT_NAME" exec integrated-manager "$@"
}

# Función para limpiar entorno
cleanup_environment() {
    echo -e "${BLUE}=== Limpiando Entorno ===${NC}"
    docker-compose -f "$COMPOSE_FILE_MANAGER" -p "$PROJECT_NAME" down -v --remove-orphans
    docker-compose -f "$COMPOSE_FILE_MAIN" down -v --remove-orphans
    docker system prune -f
    echo -e "${GREEN}✓ Entorno limpiado${NC}"
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
            run_integrated_command
            ;;
        "exec")
            exec_command "$@"
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
