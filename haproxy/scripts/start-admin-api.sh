#!/bin/bash
# Script wrapper para iniciar admin_api.py con variables de entorno cargadas

set -e

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "🚀 Iniciando HAProxy Admin API..."
echo "📁 Directorio del proyecto: $PROJECT_ROOT"

# Cargar variables de entorno
echo "🔧 Cargando variables de entorno..."
source "$PROJECT_ROOT/scripts/core/load-env.sh"
load_env

# Verificar que las variables críticas estén cargadas
if [[ -z "$HAPROXY_API_EXTERNAL_PORT" ]]; then
    echo "❌ Error: HAPROXY_API_EXTERNAL_PORT no está definida"
    exit 1
fi

echo "✅ Variables de entorno cargadas:"
echo "   - HAPROXY_API_EXTERNAL_PORT: $HAPROXY_API_EXTERNAL_PORT"

# Cambiar al directorio del script
cd "$(dirname "${BASH_SOURCE[0]}")"

# Ejecutar admin_api.py
echo "🌐 Iniciando servidor API en puerto $HAPROXY_API_EXTERNAL_PORT..."
python3 admin_api.py
