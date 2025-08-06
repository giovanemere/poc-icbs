#!/bin/bash
# Script para mostrar el estado completo del sistema de variables centralizadas

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Estado Sistema Variables Centralizadas            ║"
echo "║                Docker WebLogic Oracle Project               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}Uso: $0 [OPCIONES]${NC}"
    echo ""
    echo -e "${YELLOW}Opciones:${NC}"
    echo "  --detailed      Mostrar información detallada"
    echo "  --export        Exportar configuración a archivo"
    echo "  --help          Mostrar esta ayuda"
    echo ""
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo "  $0              # Estado básico"
    echo "  $0 --detailed   # Estado detallado"
    echo "  $0 --export     # Exportar configuración"
}

# Función para verificar archivos del sistema
check_system_files() {
    echo -e "${BLUE}=== Estado de Archivos del Sistema ===${NC}"
    
    local files_status=(
        "scripts/.env:Configuración base:required"
        "scripts/.env.development:Configuración desarrollo:required"
        "scripts/.env.staging:Configuración staging:required"
        "scripts/.env.production:Configuración producción:required"
        "scripts/core/load-env-enhanced.sh:Script carga variables:required"
        "scripts/validation/validate-env-variables.sh:Script validación:required"
        "scripts/utilities/docker-hub-config.sh:Configuración Docker Hub:required"
        "scripts/utilities/migrate-env-config.sh:Script migración:optional"
        "scripts/.env.current:Ambiente actual:optional"
        "scripts/.docker-hub-config:Credenciales Docker Hub:optional"
    )
    
    local required_missing=0
    local optional_missing=0
    
    for file_info in "${files_status[@]}"; do
        local file_path="${file_info%%:*}"
        local temp="${file_info#*:}"
        local description="${temp%%:*}"
        local requirement="${temp##*:}"
        
        local full_path="$PROJECT_ROOT/$file_path"
        
        if [ -f "$full_path" ]; then
            if [ -x "$full_path" ]; then
                echo -e "${GREEN}✓ $description (ejecutable): $file_path${NC}"
            else
                echo -e "${GREEN}✓ $description: $file_path${NC}"
            fi
        else
            if [ "$requirement" = "required" ]; then
                echo -e "${RED}✗ $description (REQUERIDO): $file_path${NC}"
                ((required_missing++))
            else
                echo -e "${YELLOW}⚠ $description (opcional): $file_path${NC}"
                ((optional_missing++))
            fi
        fi
    done
    
    echo ""
    if [ $required_missing -eq 0 ]; then
        echo -e "${GREEN}✅ Todos los archivos requeridos están presentes${NC}"
    else
        echo -e "${RED}❌ $required_missing archivos requeridos faltantes${NC}"
    fi
    
    if [ $optional_missing -gt 0 ]; then
        echo -e "${YELLOW}⚠ $optional_missing archivos opcionales faltantes${NC}"
    fi
    
    return $required_missing
}

# Función para verificar ambientes
check_environments() {
    echo -e "${BLUE}=== Estado de Ambientes ===${NC}"
    
    local environments=("development" "staging" "production")
    local env_errors=0
    
    for env in "${environments[@]}"; do
        echo -e "${CYAN}Ambiente: $env${NC}"
        
        # Intentar cargar el ambiente
        if source "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" "$env" 2>/dev/null; then
            echo -e "${GREEN}  ✓ Carga: OK${NC}"
            
            # Verificar variables críticas
            local critical_vars=("WEBLOGIC_A_EXTERNAL_PORT" "HAPROXY_HTTP_EXTERNAL_PORT" "DOCKER_NAMESPACE")
            local missing_vars=0
            
            for var in "${critical_vars[@]}"; do
                if [ -n "${!var}" ]; then
                    echo -e "${GREEN}  ✓ $var: ${!var}${NC}"
                else
                    echo -e "${RED}  ✗ $var: NO DEFINIDA${NC}"
                    ((missing_vars++))
                fi
            done
            
            if [ $missing_vars -eq 0 ]; then
                echo -e "${GREEN}  ✅ Variables críticas: OK${NC}"
            else
                echo -e "${RED}  ❌ $missing_vars variables críticas faltantes${NC}"
                ((env_errors++))
            fi
        else
            echo -e "${RED}  ✗ Error al cargar ambiente${NC}"
            ((env_errors++))
        fi
        
        echo ""
    done
    
    if [ $env_errors -eq 0 ]; then
        echo -e "${GREEN}✅ Todos los ambientes funcionan correctamente${NC}"
    else
        echo -e "${RED}❌ $env_errors ambientes con errores${NC}"
    fi
    
    return $env_errors
}

