#!/bin/bash

# =============================================================================
# Script de Actualización Automática de IPs Integrado - Versión Mejorada
# Proyecto: Docker Oracle WebLogic con Testing A/B, Canary Deployment y Feature Flags
# =============================================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PROJECT_DIR}/.env"
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

# Función mejorada para obtener IP de un contenedor
get_container_ip() {
    local container_name="$1"
    
    # Intentar obtener IP del contenedor integrado primero
    local integrated_name="${container_name}-integrated"
    
    # Obtener todas las redes del contenedor y buscar la IP
    local ip=""
    
    # Intentar con el contenedor integrado
    if docker ps --format "{{.Names}}" | grep -q "^${integrated_name}$"; then
        ip=$(docker inspect "$integrated_name" 2>/dev/null | jq -r '.[0].NetworkSettings.Networks | to_entries[] | select(.value.IPAddress != "") | .value.IPAddress' | head -1)
    fi
    
    # Si no se encontró, intentar con el nombre original
    if [[ -z "$ip" || "$ip" == "null" ]]; then
        if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
            ip=$(docker inspect "$container_name" 2>/dev/null | jq -r '.[0].NetworkSettings.Networks | to_entries[] | select(.value.IPAddress != "") | .value.IPAddress' | head -1)
        fi
    fi
    
    # Si aún no se encontró, devolver null
    if [[ -z "$ip" || "$ip" == "null" ]]; then
        echo "null"
    else
        echo "$ip"
    fi
}

# Función para esperar que un contenedor esté listo
wait_for_container() {
    local container_name="$1"
    local max_attempts="${2:-30}"
    local attempt=1
    
    log "Esperando que el contenedor $container_name esté listo..."
    
    while [[ $attempt -le $max_attempts ]]; do
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(^|\s)${container_name}(-integrated)?(\s|$)" | grep -q "Up"; then
            log_success "Contenedor $container_name está listo"
            return 0
        fi
        
        log "Intento $attempt/$max_attempts - Esperando contenedor $container_name..."
        sleep 2
        ((attempt++))
    done
    
    log_error "Timeout esperando contenedor $container_name"
    return 1
}

# Función para actualizar variable en .env
update_env_var() {
    local var_name="$1"
    local var_value="$2"
    
    if grep -q "^${var_name}=" "$ENV_FILE"; then
        # Usar un delimitador diferente para evitar problemas con IPs
        sed -i "s|^${var_name}=.*|${var_name}=${var_value}|" "$ENV_FILE"
        log "Actualizada variable $var_name=$var_value"
    else
        # Agregar nueva variable
        echo "${var_name}=${var_value}" >> "$ENV_FILE"
        log "Agregada nueva variable $var_name=$var_value"
    fi
}

# Función para actualizar configuración de HAProxy
update_haproxy_config() {
    local oracle_ip="$1"
    local weblogic_a_ip="$2"
    local weblogic_b_ip="$3"
    local haproxy_ip="$4"
    local dashboard_ip="$5"
    
    log "Actualizando configuración de HAProxy..."
    
    # Determinar qué archivo de configuración usar
    local config_file="$HAPROXY_CONFIG_DIR/haproxy.cfg"
    
    # Si existe el archivo integrado, usarlo
    if [[ -f "$HAPROXY_CONFIG_DIR/haproxy-integrated.cfg" ]]; then
        config_file="$HAPROXY_CONFIG_DIR/haproxy-integrated.cfg"
    elif [[ -f "$HAPROXY_CONFIG_DIR/haproxy-advanced-integrated.cfg" ]]; then
        config_file="$HAPROXY_CONFIG_DIR/haproxy-advanced-integrated.cfg"
    fi
    
    if [[ ! -f "$config_file" ]]; then
        log_warning "Archivo de configuración de HAProxy no encontrado: $config_file"
        return 1
    fi
    
    # Crear backup de la configuración
    cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Actualizar IPs en la configuración usando sed con delimitador diferente
    sed -i "s|server weblogic-a [0-9.]*:7001|server weblogic-a ${weblogic_a_ip}:7001|g" "$config_file"
    sed -i "s|server weblogic-b [0-9.]*:7001|server weblogic-b ${weblogic_b_ip}:7001|g" "$config_file"
    
    # También actualizar cualquier referencia a IPs específicas en rangos comunes
    sed -i "s|172\\.2[34]\\.0\\.[0-9]*|${weblogic_a_ip}|g" "$config_file"
    
    # Actualizar específicamente para WebLogic B
    sed -i "s|server weblogic-b ${weblogic_a_ip}:7001|server weblogic-b ${weblogic_b_ip}:7001|g" "$config_file"
    
    log_success "Configuración de HAProxy actualizada en $config_file"
}

