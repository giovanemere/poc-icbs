#!/bin/bash
# Script de validación para verificar la actualización de admin_ui.py

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADMIN_UI_FILE="$PROJECT_ROOT/haproxy/scripts/admin_ui.py"

echo "🔍 Validando actualización de admin_ui.py..."

# Verificar que el archivo existe
if [[ ! -f "$ADMIN_UI_FILE" ]]; then
    echo "❌ Error: $ADMIN_UI_FILE no existe"
    exit 1
fi

# Verificar que usa variables de entorno
if grep -q "os.getenv('HAPROXY_API_URL'" "$ADMIN_UI_FILE"; then
    echo "✅ admin_ui.py usa HAPROXY_API_URL desde variables de entorno"
else
    echo "❌ Error: admin_ui.py no usa HAPROXY_API_URL desde variables de entorno"
    exit 1
fi

if grep -q "os.getenv('HAPROXY_UI_PORT'" "$ADMIN_UI_FILE"; then
    echo "✅ admin_ui.py usa HAPROXY_UI_PORT desde variables de entorno"
else
    echo "❌ Error: admin_ui.py no usa HAPROXY_UI_PORT desde variables de entorno"
    exit 1
fi

# Verificar que no tiene valores hardcodeados (excepto en defaults de os.getenv)
if grep -v "os.getenv" "$ADMIN_UI_FILE" | grep -q "localhost:8081"; then
    echo "❌ Error: admin_ui.py todavía contiene valores hardcodeados (localhost:8081)"
    exit 1
else
    echo "✅ admin_ui.py no contiene valores hardcodeados de API (excepto defaults)"
fi

if grep -v "os.getenv" "$ADMIN_UI_FILE" | grep -q "port=8082"; then
    echo "❌ Error: admin_ui.py todavía contiene puerto hardcodeado (8082)"
    exit 1
else
    echo "✅ admin_ui.py no contiene puerto hardcodeado (excepto defaults)"
fi

# Cargar variables de entorno para verificar
source "$PROJECT_ROOT/scripts/core/load-env.sh"
load_env > /dev/null 2>&1

# Verificar que las variables están definidas
if [[ -z "$HAPROXY_API_URL" ]]; then
    echo "❌ Error: HAPROXY_API_URL no está definida en .env"
    exit 1
else
    echo "✅ HAPROXY_API_URL está definida: $HAPROXY_API_URL"
fi

if [[ -z "$HAPROXY_UI_PORT" ]]; then
    echo "❌ Error: HAPROXY_UI_PORT no está definida en .env"
    exit 1
else
    echo "✅ HAPROXY_UI_PORT está definida: $HAPROXY_UI_PORT"
fi

# Verificar sintaxis de Python
if python3 -m py_compile "$ADMIN_UI_FILE" 2>/dev/null; then
    echo "✅ admin_ui.py tiene sintaxis válida de Python"
else
    echo "❌ Error: admin_ui.py tiene errores de sintaxis"
    exit 1
fi

echo ""
echo "🎉 ¡Validación completada exitosamente!"
echo "📋 Resumen de la actualización:"
echo "   - ✅ Archivo actualizado: haproxy/scripts/admin_ui.py"
echo "   - ✅ Usa HAPROXY_API_URL desde variables de entorno"
echo "   - ✅ Usa HAPROXY_UI_PORT desde variables de entorno"
echo "   - ✅ No contiene valores hardcodeados"
echo "   - ✅ Sintaxis de Python válida"
echo ""
echo "🚀 Para ejecutar el admin UI:"
echo "   ./haproxy/scripts/start-admin-ui.sh"
