#!/bin/bash
# Script para gestionar el tráfico entre versiones A y B de WebLogic
# Actualizado para usar configuración centralizada
# Uso: ./manage-traffic.sh [canary|ab] [percentage]

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Cargar variables de entorno
source "$PROJECT_ROOT/scripts/core/load-env.sh"
load_env

MODE="$1"
PERCENTAGE="$2"

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Gestor de Tráfico HAProxy ===${NC}"
    echo ""
    echo -e "${YELLOW}Uso: $0 [MODO] [PORCENTAJE]${NC}"
    echo ""
    echo -e "${BLUE}Modos disponibles:${NC}"
    echo "  canary    Canary deployment (gradual rollout)"
    echo "  ab        A/B testing (split testing)"
    echo "  reset     Resetear a configuración por defecto (50/50)"
    echo ""
    echo -e "${BLUE}Ejemplos:${NC}"
    echo "  $0 canary 20    # Envía 20% del tráfico a la versión canary (B)"
    echo "  $0 ab 50        # Envía 50% del tráfico a la versión B para A/B testing"
    echo "  $0 reset        # Resetea a distribución 50/50"
    echo ""
    echo -e "${BLUE}Configuración actual:${NC}"
    echo -e "  HAProxy API: http://localhost:${HAPROXY_API_EXTERNAL_PORT:-8081}/api"
    echo -e "  HAProxy Stats: http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
    echo -e "  HAProxy Admin UI: http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}/"
    echo ""
}

# Validar parámetros
validate_parameters() {
    if [ -z "$MODE" ]; then
        echo -e "${RED}Error: Debe especificar un modo${NC}"
        show_help
        exit 1
    fi
    
    if [ "$MODE" != "reset" ] && [ -z "$PERCENTAGE" ]; then
        echo -e "${RED}Error: Debe especificar un porcentaje${NC}"
        show_help
        exit 1
    fi
    
    if [ "$MODE" != "reset" ] && ! [[ "$PERCENTAGE" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: El porcentaje debe ser un número${NC}"
        exit 1
    fi
    
    if [ "$MODE" != "reset" ] && ([ "$PERCENTAGE" -lt 0 ] || [ "$PERCENTAGE" -gt 100 ]); then
        echo -e "${RED}Error: El porcentaje debe estar entre 0 y 100${NC}"
        exit 1
    fi
    
    if [ "$MODE" != "canary" ] && [ "$MODE" != "ab" ] && [ "$MODE" != "reset" ]; then
        echo -e "${RED}Error: Modo no válido. Use 'canary', 'ab' o 'reset'${NC}"
        show_help
        exit 1
    fi
}

# Verificar que HAProxy esté ejecutándose
check_haproxy() {
    echo -e "${BLUE}=== Verificando HAProxy ===${NC}"
    
    if ! docker ps | grep -q haproxy; then
        echo -e "${RED}Error: HAProxy no está ejecutándose${NC}"
        echo "Por favor, inicie los servicios con:"
        echo -e "${YELLOW}  ./manage-services.sh start${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}HAProxy está ejecutándose correctamente${NC}"
    echo ""
}

# Función para actualizar la configuración de HAProxy
update_haproxy_config() {
    local mode="$1"
    local percentage="$2"
    local config_file="$PROJECT_ROOT/haproxy/config/haproxy.cfg"
    local temp_file=$(mktemp)
    
    echo -e "${BLUE}=== Actualizando configuración de HAProxy ===${NC}"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: Archivo de configuración no encontrado: $config_file${NC}"
        exit 1
    fi
    
    # Hacer una copia del archivo de configuración
    cp "$config_file" "$temp_file"
    
    # Calcular pesos según el modo y porcentaje
    local weight_a weight_b
    
    case "$mode" in
        "canary")
            # En canary, A es la versión estable, B es la canary
            weight_a=$((100 - percentage))
            weight_b=$percentage
            echo -e "${YELLOW}Configurando Canary Deployment: ${weight_a}% estable (A), ${weight_b}% canary (B)${NC}"
            ;;
        "ab")
            # En A/B testing, distribución específica
            weight_a=$((100 - percentage))
            weight_b=$percentage
            echo -e "${YELLOW}Configurando A/B Testing: ${weight_a}% versión A, ${weight_b}% versión B${NC}"
            ;;
        "reset")
            # Resetear a 50/50
            weight_a=50
            weight_b=50
            echo -e "${YELLOW}Reseteando a distribución 50/50${NC}"
            ;;
    esac
    
    # Actualizar pesos en la configuración
    sed -i "s/server weblogic-a .* weight [0-9]*/server weblogic-a weblogic-a:7001 check weight $weight_a/" "$temp_file"
    sed -i "s/server weblogic-b .* weight [0-9]*/server weblogic-b weblogic-b:7001 check weight $weight_b/" "$temp_file"
    
    # Verificar que los cambios se aplicaron
    if grep -q "weight $weight_a" "$temp_file" && grep -q "weight $weight_b" "$temp_file"; then
        # Aplicar la nueva configuración
        cp "$temp_file" "$config_file"
        echo -e "${GREEN}Configuración actualizada correctamente${NC}"
    else
        echo -e "${RED}Error: No se pudieron aplicar los cambios de configuración${NC}"
        rm -f "$temp_file"
        exit 1
    fi
    
    rm -f "$temp_file"
}

