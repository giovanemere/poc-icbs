#!/bin/bash
# Script para controlar las configuraciones de A/B testing y Canary deployment

# Configuración
API_HOST="localhost"
API_PORT="8081"
API_URL="http://${API_HOST}:${API_PORT}/api"

# Colores para la salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}Control de A/B Testing y Canary Deployment${NC}"
    echo ""
    echo "Uso: $0 [comando] [opciones]"
    echo ""
    echo "Comandos:"
    echo "  status                    Muestra el estado actual de la configuración"
    echo "  ab [opciones]             Configura el A/B testing"
    echo "  canary [opciones]         Configura el Canary deployment"
    echo "  weight [backend] [server] [peso]  Configura el peso de un servidor"
    echo "  help                      Muestra esta ayuda"
    echo ""
    echo "Opciones para ab:"
    echo "  --enable                  Habilita el A/B testing"
    echo "  --disable                 Deshabilita el A/B testing"
    echo "  --weight-a [0-100]        Porcentaje de tráfico para la versión A"
    echo ""
    echo "Opciones para canary:"
    echo "  --enable                  Habilita el Canary deployment"
    echo "  --disable                 Deshabilita el Canary deployment"
    echo "  --percentage [0-100]      Porcentaje de tráfico para la versión Canary"
    echo ""
    echo "Ejemplos:"
    echo "  $0 status"
    echo "  $0 ab --enable --weight-a 70"
    echo "  $0 canary --enable --percentage 20"
    echo "  $0 weight weblogic-features-a weblogic-a-features 100"
    echo ""
}

# Función para verificar si curl está instalado
check_curl() {
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Error: curl no está instalado. Por favor, instálalo para usar este script.${NC}"
        exit 1
    fi
}

# Función para verificar si jq está instalado
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq no está instalado. Por favor, instálalo para usar este script.${NC}"
        exit 1
    fi
}

# Función para mostrar el estado actual
show_status() {
    echo -e "${BLUE}Obteniendo estado actual...${NC}"
    
    # Obtener la configuración actual
    response=$(curl -s "${API_URL}/config")
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: No se pudo conectar con la API de administración.${NC}"
        echo "Asegúrate de que HAProxy esté en ejecución y la API esté disponible en ${API_URL}"
        exit 1
    fi
    
    # Mostrar la configuración de A/B testing
    ab_enabled=$(echo $response | jq -r '.ab_testing.enabled')
    ab_weight_a=$(echo $response | jq -r '.ab_testing.version_a_weight')
    ab_weight_b=$(echo $response | jq -r '.ab_testing.version_b_weight')
    
    echo -e "${YELLOW}A/B Testing:${NC}"
    if [ "$ab_enabled" = "true" ]; then
        echo -e "  Estado: ${GREEN}Habilitado${NC}"
    else
        echo -e "  Estado: ${RED}Deshabilitado${NC}"
    fi
    echo "  Peso versión A: ${ab_weight_a}%"
    echo "  Peso versión B: ${ab_weight_b}%"
    
    # Mostrar la configuración de Canary deployment
    canary_enabled=$(echo $response | jq -r '.canary.enabled')
    canary_percentage=$(echo $response | jq -r '.canary.percentage')
    
    echo -e "${YELLOW}Canary Deployment:${NC}"
    if [ "$canary_enabled" = "true" ]; then
        echo -e "  Estado: ${GREEN}Habilitado${NC}"
    else
        echo -e "  Estado: ${RED}Deshabilitado${NC}"
    fi
    echo "  Porcentaje Canary: ${canary_percentage}%"
    
    # Obtener estadísticas de los backends
    echo -e "\n${YELLOW}Estadísticas de backends:${NC}"
    curl -s "${API_URL}/stats" | jq -r '.[] | select(.svname != "BACKEND") | "\(.pxname) - \(.svname): \(.status) (\(.weight))"'
}

# Función para configurar el A/B testing
configure_ab() {
    local enable=""
    local weight_a=""
    
    # Procesar opciones
    while [[ $# -gt 0 ]]; do
        case $1 in
            --enable)
                enable="true"
                shift
                ;;
            --disable)
                enable="false"
                shift
                ;;
            --weight-a)
                weight_a="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Error: Opción desconocida: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Construir el payload JSON
    local payload="{"
    local has_payload=false
    
    if [ -n "$enable" ]; then
        payload="${payload}\"enabled\":${enable}"
        has_payload=true
    fi
    
    if [ -n "$weight_a" ]; then
        if [ $has_payload = true ]; then
            payload="${payload},"
        fi
        payload="${payload}\"weight_a\":${weight_a}"
        has_payload=true
    fi
    
    payload="${payload}}"
    
    # Si no hay opciones, mostrar ayuda
    if [ $has_payload = false ]; then
        echo -e "${RED}Error: No se especificaron opciones para A/B testing.${NC}"
        show_help
        exit 1
    fi
    
    # Enviar la configuración
    echo -e "${BLUE}Configurando A/B testing...${NC}"
    response=$(curl -s -X POST -H "Content-Type: application/json" -d "${payload}" "${API_URL}/config/ab")
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: No se pudo conectar con la API de administración.${NC}"
        exit 1
    fi
    
    # Mostrar el resultado
    status=$(echo $response | jq -r '.status')
    
    if [ "$status" = "success" ]; then
        echo -e "${GREEN}A/B testing configurado correctamente.${NC}"
        
        # Mostrar la nueva configuración
        ab_enabled=$(echo $response | jq -r '.config.enabled')
        ab_weight_a=$(echo $response | jq -r '.config.version_a_weight')
        ab_weight_b=$(echo $response | jq -r '.config.version_b_weight')
        
        echo -e "${YELLOW}Nueva configuración:${NC}"
        if [ "$ab_enabled" = "true" ]; then
            echo -e "  Estado: ${GREEN}Habilitado${NC}"
        else
            echo -e "  Estado: ${RED}Deshabilitado${NC}"
        fi
        echo "  Peso versión A: ${ab_weight_a}%"
        echo "  Peso versión B: ${ab_weight_b}%"
    else
        echo -e "${RED}Error al configurar A/B testing:${NC}"
        echo $response | jq -r '.error'
    fi
}

