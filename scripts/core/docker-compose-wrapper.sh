#!/bin/bash
# Script wrapper para docker-compose que carga automáticamente las variables de entorno

set -e

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)"
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/config/docker-compose.yml"

# Cargar variables de entorno
echo "🔧 Cargando variables de entorno..."
source "$PROJECT_ROOT/scripts/core/load-env.sh"
load_env

# Verificar que el archivo docker-compose.yml existe
if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
    echo "❌ Error: $DOCKER_COMPOSE_FILE no existe"
    exit 1
fi

echo "✅ Variables de entorno cargadas"
echo "📁 Usando archivo: $DOCKER_COMPOSE_FILE"

# Ejecutar docker-compose con los argumentos proporcionados
echo "🐳 Ejecutando: docker-compose -f $DOCKER_COMPOSE_FILE $*"
docker-compose -f "$DOCKER_COMPOSE_FILE" "$@"
