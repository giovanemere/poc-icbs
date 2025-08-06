#!/bin/bash
# Script para probar el despliegue canary
# Actualizado para usar configuración centralizada

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

NUM_REQUESTS="${1:-100}"

echo -e "${GREEN}=== Prueba de despliegue canary ===${NC}"
echo ""

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Tester de Canary Deployment ===${NC}"
    echo ""
    echo -e "${YELLOW}Uso: $0 [NUM_REQUESTS]${NC}"
    echo ""
    echo -e "${BLUE}Parámetros:${NC}"
    echo "  NUM_REQUESTS    Número de peticiones de prueba (por defecto: 100)"
    echo ""
    echo -e "${BLUE}Ejemplos:${NC}"
    echo "  $0              # 100 peticiones de prueba"
    echo "  $0 50           # 50 peticiones de prueba"
    echo "  $0 500          # 500 peticiones de prueba"
    echo ""
    echo -e "${BLUE}Configuración actual:${NC}"
    echo -e "  HAProxy URL: http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    echo -e "  WebLogic A: http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/"
    echo -e "  WebLogic B: http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/"
    echo ""
}

# Validar parámetros
validate_parameters() {
    if ! [[ "$NUM_REQUESTS" =~ ^[0-9]+$ ]] || [ "$NUM_REQUESTS" -le 0 ]; then
        echo -e "${RED}Error: El número de peticiones debe ser un número positivo${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Usando el número de peticiones: $NUM_REQUESTS${NC}"
    echo ""
}

# Verificar dependencias
check_dependencies() {
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}Error: curl no está instalado${NC}"
        echo "Por favor, instale curl para usar este script"
        exit 1
    fi
}

# Verificar que los contenedores estén ejecutándose
check_containers() {
    echo -e "${BLUE}=== Verificando contenedores ===${NC}"
    
    local containers_ok=true
    
    if ! docker ps | grep -q weblogic-a; then
        echo -e "${RED}✗ weblogic-a no está ejecutándose${NC}"
        containers_ok=false
    else
        echo -e "${GREEN}✓ weblogic-a está ejecutándose${NC}"
    fi
    
    if ! docker ps | grep -q weblogic-b; then
        echo -e "${RED}✗ weblogic-b no está ejecutándose${NC}"
        containers_ok=false
    else
        echo -e "${GREEN}✓ weblogic-b está ejecutándose${NC}"
    fi
    
    if ! docker ps | grep -q haproxy; then
        echo -e "${RED}✗ haproxy no está ejecutándose${NC}"
        containers_ok=false
    else
        echo -e "${GREEN}✓ haproxy está ejecutándose${NC}"
    fi
    
    if [ "$containers_ok" = false ]; then
        echo ""
        echo -e "${RED}Error: Algunos contenedores no están ejecutándose${NC}"
        echo "Por favor, inicie los contenedores con:"
        echo -e "${YELLOW}  ./manage-services.sh start${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Todos los contenedores están ejecutándose correctamente${NC}"
    echo ""
}

# Verificar conectividad básica
check_connectivity() {
    echo -e "${BLUE}=== Verificando conectividad ===${NC}"
    
    local connectivity_ok=true
    
    # Probar HAProxy
    if curl -s "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/" > /dev/null; then
        echo -e "${GREEN}✓ HAProxy responde correctamente${NC}"
    else
        echo -e "${RED}✗ HAProxy no responde${NC}"
        connectivity_ok=false
    fi
    
    # Probar WebLogic A
    if curl -s "http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/" > /dev/null; then
        echo -e "${GREEN}✓ WebLogic A responde correctamente${NC}"
    else
        echo -e "${YELLOW}⚠ WebLogic A no responde (puede ser normal si no hay aplicaciones desplegadas)${NC}"
    fi
    
    # Probar WebLogic B
    if curl -s "http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/" > /dev/null; then
        echo -e "${GREEN}✓ WebLogic B responde correctamente${NC}"
    else
        echo -e "${YELLOW}⚠ WebLogic B no responde (puede ser normal si no hay aplicaciones desplegadas)${NC}"
    fi
    
    if [ "$connectivity_ok" = false ]; then
        echo ""
        echo -e "${RED}Error: Problemas de conectividad detectados${NC}"
        exit 1
    fi
    
    echo ""
}

