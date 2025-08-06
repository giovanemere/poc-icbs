#!/bin/bash

echo "🔄 Aplicando configuración HAProxy + MkDocs..."

# Verificar que existe la nueva configuración
if [ ! -f "haproxy/haproxy-mkdocs.cfg" ]; then
    echo "❌ haproxy/haproxy-mkdocs.cfg no encontrado"
    exit 1
fi

# Backup configuración actual
cp haproxy/haproxy.cfg haproxy/haproxy.cfg.backup.$(date +%Y%m%d_%H%M%S)

# Aplicar nueva configuración
cp haproxy/haproxy-mkdocs.cfg haproxy/haproxy.cfg

echo "✅ Configuración aplicada"
echo "💡 Ejecuta 'docker-compose restart haproxy-lb' para aplicar cambios"
