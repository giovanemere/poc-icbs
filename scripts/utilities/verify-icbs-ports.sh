#!/bin/bash
#
# Script para verificar que todos los puertos ICBS estén funcionando correctamente
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Verificación de Puertos ICBS ===${NC}"
echo ""

# Obtener puerto dinámico de HAProxy
HAPROXY_PORT=$(grep -E '^\s*-\s*"[0-9]+:80"' config/docker-compose.yml | sed 's/.*"\([0-9]*\):80".*/\1/' 2>/dev/null || echo "8083")

# Puertos a verificar
declare -A PORTS=(
    ["HAProxy Load Balancer"]="$HAPROXY_PORT"
    ["HAProxy API Admin"]="8081"
    ["HAProxy UI Admin"]="8082"
    ["HAProxy Stats"]="8404"
    ["HAProxy HTTPS"]="8444"
    ["WebLogic A Console"]="7001"
    ["WebLogic B Console"]="7002"
    ["Oracle Database"]="1521"
    ["Oracle EM Express"]="5500"
    ["MkDocs Server"]="8000"
    ["MkDocs Dev Server"]="8001"
    ["MkDocs V1 Server"]="8002"
)

# URLs a verificar
declare -A URLS=(
    ["HAProxy Load Balancer"]="http://localhost:$HAPROXY_PORT"
    ["HAProxy API Admin"]="http://localhost:8081"
    ["HAProxy UI Admin"]="http://localhost:8082"
    ["HAProxy Stats"]="http://localhost:8404/stats"
    ["WebLogic A Console"]="http://localhost:7001/console"
    ["WebLogic B Console"]="http://localhost:7002/console"
    ["Oracle EM Express"]="https://localhost:5500/em"
    ["MkDocs Server"]="http://localhost:8000"
    ["MkDocs Dev Server"]="http://localhost:8001"
    ["MkDocs V1 Server"]="http://localhost:8002"
)

echo -e "${YELLOW}Puerto dinámico de HAProxy detectado: $HAPROXY_PORT${NC}"
echo ""

# Verificar puertos
echo -e "${BLUE}🔌 Verificando puertos en uso:${NC}"
for service in "${!PORTS[@]}"; do
    port="${PORTS[$service]}"
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        echo -e "${GREEN}✓ $service (puerto $port) - ACTIVO${NC}"
    else
        echo -e "${RED}✗ $service (puerto $port) - INACTIVO${NC}"
    fi
done

echo ""

# Verificar URLs
echo -e "${BLUE}🌐 Verificando URLs de servicios:${NC}"
for service in "${!URLS[@]}"; do
    url="${URLS[$service]}"
    if timeout 5 curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302\|401"; then
        echo -e "${GREEN}✓ $service - ACCESIBLE${NC}"
        echo -e "  ${CYAN}→ $url${NC}"
    else
        echo -e "${RED}✗ $service - NO ACCESIBLE${NC}"
        echo -e "  ${CYAN}→ $url${NC}"
    fi
done

echo ""
echo -e "${BLUE}=== Verificación completada ===${NC}"
echo -e "${YELLOW}Para más detalles, consulta: PUERTOS_CONFIGURACION.md${NC}"
