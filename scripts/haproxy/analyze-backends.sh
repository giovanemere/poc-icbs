#!/bin/bash
"""
Script para analizar la configuración actual de backends HAProxy
"""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuración
PROJECT_ROOT="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
HAPROXY_CONFIG="$PROJECT_ROOT/applications/haproxy-advanced/config/haproxy.cfg"

echo -e "${BLUE}📊 Análisis de Backends HAProxy${NC}"
echo "================================="

# Verificar que el archivo existe
if [ ! -f "$HAPROXY_CONFIG" ]; then
    echo -e "${RED}❌ Archivo de configuración no encontrado: $HAPROXY_CONFIG${NC}"
    exit 1
fi

# Función para extraer información de backends
analyze_backends() {
    echo -e "\n${YELLOW}🔍 Backends configurados:${NC}"
    echo "========================"
    
    # Extraer nombres de backends
    local backends=$(grep "^backend " "$HAPROXY_CONFIG" | awk '{print $2}')
    local backend_count=0
    
    for backend in $backends; do
        ((backend_count++))
        echo -e "\n${CYAN}[$backend_count] Backend: $backend${NC}"
        
        # Extraer configuración del backend
        local start_line=$(grep -n "^backend $backend" "$HAPROXY_CONFIG" | cut -d: -f1)
        local end_line=$(tail -n +$((start_line + 1)) "$HAPROXY_CONFIG" | grep -n "^backend \|^listen \|^frontend \|^global \|^defaults" | head -1 | cut -d: -f1)
        
        if [ -z "$end_line" ]; then
            end_line=$(wc -l < "$HAPROXY_CONFIG")
        else
            end_line=$((start_line + end_line - 1))
        fi
        
        # Extraer configuración específica
        local config_section=$(sed -n "${start_line},${end_line}p" "$HAPROXY_CONFIG")
        
        # Analizar algoritmo de balanceo
        local balance=$(echo "$config_section" | grep "balance " | awk '{print $2}')
        if [ -n "$balance" ]; then
            echo "  • Algoritmo: $balance"
        else
            echo "  • Algoritmo: roundrobin (por defecto)"
        fi
        
        # Analizar health checks
        local healthcheck=$(echo "$config_section" | grep "option httpchk" | sed 's/.*option httpchk //')
        if [ -n "$healthcheck" ]; then
            echo "  • Health Check: $healthcheck"
        else
            echo "  • Health Check: No configurado"
        fi
        
        # Analizar servidores
        local servers=$(echo "$config_section" | grep "server " | wc -l)
        echo "  • Servidores: $servers"
        
        # Listar servidores
        echo "$config_section" | grep "server " | while read -r line; do
            local server_name=$(echo "$line" | awk '{print $2}')
            local server_addr=$(echo "$line" | awk '{print $3}')
            local server_options=$(echo "$line" | cut -d' ' -f4-)
            echo "    - $server_name ($server_addr)"
            if [[ "$server_options" == *"check"* ]]; then
                echo "      ✅ Health check habilitado"
            fi
            if [[ "$server_options" == *"backup"* ]]; then
                echo "      🔄 Servidor de backup"
            fi
            if [[ "$server_options" == *"disabled"* ]]; then
                echo "      ❌ Servidor deshabilitado"
            fi
        done
        
        # Analizar configuraciones especiales
        if echo "$config_section" | grep -q "cookie"; then
            local cookie=$(echo "$config_section" | grep "cookie" | head -1 | awk '{print $2}')
            echo "  • Sticky Sessions: $cookie"
        fi
        
        if echo "$config_section" | grep -q "timeout server"; then
            local timeout=$(echo "$config_section" | grep "timeout server" | awk '{print $3}')
            echo "  • Timeout: $timeout"
        fi
    done
    
    echo -e "\n${BLUE}📈 Total de backends: $backend_count${NC}"
}

# Función para analizar frontends y routing
analyze_routing() {
    echo -e "\n${YELLOW}🛣️  Análisis de Routing:${NC}"
    echo "======================="
    
    # Extraer ACLs y routing
    local acls=$(grep "acl " "$HAPROXY_CONFIG" | wc -l)
    local use_backends=$(grep "use_backend " "$HAPROXY_CONFIG" | wc -l)
    local default_backend=$(grep "default_backend " "$HAPROXY_CONFIG" | awk '{print $2}' | head -1)
    
    echo "• ACLs configuradas: $acls"
    echo "• Reglas de routing: $use_backends"
    echo "• Backend por defecto: $default_backend"
    
    echo -e "\n${CYAN}Reglas de routing activas:${NC}"
    grep "use_backend " "$HAPROXY_CONFIG" | while read -r line; do
        local backend=$(echo "$line" | awk '{print $2}')
        local condition=$(echo "$line" | cut -d' ' -f4-)
        echo "  • $backend ← $condition"
    done
}

