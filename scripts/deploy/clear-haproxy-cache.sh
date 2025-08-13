#!/bin/bash
#
# Script para limpiar la caché de HAProxy
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Limpiando caché de HAProxy ===${NC}"

# Verificar si el contenedor de HAProxy está en ejecución
if ! docker ps | grep -q haproxy; then
    echo -e "${RED}Error: El contenedor haproxy no está en ejecución${NC}"
    echo "Por favor, inicie el contenedor con:"
    echo -e "${YELLOW}  docker-compose -f config/docker-compose.yml up -d${NC}"
    exit 1
fi

# Limpiar estadísticas
echo -e "${YELLOW}Limpiando estadísticas de HAProxy...${NC}"
docker exec haproxy bash -c "echo 'clear counters all' | socat stdio /var/run/haproxy.sock" 2>/dev/null || {
    echo -e "${RED}Error al limpiar estadísticas. Intentando método alternativo...${NC}"
    docker exec haproxy bash -c "echo 'clear counters all' | nc -U /var/run/haproxy.sock" 2>/dev/null || {
        echo -e "${RED}No se pudo limpiar las estadísticas de HAProxy${NC}"
    }
}

# Limpiar tablas de stick-tables (cookies de sesión)
echo -e "${YELLOW}Limpiando tablas de sesiones...${NC}"
docker exec haproxy bash -c "echo 'show table' | socat stdio /var/run/haproxy.sock" 2>/dev/null | grep -o '^[^ ]*' | while read table; do
    echo -e "${YELLOW}  Limpiando tabla $table...${NC}"
    docker exec haproxy bash -c "echo 'clear table $table' | socat stdio /var/run/haproxy.sock" 2>/dev/null || {
        echo -e "${RED}  Error al limpiar tabla $table${NC}"
    }
done

# Limpiar caché de cookies específicas
echo -e "${YELLOW}Limpiando caché de cookies específicas...${NC}"
for cookie in ab_test canary SERVERID; do
    echo -e "${YELLOW}  Limpiando cookie $cookie...${NC}"
    docker exec haproxy bash -c "echo 'clear table http-in $cookie' | socat stdio /var/run/haproxy.sock" 2>/dev/null || {
        echo -e "${YELLOW}  No se encontró tabla para cookie $cookie o no se pudo limpiar${NC}"
    }
done

# Verificar configuración de HAProxy
echo -e "${YELLOW}Verificando configuración de HAProxy...${NC}"
docker exec haproxy bash -c "haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg" || {
    echo -e "${RED}Error en la configuración de HAProxy${NC}"
    exit 1
}

# Recargar configuración de HAProxy sin reiniciar (soft reload)
echo -e "${YELLOW}Recargando configuración de HAProxy...${NC}"
docker exec haproxy bash -c "haproxy -sf \$(pidof haproxy) -f /usr/local/etc/haproxy/haproxy.cfg" || {
    echo -e "${RED}Error al recargar HAProxy. Intentando reiniciar el contenedor...${NC}"
    docker restart haproxy
    echo -e "${YELLOW}Contenedor HAProxy reiniciado${NC}"
}

echo -e "${GREEN}Caché de HAProxy limpiada correctamente${NC}"
echo ""
