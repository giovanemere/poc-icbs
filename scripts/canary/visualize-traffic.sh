#!/bin/bash
#
# Script para visualizar gráficamente el tráfico entre versiones A y B
#

set -e

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Visualización de Tráfico entre Versiones ===${NC}"
    echo ""
    echo "Uso: $0 [modo] [intervalo]"
    echo ""
    echo "Modos:"
    echo "  ab       - Visualiza tráfico de testing A/B"
    echo "  canary   - Visualiza tráfico de despliegue canary"
    echo "  all      - Visualiza ambos tipos de tráfico"
    echo ""
    echo "Intervalo:"
    echo "  Tiempo en segundos entre actualizaciones (por defecto: 2)"
    echo ""
    echo "Ejemplos:"
    echo "  $0 ab        - Visualiza tráfico A/B cada 2 segundos"
    echo "  $0 canary 5  - Visualiza tráfico canary cada 5 segundos"
    echo "  $0 all       - Visualiza todo el tráfico cada 2 segundos"
    echo ""
    echo "Presione Ctrl+C para salir"
    echo ""
}

# Función para dibujar una barra de progreso
draw_progress_bar() {
    local percentage=$1
    local label=$2
    local width=50
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    printf "%-15s [" "$label"
    printf "%${filled}s" '' | tr ' ' '█'
    printf "%${empty}s" '' | tr ' ' '░'
    printf "] %3d%%\n" "$percentage"
}

