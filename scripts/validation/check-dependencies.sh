#!/bin/bash
# Script para verificar dependencias de Python necesarias para admin_ui.py

echo "🔍 Verificando dependencias de Python..."

# Verificar si python-dotenv está instalado
if python3 -c "import dotenv" 2>/dev/null; then
    echo "✅ python-dotenv está instalado"
else
    echo "❌ python-dotenv NO está instalado"
    echo "📦 Instalando python-dotenv..."
    pip3 install python-dotenv
    if [ $? -eq 0 ]; then
        echo "✅ python-dotenv instalado correctamente"
    else
        echo "❌ Error al instalar python-dotenv"
        exit 1
    fi
fi

# Verificar otras dependencias
dependencies=("flask" "requests")

for dep in "${dependencies[@]}"; do
    if python3 -c "import $dep" 2>/dev/null; then
        echo "✅ $dep está instalado"
    else
        echo "❌ $dep NO está instalado"
        echo "📦 Instalando $dep..."
        pip3 install $dep
        if [ $? -eq 0 ]; then
            echo "✅ $dep instalado correctamente"
        else
            echo "❌ Error al instalar $dep"
            exit 1
        fi
    fi
done

echo "🎉 Todas las dependencias están instaladas correctamente"