# Función para recargar HAProxy
reload_haproxy() {
    echo -e "${BLUE}=== Recargando HAProxy ===${NC}"
    
    # Verificar configuración antes de recargar
    echo -e "${YELLOW}Verificando configuración...${NC}"
    if ! docker exec haproxy haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg; then
        echo -e "${RED}Error: Configuración de HAProxy no válida${NC}"
        exit 1
    fi
    
    # Recargar HAProxy sin interrumpir conexiones existentes
    echo -e "${YELLOW}Recargando HAProxy...${NC}"
    if docker exec haproxy bash -c "haproxy -sf \$(pidof haproxy) -f /usr/local/etc/haproxy/haproxy.cfg"; then
        echo -e "${GREEN}HAProxy recargado correctamente${NC}"
    else
        echo -e "${RED}Error: No se pudo recargar HAProxy${NC}"
        exit 1
    fi
    
    echo ""
}

# Función para verificar el estado actual
show_current_status() {
    echo -e "${BLUE}=== Estado Actual del Tráfico ===${NC}"
    
    # Obtener estadísticas de HAProxy
    echo -e "${YELLOW}Obteniendo estadísticas de HAProxy...${NC}"
    
    if command -v curl >/dev/null 2>&1; then
        # Intentar obtener estadísticas via API
        if curl -s "http://localhost:${HAPROXY_API_EXTERNAL_PORT:-8081}/api/stats" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ API de HAProxy disponible${NC}"
        else
            echo -e "${YELLOW}API de HAProxy no disponible, usando stats básicas${NC}"
        fi
        
        # Mostrar estado de servidores
        echo -e "${YELLOW}Estado de servidores backend:${NC}"
        if curl -s "http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats;csv" 2>/dev/null | grep -E "weblogic-[ab]" | while IFS=',' read -r pxname svname qcur qmax scur smax slim stot bin bout dreq dresp ereq econ eresp wretr wredis status weight act bck chkfail chkdown lastchg downtime qlimit pid iid sid throttle lbtot tracked type rate rate_lim rate_max check_status check_code check_duration hrsp_1xx hrsp_2xx hrsp_3xx hrsp_4xx hrsp_5xx hrsp_other hanafail req_rate req_rate_max req_tot cli_abrt srv_abrt comp_in comp_out comp_byp comp_rsp lastsess last_chk last_agt qtime ctime rtime ttime; do
            if [ "$svname" != "BACKEND" ] && [ "$svname" != "FRONTEND" ]; then
                echo -e "  ${GREEN}$svname${NC}: Status=$status, Weight=$weight"
            fi
        done; then
            :
        else
            echo -e "${YELLOW}No se pudieron obtener estadísticas detalladas${NC}"
        fi
    else
        echo -e "${YELLOW}curl no disponible, no se pueden mostrar estadísticas${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}URLs de monitoreo:${NC}"
    echo -e "  HAProxy Stats: http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
    echo -e "  HAProxy Admin UI: http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}/"
    echo -e "  Load Balancer: http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    echo ""
}

# Función para probar la configuración
test_configuration() {
    echo -e "${BLUE}=== Probando Configuración ===${NC}"
    
    if command -v curl >/dev/null 2>&1; then
        echo -e "${YELLOW}Probando conectividad...${NC}"
        
        # Probar HAProxy
        if curl -s "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/" > /dev/null; then
            echo -e "${GREEN}✓ HAProxy responde correctamente${NC}"
        else
            echo -e "${RED}✗ HAProxy no responde${NC}"
        fi
        
        # Probar WebLogic A directamente
        if curl -s "http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/" > /dev/null; then
            echo -e "${GREEN}✓ WebLogic A responde correctamente${NC}"
        else
            echo -e "${YELLOW}⚠ WebLogic A no responde (puede ser normal)${NC}"
        fi
        
        # Probar WebLogic B directamente
        if curl -s "http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/" > /dev/null; then
            echo -e "${GREEN}✓ WebLogic B responde correctamente${NC}"
        else
            echo -e "${YELLOW}⚠ WebLogic B no responde (puede ser normal)${NC}"
        fi
    else
        echo -e "${YELLOW}curl no disponible, omitiendo pruebas de conectividad${NC}"
    fi
    
    echo ""
}

# Función principal
main() {
    echo -e "${GREEN}=== Gestor de Tráfico HAProxy ===${NC}"
    echo ""
    
    # Validar parámetros
    validate_parameters
    
    # Verificar HAProxy
    check_haproxy
    
    # Procesar según el modo
    case "$MODE" in
        "reset")
            update_haproxy_config "reset"
            reload_haproxy
            ;;
        *)
            update_haproxy_config "$MODE" "$PERCENTAGE"
            reload_haproxy
            ;;
    esac
    
    # Mostrar estado actual
    show_current_status
    
    # Probar configuración
    test_configuration
    
    echo -e "${GREEN}=== Gestión de tráfico completada ===${NC}"
    echo ""
    echo -e "${YELLOW}Recomendaciones:${NC}"
    echo -e "  1. Monitorear tráfico: http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
    echo -e "  2. Simular tráfico: ./scripts/canary/simulate-traffic.sh 100 0.5"
    echo -e "  3. Ver logs: ./manage-services.sh logs haproxy"
    echo ""
}

# Manejar caso especial de ayuda
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# Ejecutar función principal
main
