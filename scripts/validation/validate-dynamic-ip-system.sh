#!/bin/bash
# Script para validar el funcionamiento del sistema de IPs dinámicas

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
echo "║           Validación Sistema de IPs Dinámicas               ║"
echo "║                  WebLogic + HAProxy                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Función para obtener la IP de un contenedor
get_container_ip() {
    local container_name=$1
    local ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name" 2>/dev/null)
    echo "$ip"
}

# Función para verificar si un contenedor está corriendo
is_container_running() {
    local container_name=$1
    docker ps --format "{{.Names}}" | grep -q "^${container_name}$"
}

# Función para verificar la configuración de HAProxy
check_haproxy_config() {
    local config_file="$PROJECT_ROOT/haproxy/config/haproxy.cfg"
    
    echo -e "${BLUE}=== Verificando Configuración HAProxy ===${NC}"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}✗ Archivo de configuración no encontrado: $config_file${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Archivo de configuración encontrado${NC}"
    
    # Verificar que las IPs están configuradas correctamente
    local weblogic_a_ip=$(get_container_ip "weblogic-a")
    local weblogic_b_ip=$(get_container_ip "weblogic-b")
    
    if [ -n "$weblogic_a_ip" ] && [ -n "$weblogic_b_ip" ]; then
        echo -e "${YELLOW}IPs actuales de contenedores:${NC}"
        echo -e "  weblogic-a: $weblogic_a_ip"
        echo -e "  weblogic-b: $weblogic_b_ip"
        
        # Verificar si las IPs están en la configuración
        if grep -q "$weblogic_a_ip" "$config_file" && grep -q "$weblogic_b_ip" "$config_file"; then
            echo -e "${GREEN}✓ IPs actuales están en la configuración HAProxy${NC}"
            return 0
        else
            echo -e "${RED}✗ IPs actuales NO están en la configuración HAProxy${NC}"
            echo -e "${YELLOW}Configuración actual en HAProxy:${NC}"
            grep -n "server weblogic-" "$config_file" | head -4
            return 1
        fi
    else
        echo -e "${RED}✗ No se pudieron obtener las IPs de los contenedores${NC}"
        return 1
    fi
}

# Función para verificar scripts de actualización
check_update_scripts() {
    echo -e "${BLUE}=== Verificando Scripts de Actualización ===${NC}"
    
    local scripts=(
        "scripts/maintenance/auto-update-haproxy.sh"
        "scripts/services/manage-services.sh"
        "scripts/services/start-with-auto-update.sh"
    )
    
    for script in "${scripts[@]}"; do
        local full_path="$PROJECT_ROOT/$script"
        if [ -f "$full_path" ] && [ -x "$full_path" ]; then
            echo -e "${GREEN}✓ $script - Existe y es ejecutable${NC}"
        else
            echo -e "${RED}✗ $script - No encontrado o no ejecutable${NC}"
            return 1
        fi
    done
    
    # Verificar integración en manage-services.sh
    if grep -q "auto-update-haproxy.sh" "$PROJECT_ROOT/scripts/services/start-with-auto-update.sh"; then
        echo -e "${GREEN}✓ Integración con start-with-auto-update.sh confirmada${NC}"
    else
        echo -e "${RED}✗ Integración con start-with-auto-update.sh NO encontrada${NC}"
        return 1
    fi
}

# Función para verificar conectividad
check_connectivity() {
    echo -e "${BLUE}=== Verificando Conectividad ===${NC}"
    
    # Verificar HAProxy load balancer
    if curl -s -f http://localhost:8083/health >/dev/null 2>&1; then
        echo -e "${GREEN}✓ HAProxy Load Balancer (8083) - Accesible${NC}"
    else
        echo -e "${RED}✗ HAProxy Load Balancer (8083) - No accesible${NC}"
    fi
    
    # Verificar HAProxy stats
    if curl -s -f http://localhost:8404/stats >/dev/null 2>&1; then
        echo -e "${GREEN}✓ HAProxy Stats (8404) - Accesible${NC}"
    else
        echo -e "${RED}✗ HAProxy Stats (8404) - No accesible${NC}"
    fi
    
    # Verificar HAProxy admin UI
    if curl -s -f http://localhost:8082 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ HAProxy Admin UI (8082) - Accesible${NC}"
    else
        echo -e "${RED}✗ HAProxy Admin UI (8082) - No accesible${NC}"
    fi
    
    # Verificar WebLogic consoles
    if curl -s -f http://localhost:7001/console >/dev/null 2>&1; then
        echo -e "${GREEN}✓ WebLogic A Console (7001) - Accesible${NC}"
    else
        echo -e "${RED}✗ WebLogic A Console (7001) - No accesible${NC}"
    fi
    
    if curl -s -f http://localhost:7002/console >/dev/null 2>&1; then
        echo -e "${GREEN}✓ WebLogic B Console (7002) - Accesible${NC}"
    else
        echo -e "${RED}✗ WebLogic B Console (7002) - No accesible${NC}"
    fi
}

