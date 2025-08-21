#!/bin/bash
#
# Script mejorado para controlar el tráfico entre versiones A y B
# Integra tanto testing A/B como despliegue canary
#

set -e

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Control de Tráfico para WebLogic A/B y Canary ===${NC}"
    echo ""
    echo "Uso: $0 [modo] [acción] [porcentaje]"
    echo ""
    echo "Modos:"
    echo "  ab       - Testing A/B entre version-a y version-b"
    echo "  canary   - Despliegue canary entre weblogic-features-a y weblogic-features-b"
    echo ""
    echo "Acciones:"
    echo "  enable   - Activa el modo seleccionado"
    echo "  disable  - Desactiva el modo seleccionado"
    echo "  set      - Establece el porcentaje de tráfico (requiere porcentaje)"
    echo "  status   - Muestra el estado actual"
    echo ""
    echo "Ejemplos:"
    echo "  $0 ab enable       - Activa testing A/B con distribución 50/50"
    echo "  $0 ab set 20       - Envía 20% del tráfico a version-b"
    echo "  $0 ab disable      - Desactiva testing A/B"
    echo "  $0 canary enable   - Activa despliegue canary con distribución 90/10"
    echo "  $0 canary set 30   - Envía 30% del tráfico a weblogic-features-b"
    echo "  $0 status          - Muestra el estado de ambos modos"
    echo ""
}

# Función para verificar si HAProxy está en ejecución
check_haproxy() {
    if ! docker ps | grep -q haproxy; then
        echo -e "${RED}Error: El contenedor HAProxy no está en ejecución${NC}"
        echo "Por favor, inicie el contenedor con:"
        echo "  docker-compose up -d haproxy"
        exit 1
    fi
}

# Función para verificar si los contenedores WebLogic están en ejecución
check_weblogic() {
    if ! docker ps | grep -q weblogic-a; then
        echo -e "${YELLOW}Advertencia: El contenedor weblogic-a no está en ejecución${NC}"
    fi
    
    if ! docker ps | grep -q weblogic-b; then
        echo -e "${YELLOW}Advertencia: El contenedor weblogic-b no está en ejecución${NC}"
    fi
}

# Función para actualizar el estado de A/B testing
update_ab_status() {
    local status=$1
    local socket="/var/run/haproxy.sock"
    
    # Usar socat para comunicarse con el socket de HAProxy
    docker exec haproxy bash -c "echo 'set var(txn.ab_testing_enabled) int($status)' | socat stdio $socket"
    
    if [ "$status" -eq 1 ]; then
        echo -e "${GREEN}Testing A/B activado${NC}"
    else
        echo -e "${YELLOW}Testing A/B desactivado${NC}"
    fi
}

# Función para actualizar el estado de Canary
update_canary_status() {
    local status=$1
    local socket="/var/run/haproxy.sock"
    
    # Usar socat para comunicarse con el socket de HAProxy
    docker exec haproxy bash -c "echo 'set var(txn.canary_enabled) int($status)' | socat stdio $socket"
    
    if [ "$status" -eq 1 ]; then
        echo -e "${GREEN}Despliegue Canary activado${NC}"
    else
        echo -e "${YELLOW}Despliegue Canary desactivado${NC}"
    fi
}