# Función para verificar integración Docker Hub
check_docker_hub_integration() {
    echo -e "${BLUE}=== Estado Integración Docker Hub ===${NC}"
    
    # Cargar variables
    source "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" development 2>/dev/null || true
    
    # Verificar variables Docker Hub
    local docker_vars=(
        "DOCKER_REGISTRY"
        "DOCKER_NAMESPACE"
        "DOCKER_USERNAME"
    )
    
    local missing_vars=0
    for var in "${docker_vars[@]}"; do
        if [ -n "${!var}" ]; then
            echo -e "${GREEN}✓ $var: ${!var}${NC}"
        else
            echo -e "${RED}✗ $var: NO DEFINIDA${NC}"
            ((missing_vars++))
        fi
    done
    
    # Verificar imágenes configuradas
    local images=(
        "WEBLOGIC_FULL_IMAGE"
        "HAPROXY_FULL_IMAGE"
        "ORACLE_FULL_IMAGE"
        "MKDOCS_FULL_IMAGE"
    )
    
    echo -e "${BLUE}Imágenes configuradas:${NC}"
    for image_var in "${images[@]}"; do
        local image_value="${!image_var}"
        if [ -n "$image_value" ]; then
            echo -e "${GREEN}✓ $image_var: $image_value${NC}"
        else
            echo -e "${YELLOW}⚠ $image_var: NO DEFINIDA${NC}"
        fi
    done
    
    # Verificar Docker CLI y autenticación
    if command -v docker >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Docker CLI disponible${NC}"
        
        if docker info 2>/dev/null | grep -q "Username:"; then
            local current_user=$(docker info 2>/dev/null | grep "Username:" | awk '{print $2}')
            echo -e "${GREEN}✓ Autenticado como: $current_user${NC}"
        else
            echo -e "${YELLOW}⚠ No autenticado en Docker Hub${NC}"
        fi
    else
        echo -e "${RED}✗ Docker CLI no disponible${NC}"
        ((missing_vars++))
    fi
    
    return $missing_vars
}

# Función para verificar sistema de IPs dinámicas
check_dynamic_ip_system() {
    echo -e "${BLUE}=== Estado Sistema IPs Dinámicas ===${NC}"
    
    # Cargar variables
    source "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" development 2>/dev/null || true
    
    # Verificar variables del sistema
    local ip_vars=(
        "ENABLE_DYNAMIC_IP_UPDATE:Habilitación sistema"
        "HAPROXY_IP_UPDATE_TIMEOUT:Timeout actualización"
        "HAPROXY_RELOAD_WAIT_TIME:Tiempo espera reload"
        "ENABLE_IP_UPDATE_LOGGING:Logging habilitado"
    )
    
    for var_desc in "${ip_vars[@]}"; do
        local var_name="${var_desc%%:*}"
        local var_description="${var_desc##*:}"
        local var_value="${!var_name}"
        
        if [ -n "$var_value" ]; then
            echo -e "${GREEN}✓ $var_description: $var_value${NC}"
        else
            echo -e "${YELLOW}⚠ $var_description: NO DEFINIDA${NC}"
        fi
    done
    
    # Verificar scripts
    local scripts=(
        "scripts/maintenance/auto-update-haproxy.sh"
        "scripts/services/start-with-auto-update.sh"
    )
    
    local missing_scripts=0
    for script in "${scripts[@]}"; do
        local script_path="$PROJECT_ROOT/$script"
        if [ -f "$script_path" ] && [ -x "$script_path" ]; then
            echo -e "${GREEN}✓ Script disponible: $script${NC}"
        else
            echo -e "${RED}✗ Script no encontrado: $script${NC}"
            ((missing_scripts++))
        fi
    done
    
    if [ $missing_scripts -eq 0 ]; then
        echo -e "${GREEN}✅ Sistema IPs dinámicas: OPERATIVO${NC}"
    else
        echo -e "${RED}❌ Sistema IPs dinámicas: $missing_scripts scripts faltantes${NC}"
    fi
    
    return $missing_scripts
}

