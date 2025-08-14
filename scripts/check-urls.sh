#!/bin/bash
#
# Script para verificar todas las URLs
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Verificando URLs desde cada nodo y HAProxy ===${NC}"
echo ""

# URLs a verificar
URLS=(
    "/weblogic-features-a/"
    "/weblogic-features-b/"
    "/version-a/"
    "/version-b/"
    "/feature-flags/"
    "/ff4j-simple/"
)

# Función para verificar una URL
check_url() {
    local url=$1
    local timeout=5
    
    # Usar curl con timeout para evitar esperas largas
    status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $timeout --max-time $timeout "$url" 2>/dev/null)
    
    if [[ "$status" == "200" || "$status" == "302" ]]; then
        echo -e "  ${GREEN}✅ $url - OK ($status)${NC}"
        return 0
    elif [[ "$status" == "000" ]]; then
        echo -e "  ${RED}❌ $url - ERROR (No se pudo conectar)${NC}"
        return 1
    else
        echo -e "  ${YELLOW}⚠️ $url - ADVERTENCIA ($status)${NC}"
        return 2
    fi
}

# Verificar si los contenedores están en ejecución
weblogic_a_running=false
weblogic_b_running=false
haproxy_running=false

# Usar docker ps con formato específico para evitar problemas con nombres parciales
if docker ps --format "{{.Names}}" | grep -q "^weblogic-a$"; then
    weblogic_a_running=true
fi

if docker ps --format "{{.Names}}" | grep -q "^weblogic-b$"; then
    weblogic_b_running=true
fi

if docker ps --format "{{.Names}}" | grep -q "^haproxy$"; then
    haproxy_running=true
fi

# Contador de errores
errors=0
warnings=0
success=0

# Verificar desde weblogic-a (puerto 7001)
if [ "$weblogic_a_running" = true ]; then
    echo -e "${YELLOW}Verificando desde weblogic-a (puerto 7001):${NC}"
    for url in "${URLS[@]}"; do
        result=$(check_url "http://localhost:7001$url")
        exit_code=$?
        echo "$result"
        
        if [ $exit_code -eq 0 ]; then
            ((success++))
        elif [ $exit_code -eq 1 ]; then
            ((errors++))
        else
            ((warnings++))
        fi
    done
    echo ""
else
    echo -e "${RED}El contenedor weblogic-a no está en ejecución${NC}"
    echo ""
fi

# Verificar desde weblogic-b (puerto 7002)
if [ "$weblogic_b_running" = true ]; then
    echo -e "${YELLOW}Verificando desde weblogic-b (puerto 7002):${NC}"
    for url in "${URLS[@]}"; do
        result=$(check_url "http://localhost:7002$url")
        exit_code=$?
        echo "$result"
        
        if [ $exit_code -eq 0 ]; then
            ((success++))
        elif [ $exit_code -eq 1 ]; then
            ((errors++))
        else
            ((warnings++))
        fi
    done
    echo ""
else
    echo -e "${YELLOW}El contenedor weblogic-b no está en ejecución${NC}"
    echo ""
fi

# Verificar desde HAProxy (puerto 8080)
if [ "$haproxy_running" = true ]; then
    echo -e "${YELLOW}Verificando desde HAProxy (puerto 8080):${NC}"
    for url in "${URLS[@]}"; do
        result=$(check_url "http://localhost:8080$url")
        exit_code=$?
        echo "$result"
        
        if [ $exit_code -eq 0 ]; then
            ((success++))
        elif [ $exit_code -eq 1 ]; then
            ((errors++))
        else
            ((warnings++))
        fi
    done
    echo ""
else
    echo -e "${YELLOW}El contenedor HAProxy no está en ejecución${NC}"
    echo ""
fi

# Mostrar resumen
echo -e "${GREEN}=== Resumen de la verificación ===${NC}"
echo -e "${GREEN}✅ URLs exitosas: $success${NC}"
echo -e "${YELLOW}⚠️ URLs con advertencias: $warnings${NC}"
echo -e "${RED}❌ URLs con errores: $errors${NC}"
echo ""

# Mostrar consejos si hay errores
if [ $errors -gt 0 ]; then
    echo -e "${YELLOW}Consejos para solucionar problemas:${NC}"
    echo -e "1. Asegúrese de que todos los contenedores estén en ejecución:"
    echo -e "   ${GREEN}docker-compose -f config/docker-compose.yml ps${NC}"
    echo -e "2. Verifique los logs de los contenedores:"
    echo -e "   ${GREEN}docker logs weblogic-a${NC}"
    echo -e "   ${GREEN}docker logs weblogic-b${NC}"
    echo -e "   ${GREEN}docker logs haproxy${NC}"
    echo -e "3. Asegúrese de que todas las aplicaciones estén desplegadas:"
    echo -e "   ${GREEN}./scripts/deploy/deploy-war.sh --all${NC}"
    echo -e "4. Reinicie los contenedores si es necesario:"
    echo -e "   ${GREEN}docker-compose -f config/docker-compose.yml restart${NC}"
    echo ""
fi

echo -e "${GREEN}=== Verificación completada ===${NC}"
echo ""

# Salir con código de error si hay errores
if [ $errors -gt 0 ]; then
    exit 1
fi

exit 0
