#!/bin/bash
# Validación de estructura de applications

echo "🔍 Validando estructura de applications..."

APPS=("weblogic-feature-flags" "haproxy-advanced" "mkdocs-server" "oracle-setup")
DIRS=("src" "config" "scripts" "deploy" "docs" "tests")

for app in "${APPS[@]}"; do
    echo "📁 $app:"
    if [[ -d "applications/$app" ]]; then
        echo "  ✅ Directorio existe"
        
        for dir in "${DIRS[@]}"; do
            if [[ -d "applications/$app/$dir" ]]; then
                echo "  ✅ $dir/"
            else
                echo "  ⚠️  $dir/ (faltante)"
            fi
        done
        
        if [[ -f "applications/$app/README.md" ]]; then
            echo "  ✅ README.md"
        else
            echo "  ❌ README.md (faltante)"
        fi
        
        if [[ -f "applications/$app/Dockerfile" ]]; then
            echo "  ✅ Dockerfile"
        else
            echo "  ❌ Dockerfile (faltante)"
        fi
    else
        echo "  ❌ Directorio no existe"
    fi
    echo ""
done

echo "🎯 Validación completada"
