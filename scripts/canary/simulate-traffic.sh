#!/bin/bash
# Script para simular tráfico a los servidores WebLogic
# Actualizado para usar configuración centralizada
# Uso: ./simulate-traffic.sh [requests] [interval]

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

REQUESTS="${1:-100}"
INTERVAL="${2:-0.5}"

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Simulador de Tráfico ===${NC}"
    echo ""
    echo -e "${YELLOW}Uso: $0 [SOLICITUDES] [INTERVALO]${NC}"
    echo ""
    echo -e "${BLUE}Parámetros:${NC}"
    echo "  SOLICITUDES    Número de solicitudes a enviar (por defecto: 100)"
    echo "  INTERVALO      Intervalo entre solicitudes en segundos (por defecto: 0.5)"
    echo ""
    echo -e "${BLUE}Ejemplos:${NC}"
    echo "  $0                    # 100 solicitudes con intervalo de 0.5s"
    echo "  $0 50                 # 50 solicitudes con intervalo de 0.5s"
    echo "  $0 200 1.0            # 200 solicitudes con intervalo de 1s"
    echo "  $0 10 0.1             # 10 solicitudes rápidas con intervalo de 0.1s"
    echo ""
    echo -e "${BLUE}Configuración actual:${NC}"
    echo -e "  HAProxy URL: http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    echo -e "  HAProxy Stats: http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
    echo ""
}

# Validar parámetros
validate_parameters() {
    if ! [[ "$REQUESTS" =~ ^[0-9]+$ ]] || [ "$REQUESTS" -le 0 ]; then
        echo -e "${RED}Error: El número de solicitudes debe ser un entero positivo${NC}"
        exit 1
    fi
    
    if ! [[ "$INTERVAL" =~ ^[0-9]+\.?[0-9]*$ ]] || (( $(echo "$INTERVAL <= 0" | bc -l) )); then
        echo -e "${RED}Error: El intervalo debe ser un número positivo${NC}"
        exit 1
    fi
    
    if [ "$REQUESTS" -gt 10000 ]; then
        echo -e "${YELLOW}Advertencia: Número alto de solicitudes ($REQUESTS)${NC}"
        echo -e "${YELLOW}¿Continuar? (y/N):${NC}"
        read -r response
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
            echo -e "${YELLOW}Operación cancelada${NC}"
            exit 0
        fi
    fi
}

# Verificar dependencias
check_dependencies() {
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}Error: curl no está instalado${NC}"
        echo "Por favor, instale curl para usar este script"
        exit 1
    fi
    
    if ! command -v bc >/dev/null 2>&1; then
        echo -e "${YELLOW}Advertencia: bc no está instalado, algunas validaciones pueden fallar${NC}"
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
    
    # Probar conectividad
    if ! curl -s "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/" > /dev/null; then
        echo -e "${RED}Error: HAProxy no responde en el puerto ${HAPROXY_HTTP_EXTERNAL_PORT:-8083}${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}HAProxy está ejecutándose y responde correctamente${NC}"
    echo ""
}

# Función para enviar una solicitud y analizar la respuesta
send_request() {
    local request_type="$1"
    local request_number="$2"
    local extra_args="$3"
    
    local haproxy_url="http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    local response_file=$(mktemp)
    
    # Enviar solicitud y capturar respuesta
    if curl -s -I $extra_args "$haproxy_url" > "$response_file" 2>/dev/null; then
        # Analizar respuesta
        local server_header=$(grep -i "server:" "$response_file" | head -1 | cut -d' ' -f2- | tr -d '\r\n')
        local cookie_header=$(grep -i "set-cookie:" "$response_file" | head -1 | cut -d' ' -f2- | tr -d '\r\n')
        local status_code=$(head -1 "$response_file" | cut -d' ' -f2)
        
        # Determinar qué servidor respondió basándose en indicadores
        local server_indicator="Unknown"
        if echo "$server_header" | grep -qi "weblogic-a"; then
            server_indicator="WebLogic-A"
        elif echo "$server_header" | grep -qi "weblogic-b"; then
            server_indicator="WebLogic-B"
        elif echo "$cookie_header" | grep -qi "server=a"; then
            server_indicator="WebLogic-A"
        elif echo "$cookie_header" | grep -qi "server=b"; then
            server_indicator="WebLogic-B"
        fi
        
        echo -e "${GREEN}[$request_number/$REQUESTS]${NC} $request_type: ${BLUE}$status_code${NC} -> ${YELLOW}$server_indicator${NC}"
        
        # Mostrar detalles adicionales si es necesario
        if [ "$request_number" -le 5 ] || [ $((request_number % 50)) -eq 0 ]; then
            if [ -n "$cookie_header" ]; then
                echo -e "    Cookie: $cookie_header"
            fi
        fi
    else
        echo -e "${RED}[$request_number/$REQUESTS]${NC} $request_type: ${RED}FAILED${NC}"
    fi
    
    rm -f "$response_file"
}

