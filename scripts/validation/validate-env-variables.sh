#!/bin/bash
# Script para validar todas las variables de entorno del proyecto

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              Validación de Variables de Entorno             ║"
echo "║                  Docker WebLogic Oracle                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}Uso: $0 [ENVIRONMENT] [OPTIONS]${NC}"
    echo ""
    echo -e "${YELLOW}Ambientes:${NC}"
    echo "  development  - Validar variables de desarrollo"
    echo "  staging      - Validar variables de staging"
    echo "  production   - Validar variables de producción"
    echo "  all          - Validar todos los ambientes"
    echo ""
    echo -e "${YELLOW}Opciones:${NC}"
    echo "  --fix        - Intentar corregir problemas automáticamente"
    echo "  --export     - Exportar variables a archivo"
    echo "  --help       - Mostrar esta ayuda"
    echo ""
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo "  $0                    # Validar ambiente actual"
    echo "  $0 production         # Validar ambiente de producción"
    echo "  $0 all --fix          # Validar todos y corregir problemas"
}

# Función para cargar variables de entorno
load_environment() {
    local environment="${1:-development}"
    
    echo -e "${BLUE}Cargando ambiente: $environment${NC}"
    
    # Cargar usando el script mejorado
    source "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" "$environment" 2>/dev/null || {
        echo -e "${RED}Error: No se pudo cargar el ambiente $environment${NC}"
        return 1
    }
}

# Función para validar variables críticas
validate_critical_variables() {
    echo -e "${BLUE}=== Validando Variables Críticas ===${NC}"
    
    local errors=0
    local warnings=0
    
    # Variables críticas obligatorias
    local critical_vars=(
        "ENVIRONMENT:Ambiente actual"
        "WEBLOGIC_A_EXTERNAL_PORT:Puerto WebLogic A"
        "WEBLOGIC_B_EXTERNAL_PORT:Puerto WebLogic B"
        "HAPROXY_HTTP_EXTERNAL_PORT:Puerto HAProxy HTTP"
        "HAPROXY_STATS_EXTERNAL_PORT:Puerto HAProxy Stats"
        "HAPROXY_API_EXTERNAL_PORT:Puerto HAProxy API"
        "ORACLE_EXTERNAL_PORT:Puerto Oracle"
        "DOCKER_NAMESPACE:Namespace Docker Hub"
        "COMPOSE_PROJECT_NAME:Nombre proyecto Docker Compose"
    )
    
    for var_desc in "${critical_vars[@]}"; do
        local var_name="${var_desc%%:*}"
        local var_description="${var_desc##*:}"
        local var_value="${!var_name}"
        
        if [ -z "$var_value" ]; then
            echo -e "${RED}✗ CRÍTICO: $var_description ($var_name) no está definida${NC}"
            ((errors++))
        else
            echo -e "${GREEN}✓ $var_description: $var_value${NC}"
        fi
    done
    
    return $errors
}

