#!/bin/bash

# SCRIPT DE AUTO-MANTENIMIENTO
# Mantiene la organización automáticamente

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 AUTO-MANTENIMIENTO INICIADO${NC}"

# Función de logging
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"; }

# Auto-corrección de permisos
find "$SCRIPTS_DIR" -name "*.sh" -type f | while read -r script; do
    if [[ ! -x "$script" ]]; then
        chmod +x "$script"
        log "Permisos corregidos: $(basename "$script")"
    fi
done

# Auto-corrección de enlaces rotos
find "$PROJECT_ROOT" -maxdepth 1 -name "*.sh" -type l | while read -r link; do
    if [[ ! -e "$link" ]]; then
        filename=$(basename "$link")
        warn "Reparando enlace roto: $filename"
        
        # Buscar el archivo en scripts/
        if [[ -f "$SCRIPTS_DIR/core/$filename" ]]; then
            rm "$link"
            ln -sf "scripts/core/$filename" "$PROJECT_ROOT/$filename"
            log "Enlace reparado: $filename → scripts/core/"
        elif [[ -f "$SCRIPTS_DIR/services/$filename" ]]; then
            rm "$link"
            ln -sf "scripts/services/$filename" "$PROJECT_ROOT/$filename"
            log "Enlace reparado: $filename → scripts/services/"
        fi
    fi
done

# Limpiar archivos temporales
find "$PROJECT_ROOT" -name "*.tmp" -delete 2>/dev/null || true
find "$PROJECT_ROOT" -name "*.bak" -delete 2>/dev/null || true

log "Auto-mantenimiento completado"

exit 0
