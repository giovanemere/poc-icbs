#!/bin/bash
# Script de inicio mejorado para HAProxy con auto-instalación de dependencias

echo "🚀 === Iniciando HAProxy con Auto-instalación ==="

# Paso 1: Auto-instalar dependencias críticas
echo "📦 Instalando dependencias automáticamente..."
if [ -f "/scripts/auto-install-dependencies.sh" ]; then
    /scripts/auto-install-dependencies.sh
else
    echo "⚠️  Script de auto-instalación no encontrado, instalando manualmente..."
    
    # Instalar socat (crítico)
    if ! command -v socat >/dev/null 2>&1; then
        echo "📦 Instalando socat..."
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update -qq
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq socat
        elif command -v apk >/dev/null 2>&1; then
            apk add --no-cache socat
        fi
    fi
    
    # Instalar python3 y dependencias
    if ! command -v python3 >/dev/null 2>&1; then
        echo "📦 Instalando Python3..."
        if command -v apt-get >/dev/null 2>&1; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3 python3-pip python3-flask python3-requests
        elif command -v apk >/dev/null 2>&1; then
            apk add --no-cache python3 py3-pip py3-flask py3-requests
        fi
    fi
fi

echo "✅ Dependencias instaladas correctamente"

# Paso 2: Configuración original de HAProxy
echo "⚙️  Configurando HAProxy..."
echo "Configuración: /usr/local/etc/haproxy/haproxy.cfg"
echo "Stats disponibles en: http://localhost:8404/stats"

# Crear directorios necesarios
mkdir -p /var/run /etc/haproxy/scripts /etc/haproxy/templates /etc/haproxy/static

# Copiar scripts
cp /scripts/dynamic_routing.lua /etc/haproxy/scripts/ 2>/dev/null || echo "⚠️  dynamic_routing.lua no encontrado"
cp /scripts/admin_api.py /etc/haproxy/scripts/ 2>/dev/null || echo "⚠️  admin_api.py no encontrado"
cp /scripts/admin_ui.py /etc/haproxy/scripts/ 2>/dev/null || echo "⚠️  admin_ui.py no encontrado"
cp -r /scripts/templates /etc/haproxy/ 2>/dev/null || echo "⚠️  templates no encontrados"
cp -r /scripts/static /etc/haproxy/ 2>/dev/null || echo "⚠️  static no encontrados"

# Dar permisos de ejecución
chmod +x /etc/haproxy/scripts/admin_api.py 2>/dev/null
chmod +x /etc/haproxy/scripts/admin_ui.py 2>/dev/null

# Paso 3: Verificar Python y determinar comando
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "❌ Error: Python no está disponible después de la instalación"
    exit 1
fi

echo "🐍 Usando Python: $PYTHON_CMD"

# Paso 4: Iniciar servicios de administración
echo "🌐 Iniciando servicios de administración..."

# Iniciar la API de administración en segundo plano
if [ -f "/etc/haproxy/scripts/admin_api.py" ]; then
    echo "📡 Iniciando API de administración en puerto 8081..."
    $PYTHON_CMD /etc/haproxy/scripts/admin_api.py &
    API_PID=$!
    echo "✅ API iniciada (PID: $API_PID)"
else
    echo "⚠️  admin_api.py no encontrado"
fi

# Iniciar la interfaz web en segundo plano
if [ -f "/etc/haproxy/scripts/admin_ui.py" ]; then
    echo "🖥️  Iniciando interfaz web de administración en puerto 8082..."
    $PYTHON_CMD /etc/haproxy/scripts/admin_ui.py &
    UI_PID=$!
    echo "✅ Interfaz web iniciada (PID: $UI_PID)"
else
    echo "⚠️  admin_ui.py no encontrado"
fi

# Paso 5: Iniciar dashboard si existe
echo "📊 Verificando dashboard..."
if [ -f "/dashboard/serve-dashboard.py" ]; then
    echo "🎯 Iniciando servidor del dashboard profesional en puerto 8000..."
    chmod +x /dashboard/serve-dashboard.py
    cd /dashboard && $PYTHON_CMD serve-dashboard.py &
    DASHBOARD_PID=$!
    echo "✅ Dashboard profesional disponible en: http://localhost:8000/ (PID: $DASHBOARD_PID)"
elif [ -f "/dashboard/api/server.py" ]; then
    echo "🎯 Iniciando servidor del dashboard básico en puerto 8000..."
    cd /dashboard && $PYTHON_CMD api/server.py &
    DASHBOARD_PID=$!
    echo "✅ Dashboard básico disponible en: http://localhost:8000/ (PID: $DASHBOARD_PID)"
else
    echo "⚠️  No se encontró servidor del dashboard"
fi

# Paso 6: Verificar que socat esté funcionando
echo "🔍 Verificando socat..."
if command -v socat >/dev/null 2>&1; then
    echo "✅ socat está disponible y funcionando"
else
    echo "❌ Error: socat no está disponible"
    exit 1
fi

# Paso 7: Esperar a que los servicios estén listos
echo "⏳ Esperando que los servicios estén listos..."
sleep 5

# Paso 8: Mostrar resumen de servicios
echo ""
echo "🎉 === HAProxy Completamente Inicializado ==="
echo "📊 Servicios disponibles:"
echo "   • HAProxy Stats: http://localhost:8404/stats"
echo "   • API Admin: http://localhost:8081/api"
echo "   • Panel Admin: http://localhost:8082"
echo "   • Dashboard: http://localhost:8000 (si está disponible)"
echo ""
echo "🔧 Dependencias instaladas:"
echo "   • socat: $(command -v socat >/dev/null 2>&1 && echo "✅ Disponible" || echo "❌ No disponible")"
echo "   • python3: $(command -v python3 >/dev/null 2>&1 && echo "✅ Disponible" || echo "❌ No disponible")"
echo "   • curl: $(command -v curl >/dev/null 2>&1 && echo "✅ Disponible" || echo "❌ No disponible")"
echo ""

# Paso 9: Iniciar HAProxy en primer plano
echo "🚀 Iniciando HAProxy en primer plano..."
exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg -db