# Función para validar puertos
validate_ports() {
    echo -e "${BLUE}=== Validando Configuración de Puertos ===${NC}"
    
    local errors=0
    local warnings=0
    
    # Puertos que deben estar definidos
    local port_vars=(
        "WEBLOGIC_A_EXTERNAL_PORT"
        "WEBLOGIC_B_EXTERNAL_PORT"
        "HAPROXY_HTTP_EXTERNAL_PORT"
        "HAPROXY_HTTPS_EXTERNAL_PORT"
        "HAPROXY_STATS_EXTERNAL_PORT"
        "HAPROXY_UI_EXTERNAL_PORT"
        "HAPROXY_API_EXTERNAL_PORT"
        "ORACLE_EXTERNAL_PORT"
        "ORACLE_EM_EXTERNAL_PORT"
        "MKDOCS_EXTERNAL_PORT"
    )
    
    # Recopilar puertos definidos
    local defined_ports=()
    for port_var in "${port_vars[@]}"; do
        local port_value="${!port_var}"
        if [ -n "$port_value" ]; then
            defined_ports+=("$port_value:$port_var")
        else
            echo -e "${YELLOW}⚠ Puerto no definido: $port_var${NC}"
            ((warnings++))
        fi
    done
    
    # Validar rangos de puertos
    for port_info in "${defined_ports[@]}"; do
        local port="${port_info%%:*}"
        local var_name="${port_info##*:}"
        
        if ! [[ "$port" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}✗ Puerto inválido en $var_name: $port (no es numérico)${NC}"
            ((errors++))
        elif [ "$port" -lt 1024 ]; then
            echo -e "${YELLOW}⚠ Puerto privilegiado en $var_name: $port (< 1024)${NC}"
            ((warnings++))
        elif [ "$port" -gt 65535 ]; then
            echo -e "${RED}✗ Puerto fuera de rango en $var_name: $port (> 65535)${NC}"
            ((errors++))
        else
            echo -e "${GREEN}✓ Puerto válido $var_name: $port${NC}"
        fi
    done
    
    # Verificar puertos duplicados
    local ports_only=($(printf '%s\n' "${defined_ports[@]}" | cut -d: -f1 | sort))
    local unique_ports=($(printf '%s\n' "${ports_only[@]}" | sort -u))
    
    if [ ${#ports_only[@]} -ne ${#unique_ports[@]} ]; then
        echo -e "${RED}✗ CRÍTICO: Puertos duplicados detectados${NC}"
        printf '%s\n' "${ports_only[@]}" | sort | uniq -d | while read -r dup_port; do
            echo -e "${RED}  Puerto duplicado: $dup_port${NC}"
            # Mostrar qué variables usan este puerto
            for port_info in "${defined_ports[@]}"; do
                if [[ "$port_info" == "$dup_port:"* ]]; then
                    echo -e "${RED}    Usado en: ${port_info##*:}${NC}"
                fi
            done
        done
        ((errors++))
    else
        echo -e "${GREEN}✓ Todos los puertos son únicos${NC}"
    fi
    
    # Verificar disponibilidad de puertos (solo si netstat está disponible)
    if command -v netstat >/dev/null 2>&1; then
        echo -e "${BLUE}Verificando disponibilidad de puertos...${NC}"
        for port_info in "${defined_ports[@]}"; do
            local port="${port_info%%:*}"
            local var_name="${port_info##*:}"
            
            if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
                echo -e "${YELLOW}⚠ Puerto $port ($var_name) está en uso${NC}"
                ((warnings++))
            else
                echo -e "${GREEN}✓ Puerto $port ($var_name) disponible${NC}"
            fi
        done
    fi
    
    echo -e "${BLUE}Resumen puertos: ${GREEN}${#unique_ports[@]} únicos${NC}, ${YELLOW}$warnings advertencias${NC}, ${RED}$errors errores${NC}"
    
    return $errors
}

# Función para validar configuración Docker Hub
validate_docker_hub() {
    echo -e "${BLUE}=== Validando Configuración Docker Hub ===${NC}"
    
    local errors=0
    local warnings=0
    
    # Variables Docker Hub
    local docker_vars=(
        "DOCKER_REGISTRY:Registry Docker"
        "DOCKER_NAMESPACE:Namespace Docker"
        "DOCKER_USERNAME:Usuario Docker"
    )
    
    for var_desc in "${docker_vars[@]}"; do
        local var_name="${var_desc%%:*}"
        local var_description="${var_desc##*:}"
        local var_value="${!var_name}"
        
        if [ -z "$var_value" ]; then
            echo -e "${RED}✗ $var_description ($var_name) no está definida${NC}"
            ((errors++))
        else
            echo -e "${GREEN}✓ $var_description: $var_value${NC}"
        fi
    done
    
    # Validar imágenes
    local image_vars=(
        "WEBLOGIC_FULL_IMAGE"
        "HAPROXY_FULL_IMAGE"
        "ORACLE_FULL_IMAGE"
        "MKDOCS_FULL_IMAGE"
    )
    
    for image_var in "${image_vars[@]}"; do
        local image_value="${!image_var}"
        if [ -z "$image_value" ]; then
            echo -e "${YELLOW}⚠ Imagen no definida: $image_var${NC}"
            ((warnings++))
        else
            # Validar formato de imagen
            if [[ "$image_value" =~ ^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+:[a-zA-Z0-9._-]+$ ]]; then
                echo -e "${GREEN}✓ Imagen válida $image_var: $image_value${NC}"
            else
                echo -e "${RED}✗ Formato de imagen inválido $image_var: $image_value${NC}"
                ((errors++))
            fi
        fi
    done
    
    # Verificar si Docker está disponible
    if command -v docker >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Docker CLI disponible${NC}"
        
        # Verificar login a Docker Hub (si DOCKER_USERNAME está definido)
        if [ -n "$DOCKER_USERNAME" ]; then
            if docker info 2>/dev/null | grep -q "Username: $DOCKER_USERNAME"; then
                echo -e "${GREEN}✓ Autenticado en Docker Hub como: $DOCKER_USERNAME${NC}"
            else
                echo -e "${YELLOW}⚠ No autenticado en Docker Hub (ejecute: docker login)${NC}"
                ((warnings++))
            fi
        fi
    else
        echo -e "${RED}✗ Docker CLI no está disponible${NC}"
        ((errors++))
    fi
    
    return $errors
}

# Función para validar sistema de IPs dinámicas
validate_dynamic_ip_system() {
    echo -e "${BLUE}=== Validando Sistema de IPs Dinámicas ===${NC}"
    
    local errors=0
    local warnings=0
    
    # Variables del sistema de IPs dinámicas
    local ip_vars=(
        "ENABLE_DYNAMIC_IP_UPDATE:Habilitación actualización IPs"
        "HAPROXY_IP_UPDATE_TIMEOUT:Timeout actualización HAProxy"
        "HAPROXY_RELOAD_WAIT_TIME:Tiempo espera reload HAProxy"
        "ENABLE_IP_UPDATE_LOGGING:Logging actualización IPs"
        "HAPROXY_CONFIG_BACKUP_ENABLED:Backup configuración HAProxy"
    )
    
    for var_desc in "${ip_vars[@]}"; do
        local var_name="${var_desc%%:*}"
        local var_description="${var_desc##*:}"
        local var_value="${!var_name}"
        
        if [ -z "$var_value" ]; then
            echo -e "${YELLOW}⚠ $var_description ($var_name) no está definida${NC}"
            ((warnings++))
        else
            echo -e "${GREEN}✓ $var_description: $var_value${NC}"
        fi
    done
    
    # Verificar scripts del sistema
    local scripts=(
        "scripts/maintenance/auto-update-haproxy.sh:Script principal actualización IPs"
        "scripts/services/start-with-auto-update.sh:Script inicio con auto-actualización"
    )
    
    for script_desc in "${scripts[@]}"; do
        local script_path="${script_desc%%:*}"
        local script_description="${script_desc##*:}"
        local full_path="$PROJECT_ROOT/$script_path"
        
        if [ -f "$full_path" ] && [ -x "$full_path" ]; then
            echo -e "${GREEN}✓ $script_description: $script_path${NC}"
        else
            echo -e "${RED}✗ $script_description no encontrado o no ejecutable: $script_path${NC}"
            ((errors++))
        fi
    done
    
    return $errors
}

# Función para validar configuración de aplicaciones
validate_applications_config() {
    echo -e "${BLUE}=== Validando Configuración de Aplicaciones ===${NC}"
    
    local errors=0
    local warnings=0
    
    # Variables de aplicaciones
    local app_vars=(
        "APPLICATIONS_ROOT:Directorio raíz aplicaciones"
        "WEBLOGIC_APP_PATH:Path aplicación WebLogic"
        "HAPROXY_APP_PATH:Path aplicación HAProxy"
        "MKDOCS_APP_PATH:Path aplicación MkDocs"
        "ORACLE_APP_PATH:Path aplicación Oracle"
    )
    
    for var_desc in "${app_vars[@]}"; do
        local var_name="${var_desc%%:*}"
        local var_description="${var_desc##*:}"
        local var_value="${!var_name}"
        
        if [ -z "$var_value" ]; then
            echo -e "${YELLOW}⚠ $var_description ($var_name) no está definida${NC}"
            ((warnings++))
        else
            echo -e "${GREEN}✓ $var_description: $var_value${NC}"
            
            # Verificar si el directorio existe (solo advertencia)
            local full_path="$PROJECT_ROOT/$var_value"
            if [ ! -d "$full_path" ]; then
                echo -e "${YELLOW}  ⚠ Directorio no existe: $full_path${NC}"
                ((warnings++))
            fi
        fi
    done
    
    return $errors
}

# Función para generar reporte de validación
generate_validation_report() {
    local environment="$1"
    local total_errors="$2"
    local total_warnings="$3"
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    REPORTE DE VALIDACIÓN                    ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Ambiente validado: ${YELLOW}$environment${NC}"
    echo -e "${BLUE}Fecha: ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
    
    if [ $total_errors -eq 0 ] && [ $total_warnings -eq 0 ]; then
        echo -e "${GREEN}✅ VALIDACIÓN EXITOSA${NC}"
        echo -e "${GREEN}Todas las variables están correctamente configuradas${NC}"
    elif [ $total_errors -eq 0 ]; then
        echo -e "${YELLOW}⚠️  VALIDACIÓN CON ADVERTENCIAS${NC}"
        echo -e "${YELLOW}$total_warnings advertencias encontradas${NC}"
        echo -e "${BLUE}Las advertencias no impiden el funcionamiento pero deberían revisarse${NC}"
    else
        echo -e "${RED}❌ VALIDACIÓN FALLIDA${NC}"
        echo -e "${RED}$total_errors errores críticos encontrados${NC}"
        if [ $total_warnings -gt 0 ]; then
            echo -e "${YELLOW}$total_warnings advertencias adicionales${NC}"
        fi
        echo -e "${BLUE}Los errores deben corregirse antes de continuar${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Próximos pasos recomendados:${NC}"
    if [ $total_errors -gt 0 ]; then
        echo -e "  1. Corregir errores críticos en archivo .env.$environment"
        echo -e "  2. Re-ejecutar validación: $0 $environment"
        echo -e "  3. Verificar funcionamiento: ./manage-services.sh status"
    elif [ $total_warnings -gt 0 ]; then
        echo -e "  1. Revisar advertencias en archivo .env.$environment"
        echo -e "  2. Considerar optimizaciones sugeridas"
        echo -e "  3. Continuar con siguiente fase del proyecto"
    else
        echo -e "  1. ✅ Configuración lista para uso"
        echo -e "  2. Continuar con: ./manage-services.sh start"
        echo -e "  3. Proceder con siguiente fase del proyecto"
    fi
}

# Función para exportar variables a archivo
export_variables() {
    local environment="$1"
    local output_file="$PROJECT_ROOT/config-export-$environment-$(date +%Y%m%d-%H%M%S).env"
    
    echo -e "${BLUE}Exportando variables de $environment a: $output_file${NC}"
    
    {
        echo "# Variables de entorno exportadas - $environment"
        echo "# Generado: $(date)"
        echo "# Ambiente: $environment"
        echo ""
        
        # Exportar variables principales
        env | grep -E "^(WEBLOGIC|HAPROXY|ORACLE|MKDOCS|DOCKER|COMPOSE|ENABLE)" | sort
        
    } > "$output_file"
    
    echo -e "${GREEN}✓ Variables exportadas a: $output_file${NC}"
}

# Función principal
main() {
    local environment="development"
    local validate_all=false
    local fix_issues=false
    local export_vars=false
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            development|staging|production)
                environment="$1"
                shift
                ;;
            all)
                validate_all=true
                shift
                ;;
            --fix)
                fix_issues=true
                shift
                ;;
            --export)
                export_vars=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Opción desconocida: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Validar todos los ambientes si se solicitó
    if [ "$validate_all" = true ]; then
        local environments=("development" "staging" "production")
        local global_errors=0
        
        for env in "${environments[@]}"; do
            echo -e "${CYAN}=== Validando ambiente: $env ===${NC}"
            
            if load_environment "$env"; then
                local env_errors=0
                
                validate_critical_variables || env_errors=$((env_errors + $?))
                validate_ports || env_errors=$((env_errors + $?))
                validate_docker_hub || env_errors=$((env_errors + $?))
                validate_dynamic_ip_system || env_errors=$((env_errors + $?))
                validate_applications_config || env_errors=$((env_errors + $?))
                
                if [ $env_errors -eq 0 ]; then
                    echo -e "${GREEN}✅ Ambiente $env: VÁLIDO${NC}"
                else
                    echo -e "${RED}❌ Ambiente $env: $env_errors errores${NC}"
                    global_errors=$((global_errors + env_errors))
                fi
            else
                echo -e "${RED}❌ No se pudo cargar ambiente $env${NC}"
                global_errors=$((global_errors + 1))
            fi
            
            echo ""
        done
        
        if [ $global_errors -eq 0 ]; then
            echo -e "${GREEN}🎉 TODOS LOS AMBIENTES VÁLIDOS${NC}"
            exit 0
        else
            echo -e "${RED}💥 $global_errors errores totales encontrados${NC}"
            exit 1
        fi
    fi
    
    # Validar ambiente específico
    echo -e "${BLUE}Validando ambiente: $environment${NC}"
    
    if ! load_environment "$environment"; then
        echo -e "${RED}Error: No se pudo cargar el ambiente $environment${NC}"
        exit 1
    fi
    
    # Exportar variables si se solicitó
    if [ "$export_vars" = true ]; then
        export_variables "$environment"
    fi
    
    # Ejecutar validaciones
    local total_errors=0
    local total_warnings=0
    
    validate_critical_variables || total_errors=$((total_errors + $?))
    validate_ports || total_errors=$((total_errors + $?))
    validate_docker_hub || total_errors=$((total_errors + $?))
    validate_dynamic_ip_system || total_errors=$((total_errors + $?))
    validate_applications_config || total_errors=$((total_errors + $?))
    
    # Generar reporte final
    generate_validation_report "$environment" "$total_errors" "$total_warnings"
    
    # Código de salida
    if [ $total_errors -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Ejecutar función principal
main "$@"
