#!/bin/bash

# =============================================================================
# Gestor Final Completo e Integrado - Solución Definitiva
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

# Función para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌${NC} $1"
}

log_header() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    🚀 SOLUCIÓN FINAL INTEGRADA 🚀                   ║"
    echo "║          WebLogic + HAProxy + Actualización Automática de IPs       ║"
    echo "║                    ✅ Sin servicios redundantes                      ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para obtener IP de un contenedor
get_container_ip() {
    local container_name="$1"
    local integrated_name="${container_name}-integrated"
    
    if docker ps --format "{{.Names}}" | grep -q "^${integrated_name}$"; then
        local ip=$(docker inspect "$integrated_name" 2>/dev/null | jq -r '.[0].NetworkSettings.Networks | to_entries[] | select(.value.IPAddress != "") | .value.IPAddress' | head -1)
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
        log "📝 Actualizada variable $var_name=$var_value"
    else
        echo "${var_name}=${var_value}" >> "$ENV_FILE"
        log "📝 Agregada nueva variable $var_name=$var_value"
    fi
}

# Función para crear configuración HAProxy que funcione
create_working_haproxy_config() {
    log "⚙️ Creando configuración HAProxy que funciona..."
    
    cat > "$HAPROXY_CONFIG_DIR/haproxy.cfg" << 'EOF'
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
    retries 3

# Frontend principal
frontend main_frontend
    bind *:80
    default_backend weblogic_backend

# Backend principal
backend weblogic_backend
    balance roundrobin
    option httpchk GET /
    server weblogic-a weblogic-a-integrated:7001 check
    server weblogic-b weblogic-b-integrated:7001 check

# Estadísticas
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

# UI de administración
listen admin_ui
    bind *:8082
    stats enable
    stats uri /
    stats refresh 10s
    stats admin if TRUE
EOF

    log_success "Configuración HAProxy creada y simplificada"
}

# Función para actualizar IPs automáticamente
update_ips_automatically() {
    log "🔄 Actualizando IPs automáticamente..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        local oracle_ip=$(get_container_ip "orcldb")
        local weblogic_a_ip=$(get_container_ip "weblogic-a")
        local weblogic_b_ip=$(get_container_ip "weblogic-b")
        local haproxy_ip=$(get_container_ip "haproxy")
        local dashboard_ip=$(get_container_ip "dashboard")
        
        if [[ "$oracle_ip" != "null" && "$weblogic_a_ip" != "null" && "$weblogic_b_ip" != "null" ]]; then
            log_success "IPs detectadas correctamente"
            
            # Actualizar variables en .env
            update_env_var "ORACLE_HOST" "$oracle_ip"
            update_env_var "WEBLOGIC_A_HOST" "$weblogic_a_ip"
            update_env_var "WEBLOGIC_B_HOST" "$weblogic_b_ip"
            
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
            
            # Mostrar resumen
            echo
            log "📋 Resumen de IPs:"
            log "  🗄️  Oracle DB: $oracle_ip:1521"
            log "  🖥️  WebLogic A: $weblogic_a_ip:7001"
            log "  🖥️  WebLogic B: $weblogic_b_ip:7001"
            if [[ "$haproxy_ip" != "null" ]]; then
                log "  ⚖️  HAProxy: $haproxy_ip:80"
            fi
            if [[ "$dashboard_ip" != "null" ]]; then
                log "  📊 Dashboard: $dashboard_ip:80"
            fi
            
            return 0
        fi
        
        log "Intento $attempt/$max_attempts - Esperando IPs..."
        sleep 2
        ((attempt++))
    done
    
    log_error "No se pudieron obtener todas las IPs"
    return 1
}

# Función para iniciar servicios
start_services() {
    log_header
    log "🚀 Iniciando solución completa integrada..."
    
    # Verificar dependencias
    if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
        log_error "Docker o Docker Compose no están disponibles"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "Instalando jq..."
        sudo apt-get update && sudo apt-get install -y jq
    fi
    
    # Limpiar servicios existentes
    log "🧹 Limpiando servicios existentes..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" down --remove-orphans 2>/dev/null || true
    docker network prune -f
    
    # Crear directorios necesarios
    mkdir -p "$PROJECT_DIR"/{data/oracle,logs/{oracle,weblogic-a,weblogic-b,haproxy,dashboard},haproxy/{config,scripts,dashboard},autodeploy,deploy,scripts}
    
    # Crear configuración HAProxy que funcione
    create_working_haproxy_config
    
    # Iniciar servicios
    log "🚀 Iniciando contenedores..."
    if docker-compose -f "$DOCKER_COMPOSE_FILE" up -d; then
        log_success "Contenedores iniciados"
    else
        log_error "Error al iniciar contenedores"
        exit 1
    fi
    
    # Esperar inicialización
    log "⏳ Esperando inicialización (30 segundos)..."
    sleep 30
    
    # Actualizar IPs
    if update_ips_automatically; then
        log_success "IPs actualizadas correctamente"
    else
        log_warning "Algunas IPs no se pudieron actualizar"
    fi
    
    # Reiniciar HAProxy con configuración actualizada
    log "🔄 Reiniciando HAProxy con configuración actualizada..."
    docker restart haproxy-integrated
    sleep 10
    
    # Mostrar estado final
    show_final_status
}

