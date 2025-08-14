#!/bin/bash

# Script de gestión integrado mejorado - Evita reinicios innecesarios
# Versión optimizada que verifica el estado antes de actuar

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuración
COMPOSE_FILE="config/docker-compose-integrated.yml"
PROJECT_NAME="weblogic-integrated"

# Servicios esperados
EXPECTED_SERVICES=("orcldb-integrated" "weblogic-a-integrated" "weblogic-b-integrated" "dashboard-integrated" "integrated-manager")

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Gestión Integrada Docker para Oracle WebLogic (MEJORADO) ===${NC}"
    echo
    echo -e "${YELLOW}Uso:${NC} $0 [COMANDO] [OPCIONES]"
    echo
    echo -e "${YELLOW}Comandos disponibles:${NC}"
    echo -e "  ${GREEN}start${NC}           - Iniciar servicios (solo los que no están ejecutándose)"
    echo -e "  ${GREEN}stop${NC}            - Detener todos los servicios"
    echo -e "  ${GREEN}restart${NC}         - Reiniciar servicios específicos o todos"
    echo -e "  ${GREEN}force-restart${NC}   - Forzar reinicio completo de todos los servicios"
    echo -e "  ${GREEN}status${NC}          - Ver estado detallado de todos los servicios"
    echo -e "  ${GREEN}health${NC}          - Verificar salud de servicios críticos"
    echo -e "  ${GREEN}logs${NC}            - Ver logs de servicios específicos"
    echo -e "  ${GREEN}run-integrated${NC}  - Ejecutar comando integrado (inteligente)"
    echo -e "  ${GREEN}exec${NC}            - Ejecutar comando en el contenedor de gestión"
    echo -e "  ${GREEN}cleanup${NC}         - Limpiar entorno y volúmenes"
    echo -e "  ${GREEN}update-ips${NC}      - Actualizar IPs de HAProxy"
    echo -e "  ${GREEN}dashboard${NC}       - Abrir dashboard en navegador"
    echo -e "  ${GREEN}fix-haproxy${NC}     - Reparar HAProxy si no está funcionando"
    echo -e "  ${GREEN}help${NC}            - Mostrar esta ayuda"
    echo
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo -e "  $0 start                    # Iniciar solo servicios parados"
    echo -e "  $0 restart haproxy          # Reiniciar solo HAProxy"
    echo -e "  $0 force-restart            # Forzar reinicio completo"
    echo -e "  $0 health                   # Verificar salud del sistema"
    echo -e "  $0 logs haproxy             # Ver logs de HAProxy"
    echo -e "  $0 fix-haproxy              # Reparar HAProxy"
    echo
    echo -e "${BLUE}URLs importantes (ENTORNO INTEGRADO):${NC}"
    echo -e "  HAProxy Frontend:     http://localhost:8090"
    echo -e "  HAProxy Stats:        http://localhost:8414/stats"
    echo -e "  Panel Admin:          http://localhost:8092"
    echo -e "  Dashboard:            http://localhost:8011"
    echo -e "  WebLogic A Console:   http://localhost:7003/console"
    echo -e "  WebLogic B Console:   http://localhost:7004/console"
    echo
    echo -e "${YELLOW}NOTA: Este script evita reinicios innecesarios para mejor rendimiento${NC}"
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

# Función para verificar si un contenedor está ejecutándose
is_container_running() {
    local container_name="$1"
    docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"
}

# Función para verificar si un contenedor existe (pero puede estar parado)
container_exists() {
    local container_name="$1"
    docker ps -a --format "table {{.Names}}" | grep -q "^${container_name}$"
}

# Función para obtener el estado de un contenedor
get_container_status() {
    local container_name="$1"
    if is_container_running "$container_name"; then
        echo "running"
    elif container_exists "$container_name"; then
        echo "stopped"
    else
        echo "missing"
    fi
}

