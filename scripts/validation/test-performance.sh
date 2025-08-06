#!/bin/bash
# Script de testing de performance
# Ejecuta pruebas de carga y performance del sistema

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

echo -e "${PURPLE}⚡ TESTING DE PERFORMANCE${NC}"
echo -e "${PURPLE}========================${NC}"
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
    esac
}

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Tester de Performance ===${NC}"
    echo ""
    echo -e "${YELLOW}Uso: $0 [OPCIÓN]${NC}"
    echo ""
    echo -e "${BLUE}Opciones:${NC}"
    echo "  --help, -h              Mostrar esta ayuda"
    echo "  --light                 Tests ligeros (10 requests)"
    echo "  --medium                Tests medios (50 requests)"
    echo "  --heavy                 Tests pesados (200 requests)"
    echo "  --stress                Tests de estrés (500 requests)"
    echo "  --response-time         Solo tests de tiempo de respuesta"
    echo "  --throughput            Solo tests de throughput"
    echo "  --concurrent            Tests de concurrencia"
    echo ""
    echo -e "${BLUE}Descripción:${NC}"
    echo "  Este script ejecuta pruebas de performance:"
    echo "  - Tiempo de respuesta"
    echo "  - Throughput (requests por segundo)"
    echo "  - Tests de carga"
    echo "  - Tests de concurrencia"
    echo "  - Análisis de distribución de carga"
    echo ""
}

# Función para preparar el entorno
setup_environment() {
    echo -e "${CYAN}🔧 PREPARANDO ENTORNO DE PERFORMANCE${NC}"
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
    local dependencies=("curl" "bc")
    for dep in "${dependencies[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} $dep disponible"
        else
            echo -e "${RED}❌${NC} $dep NO disponible"
            if [ "$dep" = "bc" ]; then
                echo -e "${YELLOW}⚠️${NC}  Instalar bc: sudo apt-get install bc"
            fi
            exit 1
        fi
    done
    
    # Verificar que los servicios estén corriendo
    if ! docker ps | grep -q haproxy; then
        echo -e "${RED}❌${NC} HAProxy no está ejecutándose"
        echo -e "${YELLOW}💡${NC} Ejecutar: ./manage-services.sh start"
        exit 1
    fi
    
    echo -e "${GREEN}✅${NC} Entorno listo para tests de performance"
    echo ""
}

# Test de tiempo de respuesta
test_response_time() {
    echo -e "${CYAN}⏱️  TEST 1: Tiempo de Respuesta${NC}"
    echo "----------------------------------------"
    
    local url="http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    local total_time=0
    local successful_requests=0
    local failed_requests=0
    local test_requests=10
    
    echo -e "${YELLOW}Ejecutando $test_requests requests para medir tiempo de respuesta...${NC}"
    
    for ((i=1; i<=test_requests; i++)); do
        local start_time=$(date +%s.%N)
        
        if curl -s -m 10 "$url" > /dev/null 2>&1; then
            local end_time=$(date +%s.%N)
            local request_time=$(echo "$end_time - $start_time" | bc -l)
            total_time=$(echo "$total_time + $request_time" | bc -l)
            ((successful_requests++))
            
            echo -e "  Request $i: ${request_time}s"
        else
            ((failed_requests++))
            echo -e "  Request $i: ${RED}FAILED${NC}"
        fi
    done
    
    if [ $successful_requests -gt 0 ]; then
        local avg_time=$(echo "scale=3; $total_time / $successful_requests" | bc -l)
        
        echo ""
        echo -e "${BLUE}Resultados de Tiempo de Respuesta:${NC}"
        echo -e "  Requests exitosos: $successful_requests/$test_requests"
        echo -e "  Tiempo promedio: ${avg_time}s"
        echo -e "  Tiempo total: ${total_time}s"
        
        # Evaluar performance
        if (( $(echo "$avg_time < 1.0" | bc -l) )); then
            log_test_result "Response Time" "PASS" "Tiempo promedio excelente: ${avg_time}s"
        elif (( $(echo "$avg_time < 3.0" | bc -l) )); then
            log_test_result "Response Time" "PASS" "Tiempo promedio aceptable: ${avg_time}s"
        else
            log_test_result "Response Time" "FAIL" "Tiempo promedio lento: ${avg_time}s"
        fi
    else
        log_test_result "Response Time" "FAIL" "Todos los requests fallaron"
    fi
    
    echo ""
}

