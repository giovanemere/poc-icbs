#!/bin/bash
# Script para verificar todas las URLs
# Actualizado para usar configuración centralizada

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Cargar variables de entorno
source "$PROJECT_ROOT/scripts/core/load-env.sh"
load_env

echo -e "${GREEN}=== Verificando URLs desde cada nodo y HAProxy ===${NC}"
echo ""

# URLs a verificar
URLS=(
    "/weblogic-features-a/"
    "/weblogic-features-b/"
    "/version-a/"
    "/version-b/"
    "/feature-flags/"
    "/ff4j-simple/"
    "/"
    "/console"
)

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Verificador de URLs ===${NC}"
    echo ""
    echo -e "${YELLOW}Uso: $0 [OPCIÓN]${NC}"
    echo ""
    echo -e "${BLUE}Opciones:${NC}"
    echo "  --help, -h          Mostrar esta ayuda"
    echo "  --quick             Verificación rápida (solo URLs principales)"
    echo "  --detailed          Verificación detallada con headers"
    echo "  --haproxy-only      Solo verificar HAProxy"
    echo "  --weblogic-only     Solo verificar WebLogic directo"
    echo ""
    echo -e "${BLUE}Configuración actual:${NC}"
    echo -e "  HAProxy: http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    echo -e "  WebLogic A: http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/"
    echo -e "  WebLogic B: http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/"
    echo ""
}

# Función para verificar una URL
check_url() {
    local base_url="$1"
    local path="$2"
    local service_name="$3"
    local timeout=5
    local show_details="${4:-false}"
    
    local full_url="${base_url}${path}"
    local temp_file=$(mktemp)
    
    # Usar curl con timeout para evitar esperas largas
    if curl -s -m "$timeout" -I "$full_url" > "$temp_file" 2>/dev/null; then
        local status_code=$(head -1 "$temp_file" | cut -d' ' -f2)
        local server_header=$(grep -i "server:" "$temp_file" 2>/dev/null | head -1 | cut -d' ' -f2- | tr -d '\r\n')
        
        case "$status_code" in
            200|302|301)
                echo -e "  ${GREEN}✓${NC} $service_name$path -> ${GREEN}$status_code${NC}"
                if [ "$show_details" = "true" ] && [ -n "$server_header" ]; then
                    echo -e "    Server: $server_header"
                fi
                ;;
            404)
                echo -e "  ${YELLOW}⚠${NC} $service_name$path -> ${YELLOW}$status_code (Not Found)${NC}"
                ;;
            *)
                echo -e "  ${RED}✗${NC} $service_name$path -> ${RED}$status_code${NC}"
                ;;
        esac
    else
        echo -e "  ${RED}✗${NC} $service_name$path -> ${RED}TIMEOUT/ERROR${NC}"
    fi
    
    rm -f "$temp_file"
}

# Función para verificar conectividad básica
check_basic_connectivity() {
    echo -e "${BLUE}=== Verificando Conectividad Básica ===${NC}"
    
    local services=(
        "HAProxy:http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}"
        "WebLogic-A:http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}"
        "WebLogic-B:http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}"
        "HAProxy-Stats:http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
        "HAProxy-Admin:http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}"
    )
    
    for service_url in "${services[@]}"; do
        local service_name=$(echo "$service_url" | cut -d':' -f1)
        local url=$(echo "$service_url" | cut -d':' -f2-)
        
        if curl -s -m 3 "$url" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $service_name está accesible"
        else
            echo -e "  ${RED}✗${NC} $service_name NO está accesible"
        fi
    done
    
    echo ""
}

# Función para verificación rápida
quick_check() {
    echo -e "${BLUE}=== Verificación Rápida ===${NC}"
    
    local quick_urls=("/" "/console")
    local base_urls=(
        "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}:HAProxy"
        "http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}:WebLogic-A"
        "http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}:WebLogic-B"
    )
    
    for base_url_info in "${base_urls[@]}"; do
        local base_url=$(echo "$base_url_info" | cut -d':' -f1-2)
        local service_name=$(echo "$base_url_info" | cut -d':' -f3)
        
        echo -e "${YELLOW}Verificando $service_name:${NC}"
        for path in "${quick_urls[@]}"; do
            check_url "$base_url" "$path" "$service_name"
        done
        echo ""
    done
}

