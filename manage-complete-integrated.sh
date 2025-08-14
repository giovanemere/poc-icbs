#!/bin/bash

# =============================================================================
# Gestor Completo de Servicios Integrado con Actualización Automática de IPs
# Proyecto: Docker Oracle WebLogic con Testing A/B, Canary Deployment y Feature Flags
# =============================================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${PROJECT_DIR}/.env"
DOCKER_COMPOSE_FILE="${PROJECT_DIR}/config/docker-compose-complete-integrated-fixed.yml"
HAPROXY_CONFIG_DIR="${PROJECT_DIR}/haproxy/config"

# Variables de configuración
NETWORK_NAME="weblogic-integrated_weblogic-network"
SUBNET_BASE="172.25.0"
GATEWAY="${SUBNET_BASE}.1"

# Función para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ✗${NC} $1"
}

log_header() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║          Gestor Completo de Servicios WebLogic + HAProxy            ║"
    echo "║         con Actualización Automática de IPs y Redes Dinámicas       ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para verificar dependencias
check_dependencies() {
    log "🔍 Verificando dependencias..."
    
    local missing_deps=()
    
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        missing_deps+=("docker-compose")
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq no está instalado, instalando..."
        sudo apt-get update && sudo apt-get install -y jq
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Dependencias faltantes: ${missing_deps[*]}"
        exit 1
    fi
    
    log_success "Todas las dependencias están disponibles"
}

# Función para limpiar redes conflictivas
cleanup_networks() {
    log "🧹 Limpiando redes conflictivas..."
    
    # Obtener redes que puedan causar conflicto
    local conflicting_networks=$(docker network ls --format "{{.Name}}" | grep -E "(weblogic|oracle)" || true)
    
    if [[ -n "$conflicting_networks" ]]; then
        log "Redes encontradas que pueden causar conflicto:"
        echo "$conflicting_networks"
        
        # Detener contenedores que usen estas redes
        for network in $conflicting_networks; do
            local containers=$(docker network inspect "$network" --format "{{range .Containers}}{{.Name}} {{end}}" 2>/dev/null || true)
            if [[ -n "$containers" ]]; then
                log "Deteniendo contenedores en red $network: $containers"
                docker stop $containers 2>/dev/null || true
            fi
        done
        
        # Remover redes no utilizadas
        docker network prune -f
        log_success "Redes limpiadas"
    else
        log_success "No hay redes conflictivas"
    fi
}

