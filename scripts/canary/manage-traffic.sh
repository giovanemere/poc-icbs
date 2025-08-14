#!/bin/bash

# Script para gestionar el tráfico entre versiones A y B de WebLogic
# Uso: ./manage-traffic.sh [canary|ab] [percentage]

MODE=$1
PERCENTAGE=$2

if [ -z "$MODE" ] || [ -z "$PERCENTAGE" ]; then
    echo "Uso: $0 [canary|ab] [percentage]"
    echo "Ejemplo: $0 canary 20 (envía 20% del tráfico a la versión canary)"
    echo "Ejemplo: $0 ab 50 (envía 50% del tráfico a la versión B para A/B testing)"
    exit 1
fi

if ! [[ "$PERCENTAGE" =~ ^[0-9]+$ ]] || [ "$PERCENTAGE" -lt 0 ] || [ "$PERCENTAGE" -gt 100 ]; then
    echo "El porcentaje debe ser un número entre 0 y 100"
    exit 1
fi

# Función para actualizar la configuración de HAProxy
update_haproxy_config() {
    local mode=$1
    local percentage=$2
    local config_file="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/config/haproxy.cfg"
    local temp_file=$(mktemp)
    
    # Hacer una copia del archivo de configuración
    cp "$config_file" "$temp_file"
    
    if [ "$mode" == "canary" ]; then
        # Actualizar la configuración para despliegue canario
        sed -i "/acl canary_user/a\\    # Canary deployment - route $percentage% of traffic to version B\\n    balance random\\n    hash-type consistent\\n    use_backend weblogic-b if { rand(100) -lt $percentage }" "$temp_file"
    elif [ "$mode" == "ab" ]; then
        # Actualizar la configuración para testing A/B
        sed -i "/acl ab_test_cookie/a\\    # A/B testing - route $percentage% of traffic to version B\\n    balance random\\n    hash-type consistent\\n    use_backend weblogic-b if { rand(100) -lt $percentage }" "$temp_file"
    fi
    
    # Reemplazar el archivo original con el modificado
    mv "$temp_file" "$config_file"
    
    echo "Configuración de HAProxy actualizada para $mode testing con $percentage% de tráfico a la versión B"
    echo "Reiniciando HAProxy..."
    
    # Reiniciar HAProxy
    docker restart haproxy
}

# Ejecutar la función principal
update_haproxy_config "$MODE" "$PERCENTAGE"

echo "Configuración completada. Monitorea el tráfico en http://localhost:8404/stats"