# Función para ejecutar pruebas de canary
run_canary_tests() {
    echo -e "${BLUE}=== Ejecutando Pruebas de Canary ===${NC}"
    echo ""
    
    local haproxy_url="http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    local total_requests=0
    local successful_requests=0
    local version_a_count=0
    local version_b_count=0
    local canary_requests=0
    local ab_test_requests=0
    
    echo -e "${YELLOW}Enviando $NUM_REQUESTS peticiones de prueba...${NC}"
    echo ""
    
    for ((i=1; i<=NUM_REQUESTS; i++)); do
        ((total_requests++))
        
        # Determinar tipo de petición
        local request_type="normal"
        local extra_args=""
        
        # Cada 5 peticiones, enviar una petición canary
        if [ $((i % 5)) -eq 0 ]; then
            request_type="canary"
            extra_args="-H 'X-Canary: true'"
            ((canary_requests++))
        # Cada 7 peticiones, enviar una petición A/B test
        elif [ $((i % 7)) -eq 0 ]; then
            request_type="ab_test"
            extra_args="--cookie 'ab_test=B'"
            ((ab_test_requests++))
        fi
        
        # Enviar petición y analizar respuesta
        local response_file=$(mktemp)
        if eval "curl -s -I $extra_args '$haproxy_url'" > "$response_file" 2>/dev/null; then
            ((successful_requests++))
            
            # Analizar qué servidor respondió
            local server_header=$(grep -i "server:" "$response_file" 2>/dev/null | head -1 | cut -d' ' -f2- | tr -d '\r\n')
            local cookie_header=$(grep -i "set-cookie:" "$response_file" 2>/dev/null | head -1 | cut -d' ' -f2- | tr -d '\r\n')
            
            # Determinar versión basándose en indicadores
            if echo "$server_header $cookie_header" | grep -qi "weblogic-a\|server=a"; then
                ((version_a_count++))
                local version="A"
            elif echo "$server_header $cookie_header" | grep -qi "weblogic-b\|server=b"; then
                ((version_b_count++))
                local version="B"
            else
                local version="Unknown"
            fi
            
            # Mostrar progreso cada 20 peticiones o para peticiones especiales
            if [ $((i % 20)) -eq 0 ] || [ "$request_type" != "normal" ]; then
                echo -e "${GREEN}[$i/$NUM_REQUESTS]${NC} $request_type -> Versión $version"
            fi
        else
            echo -e "${RED}[$i/$NUM_REQUESTS]${NC} $request_type -> ERROR"
        fi
        
        rm -f "$response_file"
        
        # Pequeña pausa entre peticiones
        sleep 0.1
    done
    
    echo ""
    echo -e "${GREEN}=== Resultados de las Pruebas ===${NC}"
    echo -e "${YELLOW}Estadísticas generales:${NC}"
    echo -e "  Total de peticiones: $total_requests"
    echo -e "  Peticiones exitosas: $successful_requests"
    echo -e "  Tasa de éxito: $(echo "scale=2; $successful_requests * 100 / $total_requests" | bc -l 2>/dev/null || echo "N/A")%"
    echo ""
    echo -e "${YELLOW}Distribución de tráfico:${NC}"
    echo -e "  Versión A (estable): $version_a_count peticiones ($(echo "scale=2; $version_a_count * 100 / $successful_requests" | bc -l 2>/dev/null || echo "N/A")%)"
    echo -e "  Versión B (canary): $version_b_count peticiones ($(echo "scale=2; $version_b_count * 100 / $successful_requests" | bc -l 2>/dev/null || echo "N/A")%)"
    echo ""
    echo -e "${YELLOW}Tipos de peticiones:${NC}"
    echo -e "  Peticiones normales: $((total_requests - canary_requests - ab_test_requests))"
    echo -e "  Peticiones canary: $canary_requests"
    echo -e "  Peticiones A/B test: $ab_test_requests"
    echo ""
}

# Función para obtener estadísticas de HAProxy
get_haproxy_stats() {
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
                echo -e "    Response times: ${rtime}ms"
            fi
        done; then
            :
        else
            echo -e "${YELLOW}No se pudieron obtener estadísticas detalladas${NC}"
        fi
    fi
    
    echo ""
}

# Función para mostrar recomendaciones
show_recommendations() {
    echo -e "${BLUE}=== Recomendaciones ===${NC}"
    echo ""
    echo -e "${YELLOW}Para ajustar el tráfico canary:${NC}"
    echo -e "  ./scripts/canary/manage-traffic.sh canary 10   # 10% canary"
    echo -e "  ./scripts/canary/manage-traffic.sh canary 25   # 25% canary"
    echo -e "  ./scripts/canary/manage-traffic.sh canary 50   # 50% canary"
    echo -e "  ./scripts/canary/manage-traffic.sh reset       # Reset a 50/50"
    echo ""
    echo -e "${YELLOW}Para monitoreo continuo:${NC}"
    echo -e "  HAProxy Stats: http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
    echo -e "  HAProxy Admin UI: http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}/"
    echo -e "  ./manage-services.sh logs haproxy"
    echo ""
    echo -e "${YELLOW}Para más pruebas:${NC}"
    echo -e "  ./scripts/canary/simulate-traffic.sh 200 0.5   # Simulación extendida"
    echo -e "  $0 500                                          # Más peticiones de prueba"
    echo ""
}

# Función principal
main() {
    # Validar parámetros
    validate_parameters
    
    # Verificar dependencias
    check_dependencies
    
    # Verificar contenedores
    check_containers
    
    # Verificar conectividad
    check_connectivity
    
    # Ejecutar pruebas
    run_canary_tests
    
    # Obtener estadísticas
    get_haproxy_stats
    
    # Mostrar recomendaciones
    show_recommendations
    
    echo -e "${GREEN}=== Pruebas de Canary Completadas ===${NC}"
}

# Manejar caso especial de ayuda
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# Ejecutar función principal
main
