#!/bin/bash
# Script de inicio para HAProxy con soporte para A/B testing y Canary deployment

# Crear directorios necesarios
mkdir -p /var/run /etc/haproxy/scripts /etc/haproxy/templates /etc/haproxy/static

# Copiar scripts
cp /scripts/dynamic_routing.lua /etc/haproxy/scripts/
cp /scripts/admin_api.py /etc/haproxy/scripts/
cp /scripts/admin_ui.py /etc/haproxy/scripts/
cp -r /scripts/templates /etc/haproxy/
cp -r /scripts/static /etc/haproxy/

# Dar permisos de ejecución
chmod +x /etc/haproxy/scripts/admin_api.py
chmod +x /etc/haproxy/scripts/admin_ui.py

# Instalar dependencias de Python si no están instaladas
if ! python3 -c "import flask" &> /dev/null; then
    echo "Instalando Flask..."
    apt-get update && apt-get install -y python3-flask
fi

# Iniciar la API de administración en segundo plano
echo "Iniciando API de administración..."
python3 /etc/haproxy/scripts/admin_api.py &

# Iniciar la interfaz web en segundo plano
echo "Iniciando interfaz web de administración..."
python3 /etc/haproxy/scripts/admin_ui.py &

# Esperar a que los servicios estén listos
sleep 2

echo "Iniciando HAProxy..."
# Iniciar HAProxy en primer plano
haproxy -f /usr/local/etc/haproxy/haproxy.cfg -db