# Función para verificar estado de contenedores
check_container_status() {
    echo -e "\n${YELLOW}🐳 Estado de Contenedores:${NC}"
    echo "=========================="
    
    # Verificar contenedores relacionados
    local containers=("haproxy" "weblogic-a" "weblogic-b" "mkdocs-server" "orcldb")
    
    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container"; then
            local status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$container" | awk '{print $2,$3,$4}')
            echo -e "  • $container: ${GREEN}$status${NC}"
            
            # Obtener IP si está disponible
            local ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container" 2>/dev/null)
            if [ -n "$ip" ]; then
                echo "    IP: $ip"
            fi
        else
            echo -e "  • $container: ${RED}No ejecutándose${NC}"
        fi
    done
}

# Función para probar conectividad
test_connectivity() {
    echo -e "\n${YELLOW}🔗 Pruebas de Conectividad:${NC}"
    echo "=========================="
    
    # Probar puertos principales
    local ports=("8083:HAProxy-LB" "8404:HAProxy-Stats" "7001:WebLogic-A" "7002:WebLogic-B" "8000:MkDocs")
    
    for port_info in "${ports[@]}"; do
        local port=$(echo "$port_info" | cut -d: -f1)
        local service=$(echo "$port_info" | cut -d: -f2)
        
        echo -n "  • $service (puerto $port): "
        if nc -z localhost "$port" 2>/dev/null; then
            echo -e "${GREEN}✅ Accesible${NC}"
        else
            echo -e "${RED}❌ No accesible${NC}"
        fi
    done
}

# Función para mostrar estadísticas HAProxy
show_haproxy_stats() {
    echo -e "\n${YELLOW}📊 Estadísticas HAProxy:${NC}"
    echo "======================="
    
    # Intentar obtener estadísticas
    if curl -s -u admin:admin123 http://localhost:8404/stats 2>/dev/null | grep -q "Statistics"; then
        echo -e "${GREEN}✅ Estadísticas accesibles${NC}"
        echo "  URL: http://localhost:8404/stats"
        echo "  Usuario: admin"
        
        # Obtener información básica de stats
        local stats_data=$(curl -s -u admin:admin123 "http://localhost:8404/stats;csv" 2>/dev/null)
        if [ -n "$stats_data" ]; then
            local active_servers=$(echo "$stats_data" | grep -c ",UP,")
            local total_servers=$(echo "$stats_data" | grep -c "server,")
            echo "  Servidores activos: $active_servers/$total_servers"
        fi
    else
        echo -e "${RED}❌ Estadísticas no accesibles${NC}"
        echo "  Verificar autenticación y estado de HAProxy"
    fi
}

# Función para generar recomendaciones
generate_recommendations() {
    echo -e "\n${YELLOW}💡 Recomendaciones:${NC}"
    echo "=================="
    
    local recommendations=()
    
    # Verificar si hay backends sin health checks
    local backends_without_hc=$(grep -A 10 "^backend " "$HAPROXY_CONFIG" | grep -B 10 "server " | grep -L "option httpchk" | wc -l)
    if [ "$backends_without_hc" -gt 0 ]; then
        recommendations+=("Configurar health checks para todos los backends")
    fi
    
    # Verificar si hay servidores sin check
    local servers_without_check=$(grep "server " "$HAPROXY_CONFIG" | grep -v "check" | wc -l)
    if [ "$servers_without_check" -gt 0 ]; then
        recommendations+=("Habilitar health checks para todos los servidores")
    fi
    
    # Verificar configuración SSL
    if ! grep -q "ssl crt" "$HAPROXY_CONFIG"; then
        recommendations+=("Considerar habilitar SSL/TLS para mayor seguridad")
    fi
    
    # Verificar rate limiting
    if ! grep -q "stick-table" "$HAPROXY_CONFIG"; then
        recommendations+=("Implementar rate limiting para prevenir abuso")
    fi
    
    # Mostrar recomendaciones
    if [ ${#recommendations[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ Configuración óptima - no hay recomendaciones${NC}"
    else
        for i in "${!recommendations[@]}"; do
            echo "  $((i+1)). ${recommendations[$i]}"
        done
    fi
}

# Función principal
main() {
    analyze_backends
    analyze_routing
    check_container_status
    test_connectivity
    show_haproxy_stats
    generate_recommendations
    
    echo -e "\n${BLUE}📋 Análisis completado${NC}"
    echo "====================="
    echo "Para aplicar configuración avanzada:"
    echo "./scripts/haproxy/apply-advanced-backends.sh"
}

# Ejecutar análisis
main "$@"