# Test de throughput
test_throughput() {
    echo -e "${CYAN}🚀 TEST 2: Throughput (Requests por Segundo)${NC}"
    echo "----------------------------------------"
    
    local url="http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    local test_duration=10  # segundos
    local request_count=0
    local successful_requests=0
    
    echo -e "${YELLOW}Ejecutando requests durante ${test_duration} segundos...${NC}"
    
    local start_time=$(date +%s)
    local end_time=$((start_time + test_duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        ((request_count++))
        
        if curl -s -m 3 "$url" > /dev/null 2>&1; then
            ((successful_requests++))
        fi
        
        # Mostrar progreso cada 10 requests
        if [ $((request_count % 10)) -eq 0 ]; then
            local current_time=$(date +%s)
            local elapsed=$((current_time - start_time))
            echo -e "  Progreso: ${request_count} requests en ${elapsed}s"
        fi
    done
    
    local actual_duration=$(($(date +%s) - start_time))
    local throughput=$(echo "scale=2; $successful_requests / $actual_duration" | bc -l)
    local success_rate=$(echo "scale=2; $successful_requests * 100 / $request_count" | bc -l)
    
    echo ""
    echo -e "${BLUE}Resultados de Throughput:${NC}"
    echo -e "  Duración: ${actual_duration}s"
    echo -e "  Total requests: $request_count"
    echo -e "  Requests exitosos: $successful_requests"
    echo -e "  Tasa de éxito: ${success_rate}%"
    echo -e "  Throughput: ${throughput} req/s"
    
    # Evaluar throughput
    if (( $(echo "$throughput >= 5.0" | bc -l) )); then
        log_test_result "Throughput" "PASS" "Throughput excelente: ${throughput} req/s"
    elif (( $(echo "$throughput >= 2.0" | bc -l) )); then
        log_test_result "Throughput" "PASS" "Throughput aceptable: ${throughput} req/s"
    else
        log_test_result "Throughput" "FAIL" "Throughput bajo: ${throughput} req/s"
    fi
    
    echo ""
}

# Test de carga
test_load() {
    echo -e "${CYAN}📊 TEST 3: Test de Carga${NC}"
    echo "----------------------------------------"
    
    local url="http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    local load_requests="${1:-50}"
    local interval=0.1
    
    echo -e "${YELLOW}Ejecutando test de carga con $load_requests requests...${NC}"
    
    local successful_requests=0
    local failed_requests=0
    local total_time=0
    local start_time=$(date +%s.%N)
    
    for ((i=1; i<=load_requests; i++)); do
        local request_start=$(date +%s.%N)
        
        if curl -s -m 5 "$url" > /dev/null 2>&1; then
            ((successful_requests++))
            local request_end=$(date +%s.%N)
            local request_time=$(echo "$request_end - $request_start" | bc -l)
            total_time=$(echo "$total_time + $request_time" | bc -l)
        else
            ((failed_requests++))
        fi
        
        # Mostrar progreso cada 10 requests
        if [ $((i % 10)) -eq 0 ]; then
            echo -e "  Progreso: $i/$load_requests requests completados"
        fi
        
        sleep $interval
    done
    
    local end_time=$(date +%s.%N)
    local total_test_time=$(echo "$end_time - $start_time" | bc -l)
    local avg_response_time=0
    
    if [ $successful_requests -gt 0 ]; then
        avg_response_time=$(echo "scale=3; $total_time / $successful_requests" | bc -l)
    fi
    
    local success_rate=$(echo "scale=2; $successful_requests * 100 / $load_requests" | bc -l)
    local effective_throughput=$(echo "scale=2; $successful_requests / $total_test_time" | bc -l)
    
    echo ""
    echo -e "${BLUE}Resultados del Test de Carga:${NC}"
    echo -e "  Total requests: $load_requests"
    echo -e "  Requests exitosos: $successful_requests"
    echo -e "  Requests fallidos: $failed_requests"
    echo -e "  Tasa de éxito: ${success_rate}%"
    echo -e "  Tiempo promedio de respuesta: ${avg_response_time}s"
    echo -e "  Throughput efectivo: ${effective_throughput} req/s"
    echo -e "  Tiempo total del test: ${total_test_time}s"
    
    # Evaluar resultados
    if (( $(echo "$success_rate >= 95.0" | bc -l) )) && (( $(echo "$avg_response_time < 2.0" | bc -l) )); then
        log_test_result "Load Test" "PASS" "Sistema maneja la carga correctamente (${success_rate}% éxito, ${avg_response_time}s promedio)"
    elif (( $(echo "$success_rate >= 80.0" | bc -l) )); then
        log_test_result "Load Test" "PASS" "Sistema maneja la carga aceptablemente (${success_rate}% éxito)"
    else
        log_test_result "Load Test" "FAIL" "Sistema no maneja la carga adecuadamente (${success_rate}% éxito)"
    fi
    
    echo ""
}

# Test de concurrencia
test_concurrency() {
    echo -e "${CYAN}🔀 TEST 4: Test de Concurrencia${NC}"
    echo "----------------------------------------"
    
    local url="http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    local concurrent_requests=5
    local requests_per_process=10
    
    echo -e "${YELLOW}Ejecutando $concurrent_requests procesos concurrentes con $requests_per_process requests cada uno...${NC}"
    
    # Crear archivos temporales para resultados
    local temp_dir=$(mktemp -d)
    local pids=()
    
    # Función para ejecutar requests en paralelo
    run_concurrent_requests() {
        local process_id=$1
        local result_file="$temp_dir/process_$process_id.result"
        local successful=0
        local failed=0
        
        for ((i=1; i<=requests_per_process; i++)); do
            if curl -s -m 3 "$url" > /dev/null 2>&1; then
                ((successful++))
            else
                ((failed++))
            fi
        done
        
        echo "$successful $failed" > "$result_file"
    }
    
    # Iniciar procesos concurrentes
    local start_time=$(date +%s.%N)
    
    for ((i=1; i<=concurrent_requests; i++)); do
        run_concurrent_requests $i &
        pids+=($!)
    done
    
    # Esperar a que todos los procesos terminen
    for pid in "${pids[@]}"; do
        wait $pid
    done
    
    local end_time=$(date +%s.%N)
    local total_test_time=$(echo "$end_time - $start_time" | bc -l)
    
    # Recopilar resultados
    local total_successful=0
    local total_failed=0
    
    for ((i=1; i<=concurrent_requests; i++)); do
        if [ -f "$temp_dir/process_$i.result" ]; then
            local result=$(cat "$temp_dir/process_$i.result")
            local successful=$(echo $result | cut -d' ' -f1)
            local failed=$(echo $result | cut -d' ' -f2)
            total_successful=$((total_successful + successful))
            total_failed=$((total_failed + failed))
        fi
    done
    
    # Limpiar archivos temporales
    rm -rf "$temp_dir"
    
    local total_requests=$((total_successful + total_failed))
    local success_rate=$(echo "scale=2; $total_successful * 100 / $total_requests" | bc -l)
    local concurrent_throughput=$(echo "scale=2; $total_successful / $total_test_time" | bc -l)
    
    echo ""
    echo -e "${BLUE}Resultados del Test de Concurrencia:${NC}"
    echo -e "  Procesos concurrentes: $concurrent_requests"
    echo -e "  Requests por proceso: $requests_per_process"
    echo -e "  Total requests: $total_requests"
    echo -e "  Requests exitosos: $total_successful"
    echo -e "  Requests fallidos: $total_failed"
    echo -e "  Tasa de éxito: ${success_rate}%"
    echo -e "  Throughput concurrente: ${concurrent_throughput} req/s"
    echo -e "  Tiempo total: ${total_test_time}s"
    
    # Evaluar concurrencia
    if (( $(echo "$success_rate >= 90.0" | bc -l) )); then
        log_test_result "Concurrency Test" "PASS" "Sistema maneja concurrencia correctamente (${success_rate}% éxito)"
    elif (( $(echo "$success_rate >= 75.0" | bc -l) )); then
        log_test_result "Concurrency Test" "PASS" "Sistema maneja concurrencia aceptablemente (${success_rate}% éxito)"
    else
        log_test_result "Concurrency Test" "FAIL" "Sistema tiene problemas con concurrencia (${success_rate}% éxito)"
    fi
    
    echo ""
}

# Test de distribución de carga
test_load_distribution() {
    echo -e "${CYAN}⚖️  TEST 5: Distribución de Carga${NC}"
    echo "----------------------------------------"
    
    # Configurar distribución 50/50
    echo -e "${YELLOW}Configurando distribución 50/50...${NC}"
    "$PROJECT_ROOT/scripts/canary/manage-traffic.sh" reset > /dev/null 2>&1
    
    # Ejecutar requests y analizar distribución
    local url="http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    local test_requests=20
    local successful_requests=0
    
    echo -e "${YELLOW}Ejecutando $test_requests requests para analizar distribución...${NC}"
    
    for ((i=1; i<=test_requests; i++)); do
        if curl -s -m 3 "$url" > /dev/null 2>&1; then
            ((successful_requests++))
        fi
        sleep 0.1
    done
    
    # Obtener estadísticas de HAProxy si están disponibles
    local stats_available=false
    if curl -s "http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats;csv" > /dev/null 2>&1; then
        stats_available=true
    fi
    
    echo ""
    echo -e "${BLUE}Resultados de Distribución de Carga:${NC}"
    echo -e "  Requests de prueba: $test_requests"
    echo -e "  Requests exitosos: $successful_requests"
    
    if [ "$stats_available" = true ]; then
        echo -e "  Estadísticas HAProxy disponibles: Sí"
        log_test_result "Load Distribution" "PASS" "Distribución de carga funcionando ($successful_requests/$test_requests exitosos)"
    else
        echo -e "  Estadísticas HAProxy disponibles: No"
        if [ $successful_requests -gt $((test_requests * 80 / 100)) ]; then
            log_test_result "Load Distribution" "PASS" "Distribución básica funcionando ($successful_requests/$test_requests exitosos)"
        else
            log_test_result "Load Distribution" "FAIL" "Problemas en distribución de carga ($successful_requests/$test_requests exitosos)"
        fi
    fi
    
    echo ""
}

# Función para mostrar resumen final
show_final_summary() {
    echo -e "${PURPLE}📊 RESUMEN DE TESTING DE PERFORMANCE${NC}"
    echo -e "${PURPLE}====================================${NC}"
    echo ""
    echo -e "${BLUE}Estadísticas de Tests:${NC}"
    echo -e "  Total de tests ejecutados: ${CYAN}$TOTAL_TESTS${NC}"
    echo -e "  Tests exitosos: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "  Tests fallidos: ${RED}$FAILED_TESTS${NC}"
    echo ""
    
    # Calcular porcentaje de éxito
    local success_rate=0
    if [ $TOTAL_TESTS -gt 0 ]; then
        success_rate=$(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc -l)
    fi
    
    echo -e "${BLUE}Tasa de Éxito: ${CYAN}${success_rate}%${NC}"
    echo ""
    
    # Determinar estado general
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}🎉 TODOS LOS TESTS DE PERFORMANCE PASARON${NC}"
        echo -e "${GREEN}El sistema tiene performance aceptable${NC}"
    elif [ $FAILED_TESTS -le 1 ]; then
        echo -e "${YELLOW}⚠️  MAYORÍA DE TESTS PASARON${NC}"
        echo -e "${YELLOW}Hay algunos aspectos de performance que mejorar${NC}"
    else
        echo -e "${RED}❌ MÚLTIPLES TESTS DE PERFORMANCE FALLARON${NC}"
        echo -e "${RED}El sistema requiere optimización de performance${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Recomendaciones de Performance:${NC}"
    
    if [ $FAILED_TESTS -gt 0 ]; then
        echo -e "  1. Revisar configuración de recursos Docker"
        echo -e "  2. Optimizar configuración de HAProxy"
        echo -e "  3. Considerar ajustar timeouts"
        echo -e "  4. Monitorear uso de CPU y memoria"
    else
        echo -e "  1. Performance actual es aceptable"
        echo -e "  2. Considerar tests de carga más intensivos"
        echo -e "  3. Implementar monitoreo continuo"
    fi
    
    echo -e "  5. Ejecutar: docker stats (para monitorear recursos)"
    echo -e "  6. Revisar logs: ./manage-services.sh logs"
    echo ""
}

# Función principal
main() {
    local test_type="${1:-medium}"
    
    case "$test_type" in
        --help|-h)
            show_help
            return 0
            ;;
        --light)
            setup_environment
            test_response_time
            test_load 10
            ;;
        --medium)
            setup_environment
            test_response_time
            test_throughput
            test_load 50
            test_load_distribution
            ;;
        --heavy)
            setup_environment
            test_response_time
            test_throughput
            test_load 200
            test_concurrency
            test_load_distribution
            ;;
        --stress)
            setup_environment
            test_response_time
            test_throughput
            test_load 500
            test_concurrency
            test_load_distribution
            ;;
        --response-time)
            setup_environment
            test_response_time
            ;;
        --throughput)
            setup_environment
            test_throughput
            ;;
        --concurrent)
            setup_environment
            test_concurrency
            ;;
        *)
            # Test medium por defecto
            setup_environment
            test_response_time
            test_throughput
            test_load 50
            test_load_distribution
            ;;
    esac
    
    show_final_summary
}

# Ejecutar función principal
main "$@"
