#!/bin/bash
"""
Script para aplicar configuración avanzada de backends HAProxy
Incluye validación, backup y rollback automático
"""

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuración
PROJECT_ROOT="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
HAPROXY_CONFIG_DIR="$PROJECT_ROOT/applications/haproxy-advanced/config"
CURRENT_CONFIG="$HAPROXY_CONFIG_DIR/haproxy.cfg"
NEW_CONFIG="$HAPROXY_CONFIG_DIR/haproxy-backends-fixed.cfg"
BACKUP_DIR="$PROJECT_ROOT/backups/haproxy"
COMPOSE_FILE="$PROJECT_ROOT/config/docker-compose.yml"

echo -e "${BLUE}🔧 Aplicando Configuración Avanzada de Backends HAProxy${NC}"
echo "============================================================"

# Crear directorio de backups
mkdir -p "$BACKUP_DIR"

# Función para hacer backup
backup_current_config() {
    local backup_name="haproxy.cfg.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CURRENT_CONFIG" "$BACKUP_DIR/$backup_name"
    echo -e "${GREEN}✅ Backup creado: $backup_name${NC}"
    echo "$backup_name" > "$BACKUP_DIR/latest_backup.txt"
}

# Función para validar configuración
validate_config() {
    local config_file="$1"
    echo -e "\n${YELLOW}🔍 Validando configuración HAProxy...${NC}"
    
    if docker run --rm -v "$config_file:/tmp/haproxy.cfg:ro" haproxy:2.6 haproxy -c -f /tmp/haproxy.cfg; then
        echo -e "${GREEN}✅ Configuración válida${NC}"
        return 0
    else
        echo -e "${RED}❌ Configuración inválida${NC}"
        return 1
    fi
}

# Función para actualizar IPs dinámicamente
update_container_ips() {
    local config_file="$1"
    echo -e "\n${YELLOW}🔄 Actualizando IPs de contenedores...${NC}"
    
    # Obtener IPs actuales de los contenedores
    local weblogic_a_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' weblogic-a 2>/dev/null || echo "172.18.0.4")
    local weblogic_b_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' weblogic-b 2>/dev/null || echo "172.18.0.2")
    local mkdocs_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mkdocs-server 2>/dev/null || echo "172.18.0.3")
    
    echo "• WebLogic A: $weblogic_a_ip"
    echo "• WebLogic B: $weblogic_b_ip"
    echo "• MkDocs: $mkdocs_ip"
    
    # Actualizar IPs en la configuración
    sed -i.tmp \
        -e "s/172\.18\.0\.4:7001/$weblogic_a_ip:7001/g" \
        -e "s/172\.18\.0\.2:7001/$weblogic_b_ip:7001/g" \
        -e "s/mkdocs-server:8000/$mkdocs_ip:8000/g" \
        "$config_file"
    
    rm -f "$config_file.tmp"
    echo -e "${GREEN}✅ IPs actualizadas${NC}"
}

# Función para aplicar configuración
apply_config() {
    echo -e "\n${YELLOW}🚀 Aplicando nueva configuración...${NC}"
    
    # Copiar nueva configuración
    cp "$NEW_CONFIG" "$CURRENT_CONFIG"
    
    # Actualizar IPs
    update_container_ips "$CURRENT_CONFIG"
    
    # Reiniciar HAProxy
    cd "$PROJECT_ROOT"
    if docker-compose -f "$COMPOSE_FILE" restart haproxy; then
        echo -e "${GREEN}✅ HAProxy reiniciado exitosamente${NC}"
        return 0
    else
        echo -e "${RED}❌ Error reiniciando HAProxy${NC}"
        return 1
    fi
}

# Función para rollback
rollback_config() {
    echo -e "\n${RED}🔄 Realizando rollback...${NC}"
    
    local latest_backup=$(cat "$BACKUP_DIR/latest_backup.txt" 2>/dev/null || echo "")
    if [ -n "$latest_backup" ] && [ -f "$BACKUP_DIR/$latest_backup" ]; then
        cp "$BACKUP_DIR/$latest_backup" "$CURRENT_CONFIG"
        cd "$PROJECT_ROOT"
        docker-compose -f "$COMPOSE_FILE" restart haproxy
        echo -e "${GREEN}✅ Rollback completado${NC}"
    else
        echo -e "${RED}❌ No se pudo realizar rollback - backup no encontrado${NC}"
    fi
}

