#!/bin/bash
# Script de validación para verificar la actualización de admin_api.py

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADMIN_API_FILE="$PROJECT_ROOT/haproxy/scripts/admin_api.py"

echo "🔍 Validando actualización de admin_api.py..."

# Verificar que el archivo existe
if [[ ! -f "$ADMIN_API_FILE" ]]; then
    echo "❌ Error: $ADMIN_API_FILE no existe"
    exit 1
fi

# Verificar que usa variables de entorno
if grep -q "os.getenv('HAPROXY_API_EXTERNAL_PORT'" "$ADMIN_API_FILE"; then
    echo "✅ admin_api.py usa HAPROXY_API_EXTERNAL_PORT desde variables de entorno"
else
    echo "❌ Error: admin_api.py no usa HAPROXY_API_EXTERNAL_PORT desde variables de entorno"
    exit 1
fi

# Verificar que no tiene valores hardcodeados (excepto en defaults de os.getenv)
if grep -v "os.getenv" "$ADMIN_API_FILE" | grep -q "port=8081"; then
    echo "❌ Error: admin_api.py todavía contiene puerto hardcodeado (8081)"
    exit 1
else
    echo "✅ admin_api.py no contiene puerto hardcodeado (excepto defaults)"
fi

# Verificar que usa rutas dinámicas para scripts
if grep -q "project_root.*scripts.*check-urls.sh" "$ADMIN_API_FILE"; then
    echo "✅ admin_api.py usa rutas dinámicas para scripts"
else
    echo "❌ Error: admin_api.py no usa rutas dinámicas para scripts"
    exit 1
fi

# Cargar variables de entorno para verificar
source "$PROJECT_ROOT/scripts/core/load-env.sh"
load_env > /dev/null 2>&1

# Verificar que las variables están definidas
if [[ -z "$HAPROXY_API_EXTERNAL_PORT" ]]; then
    echo "❌ Error: HAPROXY_API_EXTERNAL_PORT no está definida en .env"
    exit 1
else
    echo "✅ HAPROXY_API_EXTERNAL_PORT está definida: $HAPROXY_API_EXTERNAL_PORT"
fi

# Verificar sintaxis de Python
if python3 -m py_compile "$ADMIN_API_FILE" 2>/dev/null; then
    echo "✅ admin_api.py tiene sintaxis válida de Python"
else
    echo "❌ Error: admin_api.py tiene errores de sintaxis"
    exit 1
fi

echo ""
echo "🎉 ¡Validación completada exitosamente!"
echo "📋 Resumen de la actualización:"
echo "   - ✅ Archivo actualizado: haproxy/scripts/admin_api.py"
echo "   - ✅ Usa HAPROXY_API_EXTERNAL_PORT desde variables de entorno"
echo "   - ✅ No contiene valores hardcodeados"
echo "   - ✅ Usa rutas dinámicas para scripts"
echo "   - ✅ Sintaxis de Python válida"
echo ""
echo "🚀 Para ejecutar el admin API:"
echo "   ./haproxy/scripts/start-admin-api.sh"
