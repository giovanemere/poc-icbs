#!/bin/bash
#
# Script para verificar URLs de feature-flags después de la actualización
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Verificación de URLs Feature Flags ===${NC}"
echo ""

# Obtener puerto dinámico de HAProxy
HAPROXY_PORT=$(grep -E '^\s*-\s*"[0-9]+:80"' config/docker-compose.yml | sed 's/.*"\([0-9]*\):80".*/\1/' 2>/dev/null || echo "8083")

echo -e "${YELLOW}Puerto dinámico de HAProxy detectado: $HAPROXY_PORT${NC}"
echo ""

# URLs de feature-flags a verificar
declare -A FEATURE_URLS=(
    ["Feature Flags Principal"]="http://localhost:$HAPROXY_PORT/feature-flags/"
    ["Feature Flags Admin"]="http://localhost:$HAPROXY_PORT/feature-flags/admin.html"
    ["Feature Flags Info"]="http://localhost:$HAPROXY_PORT/feature-flags/info.html"
    ["FF4J Simple Principal"]="http://localhost:$HAPROXY_PORT/ff4j-simple/"
    ["FF4J Simple Info"]="http://localhost:$HAPROXY_PORT/ff4j-simple/info.html"
    ["Version A"]="http://localhost:$HAPROXY_PORT/version-a/"
    ["Version B"]="http://localhost:$HAPROXY_PORT/version-b/"
)

echo -e "${BLUE}🌐 Verificando URLs de Feature Flags:${NC}"
success_count=0
total_count=${#FEATURE_URLS[@]}

for service in "${!FEATURE_URLS[@]}"; do
    url="${FEATURE_URLS[$service]}"
    if timeout 10 curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302"; then
        echo -e "${GREEN}✓ $service - ACCESIBLE${NC}"
        echo -e "  ${CYAN}→ $url${NC}"
        ((success_count++))
    else
        echo -e "${RED}✗ $service - NO ACCESIBLE${NC}"
        echo -e "  ${CYAN}→ $url${NC}"
    fi
done

echo ""
echo -e "${BLUE}📊 Resumen de verificación:${NC}"
echo -e "${GREEN}✓ URLs accesibles: $success_count/$total_count${NC}"

if [ $success_count -eq $total_count ]; then
    echo -e "${GREEN}🎉 Todas las URLs de Feature Flags están funcionando correctamente${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Algunas URLs no están accesibles. Verifica que los servicios estén corriendo.${NC}"
    echo -e "${CYAN}Ejecuta: ./manage-services.sh start${NC}"
    exit 1
fi
