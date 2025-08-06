#!/bin/bash
# Script mejorado para cargar variables de entorno con soporte multi-ambiente

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}Uso: source $0 [ENVIRONMENT] [OPTIONS]${NC}"
    echo ""
    echo -e "${YELLOW}Ambientes disponibles:${NC}"
    echo "  development  - Configuración para desarrollo (default)"
    echo "  staging      - Configuración para staging/testing"
    echo "  production   - Configuración para producción"
    echo ""
    echo -e "${YELLOW}Opciones:${NC}"
    echo "  --validate   - Validar variables después de cargar"
    echo "  --show       - Mostrar variables cargadas"
    echo "  --help       - Mostrar esta ayuda"
    echo ""
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo "  source $0                    # Cargar ambiente development"
    echo "  source $0 production         # Cargar ambiente production"
    echo "  source $0 staging --validate # Cargar staging y validar"
}

# Función para detectar el ambiente actual
detect_environment() {
    # Prioridad de detección:
    # 1. Parámetro pasado al script
    # 2. Variable de entorno ENVIRONMENT
    # 3. Archivo .env.current
    # 4. Default: development
    
    local env_param="$1"
    
    if [ -n "$env_param" ] && [ "$env_param" != "--validate" ] && [ "$env_param" != "--show" ] && [ "$env_param" != "--help" ]; then
        echo "$env_param"
        return
    fi
    
    if [ -n "$ENVIRONMENT" ]; then
        echo "$ENVIRONMENT"
        return
    fi
    
    if [ -f "$SCRIPTS_DIR/.env.current" ]; then
        cat "$SCRIPTS_DIR/.env.current"
        return
    fi
    
    echo "development"
}

# Función para validar que el archivo de ambiente existe
validate_environment_file() {
    local environment="$1"
    local env_file="$SCRIPTS_DIR/.env.$environment"
    
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Error: Archivo de ambiente no encontrado: $env_file${NC}" >&2
        echo -e "${YELLOW}Ambientes disponibles:${NC}" >&2
        ls -1 "$SCRIPTS_DIR"/.env.* 2>/dev/null | sed 's|.*/\.env\.||' | grep -v '^$' >&2
        return 1
    fi
    
    return 0
}

# Función para cargar archivo .env
load_env_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        echo -e "${BLUE}Cargando $description: $file${NC}" >&2
        
        # Exportar variables del archivo
        set -a  # Automatically export all variables
        source "$file"
        set +a  # Stop automatically exporting
        
        return 0
    else
        echo -e "${YELLOW}Archivo no encontrado: $file${NC}" >&2
        return 1
    fi
}

