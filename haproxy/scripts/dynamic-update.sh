#!/bin/bash
# Script para actualizar dinámicamente la configuración de HAProxy
# cuando cambian las IPs de los contenedores WebLogic

# Configuración
HAPROXY_SOCKET="/var/run/haproxy.sock"
CHECK_INTERVAL=30  # Intervalo de verificación en segundos
LOG_FILE="/var/log/haproxy-dynamic-update.log"

# Función para registrar mensajes
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log "Iniciando servicio de actualización dinámica de HAProxy"

# Variables para almacenar las últimas IPs conocidas
LAST_WEBLOGIC_A_IP=""
LAST_WEBLOGIC_B_IP=""

# Función para obtener la IP de un contenedor
get_container_ip() {
    local container_name=$1
    local ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name 2>/dev/null)
    
    if [ -z "$ip" ]; then
        log "ADVERTENCIA: No se pudo obtener la IP para el contenedor $container_name"
        return 1
    fi
    
    echo $ip
    return 0
}

# Función para actualizar la configuración de HAProxy
update_haproxy_config() {
    local server=$1
    local backend=$2
    local ip=$3
    
    log "Actualizando servidor $server en backend $backend con IP $ip"
    
    # Verificar si socat está instalado
    if ! command -v socat &> /dev/null; then
        log "ERROR: socat no está instalado. No se puede actualizar HAProxy."
        return 1
    fi
    
    # Actualizar la configuración de HAProxy usando la API de runtime
    echo "set server $backend/$server addr $ip" | socat stdio $HAPROXY_SOCKET 2>&1
    
    if [ $? -ne 0 ]; then
        log "ERROR: No se pudo actualizar la configuración de HAProxy para $server"
        return 1
    fi
    
    log "Configuración actualizada correctamente para $server"
    return 0
}

# Bucle principal
while true; do
    log "Verificando IPs de contenedores WebLogic..."
    
    # Obtener las IPs actuales
    WEBLOGIC_A_IP=$(get_container_ip "weblogic-a")
    WEBLOGIC_B_IP=$(get_container_ip "weblogic-b")
    
    # Verificar si las IPs han cambiado
    if [ "$WEBLOGIC_A_IP" != "$LAST_WEBLOGIC_A_IP" ] && [ -n "$WEBLOGIC_A_IP" ]; then
        log "IP de weblogic-a ha cambiado: $LAST_WEBLOGIC_A_IP -> $WEBLOGIC_A_IP"
        
        # Actualizar todos los backends que usan weblogic-a
        update_haproxy_config "weblogic-a" "weblogic-a" "$WEBLOGIC_A_IP"
        update_haproxy_config "weblogic-a-ff4j" "ff4j-backend" "$WEBLOGIC_A_IP"
        update_haproxy_config "weblogic-a-feature" "feature-flags-backend" "$WEBLOGIC_A_IP"
        update_haproxy_config "weblogic-a-version" "version-a-backend" "$WEBLOGIC_A_IP"
        update_haproxy_config "weblogic-a-features" "weblogic-features-a" "$WEBLOGIC_A_IP"
        
        LAST_WEBLOGIC_A_IP="$WEBLOGIC_A_IP"
    fi
    
    if [ "$WEBLOGIC_B_IP" != "$LAST_WEBLOGIC_B_IP" ] && [ -n "$WEBLOGIC_B_IP" ]; then
        log "IP de weblogic-b ha cambiado: $LAST_WEBLOGIC_B_IP -> $WEBLOGIC_B_IP"
        
        # Actualizar todos los backends que usan weblogic-b
        update_haproxy_config "weblogic-b" "weblogic-b" "$WEBLOGIC_B_IP"
        update_haproxy_config "weblogic-b-ff4j" "ff4j-backend" "$WEBLOGIC_B_IP"
        update_haproxy_config "weblogic-b-feature" "feature-flags-backend" "$WEBLOGIC_B_IP"
        update_haproxy_config "weblogic-b-version" "version-b-backend" "$WEBLOGIC_B_IP"
        update_haproxy_config "weblogic-b-features" "weblogic-features-b" "$WEBLOGIC_B_IP"
        
        LAST_WEBLOGIC_B_IP="$WEBLOGIC_B_IP"
    fi
    
    # Esperar antes de la próxima verificación
    log "Esperando $CHECK_INTERVAL segundos antes de la próxima verificación..."
    sleep $CHECK_INTERVAL
done
