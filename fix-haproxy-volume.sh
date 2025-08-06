#!/bin/bash
# Script para corregir el problema de volúmenes de HAProxy

echo "=== CORRIGIENDO PROBLEMA DE HAPROXY ==="

# Detener HAProxy
echo "1. Deteniendo HAProxy..."
docker-compose stop haproxy

# El problema es que el volumen está sobrescribiendo los archivos del Dockerfile
# Vamos a modificar el docker-compose para no montar el volumen de scripts
echo "2. Creando backup del docker-compose..."
cp config/docker-compose.yml config/docker-compose.yml.backup

# Comentar la línea del volumen de scripts
echo "3. Modificando docker-compose para no montar volumen de scripts..."
sed -i 's/- ..\/haproxy\/scripts:\/scripts:z/# - ..\/haproxy\/scripts:\/scripts:z/' config/docker-compose.yml

echo "4. Reconstruyendo HAProxy..."
docker-compose build --no-cache haproxy

echo "5. Iniciando HAProxy..."
docker-compose up -d haproxy

echo "=== CORRECCIÓN COMPLETADA ==="