# Función para configurar el Canary deployment
configure_canary() {
    local enable=""
    local percentage=""
    
    # Procesar opciones
    while [[ $# -gt 0 ]]; do
        case $1 in
            --enable)
                enable="true"
                shift
                ;;
            --disable)
                enable="false"
                shift
                ;;
            --percentage)
                percentage="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Error: Opción desconocida: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Construir el payload JSON
    local payload="{"
    local has_payload=false
    
    if [ -n "$enable" ]; then
        payload="${payload}\"enabled\":${enable}"
        has_payload=true
    fi
    
    if [ -n "$percentage" ]; then
        if [ $has_payload = true ]; then
            payload="${payload},"
        fi
        payload="${payload}\"percentage\":${percentage}"
        has_payload=true
    fi
    
    payload="${payload}}"
    
    # Si no hay opciones, mostrar ayuda
    if [ $has_payload = false ]; then
        echo -e "${RED}Error: No se especificaron opciones para Canary deployment.${NC}"
        show_help
        exit 1
    fi
    
    # Enviar la configuración
    echo -e "${BLUE}Configurando Canary deployment...${NC}"
    response=$(curl -s -X POST -H "Content-Type: application/json" -d "${payload}" "${API_URL}/config/canary")
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: No se pudo conectar con la API de administración.${NC}"
        exit 1
    fi
    
    # Mostrar el resultado
    status=$(echo $response | jq -r '.status')
    
    if [ "$status" = "success" ]; then
        echo -e "${GREEN}Canary deployment configurado correctamente.${NC}"
        
        # Mostrar la nueva configuración
        canary_enabled=$(echo $response | jq -r '.config.enabled')
        canary_percentage=$(echo $response | jq -r '.config.percentage')
        
        echo -e "${YELLOW}Nueva configuración:${NC}"
        if [ "$canary_enabled" = "true" ]; then
            echo -e "  Estado: ${GREEN}Habilitado${NC}"
        else
            echo -e "  Estado: ${RED}Deshabilitado${NC}"
        fi
        echo "  Porcentaje Canary: ${canary_percentage}%"
    else
        echo -e "${RED}Error al configurar Canary deployment:${NC}"
        echo $response | jq -r '.error'
    fi
}

# Función para configurar el peso de un servidor
configure_weight() {
    local backend="$1"
    local server="$2"
    local weight="$3"
    
    # Validar parámetros
    if [ -z "$backend" ] || [ -z "$server" ] || [ -z "$weight" ]; then
        echo -e "${RED}Error: Se requieren los parámetros backend, server y weight.${NC}"
        show_help
        exit 1
    fi
    
    # Construir el payload JSON
    local payload="{\"backend\":\"${backend}\",\"server\":\"${server}\",\"weight\":${weight}}"
    
    # Enviar la configuración
    echo -e "${BLUE}Configurando peso del servidor...${NC}"
    response=$(curl -s -X POST -H "Content-Type: application/json" -d "${payload}" "${API_URL}/server/weight")
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: No se pudo conectar con la API de administración.${NC}"
        exit 1
    fi
    
    # Mostrar el resultado
    status=$(echo $response | jq -r '.status')
    
    if [ "$status" = "success" ]; then
        echo -e "${GREEN}Peso del servidor configurado correctamente.${NC}"
        echo -e "${YELLOW}Backend:${NC} ${backend}"
        echo -e "${YELLOW}Servidor:${NC} ${server}"
        echo -e "${YELLOW}Nuevo peso:${NC} ${weight}"
    else
        echo -e "${RED}Error al configurar el peso del servidor:${NC}"
        echo $response | jq -r '.error'
    fi
}

# Verificar dependencias
check_curl
check_jq

# Procesar comandos
case "$1" in
    status)
        show_status
        ;;
    ab)
        shift
        configure_ab "$@"
        ;;
    canary)
        shift
        configure_canary "$@"
        ;;
    weight)
        shift
        configure_weight "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Error: Comando desconocido: $1${NC}"
        show_help
        exit 1
        ;;
esac

exit 0
