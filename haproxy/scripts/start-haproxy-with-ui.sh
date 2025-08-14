#!/bin/bash

# Script de inicio que combina HAProxy con la interfaz profesional
set -e

echo "🚀 Iniciando HAProxy con Interfaz Profesional..."

# Función para limpiar procesos al salir
cleanup() {
    echo "🛑 Deteniendo servicios..."
    if [ -f /tmp/professional-ui.pid ]; then
        kill $(cat /tmp/professional-ui.pid) 2>/dev/null || true
        rm -f /tmp/professional-ui.pid
    fi
    exit 0
}

trap cleanup SIGTERM SIGINT

# Verificar configuración de HAProxy
echo "🔍 Verificando configuración de HAProxy..."
haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg

# Iniciar interfaz profesional en background
echo "🎨 Iniciando interfaz profesional..."
/scripts/start-professional-ui.sh &

# Esperar un momento para que Flask se inicie
sleep 5

# Iniciar HAProxy
echo "⚡ Iniciando HAProxy..."
exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg -D

# Mantener el contenedor corriendo
while true; do
    sleep 30
    # Verificar que HAProxy sigue corriendo
    if ! pgrep haproxy > /dev/null; then
        echo "❌ HAProxy se detuvo, reiniciando..."
        haproxy -f /usr/local/etc/haproxy/haproxy.cfg -D
    fi
    
    # Verificar que la UI profesional sigue corriendo
    if [ -f /tmp/professional-ui.pid ] && ! kill -0 $(cat /tmp/professional-ui.pid) 2>/dev/null; then
        echo "❌ UI Profesional se detuvo, reiniciando..."
        /scripts/start-professional-ui.sh &
    fi
done
