#!/bin/bash
# Script de gestión completa para los servicios Docker con configuración centralizada

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)"

# Función para cargar variables de entorno
load_environment() {
    # Usar el script mejorado de carga de variables
    if [ -f "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" ]; then
        source "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" "${ENVIRONMENT:-development}" 2>/dev/null
    else
        # Fallback al script original
        source "$PROJECT_ROOT/scripts/core/load-env.sh"
        load_env > /dev/null 2>&1
    fi
}

# Función para mostrar el banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Gestor de Servicios WebLogic + HAProxy         ║"
    echo "║                    Configuración Centralizada               ║"
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
    echo "  deep-clean      Limpieza profunda del sistema Docker"
    echo "  port-forward    Gestionar port-forwards de Minikube"
    echo "  config          Mostrar configuración actual"
    echo "  validate        Validar configuración"
    echo ""
    echo -e "${BLUE}Opciones para stop:${NC}"
    echo "  --force, -f     Forzar detención"
    echo ""
    echo -e "${BLUE}Opciones para logs:${NC}"
    echo "  --follow, -f    Seguir logs en tiempo real"
    echo "  [servicio]      Ver logs de un servicio específico (weblogic-a, weblogic-b, haproxy, orcldb)"
    echo ""
    echo -e "${BLUE}Opciones para port-forward:${NC}"
    echo "  start           Iniciar port-forwards de Minikube"
    echo "  stop            Detener port-forwards de Minikube"
    echo "  status          Estado de port-forwards"
    echo "  list            Listar servicios de Minikube"
    echo ""
    echo -e "${BLUE}Ejemplos:${NC}"
    echo "  $0 start                    # Iniciar servicios"
    echo "  $0 stop                     # Detener servicios"
    echo "  $0 stop --force             # Detener con fuerza"
    echo "  $0 logs --follow            # Ver todos los logs en tiempo real"
    echo "  $0 logs haproxy             # Ver logs solo de HAProxy"
    echo "  $0 status                   # Ver estado actual"
    echo "  $0 config                   # Ver configuración actual"
    echo "  $0 validate                 # Validar configuración"
    echo "  $0 port-forward start       # Iniciar port-forwards"
    echo "  $0 port-forward status      # Ver estado de port-forwards"
    echo "  $0 deep-clean --dry-run     # Ver qué se limpiaría"
    echo "  $0 deep-clean --force       # Limpieza profunda sin confirmación"
}

# Función para mostrar configuración actual
show_config() {
    show_banner
    echo -e "${BLUE}=== Configuración Actual ===${NC}"
    
    load_environment
    
    echo ""
    echo -e "${YELLOW}WebLogic Servers:${NC}"
    echo -e "  WebLogic A Port:     ${WEBLOGIC_A_EXTERNAL_PORT:-7001}"
    echo -e "  WebLogic B Port:     ${WEBLOGIC_B_EXTERNAL_PORT:-7002}"
    echo -e "  Admin Password:      ${WEBLOGIC_ADMIN_PASSWORD:-[default]}"
    
    echo ""
    echo -e "${YELLOW}HAProxy Configuration:${NC}"
    echo -e "  HTTP Port:           ${HAPROXY_HTTP_EXTERNAL_PORT:-8083}"
    echo -e "  HTTPS Port:          ${HAPROXY_HTTPS_EXTERNAL_PORT:-8444}"
    echo -e "  Stats Port:          ${HAPROXY_STATS_EXTERNAL_PORT:-8404}"
    echo -e "  API Port:            ${HAPROXY_API_EXTERNAL_PORT:-8081}"
    echo -e "  Admin UI Port:       ${HAPROXY_UI_EXTERNAL_PORT:-8082}"
    echo -e "  Stats User:          ${HAPROXY_STATS_USER:-admin}"
    echo -e "  Stats Password:      ${HAPROXY_STATS_PASSWORD:-[default]}"
    
    echo ""
    echo -e "${YELLOW}Oracle Database:${NC}"
    echo -e "  Database Port:       ${ORACLE_EXTERNAL_PORT:-1521}"
    echo -e "  EM Express Port:     ${ORACLE_EM_EXTERNAL_PORT:-5500}"
    echo -e "  Admin Password:      ${ORACLE_ADMIN_PASSWORD:-[default]}"
    
    echo ""
    echo -e "${YELLOW}Documentation:${NC}"
    echo -e "  Main Docs Port:      ${MKDOCS_EXTERNAL_PORT:-8000}"
    echo -e "  Dev Docs Port:       ${MKDOCS_DEV_EXTERNAL_PORT:-8001}"
    echo -e "  V1 Docs Port:        ${MKDOCS_V1_EXTERNAL_PORT:-8002}"
    
    echo ""
    echo -e "${YELLOW}URLs de Acceso:${NC}"
    echo -e "  Load Balancer:       http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    echo -e "  HAProxy Stats:       http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
    echo -e "  HAProxy Admin UI:    http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}/"
    echo -e "  WebLogic A Console:  http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/console"
    echo -e "  WebLogic B Console:  http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/console"
    echo -e "  Oracle EM Express:   https://localhost:${ORACLE_EM_EXTERNAL_PORT:-5500}/em"
    echo -e "  Documentation:       http://localhost:${MKDOCS_EXTERNAL_PORT:-8000}/"
}