# Función para crear directorios necesarios
create_directories() {
    log "📁 Creando directorios necesarios..."
    
    local directories=(
        "data/oracle"
        "logs/oracle"
        "logs/weblogic-a"
        "logs/weblogic-b"
        "logs/haproxy"
        "logs/dashboard"
        "logs/ip-updater"
        "logs/health-monitor"
        "haproxy/config"
        "haproxy/scripts"
        "haproxy/dashboard"
        "autodeploy"
        "deploy"
        "scripts"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$PROJECT_DIR/$dir"
    done
    
    log_success "Directorios creados"
}

# Función para actualizar variables de entorno dinámicamente
update_env_dynamic() {
    log "🔧 Actualizando variables de entorno dinámicamente..."
    
    # Detectar subnet disponible
    local subnet_found=false
    local subnet_third=25
    
    while [[ $subnet_found == false && $subnet_third -lt 255 ]]; do
        local test_subnet="172.${subnet_third}.0.0/16"
        local test_gateway="172.${subnet_third}.0.1"
        
        # Verificar si la subnet está en uso
        if ! docker network ls --format "{{.Name}}" | xargs -I {} docker network inspect {} 2>/dev/null | grep -q "172.${subnet_third}.0"; then
            SUBNET_BASE="172.${subnet_third}.0"
            GATEWAY="${SUBNET_BASE}.1"
            subnet_found=true
            log_success "Subnet disponible encontrada: 172.${subnet_third}.0.0/16"
        else
            ((subnet_third++))
        fi
    done
    
    if [[ $subnet_found == false ]]; then
        log_error "No se pudo encontrar una subnet disponible"
        exit 1
    fi
    
    # Actualizar .env con valores dinámicos
    update_env_var "SUBNET" "172.${subnet_third}.0.0/16"
    update_env_var "GATEWAY" "${GATEWAY}"
    update_env_var "NETWORK_NAME" "weblogic-integrated_weblogic-network"
    
    # Actualizar puertos externos para evitar conflictos
    update_env_var "EXTERNAL_HTTP_PORT" "8090"
    update_env_var "EXTERNAL_HTTPS_PORT" "8443"
    update_env_var "EXTERNAL_STATS_PORT" "8414"
    update_env_var "EXTERNAL_API_PORT" "8091"
    update_env_var "EXTERNAL_UI_PORT" "8092"
    update_env_var "EXTERNAL_DASHBOARD_PORT" "8011"
    update_env_var "EXTERNAL_WEBLOGIC_A_PORT" "7003"
    update_env_var "EXTERNAL_WEBLOGIC_B_PORT" "7004"
    
    log_success "Variables de entorno actualizadas dinámicamente"
}

# Función para obtener IP de un contenedor
get_container_ip() {
    local container_name="$1"
    local integrated_name="${container_name}-integrated"
    
    # Obtener IP del contenedor integrado
    if docker ps --format "{{.Names}}" | grep -q "^${integrated_name}$"; then
        local ip=$(docker inspect "$integrated_name" 2>/dev/null | jq -r '.[0].NetworkSettings.Networks | to_entries[] | select(.value.IPAddress != "") | .value.IPAddress' | head -1)
        if [[ -n "$ip" && "$ip" != "null" ]]; then
            echo "$ip"
            return 0
        fi
    fi
    
    # Fallback al nombre original
    if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
        local ip=$(docker inspect "$container_name" 2>/dev/null | jq -r '.[0].NetworkSettings.Networks | to_entries[] | select(.value.IPAddress != "") | .value.IPAddress' | head -1)
        if [[ -n "$ip" && "$ip" != "null" ]]; then
            echo "$ip"
            return 0
        fi
    fi
    
    echo "null"
}

# Función para actualizar variable en .env
update_env_var() {
    local var_name="$1"
    local var_value="$2"
    
    if grep -q "^${var_name}=" "$ENV_FILE"; then
        sed -i "s|^${var_name}=.*|${var_name}=${var_value}|" "$ENV_FILE"
        log "Actualizada variable $var_name=$var_value"
    else
        echo "${var_name}=${var_value}" >> "$ENV_FILE"
        log "Agregada nueva variable $var_name=$var_value"
    fi
}

# Función para actualizar IPs automáticamente
update_ips_automatically() {
    log "🔄 Actualizando IPs automáticamente..."
    
    # Esperar que los contenedores estén listos
    local max_attempts=60
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        local oracle_ip=$(get_container_ip "orcldb")
        local weblogic_a_ip=$(get_container_ip "weblogic-a")
        local weblogic_b_ip=$(get_container_ip "weblogic-b")
        
        if [[ "$oracle_ip" != "null" && "$weblogic_a_ip" != "null" && "$weblogic_b_ip" != "null" ]]; then
            log_success "IPs detectadas correctamente"
            
            # Actualizar variables en .env
            update_env_var "ORACLE_HOST" "$oracle_ip"
            update_env_var "WEBLOGIC_A_HOST" "$weblogic_a_ip"
            update_env_var "WEBLOGIC_B_HOST" "$weblogic_b_ip"
            
            # Obtener IPs opcionales
            local haproxy_ip=$(get_container_ip "haproxy")
            local dashboard_ip=$(get_container_ip "dashboard")
            
            if [[ "$haproxy_ip" != "null" ]]; then
                update_env_var "HAPROXY_HOST" "$haproxy_ip"
            fi
            
            if [[ "$dashboard_ip" != "null" ]]; then
                update_env_var "DASHBOARD_HOST" "$dashboard_ip"
            fi
            
            # Actualizar EXTRA_HOSTS
            local extra_hosts="weblogic-a:${weblogic_a_ip},weblogic-b:${weblogic_b_ip},oracle-db:${oracle_ip}"
            if [[ "$haproxy_ip" != "null" ]]; then
                extra_hosts="${extra_hosts},haproxy:${haproxy_ip}"
            fi
            if [[ "$dashboard_ip" != "null" ]]; then
                extra_hosts="${extra_hosts},dashboard:${dashboard_ip}"
            fi
            update_env_var "EXTRA_HOSTS" "$extra_hosts"
            
            log_success "Variables de entorno actualizadas"
            
            # Mostrar resumen de IPs
            echo
            log "📋 Resumen de IPs detectadas:"
            log "  Oracle DB: $oracle_ip:1521"
            log "  WebLogic A: $weblogic_a_ip:7001"
            log "  WebLogic B: $weblogic_b_ip:7001"
            if [[ "$haproxy_ip" != "null" ]]; then
                log "  HAProxy: $haproxy_ip:80"
            fi
            if [[ "$dashboard_ip" != "null" ]]; then
                log "  Dashboard: $dashboard_ip:80"
            fi
            
            return 0
        fi
        
        log "Intento $attempt/$max_attempts - Esperando IPs..."
        sleep 3
        ((attempt++))
    done
    
    log_error "No se pudieron obtener todas las IPs después de $max_attempts intentos"
    return 1
}

# Función para crear configuración optimizada de HAProxy
create_optimized_haproxy_config() {
    log "⚙️ Creando configuración optimizada de HAProxy..."
    
    cat > "$HAPROXY_CONFIG_DIR/haproxy.cfg" << 'EOF'
global
    log stdout format raw local0
    maxconn 4096
    stats socket /var/run/haproxy.sock mode 666 level admin
    stats timeout 30s

defaults
    log global
    mode http
    option httplog
    option dontlognull
    option forwardfor
    option http-server-close
    timeout connect 5s
    timeout client 50s
    timeout server 50s
    timeout http-request 10s
    timeout http-keep-alive 2s
    timeout check 10s
    retries 3

# Frontend principal
frontend main_frontend
    bind *:80
    
    # Reglas de enrutamiento
    acl is_ff4j path_beg /ff4j-simple
    acl is_feature_flags path_beg /feature-flags
    acl is_version_a path_beg /version-a
    acl is_version_b path_beg /version-b
    acl is_weblogic_features_a path_beg /weblogic-features-a
    acl is_weblogic_features_b path_beg /weblogic-features-b
    
    # Usar backends específicos
    use_backend ff4j_backend if is_ff4j
    use_backend feature_flags_backend if is_feature_flags
    use_backend version_a_backend if is_version_a
    use_backend version_b_backend if is_version_b
    use_backend weblogic_features_a_backend if is_weblogic_features_a
    use_backend weblogic_features_b_backend if is_weblogic_features_b
    
    # Backend por defecto
    default_backend weblogic_main_backend

# Backend principal con balanceeo
backend weblogic_main_backend
    balance roundrobin
    option httpchk GET /
    server weblogic-a weblogic-a-integrated:7001 check weight 50
    server weblogic-b weblogic-b-integrated:7001 check weight 50

# Backends específicos para aplicaciones
backend ff4j_backend
    option httpchk GET /ff4j-simple
    server weblogic-a-ff4j weblogic-a-integrated:7001 check
    server weblogic-b-ff4j weblogic-b-integrated:7001 check backup

backend feature_flags_backend
    option httpchk GET /feature-flags
    server weblogic-a-feature weblogic-a-integrated:7001 check
    server weblogic-b-feature weblogic-b-integrated:7001 check backup

backend version_a_backend
    option httpchk GET /version-a
    server weblogic-a-version weblogic-a-integrated:7001 check

backend version_b_backend
    option httpchk GET /version-b
    server weblogic-b-version weblogic-b-integrated:7001 check

backend weblogic_features_a_backend
    option httpchk GET /weblogic-features-a
    server weblogic-a-features weblogic-a-integrated:7001 check

backend weblogic_features_b_backend
    option httpchk GET /weblogic-features-b
    server weblogic-b-features weblogic-b-integrated:7001 check

# Estadísticas de HAProxy
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
    stats auth admin:admin123

# API de administración
listen api
    bind *:8081
    stats enable
    stats uri /api
    stats refresh 5s
    stats admin if TRUE
    stats auth admin:admin123

# UI de administración
listen admin_ui
    bind *:8082
    stats enable
    stats uri /
    stats refresh 10s
    stats admin if TRUE
    stats auth admin:admin123
EOF

    log_success "Configuración optimizada de HAProxy creada"
}

# Función para iniciar servicios
start_services() {
    log_header
    log "🚀 Iniciando servicios completos integrados..."
    
    # Verificar dependencias
    check_dependencies
    
    # Limpiar redes conflictivas
    cleanup_networks
    
    # Crear directorios necesarios
    create_directories
    
    # Actualizar variables de entorno dinámicamente
    update_env_dynamic
    
    # Verificar que el archivo docker-compose existe
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        log_error "Archivo docker-compose no encontrado: $DOCKER_COMPOSE_FILE"
        exit 1
    fi
    
    # Crear configuración optimizada de HAProxy
    create_optimized_haproxy_config
    
    # Iniciar servicios con docker-compose
    log "Iniciando contenedores..."
    if docker-compose -f "$DOCKER_COMPOSE_FILE" up -d; then
        log_success "Contenedores iniciados"
    else
        log_error "Error al iniciar contenedores"
        exit 1
    fi
    
    # Esperar inicialización de contenedores críticos
    log "⏳ Esperando inicialización de contenedores críticos..."
    sleep 15
    
    # Actualizar IPs automáticamente
    if update_ips_automatically; then
        log_success "IPs actualizadas correctamente"
    else
        log_warning "No se pudieron actualizar todas las IPs, continuando..."
    fi
    
    # Mostrar estado final
    show_status
    
    # Verificar conectividad
    verify_connectivity
}

# Función para detener servicios
stop_services() {
    log_header
    log "🛑 Deteniendo servicios completos integrados..."
    
    if docker-compose -f "$DOCKER_COMPOSE_FILE" down --remove-orphans; then
        log_success "Servicios detenidos correctamente"
    else
        log_error "Error al detener servicios"
        exit 1
    fi
    
    # Limpiar redes huérfanas
    docker network prune -f
    log_success "Redes limpiadas"
}

# Función para mostrar estado
show_status() {
    log "📊 Estado de servicios:"
    echo
    
    # Mostrar estado de contenedores
    docker-compose -f "$DOCKER_COMPOSE_FILE" ps
    
    echo
    log "🌐 URLs de acceso:"
    log "  HAProxy Frontend:     http://localhost:8090"
    log "  HAProxy Stats:        http://localhost:8414/stats"
    log "  HAProxy API:          http://localhost:8091/api"
    log "  Panel Admin:          http://localhost:8092"
    log "  Dashboard:            http://localhost:8011"
    log "  WebLogic A Console:   http://localhost:7003/console"
    log "  WebLogic B Console:   http://localhost:7004/console"
    log "  Oracle EM:            http://localhost:5500/em"
    
    echo
    log "📱 Aplicaciones disponibles:"
    log "  FF4J Simple:         http://localhost:8090/ff4j-simple"
    log "  Feature Flags:       http://localhost:8090/feature-flags"
    log "  Version A:           http://localhost:8090/version-a"
    log "  Version B:           http://localhost:8090/version-b"
    log "  WebLogic Features A: http://localhost:8090/weblogic-features-a"
    log "  WebLogic Features B: http://localhost:8090/weblogic-features-b"
}

# Función para verificar conectividad
verify_connectivity() {
    echo
    log "🔍 Verificación de conectividad:"
    
    local services=(
        "HAProxy Frontend:http://localhost:8090"
        "HAProxy Stats:http://localhost:8414/stats"
        "Dashboard:http://localhost:8011"
        "WebLogic A:http://localhost:7003/console"
        "WebLogic B:http://localhost:7004/console"
    )
    
    for service in "${services[@]}"; do
        local name="${service%%:*}"
        local url="${service#*:}"
        
        if curl -s --connect-timeout 5 "$url" > /dev/null; then
            log_success "$name: ✓ Accesible"
        else
            log_warning "$name: ⚠ No responde"
        fi
    done
}

# Función para reiniciar servicios
restart_services() {
    log_header
    log "🔄 Reiniciando servicios completos integrados..."
    
    stop_services
    sleep 5
    start_services
}

# Función para mostrar logs
show_logs() {
    local service="${1:-}"
    
    if [[ -z "$service" ]]; then
        log "📋 Servicios disponibles para logs:"
        docker-compose -f "$DOCKER_COMPOSE_FILE" ps --services
        return 0
    fi
    
    log "📋 Mostrando logs de $service..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" logs -f "$service"
}

# Función para mostrar ayuda
show_help() {
    log_header
    echo "Uso: $0 {start|stop|restart|status|logs|update-ips|cleanup|help}"
    echo
    echo "Comandos disponibles:"
    echo "  start      - Iniciar todos los servicios con configuración optimizada"
    echo "  stop       - Detener todos los servicios y limpiar recursos"
    echo "  restart    - Reiniciar todos los servicios"
    echo "  status     - Mostrar estado de servicios y URLs"
    echo "  logs       - Mostrar logs de un servicio específico"
    echo "  update-ips - Actualizar IPs manualmente"
    echo "  cleanup    - Limpiar redes y contenedores huérfanos"
    echo "  help       - Mostrar esta ayuda"
    echo
    echo "Características principales:"
    echo "  ✓ Actualización automática de IPs en .env"
    echo "  ✓ Gestión dinámica de redes Docker"
    echo "  ✓ Configuración optimizada de HAProxy"
    echo "  ✓ Monitoreo automático de salud"
    echo "  ✓ Servicios integrados sin redundancia"
    echo "  ✓ Verificación de conectividad"
    echo "  ✓ Gestión inteligente de recursos"
    echo
    echo "Servicios incluidos:"
    echo "  • Oracle Database (puerto 1521, 5500)"
    echo "  • WebLogic A - Estable (puerto 7003)"
    echo "  • WebLogic B - Canary (puerto 7004)"
    echo "  • HAProxy Load Balancer (puertos 8090, 8414, 8091, 8092)"
    echo "  • Dashboard Integrado (puerto 8011)"
    echo "  • Actualizador automático de IPs"
    echo "  • Monitor de salud de servicios"
}

# Función principal
main() {
    local command="${1:-help}"
    
    case "$command" in
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_status
            verify_connectivity
            ;;
        logs)
            show_logs "${2:-}"
            ;;
        update-ips)
            update_ips_automatically
            ;;
        cleanup)
            cleanup_networks
            docker system prune -f
            log_success "Limpieza completada"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Comando desconocido: $command"
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
