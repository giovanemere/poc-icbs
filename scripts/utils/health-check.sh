#!/bin/bash

# Script de verificación de salud del sistema

echo "🏥 Verificando salud del sistema..."

# Verificar Docker
if ! docker --version > /dev/null 2>&1; then
    echo "❌ Docker no está instalado o no funciona"
    exit 1
fi

# Verificar Docker Compose
if ! docker-compose --version > /dev/null 2>&1; then
    echo "❌ Docker Compose no está instalado"
    exit 1
fi

# Verificar servicios
echo "📊 Estado de servicios:"
docker-compose ps

# Verificar conectividad
echo "🌐 Verificando conectividad:"

# Obtener puerto dinámico de HAProxy
HAPROXY_PORT=$(grep -E '^\s*-\s*"[0-9]+:80"' ../../config/docker-compose.yml | sed 's/.*"\([0-9]*\):80".*/\1/' 2>/dev/null || echo "8083")

services=("localhost:$HAPROXY_PORT" "localhost:7001" "localhost:7002" "localhost:8404" "localhost:8081" "localhost:8082")
for service in "${services[@]}"; do
    if timeout 5 bash -c "</dev/tcp/${service/:/ }" 2>/dev/null; then
        echo "✅ $service - OK"
    else
        echo "❌ $service - FAIL"
    fi
done

# Verificar uso de recursos
echo "💾 Uso de recursos:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo "✅ Verificación completada"