# Función para verificar salud de servicios
check_service_health() {
    echo -e "${BLUE}=== Verificación de Salud de Servicios ===${NC}"
    
    local all_healthy=true
    
    # Verificar cada servicio
    for service in "${EXPECTED_SERVICES[@]}"; do
        local status=$(get_container_status "$service")
        case $status in
            "running")
                echo -e "${GREEN}✓ $service${NC} - Ejecutándose"
                ;;
            "stopped")
                echo -e "${YELLOW}⚠ $service${NC} - Detenido"
                all_healthy=false
                ;;
            "missing")
                echo -e "${RED}❌ $service${NC} - No existe"
                all_healthy=false
                ;;
        esac
    done
    
    # Verificar HAProxy específicamente
    if is_container_running "haproxy-integrated"; then
        echo -e "${GREEN}✓ haproxy-integrated${NC} - Ejecutándose"
        
        # Verificar que HAProxy responda
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8090 | grep -q "503\|200"; then
            echo -e "${GREEN}  └─ HAProxy Frontend respondiendo${NC}"
        else
            echo -e "${YELLOW}  └─ HAProxy Frontend no responde${NC}"
            all_healthy=false
        fi
    else
        echo -e "${RED}❌ haproxy-integrated${NC} - No ejecutándose"
        all_healthy=false
    fi
    
    if $all_healthy; then
        echo -e "${GREEN}🎉 Todos los servicios están saludables${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Algunos servicios necesitan atención${NC}"
        return 1
    fi
}

