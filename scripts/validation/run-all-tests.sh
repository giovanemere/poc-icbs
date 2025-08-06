#!/bin/bash
# Script maestro para ejecutar todas las validaciones y tests
# Orquesta la ejecución completa de validación del sistema

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Variables globales para estadísticas
TOTAL_PHASES=0
PASSED_PHASES=0
FAILED_PHASES=0

echo -e "${BOLD}${PURPLE}🚀 VALIDACIÓN COMPLETA DEL SISTEMA${NC}"
echo -e "${BOLD}${PURPLE}===================================${NC}"
echo ""
echo -e "${CYAN}Este script ejecuta una validación completa del sistema incluyendo:${NC}"
echo -e "${CYAN}• Validación de configuración y archivos${NC}"
echo -e "${CYAN}• Testing de integración${NC}"
echo -e "${CYAN}• Testing de performance${NC}"
echo -e "${CYAN}• Validación de scripts de gestión${NC}"
echo ""

# Función para registrar resultado de fase
log_phase_result() {
    local phase_name="$1"
    local result="$2"
    local message="$3"
    
    ((TOTAL_PHASES++))
    
    case "$result" in
        "PASS")
            ((PASSED_PHASES++))
            echo -e "${GREEN}✅ FASE EXITOSA${NC} - $phase_name: $message"
            ;;
        "FAIL")
            ((FAILED_PHASES++))
            echo -e "${RED}❌ FASE FALLIDA${NC} - $phase_name: $message"
            ;;
    esac
}

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Script Maestro de Validación ===${NC}"
    echo ""
    echo -e "${YELLOW}Uso: $0 [OPCIÓN]${NC}"
    echo ""
    echo -e "${BLUE}Opciones:${NC}"
    echo "  --help, -h              Mostrar esta ayuda"
    echo "  --quick                 Validación rápida (solo tests críticos)"
    echo "  --no-performance        Omitir tests de performance"
    echo "  --performance-only      Solo tests de performance"
    echo "  --integration-only      Solo tests de integración"
    echo "  --validation-only       Solo validación de sistema"
    echo "  --continue-on-error     Continuar aunque fallen algunas fases"
    echo "  --verbose               Salida detallada"
    echo ""
    echo -e "${BLUE}Descripción:${NC}"
    echo "  Este script ejecuta una batería completa de tests:"
    echo ""
    echo -e "${CYAN}  FASE 1: Validación del Sistema${NC}"
    echo "    • Configuración y archivos"
    echo "    • Servicios Docker"
    echo "    • Conectividad de red"
    echo "    • Scripts de gestión"
    echo ""
    echo -e "${CYAN}  FASE 2: Testing de Integración${NC}"
    echo "    • Ciclo de vida de servicios"
    echo "    • Load balancing"
    echo "    • Canary deployments"
    echo "    • Recuperación de fallos"
    echo ""
    echo -e "${CYAN}  FASE 3: Testing de Performance${NC}"
    echo "    • Tiempo de respuesta"
    echo "    • Throughput"
    echo "    • Tests de carga"
    echo "    • Concurrencia"
    echo ""
    echo -e "${CYAN}  FASE 4: Validación de Scripts${NC}"
    echo "    • Scripts de deployment"
    echo "    • Scripts de canary"
    echo "    • Scripts de verificación"
    echo ""
}

# Función para mostrar banner de fase
show_phase_banner() {
    local phase_number="$1"
    local phase_name="$2"
    local phase_description="$3"
    
    echo ""
    echo -e "${BOLD}${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${PURPLE}  FASE $phase_number: $phase_name${NC}"
    echo -e "${BOLD}${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$phase_description${NC}"
    echo ""
}

# Función para ejecutar comando con manejo de errores
execute_with_error_handling() {
    local command="$1"
    local phase_name="$2"
    local continue_on_error="${3:-false}"
    local verbose="${4:-false}"
    
    echo -e "${YELLOW}Ejecutando: $command${NC}"
    echo ""
    
    local temp_output=$(mktemp)
    local exit_code=0
    
    if [ "$verbose" = "true" ]; then
        # Mostrar salida en tiempo real
        if ! $command 2>&1 | tee "$temp_output"; then
            exit_code=1
        fi
    else
        # Capturar salida y mostrar solo en caso de error
        if ! $command > "$temp_output" 2>&1; then
            exit_code=1
        fi
    fi
    
    if [ $exit_code -eq 0 ]; then
        log_phase_result "$phase_name" "PASS" "Ejecutado correctamente"
        if [ "$verbose" = "false" ]; then
            echo -e "${GREEN}✅ $phase_name completado exitosamente${NC}"
        fi
    else
        log_phase_result "$phase_name" "FAIL" "Error en ejecución"
        echo -e "${RED}❌ Error en $phase_name${NC}"
        
        if [ "$verbose" = "false" ]; then
            echo -e "${YELLOW}Salida del error:${NC}"
            cat "$temp_output"
        fi
        
        if [ "$continue_on_error" = "false" ]; then
            echo -e "${RED}Deteniendo ejecución debido al error${NC}"
            rm -f "$temp_output"
            exit 1
        else
            echo -e "${YELLOW}Continuando a pesar del error...${NC}"
        fi
    fi
    
    rm -f "$temp_output"
    echo ""
}

