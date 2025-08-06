#!/bin/bash

echo "🔗 VERIFICACIÓN COMPLETA DE TODAS LAS URLs"
echo "Fecha: $(date)"
echo "=========================================="
echo ""

# Función para verificar URL
check_url() {
    local url=$1
    local name=$2
    local expected=$3
    
    echo -n "Verificando $name... "
    
    if [[ $url == https://* ]]; then
        response=$(curl -k -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    fi
    
    if [ "$response" = "$expected" ]; then
        echo "✅ HTTP $response (OK)"
    elif [ "$response" = "000" ]; then
        echo "❌ NO RESPONDE"
    else
        echo "⚠️ HTTP $response (Esperado: $expected)"
    fi
}

echo "=== SERVICIOS PRINCIPALES ==="
check_url "http://localhost:7001/console" "WebLogic A Console" "302"
check_url "http://localhost:7002/console" "WebLogic B Console" "302"
check_url "http://localhost:8404/stats" "HAProxy Stats" "200"
check_url "http://localhost:8082/" "HAProxy API" "200"
check_url "http://localhost:80/" "HAProxy Frontend" "200"
check_url "http://localhost:8000/" "MkDocs Documentation" "200"
echo ""

echo "=== SERVICIOS CON PROBLEMAS CONOCIDOS ==="
check_url "http://localhost:8083/" "HAProxy Load Balancer" "200"
echo ""

echo "=== SERVICIOS ADICIONALES ==="
check_url "https://localhost:5500/em" "Oracle EM Express" "200"
check_url "https://localhost:8444/" "HAProxy HTTPS" "200"
check_url "http://localhost:8081/" "HAProxy Admin UI" "200"
check_url "http://localhost:8087/" "HAProxy Admin UI Alt" "200"
echo ""

echo "=== RESUMEN ==="
total=0
working=0

urls=(
    "http://localhost:7001/console:302"
    "http://localhost:7002/console:302"
    "http://localhost:8404/stats:200"
    "http://localhost:8082/:200"
    "http://localhost:80/:200"
    "http://localhost:8000/:200"
    "http://localhost:8083/:200"
)

for url_expected in "${urls[@]}"; do
    url=$(echo $url_expected | cut -d: -f1,2,3)
    expected=$(echo $url_expected | cut -d: -f4)
    
    if [[ $url == https://* ]]; then
        response=$(curl -k -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    fi
    
    total=$((total + 1))
    if [ "$response" = "$expected" ]; then
        working=$((working + 1))
    fi
done

percentage=$((working * 100 / total))
echo "URLs funcionando: $working/$total ($percentage%)"

if [ $percentage -ge 85 ]; then
    echo "✅ ESTADO: SISTEMA MAYORMENTE FUNCIONAL"
elif [ $percentage -ge 70 ]; then
    echo "⚠️ ESTADO: SISTEMA PARCIALMENTE FUNCIONAL"
else
    echo "❌ ESTADO: SISTEMA CON PROBLEMAS"
fi

echo ""
echo "🔗 ENLACES DIRECTOS PARA NAVEGADOR:"
echo "  - WebLogic A: http://localhost:7001/console"
echo "  - WebLogic B: http://localhost:7002/console"
echo "  - HAProxy Stats: http://localhost:8404/stats"
echo "  - HAProxy API: http://localhost:8082/"
echo "  - HAProxy Frontend: http://localhost:80/"
echo "  - MkDocs Docs: http://localhost:8000/"
echo "  - HAProxy LB: http://localhost:8083/ (requiere fix)"
echo ""
echo "Verificación completada: $(date)"
