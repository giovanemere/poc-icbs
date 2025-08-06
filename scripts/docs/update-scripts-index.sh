#!/bin/bash
# Script para actualizar el índice de scripts

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
INDEX_FILE="$SCRIPTS_DIR/INDEX.md"

echo "🔧 Actualizando índice de scripts..."

cat > "$INDEX_FILE" << 'EOINDEX'
# Índice de Scripts del Sistema

Este documento proporciona una descripción completa de todos los scripts disponibles.

## 📁 Estructura Organizada

### 🔧 Core (Fundamentales)
Scripts esenciales para el funcionamiento del sistema.

EOINDEX

# Agregar scripts por categoría
for category_dir in "$SCRIPTS_DIR"/*; do
    if [[ -d "$category_dir" ]]; then
        category_name=$(basename "$category_dir")
        
        # Saltar directorios especiales
        [[ "$category_name" == "." || "$category_name" == ".." ]] && continue
        
        echo "" >> "$INDEX_FILE"
        
        # Crear título de categoría
        case "$category_name" in
            "core") echo "### 🔧 Core (Fundamentales)" >> "$INDEX_FILE" ;;
            "services") echo "### 🚀 Services (Servicios)" >> "$INDEX_FILE" ;;
            "deployment") echo "### 📦 Deployment (Despliegue)" >> "$INDEX_FILE" ;;
            "testing") echo "### ✅ Testing (Pruebas)" >> "$INDEX_FILE" ;;
            "maintenance") echo "### 🔧 Maintenance (Mantenimiento)" >> "$INDEX_FILE" ;;
            "monitoring") echo "### 📊 Monitoring (Monitoreo)" >> "$INDEX_FILE" ;;
            "utilities") echo "### 🛠️ Utilities (Utilidades)" >> "$INDEX_FILE" ;;
            "canary") echo "### 🔄 Canary (Despliegue Canary)" >> "$INDEX_FILE" ;;
            "build") echo "### 🏗️ Build (Construcción)" >> "$INDEX_FILE" ;;
            "docs") echo "### 📚 Docs (Documentación)" >> "$INDEX_FILE" ;;
            *) echo "### 📁 $(echo "$category_name" | sed 's/^./\U&/')" >> "$INDEX_FILE" ;;
        esac
        
        # Agregar scripts de la categoría
        for script in "$category_dir"/*.sh; do
            if [[ -f "$script" ]]; then
                script_name=$(basename "$script")
                # Extraer descripción del script
                description=$(head -10 "$script" 2>/dev/null | grep -E "^#.*[Dd]escripción|^# .*" | head -1 | sed 's/^# *//' 2>/dev/null || echo "Script de $category_name")
                echo "- \`$script_name\` - $description" >> "$INDEX_FILE"
            fi
        done
    fi
done

echo "✅ Índice actualizado: $INDEX_FILE"
