#!/bin/bash

# SCRIPT DE VALIDACIÓN CONTINUA
# Monitorea y mantiene la organización automáticamente

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 VALIDACIÓN CONTINUA INICIADA${NC}"

# Función de logging
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"; }

# Verificar archivos .sh no autorizados en raíz
UNAUTHORIZED_FILES=$(find "$PROJECT_ROOT" -maxdepth 1 -name "*.sh" -type f | wc -l)

if [[ $UNAUTHORIZED_FILES -gt 0 ]]; then
    error "Detectados $UNAUTHORIZED_FILES archivos .sh no autorizados en raíz"
    find "$PROJECT_ROOT" -maxdepth 1 -name "*.sh" -type f | while read -r file; do
        warn "Archivo no autorizado: $(basename "$file")"
    done
    echo -e "${YELLOW}Ejecutar: ./scripts/maintenance/master-cleanup.sh${NC}"
else
    log "✅ Raíz limpia - sin archivos .sh no autorizados"
fi

# Verificar enlaces simbólicos rotos
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

# Verificar estructura de scripts
if [[ -d "$SCRIPTS_DIR" ]]; then
    TOTAL_SCRIPTS=$(find "$SCRIPTS_DIR" -name "*.sh" -type f | wc -l)
    log "✅ $TOTAL_SCRIPTS scripts organizados en estructura"
else
    error "Directorio scripts/ no encontrado"
fi

# Verificar MkDocs
if [[ -f "$PROJECT_ROOT/mkdocs.yml" ]]; then
    if command -v mkdocs &> /dev/null; then
        if mkdocs build --quiet 2>/dev/null; then
            log "✅ Configuración MkDocs válida"
        else
            warn "⚠️  Problemas en configuración MkDocs"
        fi
    else
        warn "MkDocs no instalado"
    fi
else
    error "Archivo mkdocs.yml no encontrado"
fi

# Verificar documentación de scripts
if [[ -f "$PROJECT_ROOT/docs/scripts/index.md" ]]; then
    log "✅ Documentación de scripts presente"
else
    warn "⚠️  Documentación de scripts faltante"
fi

echo -e "${BLUE}🏁 Validación continua completada${NC}"

exit 0
