#!/bin/bash
# Script para generar documentación automáticamente

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "🔧 Generando documentación..."

# Crear índice de scripts actualizado
"$PROJECT_ROOT/scripts/docs/update-scripts-index.sh"

# Generar documentación de configuración
"$PROJECT_ROOT/scripts/docs/generate-config-docs.sh"

echo "✅ Documentación generada"