# FASE 1: Validación del Sistema
run_system_validation() {
    show_phase_banner "1" "VALIDACIÓN DEL SISTEMA" "Verificando configuración, archivos, servicios y conectividad"
    
    local validation_script="$PROJECT_ROOT/scripts/validate-complete-system.sh"
    
    if [ -f "$validation_script" ]; then
        execute_with_error_handling "$validation_script" "Validación del Sistema" "$1" "$2"
    else
        log_phase_result "Validación del Sistema" "FAIL" "Script de validación no encontrado"
        if [ "$1" = "false" ]; then
            exit 1
        fi
    fi
}

# FASE 2: Testing de Integración
run_integration_testing() {
    show_phase_banner "2" "TESTING DE INTEGRACIÓN" "Ejecutando escenarios reales de uso del sistema"
    
    local integration_script="$PROJECT_ROOT/scripts/test-integration.sh"
    
    if [ -f "$integration_script" ]; then
        execute_with_error_handling "$integration_script --full" "Testing de Integración" "$1" "$2"
    else
        log_phase_result "Testing de Integración" "FAIL" "Script de integración no encontrado"
        if [ "$1" = "false" ]; then
            exit 1
        fi
    fi
}

# FASE 3: Testing de Performance
run_performance_testing() {
    show_phase_banner "3" "TESTING DE PERFORMANCE" "Evaluando rendimiento, throughput y capacidad de carga"
    
    local performance_script="$PROJECT_ROOT/scripts/test-performance.sh"
    
    if [ -f "$performance_script" ]; then
        execute_with_error_handling "$performance_script --medium" "Testing de Performance" "$1" "$2"
    else
        log_phase_result "Testing de Performance" "FAIL" "Script de performance no encontrado"
        if [ "$1" = "false" ]; then
            exit 1
        fi
    fi
}

# FASE 4: Validación de Scripts de Gestión
run_scripts_validation() {
    show_phase_banner "4" "VALIDACIÓN DE SCRIPTS" "Verificando scripts de deployment, canary y gestión"
    
    local scripts_validation="$PROJECT_ROOT/scripts/validate-management-scripts-update.sh"
    
    if [ -f "$scripts_validation" ]; then
        execute_with_error_handling "$scripts_validation" "Validación de Scripts" "$1" "$2"
    else
        log_phase_result "Validación de Scripts" "FAIL" "Script de validación de scripts no encontrado"
        if [ "$1" = "false" ]; then
            exit 1
        fi
    fi
}

