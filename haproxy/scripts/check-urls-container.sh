#!/bin/bash
#
# Script para verificar todas las URLs desde dentro del contenedor HAProxy
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

# Contador de errores
errors=0
warnings=0
success=0

# Verificar desde weblogic-a (puerto 7001)
echo -e "${YELLOW}Verificando desde weblogic-a (puerto 7001):${NC}"
for url in "${URLS[@]}"; do
    result=$(check_url "http://weblogic-a:7001$url")
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

# Verificar desde weblogic-b (puerto 7001)
echo -e "${YELLOW}Verificando desde weblogic-b (puerto 7001):${NC}"
for url in "${URLS[@]}"; do
    result=$(check_url "http://weblogic-b:7001$url")
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

# Verificar desde HAProxy (puerto 80)
echo -e "${YELLOW}Verificando desde HAProxy (puerto 80):${NC}"
for url in "${URLS[@]}"; do
    result=$(check_url "http://localhost:80$url")
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

# Mostrar resumen
echo -e "${GREEN}=== Resumen de la verificación ===${NC}"
echo -e "${GREEN}✅ URLs exitosas: $success${NC}"
echo -e "${YELLOW}⚠️ URLs con advertencias: $warnings${NC}"
echo -e "${RED}❌ URLs con errores: $errors${NC}"
echo ""

echo -e "${GREEN}=== Verificación completada ===${NC}"
echo ""

# Salir con código de error si hay errores
if [ $errors -gt 0 ]; then
    exit 1
fi

exit 0