# Función para mostrar configuración actual
show_current_configuration() {
    echo -e "${BLUE}=== Configuración Actual ===${NC}"
    
    # Detectar ambiente actual
    local current_env="development"
    if [ -f "$PROJECT_ROOT/scripts/.env.current" ]; then
        current_env=$(cat "$PROJECT_ROOT/scripts/.env.current")
    fi
    
    echo -e "${CYAN}Ambiente activo: $current_env${NC}"
    
    # Cargar variables del ambiente actual
    source "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" "$current_env" 2>/dev/null || true
    
    # Mostrar configuración clave
    echo -e "${BLUE}Puertos principales:${NC}"
    echo -e "  WebLogic A:        ${WEBLOGIC_A_EXTERNAL_PORT:-NO_DEFINIDO}"
    echo -e "  WebLogic B:        ${WEBLOGIC_B_EXTERNAL_PORT:-NO_DEFINIDO}"
    echo -e "  HAProxy HTTP:      ${HAPROXY_HTTP_EXTERNAL_PORT:-NO_DEFINIDO}"
    echo -e "  HAProxy Stats:     ${HAPROXY_STATS_EXTERNAL_PORT:-NO_DEFINIDO}"
    echo -e "  Oracle DB:         ${ORACLE_EXTERNAL_PORT:-NO_DEFINIDO}"
    echo -e "  MkDocs:            ${MKDOCS_EXTERNAL_PORT:-NO_DEFINIDO}"
    
    echo -e "${BLUE}Docker Hub:${NC}"
    echo -e "  Namespace:         ${DOCKER_NAMESPACE:-NO_DEFINIDO}"
    echo -e "  Registry:          ${DOCKER_REGISTRY:-NO_DEFINIDO}"
    
    echo -e "${BLUE}Características:${NC}"
    echo -e "  IPs Dinámicas:     ${ENABLE_DYNAMIC_IP_UPDATE:-NO_DEFINIDO}"
    echo -e "  Modo Debug:        ${DEBUG_ENABLED:-NO_DEFINIDO}"
    echo -e "  SSL Habilitado:    ${SSL_ENABLED:-NO_DEFINIDO}"
}

# Función para generar reporte detallado
generate_detailed_report() {
    echo -e "${MAGENTA}=== REPORTE DETALLADO ===${NC}"
    
    # Información del sistema
    echo -e "${BLUE}Sistema:${NC}"
    echo -e "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "  Usuario: $(whoami)"
    echo -e "  Directorio: $PROJECT_ROOT"
    echo -e "  Shell: $SHELL"
    
    # Verificar todas las funciones
    local total_errors=0
    
    echo ""
    check_system_files || total_errors=$((total_errors + $?))
    
    echo ""
    check_environments || total_errors=$((total_errors + $?))
    
    echo ""
    check_docker_hub_integration || total_errors=$((total_errors + $?))
    
    echo ""
    check_dynamic_ip_system || total_errors=$((total_errors + $?))
    
    echo ""
    show_current_configuration
    
    # Resumen final
    echo ""
    echo -e "${MAGENTA}=== RESUMEN FINAL ===${NC}"
    if [ $total_errors -eq 0 ]; then
        echo -e "${GREEN}🎉 SISTEMA COMPLETAMENTE FUNCIONAL${NC}"
        echo -e "${GREEN}Todas las verificaciones pasaron exitosamente${NC}"
        
        echo -e "${BLUE}Estado del proyecto:${NC}"
        echo -e "  ✅ Variables centralizadas: IMPLEMENTADO"
        echo -e "  ✅ Multi-ambiente: FUNCIONAL"
        echo -e "  ✅ Docker Hub: CONFIGURADO"
        echo -e "  ✅ IPs Dinámicas: OPERATIVO"
        
        echo -e "${BLUE}Próximos pasos recomendados:${NC}"
        echo -e "  1. Completar integración Docker Hub (login)"
        echo -e "  2. Reestructurar directorio applications/"
        echo -e "  3. Implementar pipeline CI/CD"
        echo -e "  4. Configurar monitoreo avanzado"
        
    else
        echo -e "${RED}⚠️  SISTEMA CON $total_errors PROBLEMAS${NC}"
        echo -e "${YELLOW}Revise los errores reportados arriba${NC}"
        
        echo -e "${BLUE}Acciones recomendadas:${NC}"
        echo -e "  1. Corregir archivos faltantes"
        echo -e "  2. Validar configuración de ambientes"
        echo -e "  3. Re-ejecutar validación completa"
    fi
    
    return $total_errors
}

