#!/bin/bash
set -e

echo "🚀 Iniciando HAProxy Advanced..."
echo "📦 Docker Hub: edissonz8809/haproxy-advanced"

# Crear directorios necesarios
mkdir -p /run/haproxy

# Verificar configuración
echo "🔍 Verificando configuración..."
if haproxy -f /etc/haproxy/haproxy.cfg -c; then
    echo "✅ Configuración válida"
else
    echo "❌ Error en configuración"
    exit 1
fi

echo "🌐 Puertos disponibles:"
echo "  • Load Balancer: 8083"
echo "  • Stats: 8404/stats"
echo "  • Admin: 8082/"
echo "  • API: 8081/api"

# Iniciar HAProxy
echo "🎯 Iniciando HAProxy..."
exec haproxy -f /etc/haproxy/haproxy.cfg
