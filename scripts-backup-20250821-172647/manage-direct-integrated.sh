#!/bin/bash

# Script de gestión integrado directo - NO requiere contenedores adicionales
# Reemplaza la necesidad de ejecutar manualmente: cd /path && ./run-integrated-command.sh

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuración
COMPOSE_FILE="config/docker-compose.yml"
PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Gestión Integrada Directa - Oracle WebLogic ===${NC}"
    echo
    echo -e "${YELLOW}Uso:${NC} $0 [COMANDO] [OPCIONES]"
    echo
    echo -e "${YELLOW}Comandos disponibles:${NC}"
    echo -e "  ${GREEN}start${NC}           - Iniciar todos los servicios"
    echo -e "  ${GREEN}stop${NC}            - Detener todos los servicios"
    echo -e "  ${GREEN}restart${NC}         - Reiniciar todos los servicios"
    echo -e "  ${GREEN}status${NC}          - Ver estado de todos los servicios"
    echo -e "  ${GREEN}logs${NC}            - Ver logs de servicios"
    echo -e "  ${GREEN}run-integrated${NC}  - Ejecutar comando integrado completo"
    echo -e "  ${GREEN}cleanup-light${NC}   - Ejecutar limpieza ligera"
    echo -e "  ${GREEN}start-dashboard${NC} - Iniciar dashboard integrado"
    echo -e "  ${GREEN}update-ips${NC}      - Actualizar IPs de HAProxy"
    echo -e "  ${GREEN}full-cycle${NC}      - Ciclo completo (limpieza + inicio + dashboard)"
    echo -e "  ${GREEN}dashboard${NC}       - Abrir dashboard en navegador"
    echo -e "  ${GREEN}help${NC}            - Mostrar esta ayuda"
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
    echo -e "  ${BLUE}$0 run-integrated${NC}  ≡  ${YELLOW}cd $PROJECT_DIR && ./run-integrated-command.sh${NC}"
    echo -e "  ${BLUE}$0 full-cycle${NC}      ≡  ${YELLOW}Limpieza + Inicio + Dashboard completo${NC}"
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
    
    # Verificar que estamos en el directorio correcto
    if [ "$(pwd)" != "$PROJECT_DIR" ]; then
        echo -e "${YELLOW}⚠️  Cambiando al directorio del proyecto: $PROJECT_DIR${NC}"
        cd "$PROJECT_DIR"
    fi
}

# Función para iniciar servicios
start_services() {
    echo -e "${BLUE}=== Iniciando Servicios ===${NC}"
    docker-compose -f "$COMPOSE_FILE" up -d
    
    echo -e "${GREEN}✓ Servicios iniciados${NC}"
    echo -e "${YELLOW}Esperando que los servicios estén listos...${NC}"
    sleep 10
    
    show_status
}

# Función para detener servicios
stop_services() {
    echo -e "${BLUE}=== Deteniendo Servicios ===${NC}"
    docker-compose -f "$COMPOSE_FILE" down
    echo -e "${GREEN}✓ Servicios detenidos${NC}"
}

# Función para reiniciar servicios
restart_services() {
    echo -e "${BLUE}=== Reiniciando Servicios ===${NC}"
    docker-compose -f "$COMPOSE_FILE" restart
    echo -e "${GREEN}✓ Servicios reiniciados${NC}"
}

# Función para mostrar estado
show_status() {
    echo -e "${BLUE}=== Estado de Servicios ===${NC}"
    docker-compose -f "$COMPOSE_FILE" ps
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
        docker-compose -f "$COMPOSE_FILE" logs -f "$service"
    else
        echo -e "${BLUE}=== Logs de Todos los Servicios ===${NC}"
        docker-compose -f "$COMPOSE_FILE" logs --tail=50
    fi
}

# Función para ejecutar comando integrado
run_integrated_command() {
    echo -e "${BLUE}=== Ejecutando Comando Integrado ===${NC}"
    echo -e "${YELLOW}Equivalente a: cd $PROJECT_DIR && ./run-integrated-command.sh${NC}"
    echo
    
    # Verificar que el script existe
    if [ ! -f "./run-integrated-command.sh" ]; then
        echo -e "${RED}❌ Error: Script ./run-integrated-command.sh no encontrado${NC}"
        exit 1
    fi
    
    # Ejecutar el comando integrado directamente
    ./run-integrated-command.sh
    
    echo -e "${GREEN}✓ Comando integrado completado${NC}"
}

# Función para limpieza ligera
cleanup_light() {
    echo -e "${BLUE}=== Ejecutando Limpieza Ligera ===${NC}"
    
    if [ -f "./cleanup-environment.sh" ]; then
        ./cleanup-environment.sh light
    else
        echo -e "${YELLOW}⚠️  Script cleanup-environment.sh no encontrado, ejecutando limpieza básica${NC}"
        docker-compose -f "$COMPOSE_FILE" down
        docker system prune -f
    fi
    
    echo -e "${GREEN}✓ Limpieza ligera completada${NC}"
}

# Función para iniciar dashboard
start_dashboard() {
    echo -e "${BLUE}=== Iniciando Dashboard Integrado ===${NC}"
    
    if [ -f "./start-dashboard-integrated.sh" ]; then
        ./start-dashboard-integrated.sh
    elif [ -f "./start-dashboard-with-ip-update.sh" ]; then
        ./start-dashboard-with-ip-update.sh
    else
        echo -e "${YELLOW}⚠️  Script de dashboard no encontrado, iniciando servicios básicos${NC}"
        start_services
    fi
    
    echo -e "${GREEN}✓ Dashboard iniciado${NC}"
}

# Función para actualizar IPs
update_ips() {
    echo -e "${BLUE}=== Actualizando IPs de HAProxy ===${NC}"
    
    if [ -f "./update-haproxy-ips.sh" ]; then
        ./update-haproxy-ips.sh
    else
        echo -e "${YELLOW}⚠️  Script update-haproxy-ips.sh no encontrado${NC}"
    fi
    
    echo -e "${GREEN}✓ IPs actualizadas${NC}"
}

# Función para ciclo completo
full_cycle() {
    echo -e "${BLUE}=== Ejecutando Ciclo Completo ===${NC}"
    echo -e "${YELLOW}Esto ejecutará: limpieza + inicio + dashboard + actualización de IPs${NC}"
    echo
    
    cleanup_light
    echo
    start_services
    echo
    update_ips
    echo
    start_dashboard
    
    echo
    echo -e "${GREEN}✅ Ciclo completo terminado exitosamente${NC}"
    show_status
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
        "cleanup-light")
            cleanup_light
            ;;
        "start-dashboard")
            start_dashboard
            ;;
        "update-ips")
            update_ips
            ;;
        "full-cycle")
            full_cycle
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
