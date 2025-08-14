#!/bin/bash

# =============================================================================
# Gestor de Servicios Integrado con Actualización Automática de IPs
# Proyecto: Docker Oracle WebLogic con Testing A/B, Canary Deployment y Feature Flags
# =============================================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${PROJECT_DIR}/.env"
DOCKER_COMPOSE_FILE="${PROJECT_DIR}/config/docker-compose-integrated.yml"
HAPROXY_CONFIG_DIR="${PROJECT_DIR}/haproxy/config"

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
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          Gestor de Servicios WebLogic + HAProxy             ║"
    echo "║              con Actualización Automática de IPs            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
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
    local max_attempts=30
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
            return 0
        fi
        
        log "Intento $attempt/$max_attempts - Esperando IPs..."
        sleep 2
        ((attempt++))
    done
    
    log_error "No se pudieron obtener todas las IPs después de $max_attempts intentos"
    return 1
}

# Función para crear configuración de HAProxy simplificada
create_simple_haproxy_config() {
    local oracle_ip="$1"
    local weblogic_a_ip="$2"
    local weblogic_b_ip="$3"
    
    log "Creando configuración simplificada de HAProxy..."
    
    cat > "$HAPROXY_CONFIG_DIR/haproxy.cfg" << EOF
global
    log stdout format raw local0
    maxconn 4096
    stats socket /var/run/haproxy.sock mode 666 level admin

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

# Frontend principal
frontend main_frontend
    bind *:80
    default_backend weblogic_backend

# Backend para WebLogic
backend weblogic_backend
    balance roundrobin
    option httpchk GET /
    server weblogic-a-integrated weblogic-a-integrated:7001 check
    server weblogic-b-integrated weblogic-b-integrated:7001 check

# Estadísticas de HAProxy
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
EOF

    log_success "Configuración simplificada de HAProxy creada"
}

# Función para iniciar servicios
start_services() {
    log_header
    log "🚀 Iniciando servicios integrados..."
    
    # Verificar que el archivo docker-compose existe
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        log_error "Archivo docker-compose no encontrado: $DOCKER_COMPOSE_FILE"
        exit 1
    fi
    
    # Iniciar servicios con docker-compose
    log "Iniciando contenedores..."
    if docker-compose -f "$DOCKER_COMPOSE_FILE" up -d; then
        log_success "Contenedores iniciados"
    else
        log_error "Error al iniciar contenedores"
        exit 1
    fi
    
    # Esperar un poco para que los contenedores se inicialicen
    log "Esperando inicialización de contenedores..."
    sleep 10
    
    # Actualizar IPs automáticamente
    if update_ips_automatically; then
        log_success "IPs actualizadas correctamente"
    else
        log_warning "No se pudieron actualizar todas las IPs, continuando..."
    fi
    
    # Obtener IPs para configuración de HAProxy
    local oracle_ip=$(get_container_ip "orcldb")
    local weblogic_a_ip=$(get_container_ip "weblogic-a")
    local weblogic_b_ip=$(get_container_ip "weblogic-b")
    
    if [[ "$oracle_ip" != "null" && "$weblogic_a_ip" != "null" && "$weblogic_b_ip" != "null" ]]; then
        # Crear configuración simplificada de HAProxy
        create_simple_haproxy_config "$oracle_ip" "$weblogic_a_ip" "$weblogic_b_ip"
        
        # Reiniciar HAProxy con la nueva configuración
        log "Reiniciando HAProxy con configuración actualizada..."
        if docker restart haproxy-integrated; then
            log_success "HAProxy reiniciado"
            
            # Esperar que HAProxy se estabilice
            sleep 5
            
            # Verificar que HAProxy esté funcionando
            local attempts=0
            while [[ $attempts -lt 10 ]]; do
                if curl -s --connect-timeout 3 "http://localhost:8090" > /dev/null; then
                    log_success "HAProxy está funcionando correctamente"
                    break
                fi
                sleep 2
                ((attempts++))
            done
        else
            log_error "Error al reiniciar HAProxy"
        fi
    fi
    
    # Mostrar estado final
    show_status
}

# Función para detener servicios
stop_services() {
    log_header
    log "🛑 Deteniendo servicios integrados..."
    
    if docker-compose -f "$DOCKER_COMPOSE_FILE" down; then
        log_success "Servicios detenidos correctamente"
    else
        log_error "Error al detener servicios"
        exit 1
    fi
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
    log "  Panel Admin:          http://localhost:8092"
    log "  Dashboard:            http://localhost:8011"
    log "  WebLogic A Console:   http://localhost:7003/console"
    log "  WebLogic B Console:   http://localhost:7004/console"
    log "  Oracle EM:            http://localhost:5500/em"
    
    # Verificar conectividad
    echo
    log "🔍 Verificación de conectividad:"
    
    if curl -s --connect-timeout 3 "http://localhost:8090" > /dev/null; then
        log_success "HAProxy Frontend: ✓ Accesible"
    else
        log_warning "HAProxy Frontend: ⚠ No responde"
    fi
    
    if curl -s --connect-timeout 3 "http://localhost:8414/stats" > /dev/null; then
        log_success "HAProxy Stats: ✓ Accesible"
    else
        log_warning "HAProxy Stats: ⚠ No responde"
    fi
    
    if curl -s --connect-timeout 3 "http://localhost:8011" > /dev/null; then
        log_success "Dashboard: ✓ Accesible"
    else
        log_warning "Dashboard: ⚠ No responde"
    fi
}

# Función para reiniciar servicios
restart_services() {
    log_header
    log "🔄 Reiniciando servicios integrados..."
    
    stop_services
    sleep 3
    start_services
}

# Función para mostrar ayuda
show_help() {
    log_header
    echo "Uso: $0 {start|stop|restart|status|update-ips|help}"
    echo
    echo "Comandos disponibles:"
    echo "  start      - Iniciar todos los servicios con actualización automática de IPs"
    echo "  stop       - Detener todos los servicios"
    echo "  restart    - Reiniciar todos los servicios"
    echo "  status     - Mostrar estado de servicios y URLs"
    echo "  update-ips - Actualizar IPs manualmente"
    echo "  help       - Mostrar esta ayuda"
    echo
    echo "Características:"
    echo "  ✓ Actualización automática de IPs en .env"
    echo "  ✓ Configuración dinámica de HAProxy"
    echo "  ✓ Verificación de conectividad"
    echo "  ✓ Gestión inteligente de contenedores"
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
            ;;
        update-ips)
            update_ips_automatically
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

# Verificar dependencias
if ! command -v docker &> /dev/null; then
    log_error "Docker no está instalado o no está en el PATH"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose no está instalado o no está en el PATH"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    log_warning "jq no está instalado, instalando..."
    sudo apt-get update && sudo apt-get install -y jq
fi

# Ejecutar función principal
main "$@"