# Función para validar variables críticas
validate_critical_variables() {
    local errors=0
    
    echo -e "${BLUE}=== Validando Variables Críticas ===${NC}" >&2
    
    # Variables críticas que deben estar definidas
    local critical_vars=(
        "WEBLOGIC_A_EXTERNAL_PORT"
        "WEBLOGIC_B_EXTERNAL_PORT"
        "HAPROXY_HTTP_EXTERNAL_PORT"
        "HAPROXY_STATS_EXTERNAL_PORT"
        "ORACLE_EXTERNAL_PORT"
        "DOCKER_NAMESPACE"
        "COMPOSE_PROJECT_NAME"
    )
    
    for var in "${critical_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo -e "${RED}✗ Variable crítica no definida: $var${NC}" >&2
            ((errors++))
        else
            echo -e "${GREEN}✓ $var=${!var}${NC}" >&2
        fi
    done
    
    # Validar puertos únicos
    echo -e "${BLUE}=== Validando Puertos Únicos ===${NC}" >&2
    local ports=(
        "$WEBLOGIC_A_EXTERNAL_PORT"
        "$WEBLOGIC_B_EXTERNAL_PORT"
        "$HAPROXY_HTTP_EXTERNAL_PORT"
        "$HAPROXY_HTTPS_EXTERNAL_PORT"
        "$HAPROXY_STATS_EXTERNAL_PORT"
        "$HAPROXY_UI_EXTERNAL_PORT"
        "$HAPROXY_API_EXTERNAL_PORT"
        "$ORACLE_EXTERNAL_PORT"
        "$ORACLE_EM_EXTERNAL_PORT"
        "$MKDOCS_EXTERNAL_PORT"
    )
    
    local unique_ports=($(printf '%s\n' "${ports[@]}" | sort -u))
    
    if [ ${#ports[@]} -ne ${#unique_ports[@]} ]; then
        echo -e "${RED}✗ Puertos duplicados detectados${NC}" >&2
        printf '%s\n' "${ports[@]}" | sort | uniq -d | while read -r dup_port; do
            echo -e "${RED}  Puerto duplicado: $dup_port${NC}" >&2
        done
        ((errors++))
    else
        echo -e "${GREEN}✓ Todos los puertos son únicos${NC}" >&2
    fi
    
    # Validar rangos de puertos
    for port in "${ports[@]}"; do
        if [ -n "$port" ] && ([ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]); then
            echo -e "${RED}✗ Puerto fuera de rango válido: $port${NC}" >&2
            ((errors++))
        fi
    done
    
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✅ Todas las validaciones pasaron${NC}" >&2
        return 0
    else
        echo -e "${RED}❌ $errors errores de validación encontrados${NC}" >&2
        return 1
    fi
}

# Función para mostrar variables cargadas
show_loaded_variables() {
    echo -e "${BLUE}=== Variables de Entorno Cargadas ===${NC}" >&2
    echo "" >&2
    
    echo -e "${YELLOW}Ambiente:${NC}" >&2
    echo -e "  ENVIRONMENT=$ENVIRONMENT" >&2
    echo -e "  DEPLOYMENT_MODE=$DEPLOYMENT_MODE" >&2
    echo "" >&2
    
    echo -e "${YELLOW}WebLogic:${NC}" >&2
    echo -e "  WEBLOGIC_A_EXTERNAL_PORT=$WEBLOGIC_A_EXTERNAL_PORT" >&2
    echo -e "  WEBLOGIC_B_EXTERNAL_PORT=$WEBLOGIC_B_EXTERNAL_PORT" >&2
    echo -e "  WEBLOGIC_ADMIN_PASSWORD=$WEBLOGIC_ADMIN_PASSWORD" >&2
    echo "" >&2
    
    echo -e "${YELLOW}HAProxy:${NC}" >&2
    echo -e "  HAPROXY_HTTP_EXTERNAL_PORT=$HAPROXY_HTTP_EXTERNAL_PORT" >&2
    echo -e "  HAPROXY_HTTPS_EXTERNAL_PORT=$HAPROXY_HTTPS_EXTERNAL_PORT" >&2
    echo -e "  HAPROXY_STATS_EXTERNAL_PORT=$HAPROXY_STATS_EXTERNAL_PORT" >&2
    echo -e "  HAPROXY_UI_EXTERNAL_PORT=$HAPROXY_UI_EXTERNAL_PORT" >&2
    echo -e "  HAPROXY_API_EXTERNAL_PORT=$HAPROXY_API_EXTERNAL_PORT" >&2
    echo "" >&2
    
    echo -e "${YELLOW}Oracle:${NC}" >&2
    echo -e "  ORACLE_EXTERNAL_PORT=$ORACLE_EXTERNAL_PORT" >&2
    echo -e "  ORACLE_EM_EXTERNAL_PORT=$ORACLE_EM_EXTERNAL_PORT" >&2
    echo "" >&2
    
    echo -e "${YELLOW}Docker Hub:${NC}" >&2
    echo -e "  DOCKER_NAMESPACE=$DOCKER_NAMESPACE" >&2
    echo -e "  WEBLOGIC_FULL_IMAGE=$WEBLOGIC_FULL_IMAGE" >&2
    echo -e "  HAPROXY_FULL_IMAGE=$HAPROXY_FULL_IMAGE" >&2
    echo "" >&2
    
    echo -e "${YELLOW}Sistema IPs Dinámicas:${NC}" >&2
    echo -e "  ENABLE_DYNAMIC_IP_UPDATE=$ENABLE_DYNAMIC_IP_UPDATE" >&2
    echo -e "  HAPROXY_IP_UPDATE_TIMEOUT=$HAPROXY_IP_UPDATE_TIMEOUT" >&2
    echo -e "  ENABLE_IP_UPDATE_LOGGING=$ENABLE_IP_UPDATE_LOGGING" >&2
    echo "" >&2
}

# Función para guardar el ambiente actual
save_current_environment() {
    local environment="$1"
    echo "$environment" > "$SCRIPTS_DIR/.env.current"
    echo -e "${GREEN}Ambiente actual guardado: $environment${NC}" >&2
}

# Función principal para cargar variables de entorno
load_env_enhanced() {
    local environment
    local validate=false
    local show=false
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --validate)
                validate=true
                shift
                ;;
            --show)
                show=true
                shift
                ;;
            --help)
                show_help
                return 0
                ;;
            *)
                if [ -z "$environment" ]; then
                    environment="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Detectar ambiente si no se especificó
    if [ -z "$environment" ]; then
        environment=$(detect_environment)
    fi
    
    echo -e "${BLUE}=== Cargando Configuración de Ambiente: $environment ===${NC}" >&2
    
    # Validar que el archivo de ambiente existe
    if ! validate_environment_file "$environment"; then
        return 1
    fi
    
    # Cargar archivo base .env
    load_env_file "$SCRIPTS_DIR/.env" "configuración base"
    
    # Cargar archivo específico del ambiente
    load_env_file "$SCRIPTS_DIR/.env.$environment" "configuración de $environment"
    
    # Establecer variable ENVIRONMENT si no está definida
    export ENVIRONMENT="$environment"
    
    # Guardar ambiente actual
    save_current_environment "$environment"
    
    # Validar si se solicitó
    if [ "$validate" = true ]; then
        if ! validate_critical_variables; then
            echo -e "${RED}Error: Validación falló${NC}" >&2
            return 1
        fi
    fi
    
    # Mostrar variables si se solicitó
    if [ "$show" = true ]; then
        show_loaded_variables
    fi
    
    echo -e "${GREEN}✅ Configuración de ambiente '$environment' cargada exitosamente${NC}" >&2
    
    # Mostrar URLs de acceso
    echo -e "${BLUE}=== URLs de Acceso ===${NC}" >&2
    echo -e "  Load Balancer:     http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT}" >&2
    echo -e "  HAProxy Stats:     http://localhost:${HAPROXY_STATS_EXTERNAL_PORT}/stats" >&2
    echo -e "  HAProxy Admin:     http://localhost:${HAPROXY_UI_EXTERNAL_PORT}" >&2
    echo -e "  WebLogic A:        http://localhost:${WEBLOGIC_A_EXTERNAL_PORT}/console" >&2
    echo -e "  WebLogic B:        http://localhost:${WEBLOGIC_B_EXTERNAL_PORT}/console" >&2
    echo -e "  Documentation:     http://localhost:${MKDOCS_EXTERNAL_PORT}" >&2
    
    return 0
}

# Función de compatibilidad con el script original
load_env() {
    load_env_enhanced "$@"
}

# Si el script se ejecuta directamente (no con source), mostrar ayuda
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo -e "${YELLOW}Este script debe ser ejecutado con 'source' para cargar las variables:${NC}"
    echo -e "${BLUE}  source $0 [environment] [options]${NC}"
    echo ""
    show_help
    exit 1
fi

# Si se pasan argumentos, cargar inmediatamente
if [ $# -gt 0 ]; then
    load_env_enhanced "$@"
fi
