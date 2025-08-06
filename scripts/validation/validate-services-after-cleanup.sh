#!/bin/bash

# SCRIPT DE VALIDACIÓN POST-LIMPIEZA
# Valida que todos los servicios funcionen después de reorganizar archivos

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 VALIDACIÓN POST-LIMPIEZA INICIADA${NC}"

# Función de logging
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"; }

# Validar estructura de archivos Python
if [[ -d "$PROJECT_ROOT/scripts/python" ]]; then
    PYTHON_COUNT=$(find "$PROJECT_ROOT/scripts/python" -name "*.py" -type f | wc -l)
    log "✅ Scripts Python organizados: $PYTHON_COUNT"
else
    warn "⚠️  Carpeta scripts/python no encontrada"
fi

# Validar documentación de usuario
if [[ -d "$PROJECT_ROOT/docs/user-guides" ]]; then
    GUIDES_COUNT=$(find "$PROJECT_ROOT/docs/user-guides" -name "*.md" -type f | wc -l)
    log "✅ Guías de usuario: $GUIDES_COUNT"
else
    warn "⚠️  Carpeta docs/user-guides no encontrada"
fi

# Validar que archivos esenciales estén en raíz
ESSENTIAL_FILES=(
    "README.md"
    "docker-compose.yml"
    "mkdocs.yml"
    "requirements.txt"
)

for file in "${ESSENTIAL_FILES[@]}"; do
    if [[ -f "$PROJECT_ROOT/$file" ]]; then
        log "✅ Archivo esencial presente: $file"
    else
        error "❌ Archivo esencial faltante: $file"
    fi
done

# Validar configuración de MkDocs
if command -v mkdocs &> /dev/null; then
    if mkdocs build --quiet 2>/dev/null; then
        log "✅ Configuración MkDocs válida"
    else
        warn "⚠️  Problemas en configuración MkDocs"
    fi
else
    warn "MkDocs no instalado"
fi

# Validar enlaces simbólicos
BROKEN_LINKS=0
find "$PROJECT_ROOT" -maxdepth 1 -name "*.sh" -type l | while read -r link; do
    if [[ ! -e "$link" ]]; then
        error "Enlace roto: $(basename "$link")"
        BROKEN_LINKS=$((BROKEN_LINKS + 1))
    fi
done

if [[ $BROKEN_LINKS -eq 0 ]]; then
    log "✅ Todos los enlaces simbólicos funcionando"
fi

echo -e "${BLUE}🏁 Validación post-limpieza completada${NC}"

exit 0