# Función para mostrar el estado de los servicios
show_status() {
    show_banner
    echo -e "${BLUE}=== Estado de los Servicios Docker ===${NC}"
    
    load_environment
    
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
        echo -e "  ${GREEN}✓${NC} Load Balancer:     http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}"
        echo -e "  ${GREEN}✓${NC} HAProxy Stats:     http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
        echo -e "  ${GREEN}✓${NC} HAProxy Admin:     http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}"
        echo -e "  ${GREEN}✓${NC} HAProxy HTTPS:     https://localhost:${HAPROXY_HTTPS_EXTERNAL_PORT:-8444}"
    else
        echo -e "  ${RED}✗${NC} HAProxy no está ejecutándose"
    fi
    
    if docker ps | grep -q weblogic-a; then
        echo -e "  ${GREEN}✓${NC} WebLogic A:        http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/console"
    else
        echo -e "  ${RED}✗${NC} WebLogic A no está ejecutándose"
    fi
    
    if docker ps | grep -q weblogic-b; then
        echo -e "  ${GREEN}✓${NC} WebLogic B:        http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/console"
    else
        echo -e "  ${RED}✗${NC} WebLogic B no está ejecutándose"
    fi
    
    if docker ps | grep -q orcldb; then
        echo -e "  ${GREEN}✓${NC} Oracle DB:         localhost:${ORACLE_EXTERNAL_PORT:-1521} (XE)"
        echo -e "  ${GREEN}✓${NC} Oracle EM Express: https://localhost:${ORACLE_EM_EXTERNAL_PORT:-5500}/em"
    else
        echo -e "  ${RED}✗${NC} Oracle DB no está ejecutándose"
    fi
    
    if docker ps | grep -q mkdocs; then
        echo -e "  ${GREEN}✓${NC} Documentación:     http://localhost:${MKDOCS_EXTERNAL_PORT:-8000}/"
    else
        echo -e "  ${RED}✗${NC} Documentación no está ejecutándose"
    fi
    
    # Mostrar estado de Minikube port-forwards
    echo ""
    echo -e "${BLUE}=== Estado de Minikube Port-Forwards ===${NC}"
    if [ -f "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" ]; then
        "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" status
    else
        echo -e "${YELLOW}Script de port-forwards no encontrado${NC}"
    fi
}

# Función para validar configuración
validate_config() {
    show_banner
    echo -e "${BLUE}=== Validando Configuración ===${NC}"
    
    # Ejecutar validaciones disponibles
    validation_scripts=(
        "scripts/validate-admin-ui-update.sh"
        "scripts/validate-admin-api-update.sh"
        "scripts/validate-docker-compose-update.sh"
    )
    
    for script in "${validation_scripts[@]}"; do
        if [ -f "$PROJECT_ROOT/$script" ]; then
            echo -e "${YELLOW}Ejecutando: $script${NC}"
            "$PROJECT_ROOT/$script"
            echo ""
        fi
    done
    
    echo -e "${GREEN}Validación completada${NC}"
}