# Función para mostrar resumen final completo
show_comprehensive_summary() {
    echo ""
    echo -e "${BOLD}${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${PURPLE}  RESUMEN FINAL DE VALIDACIÓN COMPLETA${NC}"
    echo -e "${BOLD}${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${BLUE}📊 Estadísticas Generales:${NC}"
    echo -e "  Total de fases ejecutadas: ${CYAN}$TOTAL_PHASES${NC}"
    echo -e "  Fases exitosas: ${GREEN}$PASSED_PHASES${NC}"
    echo -e "  Fases fallidas: ${RED}$FAILED_PHASES${NC}"
    echo ""
    
    # Calcular porcentaje de éxito
    local success_rate=0
    if [ $TOTAL_PHASES -gt 0 ]; then
        success_rate=$(echo "scale=2; $PASSED_PHASES * 100 / $TOTAL_PHASES" | bc -l 2>/dev/null || echo "0")
    fi
    
    echo -e "${BLUE}Tasa de Éxito General: ${CYAN}${success_rate}%${NC}"
    echo ""
    
    # Determinar estado general del sistema
    if [ $FAILED_PHASES -eq 0 ]; then
        echo -e "${BOLD}${GREEN}🎉 SISTEMA COMPLETAMENTE VALIDADO${NC}"
        echo -e "${GREEN}✅ Todas las fases de validación pasaron exitosamente${NC}"
        echo -e "${GREEN}✅ El sistema está listo para uso en producción${NC}"
        echo ""
        echo -e "${BLUE}🚀 Estado del Sistema: ${GREEN}PRODUCCIÓN READY${NC}"
        
    elif [ $FAILED_PHASES -eq 1 ]; then
        echo -e "${BOLD}${YELLOW}⚠️  SISTEMA MAYORMENTE VALIDADO${NC}"
        echo -e "${YELLOW}⚠️  Una fase falló, pero el sistema es generalmente funcional${NC}"
        echo -e "${YELLOW}⚠️  Se recomienda revisar y corregir los problemas identificados${NC}"
        echo ""
        echo -e "${BLUE}🔧 Estado del Sistema: ${YELLOW}REQUIERE AJUSTES MENORES${NC}"
        
    else
        echo -e "${BOLD}${RED}❌ SISTEMA REQUIERE ATENCIÓN${NC}"
        echo -e "${RED}❌ Múltiples fases fallaron${NC}"
        echo -e "${RED}❌ El sistema no está listo para producción${NC}"
        echo ""
        echo -e "${BLUE}🛠️  Estado del Sistema: ${RED}REQUIERE CORRECCIONES${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}📋 Plan de Acción Recomendado:${NC}"
    
    if [ $FAILED_PHASES -eq 0 ]; then
        echo -e "${GREEN}  1. ✅ Sistema validado completamente${NC}"
        echo -e "${GREEN}  2. ✅ Listo para despliegue en producción${NC}"
        echo -e "${GREEN}  3. ✅ Implementar monitoreo continuo${NC}"
        echo -e "${GREEN}  4. ✅ Documentar configuración actual${NC}"
        
    elif [ $FAILED_PHASES -eq 1 ]; then
        echo -e "${YELLOW}  1. 🔍 Revisar la fase que falló${NC}"
        echo -e "${YELLOW}  2. 🔧 Aplicar correcciones necesarias${NC}"
        echo -e "${YELLOW}  3. 🔄 Re-ejecutar validación completa${NC}"
        echo -e "${YELLOW}  4. 📊 Considerar tests adicionales${NC}"
        
    else
        echo -e "${RED}  1. 🚨 Revisar todas las fases fallidas${NC}"
        echo -e "${RED}  2. 🔧 Corregir problemas de configuración${NC}"
        echo -e "${RED}  3. 🔄 Reiniciar servicios si es necesario${NC}"
        echo -e "${RED}  4. 🧪 Re-ejecutar validación por fases${NC}"
        echo -e "${RED}  5. 📞 Considerar soporte técnico si persisten problemas${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🛠️  Comandos Útiles:${NC}"
    echo -e "  ${CYAN}./manage-services.sh status${NC}     # Ver estado de servicios"
    echo -e "  ${CYAN}./manage-services.sh logs${NC}       # Ver logs del sistema"
    echo -e "  ${CYAN}./manage-services.sh restart${NC}    # Reiniciar servicios"
    echo -e "  ${CYAN}$0 --quick${NC}                      # Validación rápida"
    echo -e "  ${CYAN}$0 --validation-only${NC}            # Solo validación de sistema"
    echo ""
    
    echo -e "${BLUE}📚 Documentación:${NC}"
    echo -e "  ${CYAN}README.md${NC}                       # Documentación principal"
    echo -e "  ${CYAN}UPGRADE_PLAN.md${NC}                 # Plan de actualización"
    echo -e "  ${CYAN}CHANGELOG.md${NC}                    # Registro de cambios"
    echo ""
    
    # Timestamp final
    echo -e "${BLUE}🕐 Validación completada: ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
}

# Función principal
main() {
    local test_mode="full"
    local continue_on_error="false"
    local verbose="false"
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                return 0
                ;;
            --quick)
                test_mode="quick"
                shift
                ;;
            --no-performance)
                test_mode="no-performance"
                shift
                ;;
            --performance-only)
                test_mode="performance-only"
                shift
                ;;
            --integration-only)
                test_mode="integration-only"
                shift
                ;;
            --validation-only)
                test_mode="validation-only"
                shift
                ;;
            --continue-on-error)
                continue_on_error="true"
                shift
                ;;
            --verbose)
                verbose="true"
                shift
                ;;
            *)
                echo -e "${RED}Opción no reconocida: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Mostrar configuración de ejecución
    echo -e "${BLUE}🔧 Configuración de Ejecución:${NC}"
    echo -e "  Modo: ${CYAN}$test_mode${NC}"
    echo -e "  Continuar en error: ${CYAN}$continue_on_error${NC}"
    echo -e "  Salida detallada: ${CYAN}$verbose${NC}"
    echo ""
    
    # Ejecutar según el modo seleccionado
    case "$test_mode" in
        "quick")
            run_system_validation "$continue_on_error" "$verbose"
            ;;
        "no-performance")
            run_system_validation "$continue_on_error" "$verbose"
            run_integration_testing "$continue_on_error" "$verbose"
            run_scripts_validation "$continue_on_error" "$verbose"
            ;;
        "performance-only")
            run_performance_testing "$continue_on_error" "$verbose"
            ;;
        "integration-only")
            run_integration_testing "$continue_on_error" "$verbose"
            ;;
        "validation-only")
            run_system_validation "$continue_on_error" "$verbose"
            ;;
        "full"|*)
            # Ejecución completa
            run_system_validation "$continue_on_error" "$verbose"
            run_integration_testing "$continue_on_error" "$verbose"
            run_performance_testing "$continue_on_error" "$verbose"
            run_scripts_validation "$continue_on_error" "$verbose"
            ;;
    esac
    
    # Mostrar resumen final
    show_comprehensive_summary
    
    # Código de salida basado en resultados
    if [ $FAILED_PHASES -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Ejecutar función principal
main "$@"
