#!/bin/bash

# Script para simular tráfico a los servidores WebLogic
# Uso: ./simulate-traffic.sh [requests] [interval]

REQUESTS=${1:-100}
INTERVAL=${2:-0.5}

echo "Simulando $REQUESTS solicitudes con intervalo de $INTERVAL segundos"

# Función para enviar solicitudes
send_requests() {
    for ((i=1; i<=$REQUESTS; i++)); do
        # Solicitud normal (debería ir a la versión A por defecto)
        echo "Normal request:"
        curl -s -I http://localhost:8080/ | grep -i "set-cookie"

        # Solicitud con cabecera canary (debería ir a la versión B)
        echo "Canary header:"
        curl -s -I -H "X-Canary: true" http://localhost:8080/ | grep -i "set-cookie"

        # Solicitud con cookie canary (debería ir a la versión B)
        echo "Canary cookie:"
        curl -s -I --cookie "canary=true" http://localhost:8080/ | grep -i "set-cookie"

        # Solicitud con cookie A/B testing (debería ir a la versión B)
        echo "A/B testing:"
        curl -s -I --cookie "ab_test=B" http://localhost:8080/ | grep -i "set-cookie"

        # Solicitud a una ruta específica (debería ir a la versión B)
        echo "Feature path:"
        curl -s -I http://localhost:8080/feature/test | grep -i "set-cookie"

        echo "Completado $i de $REQUESTS"
        echo "------------------------"
        sleep $INTERVAL
    done
}

# Ejecutar la función principal
send_requests