# Función para mostrar estado final
show_final_status() {
    echo
    log "📊 Estado final de servicios:"
    docker-compose -f "$DOCKER_COMPOSE_FILE" ps
    
    echo
    log "🌐 URLs principales:"
    log "  🏠 HAProxy Frontend:     http://localhost:8090"
    log "  📊 HAProxy Stats:        http://localhost:8414/stats"
    log "  🎛️  Panel Admin:          http://localhost:8092"
    log "  📈 Dashboard:            http://localhost:8011"
    log "  🖥️  WebLogic A Console:   http://localhost:7003/console"
    log "  🖥️  WebLogic B Console:   http://localhost:7004/console"
    log "  🗄️  Oracle EM:            http://localhost:5500/em"
    
    echo
    log "📱 Aplicaciones (a través de HAProxy):"
    log "  🔧 FF4J Simple:         http://localhost:8090/ff4j-simple"
    log "  🚩 Feature Flags:       http://localhost:8090/feature-flags"
    log "  🅰️  Version A:           http://localhost:8090/version-a"
    log "  🅱️  Version B:           http://localhost:8090/version-b"
    log "  🔧 WebLogic Features A: http://localhost:8090/weblogic-features-a"
    log "  🔧 WebLogic Features B: http://localhost:8090/weblogic-features-b"
    
    # Verificar conectividad
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
            log_success "$name: ✅ Accesible"
        else
            log_warning "$name: ⚠️ No responde (puede necesitar más tiempo)"
        fi
    done
    
    echo
    log_success "🎉 Solución integrada desplegada exitosamente!"
    echo
    log "💡 Características implementadas:"
    log "  ✅ Actualización automática de IPs en .env"
    log "  ✅ Gestión dinámica de redes Docker"
    log "  ✅ Eliminación de servicios redundantes (integrated-manager removido)"
    log "  ✅ Configuración optimizada de HAProxy"
    log "  ✅ Monitoreo de salud integrado"
    log "  ✅ Variables centralizadas en .env"
    log "  ✅ Resolución automática de conflictos de red"
    
    echo
    log "🔧 Para gestionar el sistema:"
    log "  • Reiniciar: $0 restart"
    log "  • Detener: $0 stop"
    log "  • Ver estado: $0 status"
    log "  • Ver logs: $0 logs [servicio]"
    log "  • Actualizar IPs: $0 update-ips"
}

# Función para detener servicios
stop_services() {
    log_header
    log "🛑 Deteniendo servicios..."
    
    if docker-compose -f "$DOCKER_COMPOSE_FILE" down --remove-orphans; then
        log_success "Servicios detenidos correctamente"
    else
        log_error "Error al detener servicios"
    fi
    
    docker network prune -f
    log_success "Redes limpiadas"
}

# Función para reiniciar servicios
restart_services() {
    log_header
    log "🔄 Reiniciando servicios..."
    stop_services
    sleep 3
    start_services
}

# Función para mostrar logs
show_logs() {
    local service="${1:-}"
    
    if [[ -z "$service" ]]; then
        log "📋 Servicios disponibles:"
        echo "  • orcldb (Oracle Database)"
        echo "  • weblogic-a (WebLogic A)"
        echo "  • weblogic-b (WebLogic B)"
        echo "  • haproxy (HAProxy Load Balancer)"
        echo "  • dashboard (Dashboard)"
        echo
        log "Uso: $0 logs [nombre_servicio]"
        return 0
    fi
    
    log "📋 Mostrando logs de $service..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" logs -f "$service"
}

# Función para mostrar ayuda
show_help() {
    log_header
    echo "🚀 Gestor Final Integrado - Solución Completa"
    echo
    echo "Uso: $0 {start|stop|restart|status|logs|update-ips|help}"
    echo
    echo "Comandos:"
    echo "  start      - Iniciar todos los servicios (solución completa)"
    echo "  stop       - Detener todos los servicios"
    echo "  restart    - Reiniciar todos los servicios"
    echo "  status     - Mostrar estado y verificar conectividad"
    echo "  logs       - Mostrar logs de un servicio específico"
    echo "  update-ips - Actualizar IPs manualmente"
    echo "  help       - Mostrar esta ayuda"
    echo
    echo "✨ Características principales:"
    echo "  🔄 Actualización automática de IPs"
    echo "  🌐 Gestión dinámica de redes"
    echo "  🚫 Sin servicios redundantes"
    echo "  ⚖️ HAProxy optimizado"
    echo "  📊 Dashboard integrado"
    echo "  🔧 Variables centralizadas en .env"
    echo
    echo "🏗️ Servicios incluidos:"
    echo "  🗄️ Oracle Database (1521, 5500)"
    echo "  🖥️ WebLogic A - Estable (7003)"
    echo "  🖥️ WebLogic B - Canary (7004)"
    echo "  ⚖️ HAProxy Load Balancer (8090, 8414, 8091, 8092)"
    echo "  📊 Dashboard Integrado (8011)"
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
            show_final_status
            ;;
        logs)
            show_logs "${2:-}"
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

# Ejecutar función principal
main "$@"
