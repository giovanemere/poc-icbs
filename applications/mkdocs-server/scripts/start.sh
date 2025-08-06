#!/bin/bash
echo "🚀 Iniciando MkDocs Server..."
echo "📚 Documentación: Docker WebLogic Oracle Project"
echo "🌐 Puerto: 8000"

# Verificar archivos
if [[ -f "mkdocs.yml" ]]; then
    echo "✅ mkdocs.yml encontrado"
else
    echo "❌ mkdocs.yml no encontrado"
    exit 1
fi

if [[ -d "docs" ]]; then
    echo "✅ Directorio docs encontrado"
else
    echo "❌ Directorio docs no encontrado"
    exit 1
fi

# Iniciar MkDocs
echo "🎯 Iniciando servidor MkDocs..."
exec mkdocs serve --dev-addr=0.0.0.0:8000