# Función para iniciar servicios inteligentemente
smart_start_services() {
    echo -e "${BLUE}=== Inicio Inteligente de Servicios ===${NC}"
    
    local services_to_start=()
    local services_running=()
    
    # Verificar qué servicios necesitan iniciarse
    for service in "${EXPECTED_SERVICES[@]}"; do
        local status=$(get_container_status "$service")
        if [ "$status" != "running" ]; then
            services_to_start+=("$service")
            echo -e "${YELLOW}📋 $service necesita iniciarse (estado: $status)${NC}"
        else
            services_running+=("$service")
            echo -e "${GREEN}✓ $service ya está ejecutándose${NC}"
        fi
    done
    
    # Verificar HAProxy por separado
    if ! is_container_running "haproxy-integrated"; then
        echo -e "${YELLOW}📋 haproxy-integrated necesita iniciarse${NC}"
        services_to_start+=("haproxy")
    else
        echo -e "${GREEN}✓ haproxy-integrated ya está ejecutándose${NC}"
        services_running+=("haproxy")
    fi
    
    if [ ${#services_to_start[@]} -eq 0 ]; then
        echo -e "${GREEN}🎉 Todos los servicios ya están ejecutándose${NC}"
        show_status
        return 0
    fi
    
    echo -e "${CYAN}🚀 Iniciando ${#services_to_start[@]} servicios...${NC}"
    
    # Iniciar servicios usando docker-compose
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d
    
    echo -e "${GREEN}✓ Servicios iniciados${NC}"
    echo -e "${YELLOW}Esperando que los servicios estén listos...${NC}"
    sleep 10
    
    # Verificar que se iniciaron correctamente
    check_service_health
}

# Función para detener servicios
stop_services() {
    echo -e "${BLUE}=== Deteniendo Servicios ===${NC}"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down
    echo -e "${GREEN}✓ Servicios detenidos${NC}"
}

# Función para reiniciar servicios específicos
restart_services() {
    local service="$1"
    
    if [ -n "$service" ]; then
        echo -e "${BLUE}=== Reiniciando Servicio: $service ===${NC}"
        
        if [ "$service" = "haproxy" ]; then
            # Reiniciar HAProxy específicamente
            if is_container_running "haproxy-integrated"; then
                docker restart haproxy-integrated
                echo -e "${GREEN}✓ HAProxy reiniciado${NC}"
            else
                echo -e "${YELLOW}HAProxy no está ejecutándose, iniciándolo...${NC}"
                fix_haproxy
            fi
        else
            docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" restart "$service"
            echo -e "${GREEN}✓ $service reiniciado${NC}"
        fi
    else
        echo -e "${BLUE}=== Reiniciando Todos los Servicios ===${NC}"
        docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" restart
        
        # Reiniciar HAProxy por separado si existe
        if container_exists "haproxy-integrated"; then
            docker restart haproxy-integrated
        fi
        
        echo -e "${GREEN}✓ Todos los servicios reiniciados${NC}"
    fi
    
    sleep 5
    check_service_health
}

# Función para forzar reinicio completo
force_restart_services() {
    echo -e "${BLUE}=== Forzando Reinicio Completo ===${NC}"
    echo -e "${YELLOW}⚠ Esto detendrá y reiniciará todos los servicios${NC}"
    
    # Detener todo
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down
    
    # Detener HAProxy si existe
    if container_exists "haproxy-integrated"; then
        docker stop haproxy-integrated 2>/dev/null || true
    fi
    
    sleep 3
    
    # Iniciar todo de nuevo
    smart_start_services
    
    # Asegurar que HAProxy esté funcionando
    fix_haproxy
    
    echo -e "${GREEN}✓ Reinicio completo completado${NC}"
}

# Función para mostrar estado detallado
show_status() {
    echo -e "${BLUE}=== Estado Detallado de Servicios ===${NC}"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps
    
    # Mostrar HAProxy por separado
    if is_container_running "haproxy-integrated"; then
        echo -e "${GREEN}HAProxy Integrado:${NC}"
        docker ps | grep haproxy-integrated
    fi
    
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
        if [ "$service" = "haproxy" ]; then
            echo -e "${BLUE}=== Logs de HAProxy ===${NC}"
            docker logs haproxy-integrated -f
        else
            echo -e "${BLUE}=== Logs de $service ===${NC}"
            docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs -f "$service"
        fi
    else
        echo -e "${BLUE}=== Logs de Todos los Servicios ===${NC}"
        docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs -f
    fi
}

# Función para reparar HAProxy
fix_haproxy() {
    echo -e "${BLUE}=== Reparando HAProxy ===${NC}"
    
    # Detener HAProxy si está ejecutándose
    if is_container_running "haproxy-integrated"; then
        echo -e "${YELLOW}Deteniendo HAProxy actual...${NC}"
        docker stop haproxy-integrated
    fi
    
    # Remover contenedor si existe
    if container_exists "haproxy-integrated"; then
        echo -e "${YELLOW}Removiendo contenedor HAProxy...${NC}"
        docker rm haproxy-integrated
    fi
    
    # Recrear HAProxy con configuración optimizada
    echo -e "${YELLOW}Recreando HAProxy con configuración optimizada...${NC}"
    docker run -d --name haproxy-integrated \
        --network weblogic-integrated_weblogic-network \
        --ip 172.24.0.5 \
        -p 8090:80 \
        -p 8091:8081 \
        -p 8092:8082 \
        -p 8414:8404 \
        haproxy-advanced-integrated:latest
    
    echo -e "${GREEN}✓ HAProxy reparado${NC}"
    
    # Verificar que funcione
    sleep 10
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8090 | grep -q "503\|200"; then
        echo -e "${GREEN}✓ HAProxy respondiendo correctamente${NC}"
    else
        echo -e "${RED}❌ HAProxy aún no responde${NC}"
    fi
}

# Función para ejecutar comando integrado inteligente
run_integrated_command() {
    echo -e "${BLUE}=== Ejecutando Comando Integrado Inteligente ===${NC}"
    
    # Verificar salud primero
    if check_service_health; then
        echo -e "${GREEN}✓ Sistema saludable, ejecutando comando...${NC}"
    else
        echo -e "${YELLOW}⚠ Sistema necesita reparación, iniciando servicios...${NC}"
        smart_start_services
    fi
    
    # Asegurar que el integrated-manager esté listo
    if ! is_container_running "integrated-manager"; then
        echo -e "${YELLOW}Iniciando integrated-manager...${NC}"
        docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d integrated-manager
        sleep 15
    fi
    
    # Ejecutar el comando integrado
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" exec integrated-manager ./run-integrated-command.sh
    
    echo -e "${GREEN}✓ Comando integrado completado${NC}"
}

# Función para ejecutar comando personalizado
exec_command() {
    shift # Remover 'exec' del array de argumentos
    echo -e "${BLUE}=== Ejecutando Comando: $* ===${NC}"
    
    # Asegurar que integrated-manager esté ejecutándose
    if ! is_container_running "integrated-manager"; then
        echo -e "${YELLOW}Iniciando integrated-manager...${NC}"
        docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d integrated-manager
        sleep 10
    fi
    
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" exec integrated-manager "$@"
}

# Función para limpiar entorno
cleanup_environment() {
    echo -e "${BLUE}=== Limpiando Entorno ===${NC}"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down -v --remove-orphans
    
    # Limpiar HAProxy por separado
    if container_exists "haproxy-integrated"; then
        docker stop haproxy-integrated 2>/dev/null || true
        docker rm haproxy-integrated 2>/dev/null || true
    fi
    
    docker system prune -f
    echo -e "${GREEN}✓ Entorno limpiado${NC}"
}

# Función para actualizar IPs
update_ips() {
    echo -e "${BLUE}=== Actualizando IPs de HAProxy ===${NC}"
    
    if ! is_container_running "integrated-manager"; then
        echo -e "${YELLOW}Iniciando integrated-manager...${NC}"
        docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d integrated-manager
        sleep 10
    fi
    
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
            smart_start_services
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            restart_services "$2"
            ;;
        "force-restart")
            force_restart_services
            ;;
        "status")
            show_status
            ;;
        "health")
            check_service_health
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
        "fix-haproxy")
            fix_haproxy
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Ejecutar función principal con todos los argumentos
main "$@"