# Función para enviar solicitudes
send_requests() {
    echo -e "${BLUE}=== Iniciando Simulación de Tráfico ===${NC}"
    echo -e "${YELLOW}Solicitudes: $REQUESTS${NC}"
    echo -e "${YELLOW}Intervalo: $INTERVAL segundos${NC}"
    echo -e "${YELLOW}URL objetivo: http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/${NC}"
    echo ""
    
    local start_time=$(date +%s)
    local success_count=0
    local error_count=0
    
    for ((i=1; i<=REQUESTS; i++)); do
        # Solicitud normal (debería seguir la distribución de pesos configurada)
        if send_request "Normal" "$i" ""; then
            ((success_count++))
        else
            ((error_count++))
        fi
        
        # Cada 10 solicitudes, enviar diferentes tipos de solicitudes
        if [ $((i % 10)) -eq 0 ]; then
            # Solicitud con cabecera canary
            send_request "Canary-Header" "$i" "-H 'X-Canary: true'"
            
            # Solicitud con cookie canary
            send_request "Canary-Cookie" "$i" "--cookie 'canary=true'"
            
            # Solicitud con cookie A/B testing
            send_request "AB-Test" "$i" "--cookie 'ab_test=B'"
            
            # Solicitud a una ruta específica
            send_request "Feature-Path" "$i" "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/feature/test"
        fi
        
        # Mostrar progreso cada 25 solicitudes
        if [ $((i % 25)) -eq 0 ]; then
            local elapsed=$(($(date +%s) - start_time))
            local rate=$(echo "scale=2; $i / $elapsed" | bc -l 2>/dev/null || echo "N/A")
            echo -e "${BLUE}Progreso: $i/$REQUESTS (${rate} req/s)${NC}"
        fi
        
        sleep "$INTERVAL"
    done
    
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    local avg_rate=$(echo "scale=2; $REQUESTS / $total_time" | bc -l 2>/dev/null || echo "N/A")
    
    echo ""
    echo -e "${GREEN}=== Simulación Completada ===${NC}"
    echo -e "${YELLOW}Estadísticas:${NC}"
    echo -e "  Total de solicitudes: $REQUESTS"
    echo -e "  Tiempo total: ${total_time}s"
    echo -e "  Tasa promedio: ${avg_rate} req/s"
    echo -e "  Exitosas: $success_count"
    echo -e "  Errores: $error_count"
    echo ""
}

# Función para mostrar estadísticas de HAProxy después de la simulación
show_haproxy_stats() {
    echo -e "${BLUE}=== Estadísticas de HAProxy ===${NC}"
    
    if command -v curl >/dev/null 2>&1; then
        echo -e "${YELLOW}Obteniendo estadísticas actuales...${NC}"
        
        # Intentar obtener estadísticas CSV
        if curl -s "http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats;csv" 2>/dev/null | grep -E "weblogic-[ab]" | while IFS=',' read -r pxname svname qcur qmax scur smax slim stot bin bout dreq dresp ereq econ eresp wretr wredis status weight act bck chkfail chkdown lastchg downtime qlimit pid iid sid throttle lbtot tracked type rate rate_lim rate_max check_status check_code check_duration hrsp_1xx hrsp_2xx hrsp_3xx hrsp_4xx hrsp_5xx hrsp_other hanafail req_rate req_rate_max req_tot cli_abrt srv_abrt comp_in comp_out comp_byp comp_rsp lastsess last_chk last_agt qtime ctime rtime ttime; do
            if [ "$svname" != "BACKEND" ] && [ "$svname" != "FRONTEND" ]; then
                echo -e "  ${GREEN}$svname${NC}:"
                echo -e "    Status: $status"
                echo -e "    Weight: $weight"
                echo -e "    Total requests: $stot"
                echo -e "    Current sessions: $scur"
                echo -e "    Bytes in/out: $bin/$bout"
            fi
        done; then
            :
        else
            echo -e "${YELLOW}No se pudieron obtener estadísticas detalladas${NC}"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}URLs para monitoreo continuo:${NC}"
    echo -e "  HAProxy Stats: http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
    echo -e "  HAProxy Admin UI: http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}/"
    echo ""
}

# Función principal
main() {
    echo -e "${GREEN}=== Simulador de Tráfico HAProxy ===${NC}"
    echo ""
    
    # Validar parámetros
    validate_parameters
    
    # Verificar dependencias
    check_dependencies
    
    # Verificar HAProxy
    check_haproxy
    
    # Enviar solicitudes
    send_requests
    
    # Mostrar estadísticas finales
    show_haproxy_stats
    
    echo -e "${GREEN}=== Simulación finalizada ===${NC}"
    echo ""
    echo -e "${YELLOW}Recomendaciones:${NC}"
    echo -e "  1. Revisar estadísticas: http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
    echo -e "  2. Ajustar tráfico: ./scripts/canary/manage-traffic.sh canary [percentage]"
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