# Función para actualizar el porcentaje de tráfico
update_traffic_percentage() {
    local mode=$1
    local percentage=$2
    
    if [ "$mode" == "ab" ]; then
        # Actualizar porcentaje para A/B testing
        echo -e "${BLUE}Actualizando porcentaje de tráfico para testing A/B a ${percentage}%${NC}"
        
        # Crear script Python para actualizar el porcentaje
        cat > /tmp/update_ab.py << EOF
import sys
import urllib.request
import urllib.parse
import base64

# Configuración
url = 'http://localhost:9001/feature-flags/api/ff4j/propertyStore/ab-testing-percentage'
username = 'weblogic'
password = 'welcome1'
percentage = '$percentage'

# Crear autenticación básica
auth = base64.b64encode(f'{username}:{password}'.encode()).decode()

# Crear solicitud
data = urllib.parse.urlencode({'value': percentage}).encode()
headers = {
    'Authorization': f'Basic {auth}',
    'Content-Type': 'application/x-www-form-urlencoded'
}

# Enviar solicitud
req = urllib.request.Request(url, data=data, headers=headers, method='POST')

try:
    with urllib.request.urlopen(req) as response:
        print(f'Porcentaje de tráfico para A/B testing actualizado a {percentage}%')
except urllib.error.HTTPError as e:
    print(f'Error al actualizar el porcentaje: {e.code} {e.reason}')
    sys.exit(1)
except urllib.error.URLError as e:
    print(f'Error al conectar con el servidor: {e.reason}')
    sys.exit(1)
EOF

        # Ejecutar script Python
        python3 /tmp/update_ab.py
        rm -f /tmp/update_ab.py
        
    elif [ "$mode" == "canary" ]; then
        # Actualizar porcentaje para Canary
        echo -e "${BLUE}Actualizando porcentaje de tráfico para despliegue Canary a ${percentage}%${NC}"
        
        # Crear script Python para actualizar el porcentaje
        cat > /tmp/update_canary.py << EOF
import sys
import urllib.request
import urllib.parse
import base64

# Configuración
url = 'http://localhost:9001/feature-flags/api/ff4j/propertyStore/canary-percentage'
username = 'weblogic'
password = 'welcome1'
percentage = '$percentage'

# Crear autenticación básica
auth = base64.b64encode(f'{username}:{password}'.encode()).decode()

# Crear solicitud
data = urllib.parse.urlencode({'value': percentage}).encode()
headers = {
    'Authorization': f'Basic {auth}',
    'Content-Type': 'application/x-www-form-urlencoded'
}

# Enviar solicitud
req = urllib.request.Request(url, data=data, headers=headers, method='POST')

try:
    with urllib.request.urlopen(req) as response:
        print(f'Porcentaje de tráfico para despliegue Canary actualizado a {percentage}%')
except urllib.error.HTTPError as e:
    print(f'Error al actualizar el porcentaje: {e.code} {e.reason}')
    sys.exit(1)
except urllib.error.URLError as e:
    print(f'Error al conectar con el servidor: {e.reason}')
    sys.exit(1)
EOF

        # Ejecutar script Python
        python3 /tmp/update_canary.py
        rm -f /tmp/update_canary.py
    fi
}

