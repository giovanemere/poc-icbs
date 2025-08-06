#!/bin/bash

# =============================================================================
# Script para corregir las IPs de HAProxy automáticamente
# Soluciona el problema "Error al cargar datos: NOT FOUND"
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to get container IP
get_container_ip() {
    local container_name=$1
    local ip=$(docker inspect "$container_name" --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
    
    if [ -n "$ip" ] && [ "$ip" != "<no value>" ]; then
        echo "$ip"
    else
        echo ""
    fi
}

# Function to check if container is running
check_container_running() {
    local container_name=$1
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return 0
    else
        return 1
    fi
}

# Function to update HAProxy configuration
update_haproxy_config() {
    local weblogic_a_ip=$1
    local weblogic_b_ip=$2
    
    print_status "Actualizando configuración de HAProxy..."
    
    # Create backup
    local backup_file="/usr/local/etc/haproxy/haproxy.cfg.bak.$(date +%Y%m%d_%H%M%S)"
    docker exec haproxy cp /usr/local/etc/haproxy/haproxy.cfg "$backup_file"
    print_success "Backup creado: $backup_file"
    
    # Update weblogic-a IP
    docker exec haproxy sed -i "s/server weblogic-a [0-9.]*:7001/server weblogic-a ${weblogic_a_ip}:7001/g" /usr/local/etc/haproxy/haproxy.cfg
    print_success "IP de weblogic-a actualizada a: $weblogic_a_ip"
    
    # Update weblogic-b IP
    docker exec haproxy sed -i "s/server weblogic-b [0-9.]*:7001/server weblogic-b ${weblogic_b_ip}:7001/g" /usr/local/etc/haproxy/haproxy.cfg
    print_success "IP de weblogic-b actualizada a: $weblogic_b_ip"
}

# Function to reload HAProxy
reload_haproxy() {
    print_status "Recargando configuración de HAProxy..."
    
    # Get current HAProxy PID
    local current_pid=$(docker exec haproxy cat /var/run/haproxy.pid 2>/dev/null || echo "")
    
    # Reload HAProxy with graceful restart
    if [ -n "$current_pid" ]; then
        docker exec haproxy haproxy -f /usr/local/etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -sf "$current_pid"
    else
        docker exec haproxy haproxy -f /usr/local/etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid
    fi
    
    if [ $? -eq 0 ]; then
        print_success "HAProxy recargado exitosamente"
        return 0
    else
        print_error "Error al recargar HAProxy"
        return 1
    fi
}

# Function to test URLs after fix
test_urls_after_fix() {
    print_status "Probando URLs después de la corrección..."
    
    local test_urls=(
        "http://localhost:8083/"
        "http://localhost:8083/console"
        "http://localhost:8083/feature-flags/"
        "http://localhost:8082/"
        "http://localhost:8404/stats"
    )
    
    local success_count=0
    local total_count=${#test_urls[@]}
    
    for url in "${test_urls[@]}"; do
        if curl -s -m 5 "$url" > /dev/null 2>&1; then
            print_success "✓ $url"
            ((success_count++))
        else
            print_error "✗ $url"
        fi
    done
    
    echo ""
    print_status "Resultado: $success_count/$total_count URLs funcionando"
    
    if [ $success_count -eq $total_count ]; then
        print_success "¡Todas las URLs están funcionando correctamente!"
        return 0
    else
        print_warning "Algunas URLs aún tienen problemas"
        return 1
    fi
}

# Function to restart HAProxy API if needed
restart_haproxy_api() {
    print_status "Reiniciando servicios de HAProxy..."
    
    # Kill existing admin API processes
    docker exec haproxy pkill -f "admin_api.py" 2>/dev/null || true
    docker exec haproxy pkill -f "admin_ui.py" 2>/dev/null || true
    
    # Wait a moment
    sleep 2
    
    # Start admin API
    docker exec -d haproxy python3 /scripts/admin_api.py
    docker exec -d haproxy python3 /scripts/admin_ui.py
    
    print_success "Servicios de HAProxy reiniciados"
}

# Main function
main() {
    echo -e "${BLUE}🚀 Iniciando corrección de IPs de HAProxy${NC}"
    echo ""
    
    # Check if containers are running
    print_status "Verificando estado de contenedores..."
    
    if ! check_container_running "haproxy"; then
        print_error "El contenedor HAProxy no está ejecutándose"
        exit 1
    fi
    
    if ! check_container_running "weblogic-a"; then
        print_error "El contenedor weblogic-a no está ejecutándose"
        exit 1
    fi
    
    if ! check_container_running "weblogic-b"; then
        print_error "El contenedor weblogic-b no está ejecutándose"
        exit 1
    fi
    
    print_success "Todos los contenedores están ejecutándose"
    
    # Get current IPs
    print_status "Obteniendo IPs actuales de los contenedores..."
    
    local weblogic_a_ip=$(get_container_ip "weblogic-a")
    local weblogic_b_ip=$(get_container_ip "weblogic-b")
    local haproxy_ip=$(get_container_ip "haproxy")
    
    if [ -z "$weblogic_a_ip" ]; then
        print_error "No se pudo obtener la IP de weblogic-a"
        exit 1
    fi
    
    if [ -z "$weblogic_b_ip" ]; then
        print_error "No se pudo obtener la IP de weblogic-b"
        exit 1
    fi
    
    print_success "weblogic-a IP: $weblogic_a_ip"
    print_success "weblogic-b IP: $weblogic_b_ip"
    print_success "haproxy IP: $haproxy_ip"
    
    # Show current HAProxy configuration
    print_status "Configuración actual de HAProxy:"
    docker exec haproxy grep -A 2 "server weblogic" /usr/local/etc/haproxy/haproxy.cfg || true
    echo ""
    
    # Update HAProxy configuration
    update_haproxy_config "$weblogic_a_ip" "$weblogic_b_ip"
    
    # Show updated configuration
    print_status "Nueva configuración de HAProxy:"
    docker exec haproxy grep -A 2 "server weblogic" /usr/local/etc/haproxy/haproxy.cfg
    echo ""
    
    # Reload HAProxy
    if ! reload_haproxy; then
        print_error "Error al recargar HAProxy"
        exit 1
    fi
    
    # Restart HAProxy API services
    restart_haproxy_api
    
    # Wait for services to stabilize
    print_status "Esperando a que los servicios se estabilicen..."
    sleep 5
    
    # Test URLs
    test_urls_after_fix
    
    echo ""
    print_success "🎉 Corrección de IPs completada!"
    echo ""
    print_status "URLs para verificar:"
    echo "  • Load Balancer: http://localhost:8083/"
    echo "  • HAProxy Admin: http://localhost:8082/"
    echo "  • HAProxy Stats: http://localhost:8404/stats"
    echo "  • WebLogic A: http://localhost:7001/console"
    echo "  • WebLogic B: http://localhost:7002/console"
    echo ""
    print_status "Para verificar el estado de URLs:"
    echo "  docker exec haproxy /scripts/check-urls-container.sh"
    echo ""
}

# Handle script arguments
case "${1:-fix}" in
    "fix"|"")
        main
        ;;
    "check")
        print_status "Verificando IPs actuales..."
        echo "weblogic-a: $(get_container_ip weblogic-a)"
        echo "weblogic-b: $(get_container_ip weblogic-b)"
        echo "haproxy: $(get_container_ip haproxy)"
        echo ""
        print_status "Configuración actual de HAProxy:"
        docker exec haproxy grep -A 2 "server weblogic" /usr/local/etc/haproxy/haproxy.cfg 2>/dev/null || print_error "No se pudo leer la configuración"
        ;;
    "test")
        test_urls_after_fix
        ;;
    "restart-api")
        restart_haproxy_api
        ;;
    *)
        echo "Usage: $0 [fix|check|test|restart-api]"
        echo ""
        echo "Commands:"
        echo "  fix         - Corregir IPs automáticamente (default)"
        echo "  check       - Verificar IPs actuales"
        echo "  test        - Probar URLs"
        echo "  restart-api - Reiniciar API de HAProxy"
        exit 1
        ;;
esac
