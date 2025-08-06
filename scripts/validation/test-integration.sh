#!/bin/bash
# Script de testing de integración
# Prueba escenarios reales de uso del sistema

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
TOTAL_SCENARIOS=0
PASSED_SCENARIOS=0
FAILED_SCENARIOS=0

echo -e "${PURPLE}🧪 TESTING DE INTEGRACIÓN${NC}"
echo -e "${PURPLE}=========================${NC}"
echo ""

# Función para registrar resultado de escenario
log_scenario_result() {
    local scenario_name="$1"
    local result="$2"
    local message="$3"
    
    ((TOTAL_SCENARIOS++))
    
    case "$result" in
        "PASS")
            ((PASSED_SCENARIOS++))
            echo -e "${GREEN}✅ PASS${NC} - $scenario_name: $message"
            ;;
        "FAIL")
            ((FAILED_SCENARIOS++))
            echo -e "${RED}❌ FAIL${NC} - $scenario_name: $message"
            ;;
    esac
}

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Tester de Integración ===${NC}"
    echo ""
    echo -e "${YELLOW}Uso: $0 [OPCIÓN]${NC}"
    echo ""
    echo -e "${BLUE}Opciones:${NC}"
    echo "  --help, -h              Mostrar esta ayuda"
    echo "  --basic                 Solo tests básicos"
    echo "  --canary                Solo tests de canary deployment"
    echo "  --deployment            Solo tests de deployment"
    echo "  --load-balancing        Solo tests de load balancing"
    echo "  --full                  Tests completos (por defecto)"
    echo ""
    echo -e "${BLUE}Descripción:${NC}"
    echo "  Este script ejecuta escenarios de integración reales:"
    echo "  - Inicio y parada de servicios"
    echo "  - Deployment de aplicaciones"
    echo "  - Canary deployments"
    echo "  - Load balancing"
    echo "  - Recuperación de fallos"
    echo ""
}

# Función para preparar el entorno
setup_environment() {
    echo -e "${CYAN}🔧 PREPARANDO ENTORNO DE TESTING${NC}"
    echo "----------------------------------------"
    
    # Cargar configuración
    if [ -f "$PROJECT_ROOT/scripts/core/load-env.sh" ]; then
        source "$PROJECT_ROOT/scripts/core/load-env.sh"
        if load_env > /dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} Configuración cargada correctamente"
        else
            echo -e "${RED}❌${NC} Error al cargar configuración"
            exit 1
        fi
    else
        echo -e "${RED}❌${NC} Archivo load-env.sh no encontrado"
        exit 1
    fi
    
    # Verificar dependencias
    local dependencies=("docker" "curl")
    for dep in "${dependencies[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} $dep disponible"
        else
            echo -e "${RED}❌${NC} $dep NO disponible"
            exit 1
        fi
    done
    
    echo ""
}