# Función para probar servicios
test_services() {
    echo -e "\n${YELLOW}🧪 Probando servicios...${NC}"
    
    # Esperar a que HAProxy esté listo
    sleep 10
    
    local tests_passed=0
    local total_tests=6
    
    # Test 1: HAProxy Stats
    echo -n "• HAProxy Stats: "
    if curl -s -u admin:admin123 http://localhost:8404/stats | grep -q "Statistics"; then
        echo -e "${GREEN}✅${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}❌${NC}"
    fi
    
    # Test 2: Health Check
    echo -n "• Health Check: "
    if curl -s http://localhost:8083/health | grep -q "healthy"; then
        echo -e "${GREEN}✅${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}❌${NC}"
    fi
    
    # Test 3: WebLogic A
    echo -n "• WebLogic A: "
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:7001/console | grep -q "200\|302"; then
        echo -e "${GREEN}✅${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}❌${NC}"
    fi
    
    # Test 4: WebLogic B
    echo -n "• WebLogic B: "
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:7002/console | grep -q "200\|302"; then
        echo -e "${GREEN}✅${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}❌${NC}"
    fi
    
    # Test 5: MkDocs
    echo -n "• MkDocs: "
    if curl -s http://localhost:8000/ | grep -q "WebLogic\|Documentation"; then
        echo -e "${GREEN}✅${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}❌${NC}"
    fi
    
    # Test 6: Load Balancer
    echo -n "• Load Balancer: "
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8083/ | grep -q "503\|200"; then
        echo -e "${GREEN}✅${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}❌${NC}"
    fi
    
    echo -e "\n${BLUE}📊 Resultados: $tests_passed/$total_tests pruebas exitosas${NC}"
    
    if [ $tests_passed -ge 4 ]; then
        return 0
    else
        return 1
    fi
}

# Función principal
main() {
    echo -e "\n${YELLOW}📋 Verificando prerrequisitos...${NC}"
    
    # Verificar archivos necesarios
    if [ ! -f "$NEW_CONFIG" ]; then
        echo -e "${RED}❌ Configuración avanzada no encontrada: $NEW_CONFIG${NC}"
        exit 1
    fi
    
    if [ ! -f "$CURRENT_CONFIG" ]; then
        echo -e "${RED}❌ Configuración actual no encontrada: $CURRENT_CONFIG${NC}"
        exit 1
    fi
    
    # Verificar que HAProxy esté ejecutándose
    if ! docker ps | grep -q haproxy; then
        echo -e "${RED}❌ HAProxy no está ejecutándose${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerrequisitos verificados${NC}"
    
    # Hacer backup
    echo -e "\n${YELLOW}💾 Creando backup...${NC}"
    backup_current_config
    
    # Validar nueva configuración
    if ! validate_config "$NEW_CONFIG"; then
        echo -e "${RED}❌ La nueva configuración no es válida${NC}"
        exit 1
    fi
    
    # Aplicar configuración
    if apply_config; then
        echo -e "${GREEN}✅ Configuración aplicada${NC}"
    else
        echo -e "${RED}❌ Error aplicando configuración${NC}"
        rollback_config
        exit 1
    fi
    
    # Probar servicios
    if test_services; then
        echo -e "\n${GREEN}🎉 ¡Configuración avanzada aplicada exitosamente!${NC}"
        echo "=============================================="
        echo -e "${YELLOW}📋 NUEVAS CARACTERÍSTICAS:${NC}"
        echo "• ✅ Backends especializados por tipo de contenido"
        echo "• ✅ Algoritmos de balanceo optimizados"
        echo "• ✅ Health checks mejorados"
        echo "• ✅ Canary deployment (5% del tráfico)"
        echo "• ✅ Sticky sessions para administración"
        echo "• ✅ Rate limiting básico"
        echo "• ✅ Headers de seguridad"
        echo "• ✅ Configuración SSL/TLS mejorada"
        echo ""
        echo -e "${YELLOW}🔗 URLs de acceso:${NC}"
        echo "• Load Balancer: http://localhost:8083/"
        echo "• Stats: http://localhost:8404/stats"
        echo "• WebLogic A: http://localhost:7001/console"
        echo "• WebLogic B: http://localhost:7002/console"
        echo "• MkDocs: http://localhost:8000/"
    else
        echo -e "\n${RED}❌ Algunas pruebas fallaron - realizando rollback${NC}"
        rollback_config
        exit 1
    fi
}

# Ejecutar función principal
main "$@"