# Función para exportar configuración
export_configuration() {
    local output_file="$PROJECT_ROOT/system-config-export-$(date +%Y%m%d-%H%M%S).txt"
    
    echo -e "${BLUE}Exportando configuración del sistema...${NC}"
    
    {
        echo "# Configuración Sistema Variables Centralizadas"
        echo "# Generado: $(date)"
        echo "# Proyecto: Docker WebLogic Oracle"
        echo ""
        
        echo "## ARCHIVOS DEL SISTEMA"
        ls -la "$PROJECT_ROOT/scripts/.env"* 2>/dev/null || echo "No hay archivos .env"
        echo ""
        
        echo "## VARIABLES DE AMBIENTE DEVELOPMENT"
        source "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" development 2>/dev/null || true
        env | grep -E "^(WEBLOGIC|HAPROXY|ORACLE|MKDOCS|DOCKER|COMPOSE|ENABLE)" | sort
        echo ""
        
        echo "## ESTADO DOCKER"
        docker --version 2>/dev/null || echo "Docker no disponible"
        docker info 2>/dev/null | grep -E "(Username|Server Version)" || echo "No hay información Docker"
        echo ""
        
        echo "## PUERTOS EN USO"
        netstat -tlnp 2>/dev/null | grep -E ":(7001|7002|8081|8082|8083|8404|1521|5500|8000)" || echo "netstat no disponible"
        
    } > "$output_file"
    
    echo -e "${GREEN}✓ Configuración exportada a: $output_file${NC}"
}

# Función principal
main() {
    local detailed=false
    local export_config=false
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --detailed)
                detailed=true
                shift
                ;;
            --export)
                export_config=true
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
    
    # Mostrar información básica siempre
    show_current_configuration
    
    echo ""
    
    # Mostrar información detallada si se solicitó
    if [ "$detailed" = true ]; then
        generate_detailed_report
        local exit_code=$?
    else
        # Verificación básica
        echo -e "${BLUE}=== Verificación Básica ===${NC}"
        local basic_errors=0
        
        # Verificar archivos críticos
        local critical_files=(
            "scripts/.env"
            "scripts/core/load-env-enhanced.sh"
            "scripts/validation/validate-env-variables.sh"
        )
        
        for file in "${critical_files[@]}"; do
            if [ -f "$PROJECT_ROOT/$file" ]; then
                echo -e "${GREEN}✓ $file${NC}"
            else
                echo -e "${RED}✗ $file${NC}"
                ((basic_errors++))
            fi
        done
        
        # Probar carga de variables
        if source "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" development 2>/dev/null; then
            echo -e "${GREEN}✓ Carga de variables: OK${NC}"
        else
            echo -e "${RED}✗ Error en carga de variables${NC}"
            ((basic_errors++))
        fi
        
        if [ $basic_errors -eq 0 ]; then
            echo -e "${GREEN}✅ Verificación básica: EXITOSA${NC}"
            local exit_code=0
        else
            echo -e "${RED}❌ Verificación básica: $basic_errors errores${NC}"
            local exit_code=1
        fi
    fi
    
    # Exportar configuración si se solicitó
    if [ "$export_config" = true ]; then
        echo ""
        export_configuration
    fi
    
    # Mensaje final
    echo ""
    echo -e "${CYAN}Para más información detallada, ejecute: $0 --detailed${NC}"
    echo -e "${CYAN}Para validación completa, ejecute: ./scripts/validation/validate-env-variables.sh${NC}"
    
    exit ${exit_code:-0}
}

# Ejecutar función principal
main "$@"
