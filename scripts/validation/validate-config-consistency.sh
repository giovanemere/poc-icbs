#!/bin/bash
# Script para validar consistencia de configuración
# Verifica que todas las configuraciones estén sincronizadas

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Variables globales para estadísticas
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

echo -e "${BLUE}🔍 VALIDACIÓN DE CONSISTENCIA DE CONFIGURACIÓN${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# Función para registrar resultado de check
log_check_result() {
    local check_name="$1"
    local result="$2"
    local message="$3"
    
    ((TOTAL_CHECKS++))
    
    case "$result" in
        "PASS")
            ((PASSED_CHECKS++))
            echo -e "${GREEN}✅ PASS${NC} - $check_name: $message"
            ;;
        "FAIL")
            ((FAILED_CHECKS++))
            echo -e "${RED}❌ FAIL${NC} - $check_name: $message"
            ;;
        "WARN")
            ((WARNING_CHECKS++))
            echo -e "${YELLOW}⚠️  WARN${NC} - $check_name: $message"
            ;;
    esac
}

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Validador de Consistencia de Configuración ===${NC}"
    echo ""
    echo -e "${YELLOW}Uso: $0 [OPCIÓN]${NC}"
    echo ""
    echo -e "${BLUE}Opciones:${NC}"
    echo "  --help, -h              Mostrar esta ayuda"
    echo "  --ports-only            Solo validar consistencia de puertos"
    echo "  --env-only              Solo validar variables de entorno"
    echo "  --docker-only           Solo validar configuración Docker"
    echo "  --haproxy-only          Solo validar configuración HAProxy"
    echo "  --fix-permissions       Corregir permisos de archivos"
    echo ""
    echo -e "${BLUE}Descripción:${NC}"
    echo "  Este script verifica que todas las configuraciones estén"
    echo "  sincronizadas y sean consistentes entre:"
    echo "  - Archivo .env"
    echo "  - docker-compose.yml"
    echo "  - Configuración HAProxy"
    echo "  - Scripts de gestión"
    echo ""
}

# Función para cargar configuración
load_configuration() {
    echo -e "${CYAN}📋 Cargando Configuración${NC}"
    echo "----------------------------------------"
    
    if [ -f "$PROJECT_ROOT/scripts/core/load-env.sh" ]; then
        source "$PROJECT_ROOT/scripts/core/load-env.sh"
        if load_env > /dev/null 2>&1; then
            log_check_result "Config Load" "PASS" "Configuración cargada correctamente"
        else
            log_check_result "Config Load" "FAIL" "Error al cargar configuración"
            return 1
        fi
    else
        log_check_result "Config Load" "FAIL" "Archivo load-env.sh no encontrado"
        return 1
    fi
    
    echo ""
}

