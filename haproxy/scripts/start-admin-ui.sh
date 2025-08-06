#!/bin/bash
# Script wrapper para iniciar admin_ui.py con variables de entorno cargadas

set -e

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "🚀 Iniciando HAProxy Admin UI..."
echo "📁 Directorio del proyecto: $PROJECT_ROOT"

# Cargar variables de entorno
echo "🔧 Cargando variables de entorno..."
source "$PROJECT_ROOT/scripts/core/load-env.sh"
load_env

# Verificar que las variables críticas estén cargadas
if [[ -z "$HAPROXY_API_URL" ]]; then
    echo "❌ Error: HAPROXY_API_URL no está definida"
    exit 1
fi

if [[ -z "$HAPROXY_UI_PORT" ]]; then
    echo "❌ Error: HAPROXY_UI_PORT no está definida"
    exit 1
fi

echo "✅ Variables de entorno cargadas:"
echo "   - HAPROXY_API_URL: $HAPROXY_API_URL"
echo "   - HAPROXY_UI_PORT: $HAPROXY_UI_PORT"

# Cambiar al directorio del script
cd "$(dirname "${BASH_SOURCE[0]}")"

# Ejecutar admin_ui.py
echo "🌐 Iniciando servidor web en puerto $HAPROXY_UI_PORT..."
python3 admin_ui.py