# Función para iniciar servicios
start_services() {
    show_banner
    echo -e "${BLUE}=== Iniciando Servicios ===${NC}"
    
    # Iniciar servicios Docker
    if [ -f "$PROJECT_ROOT/scripts/services/start-with-auto-update.sh" ]; then
        "$PROJECT_ROOT/scripts/services/start-with-auto-update.sh"
    else
        echo -e "${RED}Error: Script de inicio no encontrado${NC}"
        exit 1
    fi
    
    # Iniciar port-forwards de Minikube si está disponible
    echo ""
    echo -e "${BLUE}=== Verificando Minikube ===${NC}"
    if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
        echo -e "${YELLOW}Minikube detectado, iniciando port-forwards...${NC}"
        if [ -f "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" ]; then
            "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" start
        else
            echo -e "${YELLOW}Script de port-forwards no encontrado${NC}"
        fi
    else
        echo -e "${YELLOW}Minikube no está corriendo o no está instalado${NC}"
        echo -e "${YELLOW}Solo se iniciaron los servicios Docker${NC}"
    fi
}

# Función para detener servicios
stop_services() {
    show_banner
    echo -e "${BLUE}=== Deteniendo Servicios ===${NC}"
    
    # Detener port-forwards de Minikube primero
    echo -e "${YELLOW}Deteniendo port-forwards de Minikube...${NC}"
    if [ -f "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" ]; then
        "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" stop
    fi
    
    # Detener servicios Docker
    echo ""
    if [ -f "$PROJECT_ROOT/stop-all-services.sh" ]; then
        if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
            "$PROJECT_ROOT/stop-all-services.sh" --force
        else
            "$PROJECT_ROOT/stop-all-services.sh"
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
    
    load_environment
    
    if [ "$follow" = "--follow" ] || [ "$follow" = "-f" ]; then
        if [ -n "$service" ] && [ "$service" != "--follow" ] && [ "$service" != "-f" ]; then
            echo -e "${YELLOW}Siguiendo logs de $service (Ctrl+C para salir)...${NC}"
            "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" logs -f "$service"
        else
            echo -e "${YELLOW}Siguiendo logs de todos los servicios (Ctrl+C para salir)...${NC}"
            "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" logs -f
        fi
    else
        if [ -n "$service" ]; then
            echo -e "${YELLOW}Logs de $service:${NC}"
            "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" logs "$service"
        else
            echo -e "${YELLOW}Logs de todos los servicios:${NC}"
            "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" logs
        fi
    fi
}

# Función para actualizar HAProxy
update_haproxy() {
    show_banner
    echo -e "${BLUE}=== Actualizando HAProxy ===${NC}"
    
    if [ -f "$PROJECT_ROOT/scripts/maintenance/auto-update-haproxy.sh" ]; then
        "$PROJECT_ROOT/scripts/maintenance/auto-update-haproxy.sh"
    else
        echo -e "${RED}Error: Script de actualización de HAProxy no encontrado${NC}"
        exit 1
    fi
}

# Función para manejar port-forwards
manage_port_forwards() {
    local action="$1"
    
    if [ -f "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" ]; then
        "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" "$action"
    else
        echo -e "${RED}Error: Script de port-forwards no encontrado${NC}"
        exit 1
    fi
}

# Función para limpiar completamente
clean_all() {
    show_banner
    echo -e "${BLUE}=== Limpieza Completa ===${NC}"
    
    if [ -f "$PROJECT_ROOT/stop-all-services.sh" ]; then
        "$PROJECT_ROOT/stop-all-services.sh" --clean
    else
        echo -e "${RED}Error: Script de limpieza no encontrado${NC}"
        exit 1
    fi
}

# Función para limpieza profunda
deep_clean() {
    local option="$1"
    show_banner
    echo -e "${BLUE}=== Limpieza Profunda del Sistema ===${NC}"
    
    if [ -f "$PROJECT_ROOT/scripts/cleanup-all.sh" ]; then
        if [ -n "$option" ]; then
            "$PROJECT_ROOT/scripts/cleanup-all.sh" "$option"
        else
            "$PROJECT_ROOT/scripts/cleanup-all.sh"
        fi
    else
        echo -e "${RED}Error: Script de limpieza profunda no encontrado${NC}"
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
        config)
            show_config
            ;;
        validate)
            validate_config
            ;;
        logs)
            show_logs "$2" "$3"
            ;;
        update-haproxy)
            update_haproxy
            ;;
        port-forward)
            manage_port_forwards "$2"
            ;;
        clean)
            clean_all
            ;;
        deep-clean)
            deep_clean "$2"
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
