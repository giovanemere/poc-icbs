#!/bin/bash

# Script para probar el dashboard profesional
# Autor: Sistema de Gestión de Tráfico
# Fecha: $(date)

set -e

echo "=== Probando Dashboard Profesional ==="
echo

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar estado
show_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Función para probar URL
test_url() {
    local url=$1
    local description=$2
    local expected_status=${3:-200}
    
    echo -n "Probando $description... "
    
    if response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null); then
        if [ "$response" = "$expected_status" ]; then
            echo -e "${GREEN}OK${NC} (HTTP $response)"
            return 0
        else
            echo -e "${YELLOW}WARN${NC} (HTTP $response, esperado $expected_status)"
            return 1
        fi
    else
        echo -e "${RED}FAIL${NC} (No respuesta)"
        return 1
    fi
}

# Función para probar JSON endpoint
test_json_endpoint() {
    local url=$1
    local description=$2
    
    echo -n "Probando $description... "
    
    if response=$(curl -s --max-time 10 "$url" 2>/dev/null); then
        if echo "$response" | jq . >/dev/null 2>&1; then
            echo -e "${GREEN}OK${NC} (JSON válido)"
            return 0
        else
            echo -e "${YELLOW}WARN${NC} (Respuesta no es JSON válido)"
            echo "Respuesta: $response"
            return 1
        fi
    else
        echo -e "${RED}FAIL${NC} (No respuesta)"
        return 1
    fi
}

echo "1. Verificando que los contenedores estén ejecutándose..."
echo

# Verificar contenedores
containers=("haproxy" "dashboard")
for container in "${containers[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
        show_status 0 "Contenedor $container está ejecutándose"
    else
        show_status 1 "Contenedor $container NO está ejecutándose"
        echo -e "${RED}Error: El contenedor $container no está ejecutándose${NC}"
        echo "Ejecuta: docker-compose -f config/docker-compose-images.yml up -d"
        exit 1
    fi
done

echo
echo "2. Probando acceso directo al dashboard..."
echo

# Probar acceso directo al dashboard (puerto 8001)
test_url "http://localhost:8001/" "Dashboard directo (puerto 8001)"
test_json_endpoint "http://localhost:8001/api/health" "Health check directo"
test_json_endpoint "http://localhost:8001/api/stats" "API de estadísticas directa"

echo
echo "3. Probando acceso a través de HAProxy..."
echo

# Probar acceso a través de HAProxy (puerto 8080)
test_url "http://localhost:8080/dashboard/" "Dashboard a través de HAProxy"
test_json_endpoint "http://localhost:8080/dashboard/api/health" "Health check a través de HAProxy"
test_json_endpoint "http://localhost:8080/dashboard/api/stats" "API de estadísticas a través de HAProxy"

echo
echo "4. Verificando logs del dashboard..."
echo

# Mostrar logs recientes del dashboard
echo "Últimas 10 líneas de logs del dashboard:"
docker logs --tail 10 dashboard 2>/dev/null || echo -e "${YELLOW}No se pudieron obtener los logs del dashboard${NC}"

echo
echo "5. Verificando configuración de HAProxy..."
echo

# Verificar que HAProxy esté configurado para el dashboard
if docker exec haproxy grep -q "dashboard-backend" /usr/local/etc/haproxy/haproxy.cfg 2>/dev/null; then
    show_status 0 "HAProxy tiene configuración para dashboard-backend"
else
    show_status 1 "HAProxy NO tiene configuración para dashboard-backend"
fi

if docker exec haproxy grep -q "path_dashboard" /usr/local/etc/haproxy/haproxy.cfg 2>/dev/null; then
    show_status 0 "HAProxy tiene ACL para path_dashboard"
else
    show_status 1 "HAProxy NO tiene ACL para path_dashboard"
fi

echo
echo "6. Probando conectividad interna..."
echo

# Probar conectividad desde HAProxy al dashboard
if docker exec haproxy curl -s --max-time 5 "http://dashboard:8000/api/health" >/dev/null 2>&1; then
    show_status 0 "HAProxy puede conectarse al dashboard internamente"
else
    show_status 1 "HAProxy NO puede conectarse al dashboard internamente"
fi

echo
echo "=== Resumen de URLs del Dashboard ==="
echo
echo -e "${GREEN}Dashboard directo:${NC}           http://localhost:8001/"
echo -e "${GREEN}Dashboard vía HAProxy:${NC}       http://localhost:8080/dashboard/"
echo -e "${GREEN}API Health Check:${NC}            http://localhost:8080/dashboard/api/health"
echo -e "${GREEN}API Estadísticas:${NC}            http://localhost:8080/dashboard/api/stats"
echo
echo -e "${YELLOW}Nota:${NC} El dashboard profesional está disponible en ambas URLs."
echo -e "${YELLOW}      Se recomienda usar la URL vía HAProxy para producción.${NC}"
echo

echo "=== Prueba completada ==="
