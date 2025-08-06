#!/bin/bash

# Script para iniciar HAProxy con puerto dinámico
# Encuentra automáticamente un puerto libre y actualiza la configuración

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Iniciando HAProxy Load Balancer con puerto dinámico..."
echo ""

# Verificar si HAProxy está corriendo
if docker ps | grep -q "haproxy"; then
    echo "⚠️  HAProxy ya está corriendo. Deteniéndolo primero..."
    docker-compose -f "$PROJECT_DIR/config/docker-compose.yml" stop haproxy
    echo "✅ HAProxy detenido"
    echo ""
fi

# Actualizar puerto dinámicamente
echo "🔧 Configurando puerto dinámico..."
"$SCRIPT_DIR/update-haproxy-port.sh" auto

echo ""
echo "🐳 Iniciando HAProxy con la nueva configuración..."

# Cambiar al directorio del proyecto para docker-compose
cd "$PROJECT_DIR"

# Iniciar HAProxy
docker-compose -f config/docker-compose.yml up -d haproxy

echo ""
echo "⏳ Esperando que HAProxy esté listo..."
sleep 5

# Obtener el puerto configurado
PUERTO=$(grep -E '^\s*-\s*"[0-9]+:80"' config/docker-compose.yml | sed 's/.*"\([0-9]*\):80".*/\1/' | head -1)

# Verificar que HAProxy está corriendo
if docker ps | grep -q "haproxy"; then
    echo "✅ HAProxy Load Balancer iniciado exitosamente!"
    echo ""
    echo "🔗 URLs de acceso:"
    echo "   • Load Balancer:    http://localhost:$PUERTO"
    echo "   • HAProxy Stats:    http://localhost:8404/stats"
    echo "   • HAProxy Admin UI: http://localhost:8082"
    echo "   • HAProxy Admin API: http://localhost:8081"
    echo ""
    echo "📊 Estado del contenedor:"
    docker ps --filter "name=haproxy" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "❌ Error: HAProxy no se pudo iniciar correctamente"
    echo ""
    echo "📋 Logs del contenedor:"
    docker logs haproxy --tail 20
    exit 1
fi