# Función para verificar backends HAProxy
check_haproxy_backends() {
    echo -e "${BLUE}=== Verificando Backends HAProxy ===${NC}"
    
    # Obtener estado de backends desde HAProxy stats
    local stats_url="http://localhost:8404/stats;csv"
    
    if curl -s "$stats_url" >/dev/null 2>&1; then
        local backends_status=$(curl -s "$stats_url" | grep -E "(weblogic-a|weblogic-b|weblogic-features)" | cut -d',' -f1,18)
        
        echo -e "${YELLOW}Estado de backends:${NC}"
        echo "$backends_status" | while IFS=',' read -r name status; do
            if [ "$status" = "UP" ]; then
                echo -e "  ${GREEN}✓ $name: $status${NC}"
            else
                echo -e "  ${RED}✗ $name: $status${NC}"
            fi
        done
    else
        echo -e "${RED}✗ No se pudo obtener estado de backends${NC}"
    fi
}

# Función para test de reinicio
test_restart_functionality() {
    echo -e "${BLUE}=== Test de Funcionalidad de Reinicio ===${NC}"
    echo -e "${YELLOW}ADVERTENCIA: Este test reiniciará los servicios${NC}"
    
    read -p "¿Desea continuar con el test de reinicio? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Test de reinicio omitido${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Obteniendo IPs antes del reinicio...${NC}"
    local ip_before_a=$(get_container_ip "weblogic-a")
    local ip_before_b=$(get_container_ip "weblogic-b")
    
    echo -e "  weblogic-a: $ip_before_a"
    echo -e "  weblogic-b: $ip_before_b"
    
    echo -e "${YELLOW}Reiniciando servicios...${NC}"
    "$PROJECT_ROOT/manage-services.sh" restart
    
    echo -e "${YELLOW}Esperando estabilización...${NC}"
    sleep 15
    
    echo -e "${YELLOW}Obteniendo IPs después del reinicio...${NC}"
    local ip_after_a=$(get_container_ip "weblogic-a")
    local ip_after_b=$(get_container_ip "weblogic-b")
    
    echo -e "  weblogic-a: $ip_after_a"
    echo -e "  weblogic-b: $ip_after_b"
    
    # Verificar si las IPs cambiaron
    if [ "$ip_before_a" != "$ip_after_a" ] || [ "$ip_before_b" != "$ip_after_b" ]; then
        echo -e "${YELLOW}✓ IPs cambiaron después del reinicio (comportamiento esperado)${NC}"
        
        # Verificar si la configuración se actualizó
        if check_haproxy_config; then
            echo -e "${GREEN}✓ Sistema de IPs dinámicas funcionó correctamente${NC}"
            return 0
        else
            echo -e "${RED}✗ Sistema de IPs dinámicas NO funcionó correctamente${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}? IPs no cambiaron (puede ser normal en algunos casos)${NC}"
        return 0
    fi
}

# Función principal
main() {
    local test_restart=false
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --test-restart)
                test_restart=true
                shift
                ;;
            --help|-h)
                echo "Uso: $0 [--test-restart] [--help]"
                echo ""
                echo "Opciones:"
                echo "  --test-restart    Incluir test de reinicio (reinicia servicios)"
                echo "  --help, -h        Mostrar esta ayuda"
                exit 0
                ;;
            *)
                echo "Opción desconocida: $1"
                exit 1
                ;;
        esac
    done
    
    local all_passed=true
    
    # Verificar que los servicios estén corriendo
    echo -e "${BLUE}=== Verificando Estado de Servicios ===${NC}"
    local containers=("weblogic-a" "weblogic-b" "haproxy")
    
    for container in "${containers[@]}"; do
        if is_container_running "$container"; then
            echo -e "${GREEN}✓ $container está corriendo${NC}"
        else
            echo -e "${RED}✗ $container NO está corriendo${NC}"
            all_passed=false
        fi
    done
    
    if [ "$all_passed" = false ]; then
        echo -e "${RED}Error: Algunos servicios no están corriendo. Inicie los servicios primero.${NC}"
        echo -e "${YELLOW}Ejecute: ./manage-services.sh start${NC}"
        exit 1
    fi
    
    echo ""
    
    # Ejecutar verificaciones
    if ! check_update_scripts; then
        all_passed=false
    fi
    
    echo ""
    
    if ! check_haproxy_config; then
        all_passed=false
    fi
    
    echo ""
    
    check_connectivity
    
    echo ""
    
    check_haproxy_backends
    
    echo ""
    
    # Test de reinicio si se solicita
    if [ "$test_restart" = true ]; then
        if ! test_restart_functionality; then
            all_passed=false
        fi
        echo ""
    fi
    
    # Resultado final
    echo -e "${CYAN}=== Resultado Final ===${NC}"
    if [ "$all_passed" = true ]; then
        echo -e "${GREEN}✅ SISTEMA DE IPS DINÁMICAS VALIDADO EXITOSAMENTE${NC}"
        echo -e "${BLUE}El sistema está funcionando correctamente y puede manejar cambios de IP automáticamente.${NC}"
        exit 0
    else
        echo -e "${RED}❌ SISTEMA DE IPS DINÁMICAS REQUIERE ATENCIÓN${NC}"
        echo -e "${YELLOW}Revise los errores reportados arriba y corrija los problemas identificados.${NC}"
        exit 1
    fi
}

# Ejecutar función principal
main "$@"
