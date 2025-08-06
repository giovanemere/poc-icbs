#!/bin/bash

# Script de validación rápida para verificar que todos los scripts funcionen
set -e

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPTS_DIR")"

echo "🔍 Validación rápida de scripts..."

# Verificar sintaxis
echo "📝 Verificando sintaxis..."
SYNTAX_OK=0
SYNTAX_ERROR=0

find "$SCRIPTS_DIR" -name "*.sh" -type f | while read -r script; do
    if bash -n "$script" 2>/dev/null; then
        echo "✅ $(basename "$script")"
        SYNTAX_OK=$((SYNTAX_OK + 1))
    else
        echo "❌ Error de sintaxis en: $(basename "$script")"
        SYNTAX_ERROR=$((SYNTAX_ERROR + 1))
    fi
done

# Verificar permisos
echo "🔐 Verificando permisos..."
find "$SCRIPTS_DIR" -name "*.sh" -type f | while read -r script; do
    if [[ ! -x "$script" ]]; then
        echo "⚠️  Sin permisos de ejecución: $(basename "$script")"
        chmod +x "$script"
        echo "✅ Permisos corregidos: $(basename "$script")"
    fi
done

# Verificar enlaces simbólicos
echo "🔗 Verificando enlaces simbólicos..."
for link in "$PROJECT_ROOT"/*.sh; do
    if [[ -L "$link" ]]; then
        if [[ ! -e "$link" ]]; then
            echo "❌ Enlace roto: $(basename "$link")"
        else
            echo "✅ Enlace válido: $(basename "$link")"
        fi
    fi
done

echo "✅ Validación rápida completada"