# Función para reiniciar HAProxy de forma segura
restart_haproxy_safe() {
    log "Reiniciando HAProxy de forma segura..."
    
    # Verificar que el contenedor existe
    if ! docker ps -a --format "{{.Names}}" | grep -q "haproxy-integrated"; then
        log_error "Contenedor haproxy-integrated no encontrado"
        return 1
    fi
    
    # Verificar configuración antes de reiniciar
    if docker exec haproxy-integrated haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg 2>/dev/null; then
        log_success "Configuración de HAProxy válida"
        docker restart haproxy-integrated
        log_success "HAProxy reiniciado correctamente"
        
        # Esperar un poco para que HAProxy se inicie
        sleep 5
        
        # Verificar que HAProxy esté funcionando
        local attempts=0
        while [[ $attempts -lt 10 ]]; do
            if docker ps --format "{{.Names}}\t{{.Status}}" | grep "haproxy-integrated" | grep -q "Up"; then
                log_success "HAProxy está funcionando correctamente"
                return 0
            fi
            sleep 2
            ((attempts++))
        done
        
        log_warning "HAProxy tardó más de lo esperado en iniciarse"
    else
        log_error "Configuración de HAProxy inválida, no se reiniciará"
        return 1
    fi
}

# Función principal
main() {
    log "🚀 Iniciando actualización automática de IPs..."
    
    # Verificar que Docker esté disponible
    if ! command -v docker &> /dev/null; then
        log_error "Docker no está disponible"
        exit 1
    fi
    
    # Verificar que jq esté disponible
    if ! command -v jq &> /dev/null; then
        log_warning "jq no está disponible, instalando..."
        sudo apt-get update && sudo apt-get install -y jq
    fi
    
    # Esperar que los contenedores estén listos
    log "Esperando que los contenedores estén listos..."
    wait_for_container "orcldb" 60
    wait_for_container "weblogic-a" 60
    wait_for_container "weblogic-b" 60
    wait_for_container "dashboard" 30
    
    # Obtener IPs dinámicas de los contenedores
    log "Obteniendo IPs dinámicas de los contenedores..."
    
    ORACLE_IP=$(get_container_ip "orcldb")
    WEBLOGIC_A_IP=$(get_container_ip "weblogic-a")
    WEBLOGIC_B_IP=$(get_container_ip "weblogic-b")
    HAPROXY_IP=$(get_container_ip "haproxy")
    DASHBOARD_IP=$(get_container_ip "dashboard")
    
    # Mostrar IPs detectadas
    log "IPs detectadas:"
    log "  Oracle DB: $ORACLE_IP"
    log "  WebLogic A: $WEBLOGIC_A_IP"
    log "  WebLogic B: $WEBLOGIC_B_IP"
    log "  HAProxy: $HAPROXY_IP"
    log "  Dashboard: $DASHBOARD_IP"
    
    # Verificar que se obtuvieron las IPs críticas
    if [[ "$ORACLE_IP" == "null" || "$WEBLOGIC_A_IP" == "null" || "$WEBLOGIC_B_IP" == "null" ]]; then
        log_error "No se pudieron obtener todas las IPs necesarias"
        log "Contenedores disponibles:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Mostrar información de red para debug
        log "Información de redes Docker:"
        docker network ls
        
        exit 1
    fi
    
    # Actualizar variables en .env
    log "Actualizando variables en .env..."
    update_env_var "ORACLE_HOST" "$ORACLE_IP"
    update_env_var "WEBLOGIC_A_HOST" "$WEBLOGIC_A_IP"
    update_env_var "WEBLOGIC_B_HOST" "$WEBLOGIC_B_IP"
    
    if [[ "$HAPROXY_IP" != "null" && -n "$HAPROXY_IP" ]]; then
        update_env_var "HAPROXY_HOST" "$HAPROXY_IP"
    fi
    
    if [[ "$DASHBOARD_IP" != "null" && -n "$DASHBOARD_IP" ]]; then
        update_env_var "DASHBOARD_HOST" "$DASHBOARD_IP"
    fi
    
    # Actualizar configuración de HAProxy
    if [[ -d "$HAPROXY_CONFIG_DIR" ]]; then
        update_haproxy_config "$ORACLE_IP" "$WEBLOGIC_A_IP" "$WEBLOGIC_B_IP" "$HAPROXY_IP" "$DASHBOARD_IP"
        
        # Reiniciar HAProxy si está ejecutándose
        if docker ps | grep -q "haproxy-integrated"; then
            sleep 2  # Dar tiempo para que se actualice la configuración
            restart_haproxy_safe
        fi
    else
        log_warning "Directorio de configuración de HAProxy no encontrado: $HAPROXY_CONFIG_DIR"
    fi
    
    # Actualizar EXTRA_HOSTS
    EXTRA_HOSTS="weblogic-a:${WEBLOGIC_A_IP},weblogic-b:${WEBLOGIC_B_IP},oracle-db:${ORACLE_IP}"
    if [[ "$HAPROXY_IP" != "null" && -n "$HAPROXY_IP" ]]; then
        EXTRA_HOSTS="${EXTRA_HOSTS},haproxy:${HAPROXY_IP}"
    fi
    if [[ "$DASHBOARD_IP" != "null" && -n "$DASHBOARD_IP" ]]; then
        EXTRA_HOSTS="${EXTRA_HOSTS},dashboard:${DASHBOARD_IP}"
    fi
    update_env_var "EXTRA_HOSTS" "$EXTRA_HOSTS"
    
    log_success "🎉 Actualización de IPs completada exitosamente"
    
    # Mostrar resumen
    echo
    log "📋 Resumen de configuración:"
    log "  Oracle DB: $ORACLE_IP:1521"
    log "  WebLogic A: $WEBLOGIC_A_IP:7001"
    log "  WebLogic B: $WEBLOGIC_B_IP:7001"
    if [[ "$HAPROXY_IP" != "null" && -n "$HAPROXY_IP" ]]; then
        log "  HAProxy: $HAPROXY_IP:80"
    fi
    if [[ "$DASHBOARD_IP" != "null" && -n "$DASHBOARD_IP" ]]; then
        log "  Dashboard: $DASHBOARD_IP:80"
    fi
    
    # Verificar conectividad
    log "🔍 Verificando conectividad..."
    sleep 3  # Dar tiempo para que HAProxy se estabilice
    
    if curl -s --connect-timeout 5 "http://localhost:8090" > /dev/null; then
        log_success "HAProxy Frontend accesible en http://localhost:8090"
    else
        log_warning "HAProxy Frontend no responde aún (puede necesitar más tiempo)"
        log "Verificando estado de HAProxy..."
        docker logs haproxy-integrated --tail 10
    fi
    
    # Mostrar URLs finales
    echo
    log "🌐 URLs de acceso actualizadas:"
    log "  HAProxy Frontend: http://localhost:8090"
    log "  HAProxy Stats: http://localhost:8414/stats"
    log "  Panel Admin: http://localhost:8092"
    log "  Dashboard: http://localhost:8011"
    log "  WebLogic A Console: http://localhost:7003/console"
    log "  WebLogic B Console: http://localhost:7004/console"
}

# Ejecutar función principal si el script se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