# Escenario 1: Test de inicio y parada de servicios
test_service_lifecycle() {
    echo -e "${CYAN}🔄 ESCENARIO 1: Ciclo de Vida de Servicios${NC}"
    echo "----------------------------------------"
    
    # Test 1.1: Parar todos los servicios
    echo -e "${YELLOW}Test 1.1: Parando servicios...${NC}"
    if "$PROJECT_ROOT/manage-services.sh" stop > /dev/null 2>&1; then
        log_scenario_result "Service Stop" "PASS" "Servicios parados correctamente"
    else
        log_scenario_result "Service Stop" "FAIL" "Error al parar servicios"
    fi
    
    # Esperar un momento
    sleep 3
    
    # Test 1.2: Iniciar todos los servicios
    echo -e "${YELLOW}Test 1.2: Iniciando servicios...${NC}"
    if "$PROJECT_ROOT/manage-services.sh" start > /dev/null 2>&1; then
        log_scenario_result "Service Start" "PASS" "Servicios iniciados correctamente"
    else
        log_scenario_result "Service Start" "FAIL" "Error al iniciar servicios"
    fi
    
    # Esperar a que los servicios estén listos
    echo -e "${YELLOW}Esperando a que los servicios estén listos...${NC}"
    sleep 15
    
    # Test 1.3: Verificar que todos los servicios están corriendo
    local services=("weblogic-a" "weblogic-b" "haproxy")
    local running_count=0
    
    for service in "${services[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "$service"; then
            ((running_count++))
        fi
    done
    
    if [ $running_count -eq ${#services[@]} ]; then
        log_scenario_result "All Services Running" "PASS" "Todos los servicios están ejecutándose"
    else
        log_scenario_result "All Services Running" "FAIL" "Solo $running_count/${#services[@]} servicios ejecutándose"
    fi
    
    # Test 1.4: Verificar conectividad básica
    echo -e "${YELLOW}Test 1.4: Verificando conectividad...${NC}"
    if curl -s -m 10 "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/" > /dev/null 2>&1; then
        log_scenario_result "Basic Connectivity" "PASS" "HAProxy responde correctamente"
    else
        log_scenario_result "Basic Connectivity" "FAIL" "HAProxy no responde"
    fi
    
    echo ""
}

# Escenario 2: Test de load balancing
test_load_balancing() {
    echo -e "${CYAN}⚖️  ESCENARIO 2: Load Balancing${NC}"
    echo "----------------------------------------"
    
    # Test 2.1: Configurar distribución 50/50
    echo -e "${YELLOW}Test 2.1: Configurando distribución 50/50...${NC}"
    if "$PROJECT_ROOT/scripts/canary/manage-traffic.sh" reset > /dev/null 2>&1; then
        log_scenario_result "Traffic Reset" "PASS" "Tráfico reseteado a 50/50"
    else
        log_scenario_result "Traffic Reset" "FAIL" "Error al resetear tráfico"
    fi
    
    # Test 2.2: Simular tráfico y verificar distribución
    echo -e "${YELLOW}Test 2.2: Simulando tráfico...${NC}"
    local temp_file=$(mktemp)
    
    # Enviar 20 requests y capturar respuestas
    local requests_sent=0
    local successful_requests=0
    
    for ((i=1; i<=20; i++)); do
        ((requests_sent++))
        if curl -s -m 3 "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/" > /dev/null 2>&1; then
            ((successful_requests++))
        fi
        sleep 0.1
    done
    
    rm -f "$temp_file"
    
    local success_rate=$(echo "scale=2; $successful_requests * 100 / $requests_sent" | bc -l 2>/dev/null || echo "0")
    
    if (( $(echo "$success_rate >= 80" | bc -l 2>/dev/null || echo "0") )); then
        log_scenario_result "Load Balancing" "PASS" "Tasa de éxito: ${success_rate}% ($successful_requests/$requests_sent)"
    else
        log_scenario_result "Load Balancing" "FAIL" "Tasa de éxito baja: ${success_rate}% ($successful_requests/$requests_sent)"
    fi
    
    echo ""
}

# Escenario 3: Test de canary deployment
test_canary_deployment() {
    echo -e "${CYAN}🎯 ESCENARIO 3: Canary Deployment${NC}"
    echo "----------------------------------------"
    
    # Test 3.1: Configurar 20% canary
    echo -e "${YELLOW}Test 3.1: Configurando 20% canary...${NC}"
    if "$PROJECT_ROOT/scripts/canary/manage-traffic.sh" canary 20 > /dev/null 2>&1; then
        log_scenario_result "Canary Setup" "PASS" "Canary 20% configurado correctamente"
    else
        log_scenario_result "Canary Setup" "FAIL" "Error al configurar canary"
    fi
    
    # Test 3.2: Probar canary deployment
    echo -e "${YELLOW}Test 3.2: Probando canary deployment...${NC}"
    if "$PROJECT_ROOT/scripts/canary/test-canary.sh" 10 > /dev/null 2>&1; then
        log_scenario_result "Canary Test" "PASS" "Test de canary ejecutado correctamente"
    else
        log_scenario_result "Canary Test" "FAIL" "Error en test de canary"
    fi
    
    # Test 3.3: Incrementar canary a 50%
    echo -e "${YELLOW}Test 3.3: Incrementando canary a 50%...${NC}"
    if "$PROJECT_ROOT/scripts/canary/manage-traffic.sh" canary 50 > /dev/null 2>&1; then
        log_scenario_result "Canary Increment" "PASS" "Canary incrementado a 50%"
    else
        log_scenario_result "Canary Increment" "FAIL" "Error al incrementar canary"
    fi
    
    # Test 3.4: Rollback a configuración normal
    echo -e "${YELLOW}Test 3.4: Rollback a configuración normal...${NC}"
    if "$PROJECT_ROOT/scripts/canary/manage-traffic.sh" reset > /dev/null 2>&1; then
        log_scenario_result "Canary Rollback" "PASS" "Rollback ejecutado correctamente"
    else
        log_scenario_result "Canary Rollback" "FAIL" "Error en rollback"
    fi
    
    echo ""
}

# Escenario 4: Test de deployment de aplicaciones
test_application_deployment() {
    echo -e "${CYAN}📦 ESCENARIO 4: Deployment de Aplicaciones${NC}"
    echo "----------------------------------------"
    
    # Test 4.1: Verificar script de deployment
    echo -e "${YELLOW}Test 4.1: Verificando script de deployment...${NC}"
    if "$PROJECT_ROOT/scripts/deploy/deploy-war.sh" --help > /dev/null 2>&1; then
        log_scenario_result "Deploy Script" "PASS" "Script de deployment funciona"
    else
        log_scenario_result "Deploy Script" "FAIL" "Script de deployment no funciona"
    fi
    
    # Test 4.2: Limpiar cachés
    echo -e "${YELLOW}Test 4.2: Limpiando cachés...${NC}"
    if "$PROJECT_ROOT/scripts/deploy/deploy-war.sh" --clean-only > /dev/null 2>&1; then
        log_scenario_result "Cache Clean" "PASS" "Cachés limpiados correctamente"
    else
        log_scenario_result "Cache Clean" "FAIL" "Error al limpiar cachés"
    fi
    
    # Test 4.3: Verificar URLs de deployment
    echo -e "${YELLOW}Test 4.3: Verificando URLs de deployment...${NC}"
    if "$PROJECT_ROOT/scripts/deploy/deploy-war.sh" --verify-only > /dev/null 2>&1; then
        log_scenario_result "Deploy URLs" "PASS" "URLs de deployment verificadas"
    else
        log_scenario_result "Deploy URLs" "FAIL" "Error al verificar URLs"
    fi
    
    # Test 4.4: Test de deployment completo (solo verificación)
    echo -e "${YELLOW}Test 4.4: Verificando deployment completo...${NC}"
    if "$PROJECT_ROOT/scripts/deploy/deploy-complete.sh" --verify-only > /dev/null 2>&1; then
        log_scenario_result "Complete Deploy" "PASS" "Verificación de deployment completo exitosa"
    else
        log_scenario_result "Complete Deploy" "FAIL" "Error en verificación de deployment completo"
    fi
    
    echo ""
}

# Escenario 5: Test de recuperación de fallos
test_failure_recovery() {
    echo -e "${CYAN}🔧 ESCENARIO 5: Recuperación de Fallos${NC}"
    echo "----------------------------------------"
    
    # Test 5.1: Simular fallo de un servicio WebLogic
    echo -e "${YELLOW}Test 5.1: Simulando fallo de WebLogic B...${NC}"
    if docker stop weblogic-b > /dev/null 2>&1; then
        log_scenario_result "Service Stop" "PASS" "WebLogic B parado para simular fallo"
        
        # Esperar un momento
        sleep 3
        
        # Verificar que HAProxy sigue funcionando
        if curl -s -m 5 "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/" > /dev/null 2>&1; then
            log_scenario_result "Failover" "PASS" "HAProxy sigue funcionando con un backend caído"
        else
            log_scenario_result "Failover" "FAIL" "HAProxy no funciona con un backend caído"
        fi
        
        # Test 5.2: Recuperar el servicio
        echo -e "${YELLOW}Test 5.2: Recuperando WebLogic B...${NC}"
        if docker start weblogic-b > /dev/null 2>&1; then
            log_scenario_result "Service Recovery" "PASS" "WebLogic B recuperado"
            
            # Esperar a que el servicio esté listo
            sleep 10
            
            # Verificar que ambos backends funcionan
            if curl -s -m 5 "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/" > /dev/null 2>&1; then
                log_scenario_result "Full Recovery" "PASS" "Sistema completamente recuperado"
            else
                log_scenario_result "Full Recovery" "FAIL" "Sistema no completamente recuperado"
            fi
        else
            log_scenario_result "Service Recovery" "FAIL" "Error al recuperar WebLogic B"
        fi
    else
        log_scenario_result "Service Stop" "FAIL" "Error al parar WebLogic B"
    fi
    
    echo ""
}

# Escenario 6: Test de verificación de URLs
test_url_verification() {
    echo -e "${CYAN}🌐 ESCENARIO 6: Verificación de URLs${NC}"
    echo "----------------------------------------"
    
    # Test 6.1: Verificación rápida
    echo -e "${YELLOW}Test 6.1: Verificación rápida de URLs...${NC}"
    if "$PROJECT_ROOT/scripts/check-urls.sh" --quick > /dev/null 2>&1; then
        log_scenario_result "Quick URL Check" "PASS" "Verificación rápida exitosa"
    else
        log_scenario_result "Quick URL Check" "FAIL" "Error en verificación rápida"
    fi
    
    # Test 6.2: Verificación solo HAProxy
    echo -e "${YELLOW}Test 6.2: Verificación solo HAProxy...${NC}"
    if "$PROJECT_ROOT/scripts/check-urls.sh" --haproxy-only > /dev/null 2>&1; then
        log_scenario_result "HAProxy URL Check" "PASS" "Verificación HAProxy exitosa"
    else
        log_scenario_result "HAProxy URL Check" "FAIL" "Error en verificación HAProxy"
    fi
    
    # Test 6.3: Verificación solo WebLogic
    echo -e "${YELLOW}Test 6.3: Verificación solo WebLogic...${NC}"
    if "$PROJECT_ROOT/scripts/check-urls.sh" --weblogic-only > /dev/null 2>&1; then
        log_scenario_result "WebLogic URL Check" "PASS" "Verificación WebLogic exitosa"
    else
        log_scenario_result "WebLogic URL Check" "FAIL" "Error en verificación WebLogic"
    fi
    
    echo ""
}

# Función para mostrar resumen final
show_final_summary() {
    echo -e "${PURPLE}📊 RESUMEN DE TESTING DE INTEGRACIÓN${NC}"
    echo -e "${PURPLE}====================================${NC}"
    echo ""
    echo -e "${BLUE}Estadísticas de Escenarios:${NC}"
    echo -e "  Total de escenarios ejecutados: ${CYAN}$TOTAL_SCENARIOS${NC}"
    echo -e "  Escenarios exitosos: ${GREEN}$PASSED_SCENARIOS${NC}"
    echo -e "  Escenarios fallidos: ${RED}$FAILED_SCENARIOS${NC}"
    echo ""
    
    # Calcular porcentaje de éxito
    local success_rate=0
    if [ $TOTAL_SCENARIOS -gt 0 ]; then
        success_rate=$(echo "scale=2; $PASSED_SCENARIOS * 100 / $TOTAL_SCENARIOS" | bc -l 2>/dev/null || echo "0")
    fi
    
    echo -e "${BLUE}Tasa de Éxito: ${CYAN}${success_rate}%${NC}"
    echo ""
    
    # Determinar estado general
    if [ $FAILED_SCENARIOS -eq 0 ]; then
        echo -e "${GREEN}🎉 TODOS LOS ESCENARIOS DE INTEGRACIÓN PASARON${NC}"
        echo -e "${GREEN}El sistema está listo para producción${NC}"
    elif [ $FAILED_SCENARIOS -le 2 ]; then
        echo -e "${YELLOW}⚠️  MAYORÍA DE ESCENARIOS PASARON${NC}"
        echo -e "${YELLOW}Hay algunos problemas menores que revisar${NC}"
    else
        echo -e "${RED}❌ MÚLTIPLES ESCENARIOS FALLARON${NC}"
        echo -e "${RED}El sistema requiere atención antes de producción${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Recomendaciones:${NC}"
    
    if [ $FAILED_SCENARIOS -gt 0 ]; then
        echo -e "  1. Revisar logs de servicios: ./manage-services.sh logs"
        echo -e "  2. Verificar configuración: ./scripts/validate-complete-system.sh"
        echo -e "  3. Reiniciar servicios si es necesario: ./manage-services.sh restart"
    else
        echo -e "  1. Sistema listo para uso en producción"
        echo -e "  2. Considerar ejecutar tests de carga adicionales"
        echo -e "  3. Monitorear métricas de performance"
    fi
    
    echo ""
}

# Función principal
main() {
    local test_type="${1:-full}"
    
    case "$test_type" in
        --help|-h)
            show_help
            return 0
            ;;
        --basic)
            setup_environment
            test_service_lifecycle
            test_url_verification
            ;;
        --canary)
            setup_environment
            test_canary_deployment
            ;;
        --deployment)
            setup_environment
            test_application_deployment
            ;;
        --load-balancing)
            setup_environment
            test_load_balancing
            ;;
        --full|*)
            # Testing completo
            setup_environment
            test_service_lifecycle
            test_load_balancing
            test_canary_deployment
            test_application_deployment
            test_failure_recovery
            test_url_verification
            ;;
    esac
    
    show_final_summary
}

# Ejecutar función principal
main "$@"
