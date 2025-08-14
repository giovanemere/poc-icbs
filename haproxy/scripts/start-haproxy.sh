#!/bin/bash
# Script de inicio para HAProxy con soporte para A/B testing y Canary deployment

echo "=== Iniciando HAProxy ==="
echo "Configuración: /usr/local/etc/haproxy/haproxy.cfg"
echo "Stats disponibles en: http://localhost:8404/stats"

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

# Verificar si Python3 está disponible
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "Advertencia: Python no está disponible. Instalando..."
    apt-get update && apt-get install -y python3 python3-flask
    PYTHON_CMD="python3"
fi

# Iniciar la API de administración en segundo plano
echo "Iniciando API de administración en puerto 8081..."
$PYTHON_CMD /etc/haproxy/scripts/admin_api.py &

# Iniciar la interfaz web en segundo plano
echo "Iniciando interfaz web de administración en puerto 8082..."
$PYTHON_CMD /etc/haproxy/scripts/admin_ui.py &

# Iniciar el servidor del dashboard profesional si existe
if [ -f "/dashboard/serve-dashboard.py" ]; then
    echo "Iniciando servidor del dashboard profesional en puerto 8000..."
    chmod +x /dashboard/serve-dashboard.py
    cd /dashboard && $PYTHON_CMD serve-dashboard.py &
    echo "Dashboard profesional disponible en: http://localhost:8000/"
elif [ -f "/dashboard/api/server.py" ]; then
    echo "Iniciando servidor del dashboard básico en puerto 8000..."
    cd /dashboard && $PYTHON_CMD api/server.py &
    echo "Dashboard básico disponible en: http://localhost:8000/"
else
    echo "Advertencia: No se encontró servidor del dashboard"
fi

# Esperar a que los servicios estén listos
sleep 3

echo "Iniciando HAProxy..."
# Iniciar HAProxy en primer plano
haproxy -f /usr/local/etc/haproxy/haproxy.cfg -db
