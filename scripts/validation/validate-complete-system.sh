#!/bin/bash
# Script de validación completa del sistema
# Valida toda la infraestructura, configuración y funcionalidades

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Variables globales para estadísticas
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

echo -e "${PURPLE}🔍 VALIDACIÓN COMPLETA DEL SISTEMA${NC}"
echo -e "${PURPLE}====================================${NC}"
echo ""

# Función para registrar resultado de test
log_test_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    ((TOTAL_TESTS++))
    
    case "$result" in
        "PASS")
            ((PASSED_TESTS++))
            echo -e "${GREEN}✅ PASS${NC} - $test_name: $message"
            ;;
        "FAIL")
            ((FAILED_TESTS++))
            echo -e "${RED}❌ FAIL${NC} - $test_name: $message"
            ;;
        "WARN")
            ((WARNING_TESTS++))
            echo -e "${YELLOW}⚠️  WARN${NC} - $test_name: $message"
            ;;
    esac
}

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Validador Completo del Sistema ===${NC}"
    echo ""
    echo -e "${YELLOW}Uso: $0 [OPCIÓN]${NC}"
    echo ""
    echo -e "${BLUE}Opciones:${NC}"
    echo "  --help, -h              Mostrar esta ayuda"
    echo "  --quick                 Validación rápida (solo tests críticos)"
    echo "  --config-only           Solo validar configuración"
    echo "  --services-only         Solo validar servicios"
    echo "  --scripts-only          Solo validar scripts"
    echo "  --connectivity-only     Solo validar conectividad"
    echo "  --performance           Incluir tests de performance"
    echo "  --verbose               Salida detallada"
    echo ""
    echo -e "${BLUE}Descripción:${NC}"
    echo "  Este script realiza una validación completa de:"
    echo "  - Configuración del sistema"
    echo "  - Estado de servicios Docker"
    echo "  - Funcionalidad de scripts"
    echo "  - Conectividad de red"
    echo "  - Integridad de archivos"
    echo "  - Performance básica (opcional)"
    echo ""
}

# Función para cargar configuración
load_configuration() {
    echo -e "${CYAN}📋 FASE 1: Cargando Configuración${NC}"
    echo "----------------------------------------"
    
    if [ -f "$PROJECT_ROOT/scripts/core/load-env.sh" ]; then
        source "$PROJECT_ROOT/scripts/core/load-env.sh"
        if load_env > /dev/null 2>&1; then
            log_test_result "Config Load" "PASS" "Configuración cargada correctamente"
        else
            log_test_result "Config Load" "FAIL" "Error al cargar configuración"
            return 1
        fi
    else
        log_test_result "Config Load" "FAIL" "Archivo load-env.sh no encontrado"
        return 1
    fi
    
    # Verificar variables críticas
    local critical_vars=(
        "WEBLOGIC_A_EXTERNAL_PORT"
        "WEBLOGIC_B_EXTERNAL_PORT"
        "HAPROXY_HTTP_EXTERNAL_PORT"
        "HAPROXY_STATS_EXTERNAL_PORT"
    )
    
    for var in "${critical_vars[@]}"; do
        if [ -n "${!var}" ]; then
            log_test_result "Config Var $var" "PASS" "Variable definida: ${!var}"
        else
            log_test_result "Config Var $var" "FAIL" "Variable no definida"
        fi
    done
    
    echo ""
}

# Función para validar archivos del sistema
validate_system_files() {
    echo -e "${CYAN}📁 FASE 2: Validando Archivos del Sistema${NC}"
    echo "----------------------------------------"
    
    # Archivos críticos que deben existir
    local critical_files=(
        ".env"
        "docker-compose.yml"
        "manage-services.sh"
        "start-all.sh"
        "scripts/core/load-env.sh"
        "scripts/core/docker-compose-wrapper.sh"
        "haproxy/config/haproxy.cfg"
    )
    
    for file in "${critical_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            log_test_result "File Exists" "PASS" "$file encontrado"
        else
            log_test_result "File Exists" "FAIL" "$file NO encontrado"
        fi
    done
    
    # Verificar permisos de scripts
    local executable_scripts=(
        "manage-services.sh"
        "start-all.sh"
        "scripts/core/load-env.sh"
        "scripts/core/docker-compose-wrapper.sh"
    )
    
    for script in "${executable_scripts[@]}"; do
        if [ -x "$PROJECT_ROOT/$script" ]; then
            log_test_result "Script Executable" "PASS" "$script es ejecutable"
        else
            log_test_result "Script Executable" "FAIL" "$script NO es ejecutable"
        fi
    done
    
    # Verificar integridad de configuración HAProxy
    if [ -f "$PROJECT_ROOT/haproxy/config/haproxy.cfg" ]; then
        if grep -q "weblogic-a" "$PROJECT_ROOT/haproxy/config/haproxy.cfg" && \
           grep -q "weblogic-b" "$PROJECT_ROOT/haproxy/config/haproxy.cfg"; then
            log_test_result "HAProxy Config" "PASS" "Configuración HAProxy válida"
        else
            log_test_result "HAProxy Config" "FAIL" "Configuración HAProxy incompleta"
        fi
    fi
    
    echo ""
}