# Función para obtener estadísticas de tráfico
get_traffic_stats() {
    local mode=$1
    
    if [ "$mode" == "ab" ] || [ "$mode" == "all" ]; then
        # Obtener estadísticas de A/B testing
        local ab_status=$(curl -s http://localhost:9001/feature-flags/api/ff4j/propertyStore/ab-testing-enabled | grep -o '"value":"[^"]*"' | cut -d'"' -f4)
        local ab_percentage=$(curl -s http://localhost:9001/feature-flags/api/ff4j/propertyStore/ab-testing-percentage | grep -o '"value":"[^"]*"' | cut -d'"' -f4)
        
        echo -e "${CYAN}Testing A/B:${NC}"
        if [ "$ab_status" == "true" ]; then
            echo -e "  Estado: ${GREEN}Activo${NC}"
            draw_progress_bar $((100-ab_percentage)) "Version A"
            draw_progress_bar $ab_percentage "Version B"
        else
            echo -e "  Estado: ${YELLOW}Inactivo${NC}"
            draw_progress_bar 100 "Version A"
            draw_progress_bar 0 "Version B"
        fi
        echo ""
    fi
    
    if [ "$mode" == "canary" ] || [ "$mode" == "all" ]; then
        # Obtener estadísticas de Canary
        local canary_status=$(curl -s http://localhost:9001/feature-flags/api/ff4j/propertyStore/canary-enabled | grep -o '"value":"[^"]*"' | cut -d'"' -f4)
        local canary_percentage=$(curl -s http://localhost:9001/feature-flags/api/ff4j/propertyStore/canary-percentage | grep -o '"value":"[^"]*"' | cut -d'"' -f4)
        
        echo -e "${CYAN}Despliegue Canary:${NC}"
        if [ "$canary_status" == "true" ]; then
            echo -e "  Estado: ${GREEN}Activo${NC}"
            draw_progress_bar $((100-canary_percentage)) "WebLogic A"
            draw_progress_bar $canary_percentage "WebLogic B"
        else
            echo -e "  Estado: ${YELLOW}Inactivo${NC}"
            draw_progress_bar 100 "WebLogic A"
            draw_progress_bar 0 "WebLogic B"
        fi
        echo ""
    fi
}

# Función para obtener estadísticas de peticiones
get_request_stats() {
    local mode=$1
    
    # Obtener estadísticas de HAProxy
    local stats=$(curl -s http://localhost:8404/stats;csv)
    
    if [ "$mode" == "ab" ] || [ "$mode" == "all" ]; then
        # Extraer estadísticas para version-a y version-b
        local version_a_requests=$(echo "$stats" | grep "version-a-backend" | cut -d, -f8)
        local version_b_requests=$(echo "$stats" | grep "version-b-backend" | cut -d, -f8)
        
        # Calcular total y porcentajes
        local total_requests=$((version_a_requests + version_b_requests))
        local version_a_percentage=0
        local version_b_percentage=0
        
        if [ "$total_requests" -gt 0 ]; then
            version_a_percentage=$((version_a_requests * 100 / total_requests))
            version_b_percentage=$((version_b_requests * 100 / total_requests))
        fi
        
        echo -e "${CYAN}Peticiones A/B Testing:${NC}"
        echo -e "  Total: $total_requests peticiones"
        draw_progress_bar $version_a_percentage "Version A ($version_a_requests)"
        draw_progress_bar $version_b_percentage "Version B ($version_b_requests)"
        echo ""
    fi
    
    if [ "$mode" == "canary" ] || [ "$mode" == "all" ]; then
        # Extraer estadísticas para weblogic-features-a y weblogic-features-b
        local features_a_requests=$(echo "$stats" | grep "weblogic-features-a" | cut -d, -f8)
        local features_b_requests=$(echo "$stats" | grep "weblogic-features-b" | cut -d, -f8)
        
        # Calcular total y porcentajes
        local total_features_requests=$((features_a_requests + features_b_requests))
        local features_a_percentage=0
        local features_b_percentage=0
        
        if [ "$total_features_requests" -gt 0 ]; then
            features_a_percentage=$((features_a_requests * 100 / total_features_requests))
            features_b_percentage=$((features_b_requests * 100 / total_features_requests))
        fi
        
        echo -e "${CYAN}Peticiones Canary:${NC}"
        echo -e "  Total: $total_features_requests peticiones"
        draw_progress_bar $features_a_percentage "WebLogic A ($features_a_requests)"
        draw_progress_bar $features_b_percentage "WebLogic B ($features_b_requests)"
        echo ""
    fi
}

# Verificar argumentos
if [ $# -lt 1 ]; then
    show_help
    exit 0
fi

# Procesar argumentos
MODE=$1
INTERVAL=${2:-2}

# Verificar si se solicita ayuda
if [ "$MODE" == "help" ] || [ "$MODE" == "--help" ] || [ "$MODE" == "-h" ]; then
    show_help
    exit 0
fi

# Verificar modo válido
if [ "$MODE" != "ab" ] && [ "$MODE" != "canary" ] && [ "$MODE" != "all" ]; then
    echo -e "${RED}Error: Modo inválido '$MODE'${NC}"
    show_help
    exit 1
fi

# Verificar si el intervalo es válido
if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [ "$INTERVAL" -lt 1 ]; then
    echo -e "${RED}Error: El intervalo debe ser un número entero positivo${NC}"
    exit 1
fi

# Verificar si HAProxy está en ejecución
if ! docker ps | grep -q haproxy; then
    echo -e "${RED}Error: El contenedor HAProxy no está en ejecución${NC}"
    echo "Por favor, inicie el contenedor con:"
    echo "  docker-compose up -d haproxy"
    exit 1
fi

# Función para limpiar la pantalla y mostrar estadísticas
show_stats() {
    clear
    echo -e "${BLUE}=== Visualización de Tráfico entre Versiones ===${NC}"
    echo -e "Modo: $MODE | Intervalo: ${INTERVAL}s | $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "Presione ${RED}Ctrl+C${NC} para salir"
    echo ""
    
    get_traffic_stats "$MODE"
    get_request_stats "$MODE"
    
    echo -e "Para más detalles, visite: ${BLUE}http://localhost:8404/stats${NC}"
}

# Bucle principal
echo -e "${BLUE}Iniciando visualización de tráfico...${NC}"
echo -e "Presione ${RED}Ctrl+C${NC} para salir"

trap "echo -e '\n${YELLOW}Visualización detenida${NC}'; exit 0" INT

while true; do
    show_stats
    sleep $INTERVAL
done
