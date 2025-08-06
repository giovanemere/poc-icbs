#!/bin/bash

# Script de limpieza del proyecto

echo "🧹 Limpiando proyecto..."

# Limpiar contenedores
echo "Deteniendo contenedores..."
docker-compose down

# Limpiar imágenes no utilizadas
echo "Limpiando imágenes Docker..."
docker image prune -f

# Limpiar logs antiguos
echo "Limpiando logs antiguos..."
find logs/ -name "*.log" -mtime +7 -delete 2>/dev/null || true

# Limpiar archivos temporales
echo "Limpiando archivos temporales..."
find . -name "*.tmp" -delete 2>/dev/null || true
find . -name "*.bak" -delete 2>/dev/null || true

# Limpiar target de Maven
echo "Limpiando builds de Maven..."
find . -name "target" -type d -exec rm -rf {} + 2>/dev/null || true

echo "✅ Limpieza completada"