# Función para mostrar el estado actual
show_status() {
    echo -e "${BLUE}=== Estado Actual de Distribución de Tráfico ===${NC}"
    echo ""
    
    # Verificar estado de A/B testing
    local ab_status=$(curl -s http://localhost:9001/feature-flags/api/ff4j/propertyStore/ab-testing-enabled | grep -o '"value":"[^"]*"' | cut -d'"' -f4)
    local ab_percentage=$(curl -s http://localhost:9001/feature-flags/api/ff4j/propertyStore/ab-testing-percentage | grep -o '"value":"[^"]*"' | cut -d'"' -f4)
    
    echo -e "Testing A/B: ${ab_status}"
    if [ "$ab_status" == "true" ]; then
        echo -e "  - Estado: ${GREEN}Activo${NC}"
        echo -e "  - Distribución: ${ab_percentage}% a version-b, $((100-ab_percentage))% a version-a"
    else
        echo -e "  - Estado: ${YELLOW}Inactivo${NC}"
        echo -e "  - Todo el tráfico va a version-a"
    fi
    
    echo ""
    
    # Verificar estado de Canary
    local canary_status=$(curl -s http://localhost:9001/feature-flags/api/ff4j/propertyStore/canary-enabled | grep -o '"value":"[^"]*"' | cut -d'"' -f4)
    local canary_percentage=$(curl -s http://localhost:9001/feature-flags/api/ff4j/propertyStore/canary-percentage | grep -o '"value":"[^"]*"' | cut -d'"' -f4)
    
    echo -e "Despliegue Canary: ${canary_status}"
    if [ "$canary_status" == "true" ]; then
        echo -e "  - Estado: ${GREEN}Activo${NC}"
        echo -e "  - Distribución: ${canary_percentage}% a weblogic-features-b, $((100-canary_percentage))% a weblogic-features-a"
    else
        echo -e "  - Estado: ${YELLOW}Inactivo${NC}"
        echo -e "  - Todo el tráfico va a weblogic-features-a"
    fi
    
    echo ""
    echo -e "Para monitorear el tráfico en tiempo real, visite: ${BLUE}http://localhost:8404/stats${NC}"
    echo ""
}

# Verificar argumentos
if [ $# -lt 1 ]; then
    show_help
    exit 0
fi

# Procesar argumentos
MODE=$1
ACTION=$2
PERCENTAGE=$3

# Verificar si se solicita ayuda
if [ "$MODE" == "help" ] || [ "$MODE" == "--help" ] || [ "$MODE" == "-h" ]; then
    show_help
    exit 0
fi

# Verificar si se solicita estado
if [ "$MODE" == "status" ]; then
    check_haproxy
    show_status
    exit 0
fi

# Verificar modo válido
if [ "$MODE" != "ab" ] && [ "$MODE" != "canary" ]; then
    echo -e "${RED}Error: Modo inválido '$MODE'${NC}"
    show_help
    exit 1
fi

# Verificar acción válida
if [ "$ACTION" != "enable" ] && [ "$ACTION" != "disable" ] && [ "$ACTION" != "set" ] && [ "$ACTION" != "status" ]; then
    echo -e "${RED}Error: Acción inválida '$ACTION'${NC}"
    show_help
    exit 1
fi

# Verificar si se necesita porcentaje
if [ "$ACTION" == "set" ] && [ -z "$PERCENTAGE" ]; then
    echo -e "${RED}Error: La acción 'set' requiere un porcentaje${NC}"
    show_help
    exit 1
fi

# Verificar si el porcentaje es válido
if [ ! -z "$PERCENTAGE" ]; then
    if ! [[ "$PERCENTAGE" =~ ^[0-9]+$ ]] || [ "$PERCENTAGE" -lt 0 ] || [ "$PERCENTAGE" -gt 100 ]; then
        echo -e "${RED}Error: El porcentaje debe ser un número entre 0 y 100${NC}"
        exit 1
    fi
fi

# Verificar si HAProxy está en ejecución
check_haproxy

# Verificar si WebLogic está en ejecución
check_weblogic

# Ejecutar la acción correspondiente
if [ "$MODE" == "ab" ]; then
    if [ "$ACTION" == "enable" ]; then
        update_ab_status 1
        update_traffic_percentage "ab" ${PERCENTAGE:-50}
    elif [ "$ACTION" == "disable" ]; then
        update_ab_status 0
    elif [ "$ACTION" == "set" ]; then
        update_traffic_percentage "ab" $PERCENTAGE
    elif [ "$ACTION" == "status" ]; then
        show_status
    fi
elif [ "$MODE" == "canary" ]; then
    if [ "$ACTION" == "enable" ]; then
        update_canary_status 1
        update_traffic_percentage "canary" ${PERCENTAGE:-10}
    elif [ "$ACTION" == "disable" ]; then
        update_canary_status 0
    elif [ "$ACTION" == "set" ]; then
        update_traffic_percentage "canary" $PERCENTAGE
    elif [ "$ACTION" == "status" ]; then
        show_status
    fi
fi

# Mostrar estado actual
echo ""
echo -e "${BLUE}Estado actual después de los cambios:${NC}"
show_status
