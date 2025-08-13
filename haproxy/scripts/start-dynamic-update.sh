#!/bin/bash
# Script para iniciar el servicio de actualización dinámica de HAProxy

# Verificar si socat está instalado
if ! command -v socat &> /dev/null; then
    echo "Instalando socat..."
    apt-get update && apt-get install -y socat
fi

# Verificar si el script existe
if [ ! -f /scripts/dynamic-update.sh ]; then
    echo "ERROR: No se encontró el script dynamic-update.sh"
    exit 1
fi

# Dar permisos de ejecución
chmod +x /scripts/dynamic-update.sh

# Iniciar el script en segundo plano
echo "Iniciando servicio de actualización dinámica de HAProxy..."
nohup /scripts/dynamic-update.sh > /var/log/dynamic-update.log 2>&1 &

echo "Servicio iniciado con PID $!"
