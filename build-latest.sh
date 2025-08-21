#!/bin/bash

# Script para construir imágenes Docker

echo "🐳 CONSTRUYENDO IMÁGENES DOCKER"
echo "==============================="

# Verificar que Docker esté corriendo
if ! docker ps > /dev/null 2>&1; then
    echo "❌ Docker no está corriendo"
    exit 1
fi

echo "✅ Docker está corriendo"

# Construir imágenes usando docker-compose
echo "🔨 Construyendo imágenes con docker-compose..."

if [ -f "config/docker-compose.yml" ]; then
    echo "📁 Usando: config/docker-compose.yml"
    
    # Build de las imágenes
    docker-compose -f config/docker-compose.yml build --no-cache
    
    if [ $? -eq 0 ]; then
        echo "✅ Imágenes construidas exitosamente"
        
        echo
        echo "📊 Imágenes disponibles:"
        docker images | grep -E "(weblogic|oracle|haproxy)" | head -10
        
    else
        echo "❌ Error al construir imágenes"
        exit 1
    fi
    
else
    echo "❌ config/docker-compose.yml no encontrado"
    exit 1
fi

echo
echo "🎉 Build de imágenes completado"
