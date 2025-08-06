#!/bin/bash

# =============================================================================
# INTEGRATE REGISTRY VARIABLES
# =============================================================================
# Script para integrar variables del .env.registry con el sistema principal

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔧 Integrando variables del registry..."

# Verificar que existe .env.registry
if [[ ! -f "$PROJECT_ROOT/.env.registry" ]]; then
    echo "❌ Error: No se encuentra .env.registry"
    exit 1
fi

# Crear backup del .env actual
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    cp "$PROJECT_ROOT/.env" "$PROJECT_ROOT/.env.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backup creado de .env actual"
fi

# Integrar variables del registry al .env principal
echo "🔄 Integrando variables..."

# Agregar sección de Docker Hub al .env si no existe
if ! grep -q "DOCKER HUB IMAGES" "$PROJECT_ROOT/.env" 2>/dev/null; then
    echo "" >> "$PROJECT_ROOT/.env"
    echo "# ==============================================================================" >> "$PROJECT_ROOT/.env"
    echo "# DOCKER HUB IMAGES - FROM .env.registry" >> "$PROJECT_ROOT/.env"
    echo "# ==============================================================================" >> "$PROJECT_ROOT/.env"
    
    # Extraer variables principales del .env.registry
    grep "^MKDOCS_IMAGE=" "$PROJECT_ROOT/.env.registry" >> "$PROJECT_ROOT/.env"
    grep "^MKDOCS_VERSION=" "$PROJECT_ROOT/.env.registry" >> "$PROJECT_ROOT/.env"
    grep "^HAPROXY_IMAGE=" "$PROJECT_ROOT/.env.registry" >> "$PROJECT_ROOT/.env"
    grep "^HAPROXY_VERSION=" "$PROJECT_ROOT/.env.registry" >> "$PROJECT_ROOT/.env"
    grep "^WEBLOGIC_IMAGE=" "$PROJECT_ROOT/.env.registry" >> "$PROJECT_ROOT/.env"
    grep "^WEBLOGIC_VERSION=" "$PROJECT_ROOT/.env.registry" >> "$PROJECT_ROOT/.env"
    grep "^ORACLE_IMAGE=" "$PROJECT_ROOT/.env.registry" >> "$PROJECT_ROOT/.env"
    grep "^ORACLE_VERSION=" "$PROJECT_ROOT/.env.registry" >> "$PROJECT_ROOT/.env"
    
    echo "✅ Variables del registry integradas en .env"
else
    echo "ℹ️  Variables del registry ya están integradas"
fi

# Verificar integración
echo "🔍 Verificando integración..."
if grep -q "edissonz8809" "$PROJECT_ROOT/.env"; then
    echo "✅ Variables del Docker Hub correctamente integradas"
else
    echo "❌ Error en la integración"
    exit 1
fi

echo "🎉 Integración completada exitosamente!"
echo ""
echo "📋 Variables disponibles:"
echo "   - MKDOCS_IMAGE: $(grep MKDOCS_IMAGE= $PROJECT_ROOT/.env | cut -d= -f2)"
echo "   - HAPROXY_IMAGE: $(grep HAPROXY_IMAGE= $PROJECT_ROOT/.env | cut -d= -f2)"
echo "   - WEBLOGIC_IMAGE: $(grep WEBLOGIC_IMAGE= $PROJECT_ROOT/.env | cut -d= -f2)"
echo ""
echo "🚀 Listo para usar imágenes Docker Hub!"