# Función para validar consistencia de puertos
validate_port_consistency() {
    echo -e "${CYAN}🔌 Validando Consistencia de Puertos${NC}"
    echo "----------------------------------------"
    
    # Definir puertos esperados desde .env
    local env_ports=(
        "WEBLOGIC_A_EXTERNAL_PORT:${WEBLOGIC_A_EXTERNAL_PORT:-7001}"
        "WEBLOGIC_B_EXTERNAL_PORT:${WEBLOGIC_B_EXTERNAL_PORT:-7002}"
        "HAPROXY_HTTP_EXTERNAL_PORT:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}"
        "HAPROXY_HTTPS_EXTERNAL_PORT:${HAPROXY_HTTPS_EXTERNAL_PORT:-8444}"
        "HAPROXY_STATS_EXTERNAL_PORT:${HAPROXY_STATS_EXTERNAL_PORT:-8404}"
        "HAPROXY_API_EXTERNAL_PORT:${HAPROXY_API_EXTERNAL_PORT:-8081}"
        "HAPROXY_UI_EXTERNAL_PORT:${HAPROXY_UI_EXTERNAL_PORT:-8082}"
    )
    
    # Verificar que los puertos estén definidos en .env
    for port_info in "${env_ports[@]}"; do
        local var_name=$(echo "$port_info" | cut -d':' -f1)
        local port_value=$(echo "$port_info" | cut -d':' -f2)
        
        if [ -n "$port_value" ] && [ "$port_value" != ":-" ]; then
            log_check_result "Port Definition" "PASS" "$var_name definido como $port_value"
        else
            log_check_result "Port Definition" "FAIL" "$var_name no está definido"
        fi
    done
    
    # Verificar consistencia en docker-compose.yml
    local compose_file="$PROJECT_ROOT/docker-compose.yml"
    if [ -f "$compose_file" ]; then
        # Verificar que docker-compose.yml use variables de entorno
        if grep -q "\${WEBLOGIC_A_EXTERNAL_PORT}" "$compose_file"; then
            log_check_result "Docker Compose Vars" "PASS" "docker-compose.yml usa variables de entorno"
        else
            log_check_result "Docker Compose Vars" "FAIL" "docker-compose.yml no usa variables de entorno"
        fi
        
        # Verificar que no haya puertos hardcodeados
        local hardcoded_found=false
        local common_ports=("7001" "7002" "8083" "8404" "8082" "8081")
        
        for port in "${common_ports[@]}"; do
            if grep -E "^\s*-\s*[\"']?$port:" "$compose_file" > /dev/null; then
                log_check_result "Hardcoded Ports" "FAIL" "Puerto hardcodeado $port encontrado en docker-compose.yml"
                hardcoded_found=true
            fi
        done
        
        if [ "$hardcoded_found" = false ]; then
            log_check_result "Hardcoded Ports" "PASS" "No se encontraron puertos hardcodeados en docker-compose.yml"
        fi
    else
        log_check_result "Docker Compose File" "FAIL" "docker-compose.yml no encontrado"
    fi
    
    # Verificar consistencia en configuración HAProxy
    local haproxy_config="$PROJECT_ROOT/haproxy/config/haproxy.cfg"
    if [ -f "$haproxy_config" ]; then
        # Verificar que HAProxy use los puertos correctos
        if grep -q "bind \*:80" "$haproxy_config" && grep -q "bind \*:443" "$haproxy_config"; then
            log_check_result "HAProxy Ports" "PASS" "HAProxy configurado con puertos internos correctos"
        else
            log_check_result "HAProxy Ports" "WARN" "Configuración de puertos HAProxy no estándar"
        fi
        
        # Verificar backends
        if grep -q "server weblogic-a weblogic-a:7001" "$haproxy_config" && \
           grep -q "server weblogic-b weblogic-b:7001" "$haproxy_config"; then
            log_check_result "HAProxy Backends" "PASS" "Backends HAProxy configurados correctamente"
        else
            log_check_result "HAProxy Backends" "FAIL" "Backends HAProxy mal configurados"
        fi
    else
        log_check_result "HAProxy Config" "FAIL" "Configuración HAProxy no encontrada"
    fi
    
    echo ""
}

