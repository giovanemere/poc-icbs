#!/bin/bash
#
# Script para verificar directamente las URLs en cada nodo WebLogic
#

set -e

echo "=== Verificando URLs directamente en cada nodo WebLogic ==="
echo ""

# URLs a verificar
URLS=(
    "/weblogic-features-a/"
    "/weblogic-features-b/"
    "/version-a/"
    "/version-b/"
    "/feature-flags/"
)

# Verificar desde weblogic-a (puerto 7001)
echo "Verificando desde weblogic-a (puerto 7001):"
for url in "${URLS[@]}"; do
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7001$url)
    if [ "$status" == "200" ]; then
        echo "  ✅ http://localhost:7001$url - OK ($status)"
    else
        echo "  ❌ http://localhost:7001$url - ERROR ($status)"
    fi
done
echo ""

# Verificar desde weblogic-b (puerto 7002)
echo "Verificando desde weblogic-b (puerto 7002):"
for url in "${URLS[@]}"; do
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7002$url)
    if [ "$status" == "200" ]; then
        echo "  ✅ http://localhost:7002$url - OK ($status)"
    else
        echo "  ❌ http://localhost:7002$url - ERROR ($status)"
    fi
done
echo ""

echo "=== Verificación completada ==="
echo ""