# Función para validar servicios Docker
validate_docker_services() {
    echo -e "${CYAN}🐳 FASE 3: Validando Servicios Docker${NC}"
    echo "----------------------------------------"
    
    # Verificar que Docker esté disponible
    if command -v docker >/dev/null 2>&1; then
        log_test_result "Docker Available" "PASS" "Docker está disponible"
    else
        log_test_result "Docker Available" "FAIL" "Docker NO está disponible"
        return 1
    fi
    
    # Verificar que docker-compose esté disponible
    if command -v docker-compose >/dev/null 2>&1; then
        log_test_result "Docker Compose Available" "PASS" "docker-compose está disponible"
    else
        log_test_result "Docker Compose Available" "FAIL" "docker-compose NO está disponible"
    fi
    
    # Verificar servicios en ejecución
    local expected_services=("weblogic-a" "weblogic-b" "haproxy")
    local running_services=0
    
    for service in "${expected_services[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "$service"; then
            log_test_result "Service Running" "PASS" "$service está ejecutándose"
            ((running_services++))
        else
            log_test_result "Service Running" "WARN" "$service NO está ejecutándose"
        fi
    done
    
    # Verificar estado general de servicios
    if [ $running_services -eq ${#expected_services[@]} ]; then
        log_test_result "All Services" "PASS" "Todos los servicios están ejecutándose"
    elif [ $running_services -gt 0 ]; then
        log_test_result "All Services" "WARN" "Solo $running_services/${#expected_services[@]} servicios ejecutándose"
    else
        log_test_result "All Services" "FAIL" "Ningún servicio está ejecutándose"
    fi
    
    # Verificar salud de contenedores
    for service in "${expected_services[@]}"; do
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$service" | grep -q "Up"; then
            log_test_result "Service Health" "PASS" "$service está saludable"
        elif docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -q "$service"; then
            log_test_result "Service Health" "WARN" "$service existe pero no está Up"
        else
            log_test_result "Service Health" "FAIL" "$service no existe"
        fi
    done
    
    echo ""
}

# Función para validar conectividad de red
validate_network_connectivity() {
    echo -e "${CYAN}🌐 FASE 4: Validando Conectividad de Red${NC}"
    echo "----------------------------------------"
    
    if ! command -v curl >/dev/null 2>&1; then
        log_test_result "Curl Available" "FAIL" "curl no está disponible"
        return 1
    fi
    
    log_test_result "Curl Available" "PASS" "curl está disponible"
    
    # URLs a probar
    local test_urls=(
        "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/:HAProxy HTTP"
        "http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats:HAProxy Stats"
        "http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}/:HAProxy Admin"
        "http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/:WebLogic A"
        "http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/:WebLogic B"
    )
    
    for url_info in "${test_urls[@]}"; do
        local url=$(echo "$url_info" | cut -d':' -f1-2)
        local service_name=$(echo "$url_info" | cut -d':' -f3)
        
        if curl -s -m 5 "$url" > /dev/null 2>&1; then
            log_test_result "Connectivity" "PASS" "$service_name responde correctamente"
        else
            log_test_result "Connectivity" "WARN" "$service_name no responde (puede ser normal si no hay apps)"
        fi
    done
    
    # Verificar conectividad interna entre contenedores
    if docker ps | grep -q haproxy && docker ps | grep -q weblogic-a; then
        if docker exec haproxy ping -c 1 weblogic-a > /dev/null 2>&1; then
            log_test_result "Internal Network" "PASS" "HAProxy puede alcanzar WebLogic A"
        else
            log_test_result "Internal Network" "FAIL" "HAProxy NO puede alcanzar WebLogic A"
        fi
    fi
    
    if docker ps | grep -q haproxy && docker ps | grep -q weblogic-b; then
        if docker exec haproxy ping -c 1 weblogic-b > /dev/null 2>&1; then
            log_test_result "Internal Network" "PASS" "HAProxy puede alcanzar WebLogic B"
        else
            log_test_result "Internal Network" "FAIL" "HAProxy NO puede alcanzar WebLogic B"
        fi
    fi
    
    echo ""
}

# Función para validar scripts
validate_scripts() {
    echo -e "${CYAN}📜 FASE 5: Validando Scripts${NC}"
    echo "----------------------------------------"
    
    # Scripts críticos a validar
    local critical_scripts=(
        "manage-services.sh"
        "start-all.sh"
        "scripts/deploy/deploy-war.sh"
        "scripts/deploy/deploy-complete.sh"
        "scripts/canary/manage-traffic.sh"
        "scripts/canary/simulate-traffic.sh"
        "scripts/canary/test-canary.sh"
        "scripts/check-urls.sh"
    )
    
    for script in "${critical_scripts[@]}"; do
        if [ -f "$PROJECT_ROOT/$script" ]; then
            # Verificar que el script es ejecutable
            if [ -x "$PROJECT_ROOT/$script" ]; then
                log_test_result "Script Executable" "PASS" "$script es ejecutable"
                
                # Probar ejecución de ayuda
                if "$PROJECT_ROOT/$script" --help > /dev/null 2>&1; then
                    log_test_result "Script Help" "PASS" "$script --help funciona"
                else
                    log_test_result "Script Help" "WARN" "$script --help no funciona"
                fi
                
                # Verificar que usa configuración centralizada
                if grep -q "load-env.sh" "$PROJECT_ROOT/$script"; then
                    log_test_result "Script Config" "PASS" "$script usa configuración centralizada"
                else
                    log_test_result "Script Config" "WARN" "$script no usa configuración centralizada"
                fi
            else
                log_test_result "Script Executable" "FAIL" "$script NO es ejecutable"
            fi
        else
            log_test_result "Script Exists" "FAIL" "$script NO encontrado"
        fi
    done
    
    echo ""
}

# Función para validar configuración de HAProxy
validate_haproxy_configuration() {
    echo -e "${CYAN}⚖️  FASE 6: Validando Configuración HAProxy${NC}"
    echo "----------------------------------------"
    
    if docker ps | grep -q haproxy; then
        # Verificar configuración HAProxy
        if docker exec haproxy haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg > /dev/null 2>&1; then
            log_test_result "HAProxy Config Valid" "PASS" "Configuración HAProxy es válida"
        else
            log_test_result "HAProxy Config Valid" "FAIL" "Configuración HAProxy NO es válida"
        fi
        
        # Verificar estadísticas HAProxy
        if curl -s "http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats" > /dev/null 2>&1; then
            log_test_result "HAProxy Stats" "PASS" "Estadísticas HAProxy accesibles"
        else
            log_test_result "HAProxy Stats" "FAIL" "Estadísticas HAProxy NO accesibles"
        fi
        
        # Verificar backends configurados
        if curl -s "http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats;csv" 2>/dev/null | grep -q "weblogic-a"; then
            log_test_result "HAProxy Backend A" "PASS" "Backend weblogic-a configurado"
        else
            log_test_result "HAProxy Backend A" "FAIL" "Backend weblogic-a NO configurado"
        fi
        
        if curl -s "http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats;csv" 2>/dev/null | grep -q "weblogic-b"; then
            log_test_result "HAProxy Backend B" "PASS" "Backend weblogic-b configurado"
        else
            log_test_result "HAProxy Backend B" "FAIL" "Backend weblogic-b NO configurado"
        fi
    else
        log_test_result "HAProxy Running" "FAIL" "HAProxy no está ejecutándose"
    fi
    
    echo ""
}

# Función para tests de performance básicos
validate_performance() {
    echo -e "${CYAN}⚡ FASE 7: Tests de Performance Básicos${NC}"
    echo "----------------------------------------"
    
    if ! command -v curl >/dev/null 2>&1; then
        log_test_result "Performance Tools" "FAIL" "curl no disponible para tests de performance"
        return 1
    fi
    
    # Test de tiempo de respuesta HAProxy
    local start_time=$(date +%s.%N)
    if curl -s -m 10 "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/" > /dev/null 2>&1; then
        local end_time=$(date +%s.%N)
        local response_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
        
        if [ "$response_time" != "N/A" ] && (( $(echo "$response_time < 5.0" | bc -l) )); then
            log_test_result "HAProxy Response Time" "PASS" "Tiempo de respuesta: ${response_time}s"
        else
            log_test_result "HAProxy Response Time" "WARN" "Tiempo de respuesta lento: ${response_time}s"
        fi
    else
        log_test_result "HAProxy Response Time" "FAIL" "HAProxy no responde"
    fi
    
    # Test de múltiples requests
    local success_count=0
    local total_requests=10
    
    for ((i=1; i<=total_requests; i++)); do
        if curl -s -m 3 "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/" > /dev/null 2>&1; then
            ((success_count++))
        fi
    done
    
    local success_rate=$(echo "scale=2; $success_count * 100 / $total_requests" | bc -l 2>/dev/null || echo "0")
    
    if (( $(echo "$success_rate >= 90" | bc -l 2>/dev/null || echo "0") )); then
        log_test_result "Multiple Requests" "PASS" "Tasa de éxito: ${success_rate}% ($success_count/$total_requests)"
    elif (( $(echo "$success_rate >= 70" | bc -l 2>/dev/null || echo "0") )); then
        log_test_result "Multiple Requests" "WARN" "Tasa de éxito: ${success_rate}% ($success_count/$total_requests)"
    else
        log_test_result "Multiple Requests" "FAIL" "Tasa de éxito: ${success_rate}% ($success_count/$total_requests)"
    fi
    
    echo ""
}

# Función para mostrar resumen final
show_final_summary() {
    echo -e "${PURPLE}📊 RESUMEN FINAL DE VALIDACIÓN${NC}"
    echo -e "${PURPLE}===============================${NC}"
    echo ""
    echo -e "${BLUE}Estadísticas de Tests:${NC}"
    echo -e "  Total de tests ejecutados: ${CYAN}$TOTAL_TESTS${NC}"
    echo -e "  Tests exitosos: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "  Tests fallidos: ${RED}$FAILED_TESTS${NC}"
    echo -e "  Advertencias: ${YELLOW}$WARNING_TESTS${NC}"
    echo ""
    
    # Calcular porcentaje de éxito
    local success_rate=0
    if [ $TOTAL_TESTS -gt 0 ]; then
        success_rate=$(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc -l 2>/dev/null || echo "0")
    fi
    
    echo -e "${BLUE}Tasa de Éxito: ${CYAN}${success_rate}%${NC}"
    echo ""
    
    # Determinar estado general del sistema
    if [ $FAILED_TESTS -eq 0 ]; then
        if [ $WARNING_TESTS -eq 0 ]; then
            echo -e "${GREEN}🎉 SISTEMA COMPLETAMENTE VALIDADO${NC}"
            echo -e "${GREEN}Todos los tests pasaron exitosamente${NC}"
        else
            echo -e "${YELLOW}⚠️  SISTEMA MAYORMENTE VALIDADO${NC}"
            echo -e "${YELLOW}Hay algunas advertencias que revisar${NC}"
        fi
    elif [ $FAILED_TESTS -le 2 ]; then
        echo -e "${YELLOW}⚠️  SISTEMA PARCIALMENTE VALIDADO${NC}"
        echo -e "${YELLOW}Hay algunos problemas menores que corregir${NC}"
    else
        echo -e "${RED}❌ SISTEMA REQUIERE ATENCIÓN${NC}"
        echo -e "${RED}Hay problemas significativos que resolver${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Recomendaciones:${NC}"
    
    if [ $FAILED_TESTS -gt 0 ]; then
        echo -e "  1. Revisar y corregir los tests fallidos"
        echo -e "  2. Ejecutar: ./manage-services.sh start (si servicios no están corriendo)"
        echo -e "  3. Verificar configuración en .env"
    fi
    
    if [ $WARNING_TESTS -gt 0 ]; then
        echo -e "  4. Revisar advertencias para optimización"
        echo -e "  5. Considerar desplegar aplicaciones de prueba"
    fi
    
    echo -e "  6. Ejecutar: ./manage-services.sh status"
    echo -e "  7. Ejecutar: ./manage-services.sh logs"
    echo ""
}

# Función principal
main() {
    local mode="${1:-full}"
    
    case "$mode" in
        --help|-h)
            show_help
            return 0
            ;;
        --quick)
            load_configuration
            validate_system_files
            validate_docker_services
            ;;
        --config-only)
            load_configuration
            validate_system_files
            ;;
        --services-only)
            load_configuration
            validate_docker_services
            ;;
        --scripts-only)
            load_configuration
            validate_scripts
            ;;
        --connectivity-only)
            load_configuration
            validate_network_connectivity
            ;;
        --performance)
            load_configuration
            validate_docker_services
            validate_network_connectivity
            validate_performance
            ;;
        *)
            # Validación completa
            load_configuration
            validate_system_files
            validate_docker_services
            validate_network_connectivity
            validate_scripts
            validate_haproxy_configuration
            
            # Incluir performance si se especifica
            if [ "$1" = "--performance" ]; then
                validate_performance
            fi
            ;;
    esac
    
    show_final_summary
}

# Ejecutar función principal
main "$@"