# Función para validar variables de entorno
validate_environment_variables() {
    echo -e "${CYAN}🌍 Validando Variables de Entorno${NC}"
    echo "----------------------------------------"
    
    # Variables críticas que deben estar definidas
    local critical_vars=(
        "WEBLOGIC_A_EXTERNAL_PORT"
        "WEBLOGIC_B_EXTERNAL_PORT"
        "HAPROXY_HTTP_EXTERNAL_PORT"
        "HAPROXY_STATS_EXTERNAL_PORT"
        "HAPROXY_UI_EXTERNAL_PORT"
        "HAPROXY_API_EXTERNAL_PORT"
    )
    
    # Verificar que las variables estén definidas
    for var in "${critical_vars[@]}"; do
        if [ -n "${!var}" ]; then
            log_check_result "Env Var $var" "PASS" "Definida como ${!var}"
        else
            log_check_result "Env Var $var" "FAIL" "No está definida"
        fi
    done
    
    # Verificar que no haya conflictos de puertos
    local used_ports=()
    for var in "${critical_vars[@]}"; do
        local port_value="${!var}"
        if [ -n "$port_value" ]; then
            # Verificar si el puerto ya está en uso por otra variable
            for used_port in "${used_ports[@]}"; do
                if [ "$port_value" = "$used_port" ]; then
                    log_check_result "Port Conflict" "FAIL" "Puerto $port_value usado por múltiples servicios"
                fi
            done
            used_ports+=("$port_value")
        fi
    done
    
    if [ ${#used_ports[@]} -eq ${#critical_vars[@]} ]; then
        log_check_result "Port Uniqueness" "PASS" "Todos los puertos son únicos"
    fi
    
    # Verificar rangos de puertos válidos
    for var in "${critical_vars[@]}"; do
        local port_value="${!var}"
        if [ -n "$port_value" ]; then
            if [ "$port_value" -ge 1024 ] && [ "$port_value" -le 65535 ]; then
                log_check_result "Port Range $var" "PASS" "Puerto $port_value en rango válido"
            else
                log_check_result "Port Range $var" "FAIL" "Puerto $port_value fuera de rango válido"
            fi
        fi
    done
    
    echo ""
}

# Función para validar configuración Docker
validate_docker_configuration() {
    echo -e "${CYAN}🐳 Validando Configuración Docker${NC}"
    echo "----------------------------------------"
    
    local compose_file="$PROJECT_ROOT/docker-compose.yml"
    
    if [ -f "$compose_file" ]; then
        # Verificar sintaxis YAML
        if command -v docker-compose >/dev/null 2>&1; then
            if docker-compose -f "$compose_file" config > /dev/null 2>&1; then
                log_check_result "Docker Compose Syntax" "PASS" "Sintaxis YAML válida"
            else
                log_check_result "Docker Compose Syntax" "FAIL" "Sintaxis YAML inválida"
            fi
        else
            log_check_result "Docker Compose Available" "WARN" "docker-compose no disponible para validación"
        fi
        
        # Verificar servicios definidos
        local expected_services=("weblogic-a" "weblogic-b" "haproxy")
        for service in "${expected_services[@]}"; do
            if grep -q "^  $service:" "$compose_file"; then
                log_check_result "Service Definition" "PASS" "Servicio $service definido"
            else
                log_check_result "Service Definition" "FAIL" "Servicio $service NO definido"
            fi
        done
        
        # Verificar redes
        if grep -q "networks:" "$compose_file"; then
            log_check_result "Networks Definition" "PASS" "Redes Docker definidas"
        else
            log_check_result "Networks Definition" "WARN" "No se encontraron definiciones de red"
        fi
        
        # Verificar volúmenes
        if grep -q "volumes:" "$compose_file"; then
            log_check_result "Volumes Definition" "PASS" "Volúmenes Docker definidos"
        else
            log_check_result "Volumes Definition" "WARN" "No se encontraron definiciones de volumen"
        fi
    else
        log_check_result "Docker Compose File" "FAIL" "docker-compose.yml no encontrado"
    fi
    
    echo ""
}

# Función para validar configuración HAProxy
validate_haproxy_configuration() {
    echo -e "${CYAN}⚖️  Validando Configuración HAProxy${NC}"
    echo "----------------------------------------"
    
    local haproxy_config="$PROJECT_ROOT/haproxy/config/haproxy.cfg"
    
    if [ -f "$haproxy_config" ]; then
        # Verificar secciones principales
        local sections=("global" "defaults" "frontend" "backend")
        for section in "${sections[@]}"; do
            if grep -q "^$section" "$haproxy_config"; then
                log_check_result "HAProxy Section" "PASS" "Sección $section presente"
            else
                log_check_result "HAProxy Section" "FAIL" "Sección $section ausente"
            fi
        done
        
        # Verificar configuración de stats
        if grep -q "stats enable" "$haproxy_config"; then
            log_check_result "HAProxy Stats" "PASS" "Estadísticas habilitadas"
        else
            log_check_result "HAProxy Stats" "WARN" "Estadísticas no habilitadas"
        fi
        
        # Verificar configuración de health checks
        if grep -q "check" "$haproxy_config"; then
            log_check_result "HAProxy Health Checks" "PASS" "Health checks configurados"
        else
            log_check_result "HAProxy Health Checks" "WARN" "Health checks no configurados"
        fi
        
        # Verificar balance algorithm
        if grep -q "balance" "$haproxy_config"; then
            local balance_method=$(grep "balance" "$haproxy_config" | head -1 | awk '{print $2}')
            log_check_result "HAProxy Balance" "PASS" "Método de balance: $balance_method"
        else
            log_check_result "HAProxy Balance" "WARN" "Método de balance no especificado"
        fi
        
        # Verificar sintaxis HAProxy si está disponible
        if docker ps | grep -q haproxy; then
            if docker exec haproxy haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg > /dev/null 2>&1; then
                log_check_result "HAProxy Syntax" "PASS" "Sintaxis HAProxy válida"
            else
                log_check_result "HAProxy Syntax" "FAIL" "Sintaxis HAProxy inválida"
            fi
        else
            log_check_result "HAProxy Container" "WARN" "Contenedor HAProxy no disponible para validación"
        fi
    else
        log_check_result "HAProxy Config File" "FAIL" "Archivo de configuración HAProxy no encontrado"
    fi
    
    echo ""
}

# Función para validar permisos de archivos
validate_file_permissions() {
    echo -e "${CYAN}🔐 Validando Permisos de Archivos${NC}"
    echo "----------------------------------------"
    
    # Scripts que deben ser ejecutables
    local executable_files=(
        "manage-services.sh"
        "start-all.sh"
        "scripts/core/load-env.sh"
        "scripts/core/docker-compose-wrapper.sh"
        "scripts/deploy/deploy-war.sh"
        "scripts/deploy/deploy-complete.sh"
        "scripts/canary/manage-traffic.sh"
        "scripts/canary/simulate-traffic.sh"
        "scripts/canary/test-canary.sh"
        "scripts/check-urls.sh"
        "scripts/validate-complete-system.sh"
        "scripts/test-integration.sh"
        "scripts/test-performance.sh"
        "scripts/run-all-tests.sh"
        "scripts/validate-config-consistency.sh"
    )
    
    for file in "${executable_files[@]}"; do
        local full_path="$PROJECT_ROOT/$file"
        if [ -f "$full_path" ]; then
            if [ -x "$full_path" ]; then
                log_check_result "File Permissions" "PASS" "$file es ejecutable"
            else
                log_check_result "File Permissions" "FAIL" "$file NO es ejecutable"
            fi
        else
            log_check_result "File Exists" "WARN" "$file no encontrado"
        fi
    done
    
    # Archivos de configuración que deben ser legibles
    local config_files=(
        ".env"
        "docker-compose.yml"
        "haproxy/config/haproxy.cfg"
    )
    
    for file in "${config_files[@]}"; do
        local full_path="$PROJECT_ROOT/$file"
        if [ -f "$full_path" ]; then
            if [ -r "$full_path" ]; then
                log_check_result "Config Readable" "PASS" "$file es legible"
            else
                log_check_result "Config Readable" "FAIL" "$file NO es legible"
            fi
        else
            log_check_result "Config Exists" "FAIL" "$file no encontrado"
        fi
    done
    
    echo ""
}

# Función para corregir permisos
fix_permissions() {
    echo -e "${CYAN}🔧 Corrigiendo Permisos de Archivos${NC}"
    echo "----------------------------------------"
    
    # Scripts que deben ser ejecutables
    local executable_files=(
        "manage-services.sh"
        "start-all.sh"
        "scripts/core/load-env.sh"
        "scripts/core/docker-compose-wrapper.sh"
        "scripts/deploy/deploy-war.sh"
        "scripts/deploy/deploy-complete.sh"
        "scripts/canary/manage-traffic.sh"
        "scripts/canary/simulate-traffic.sh"
        "scripts/canary/test-canary.sh"
        "scripts/check-urls.sh"
        "scripts/validate-complete-system.sh"
        "scripts/test-integration.sh"
        "scripts/test-performance.sh"
        "scripts/run-all-tests.sh"
        "scripts/validate-config-consistency.sh"
    )
    
    for file in "${executable_files[@]}"; do
        local full_path="$PROJECT_ROOT/$file"
        if [ -f "$full_path" ]; then
            chmod +x "$full_path"
            echo -e "${GREEN}✅${NC} Permisos corregidos para $file"
        fi
    done
    
    echo ""
}

# Función para mostrar resumen final
show_final_summary() {
    echo -e "${BLUE}📊 RESUMEN DE VALIDACIÓN DE CONSISTENCIA${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""
    echo -e "${BLUE}Estadísticas de Validación:${NC}"
    echo -e "  Total de checks ejecutados: ${CYAN}$TOTAL_CHECKS${NC}"
    echo -e "  Checks exitosos: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "  Checks fallidos: ${RED}$FAILED_CHECKS${NC}"
    echo -e "  Advertencias: ${YELLOW}$WARNING_CHECKS${NC}"
    echo ""
    
    # Calcular porcentaje de éxito
    local success_rate=0
    if [ $TOTAL_CHECKS -gt 0 ]; then
        success_rate=$(echo "scale=2; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc -l 2>/dev/null || echo "0")
    fi
    
    echo -e "${BLUE}Tasa de Éxito: ${CYAN}${success_rate}%${NC}"
    echo ""
    
    # Determinar estado general
    if [ $FAILED_CHECKS -eq 0 ]; then
        if [ $WARNING_CHECKS -eq 0 ]; then
            echo -e "${GREEN}🎉 CONFIGURACIÓN COMPLETAMENTE CONSISTENTE${NC}"
            echo -e "${GREEN}Todas las validaciones pasaron exitosamente${NC}"
        else
            echo -e "${YELLOW}⚠️  CONFIGURACIÓN MAYORMENTE CONSISTENTE${NC}"
            echo -e "${YELLOW}Hay algunas advertencias que revisar${NC}"
        fi
    else
        echo -e "${RED}❌ INCONSISTENCIAS DETECTADAS${NC}"
        echo -e "${RED}Hay problemas de configuración que corregir${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Recomendaciones:${NC}"
    
    if [ $FAILED_CHECKS -gt 0 ]; then
        echo -e "  1. Revisar y corregir los checks fallidos"
        echo -e "  2. Verificar archivo .env"
        echo -e "  3. Validar docker-compose.yml"
        echo -e "  4. Revisar configuración HAProxy"
        echo -e "  5. Ejecutar: $0 --fix-permissions"
    fi
    
    if [ $WARNING_CHECKS -gt 0 ]; then
        echo -e "  6. Revisar advertencias para optimización"
        echo -e "  7. Considerar mejoras de configuración"
    fi
    
    if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
        echo -e "  1. Configuración óptima detectada"
        echo -e "  2. Sistema listo para operación"
    fi
    
    echo ""
}

# Función principal
main() {
    local validation_mode="${1:-full}"
    
    case "$validation_mode" in
        --help|-h)
            show_help
            return 0
            ;;
        --ports-only)
            load_configuration
            validate_port_consistency
            ;;
        --env-only)
            load_configuration
            validate_environment_variables
            ;;
        --docker-only)
            load_configuration
            validate_docker_configuration
            ;;
        --haproxy-only)
            load_configuration
            validate_haproxy_configuration
            ;;
        --fix-permissions)
            fix_permissions
            return 0
            ;;
        *)
            # Validación completa
            load_configuration
            validate_port_consistency
            validate_environment_variables
            validate_docker_configuration
            validate_haproxy_configuration
            validate_file_permissions
            ;;
    esac
    
    show_final_summary
}

# Ejecutar función principal
main "$@"