# Función para verificación detallada
detailed_check() {
    echo -e "${BLUE}=== Verificación Detallada ===${NC}"
    
    local base_urls=(
        "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}:HAProxy"
        "http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}:WebLogic-A"
        "http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}:WebLogic-B"
    )
    
    for base_url_info in "${base_urls[@]}"; do
        local base_url=$(echo "$base_url_info" | cut -d':' -f1-2)
        local service_name=$(echo "$base_url_info" | cut -d':' -f3)
        
        echo -e "${YELLOW}Verificando $service_name:${NC}"
        for path in "${URLS[@]}"; do
            check_url "$base_url" "$path" "$service_name" "true"
        done
        echo ""
    done
}

# Función para verificar solo HAProxy
haproxy_only_check() {
    echo -e "${BLUE}=== Verificación Solo HAProxy ===${NC}"
    
    local haproxy_url="http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}"
    
    echo -e "${YELLOW}Verificando HAProxy Load Balancer:${NC}"
    for path in "${URLS[@]}"; do
        check_url "$haproxy_url" "$path" "HAProxy" "true"
    done
    
    echo ""
    echo -e "${YELLOW}Verificando servicios de HAProxy:${NC}"
    check_url "http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}" "/stats" "HAProxy-Stats"
    check_url "http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}" "/" "HAProxy-Admin"
    check_url "http://localhost:${HAPROXY_API_EXTERNAL_PORT:-8081}" "/api" "HAProxy-API"
    
    echo ""
}

# Función para verificar solo WebLogic
weblogic_only_check() {
    echo -e "${BLUE}=== Verificación Solo WebLogic ===${NC}"
    
    local weblogic_urls=(
        "http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}:WebLogic-A"
        "http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}:WebLogic-B"
    )
    
    for base_url_info in "${weblogic_urls[@]}"; do
        local base_url=$(echo "$base_url_info" | cut -d':' -f1-2)
        local service_name=$(echo "$base_url_info" | cut -d':' -f3)
        
        echo -e "${YELLOW}Verificando $service_name:${NC}"
        for path in "${URLS[@]}"; do
            check_url "$base_url" "$path" "$service_name" "true"
        done
        echo ""
    done
}

# Función para mostrar resumen de configuración
show_config_summary() {
    echo -e "${BLUE}=== Resumen de Configuración ===${NC}"
    echo ""
    echo -e "${YELLOW}Puertos configurados:${NC}"
    echo -e "  HAProxy HTTP:      ${HAPROXY_HTTP_EXTERNAL_PORT:-8083}"
    echo -e "  HAProxy HTTPS:     ${HAPROXY_HTTPS_EXTERNAL_PORT:-8444}"
    echo -e "  HAProxy Stats:     ${HAPROXY_STATS_EXTERNAL_PORT:-8404}"
    echo -e "  HAProxy API:       ${HAPROXY_API_EXTERNAL_PORT:-8081}"
    echo -e "  HAProxy Admin UI:  ${HAPROXY_UI_EXTERNAL_PORT:-8082}"
    echo -e "  WebLogic A:        ${WEBLOGIC_A_EXTERNAL_PORT:-7001}"
    echo -e "  WebLogic B:        ${WEBLOGIC_B_EXTERNAL_PORT:-7002}"
    echo ""
    echo -e "${YELLOW}URLs principales:${NC}"
    echo -e "  Load Balancer:     http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    echo -e "  HAProxy Stats:     http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
    echo -e "  HAProxy Admin UI:  http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}/"
    echo -e "  WebLogic A Console: http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/console"
    echo -e "  WebLogic B Console: http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/console"
    echo ""
}

# Función principal
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --quick)
            check_basic_connectivity
            quick_check
            show_config_summary
            ;;
        --detailed)
            check_basic_connectivity
            detailed_check
            show_config_summary
            ;;
        --haproxy-only)
            haproxy_only_check
            ;;
        --weblogic-only)
            weblogic_only_check
            ;;
        "")
            # Verificación estándar
            check_basic_connectivity
            detailed_check
            show_config_summary
            ;;
        *)
            echo -e "${RED}Opción no reconocida: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}=== Verificación de URLs completada ===${NC}"
    echo ""
    echo -e "${YELLOW}Para más información:${NC}"
    echo -e "  ./manage-services.sh status    # Ver estado de servicios"
    echo -e "  ./manage-services.sh logs      # Ver logs"
    echo ""
}

# Ejecutar función principal
main "$@"
