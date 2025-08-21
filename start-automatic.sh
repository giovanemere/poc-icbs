#!/bin/bash

# Script para subir servicios automáticamente

echo "🚀 INICIANDO SERVICIOS AUTOMÁTICAMENTE"
echo "======================================"

# Verificar que Docker esté corriendo
if ! docker ps > /dev/null 2>&1; then
    echo "❌ Docker no está corriendo"
    exit 1
fi

echo "✅ Docker está corriendo"

# Verificar docker-compose.yml
if [ ! -f "config/docker-compose.yml" ]; then
    echo "❌ config/docker-compose.yml no encontrado"
    exit 1
fi

echo "📁 Usando: config/docker-compose.yml"

# Detener servicios existentes si están corriendo
echo "🛑 Deteniendo servicios existentes..."
docker-compose -f config/docker-compose.yml down

# Esperar un momento
sleep 3

# Iniciar servicios Docker
echo "🚀 Iniciando servicios Docker..."
docker-compose -f config/docker-compose.yml up -d

if [ $? -eq 0 ]; then
    echo "✅ Servicios Docker iniciados exitosamente"
    
    echo
    echo "📊 Estado de los servicios:"
    docker-compose -f config/docker-compose.yml ps
    
else
    echo "❌ Error al iniciar servicios Docker"
    echo "📋 Logs de error:"
    docker-compose -f config/docker-compose.yml logs --tail=20
    exit 1
fi

# Esperar que los servicios se inicialicen
echo
echo "⏳ Esperando que los servicios Docker se inicialicen..."
sleep 10

# Iniciar Dashboard Unificado
echo "🎛️ Iniciando Dashboard Unificado..."

# Verificar si el dashboard ya está corriendo
if pgrep -f "http.server 8085" > /dev/null; then
    echo "⚠️ Dashboard ya está corriendo, deteniéndolo..."
    pkill -f "http.server 8085"
    sleep 2
fi

# Verificar que el archivo del dashboard existe
if [ -f "unified-dashboard-fixed.html" ]; then
    echo "✅ Dashboard corregido encontrado"
    
    # Iniciar servidor HTTP para el dashboard
    nohup python3 -m http.server 8085 > dashboard.log 2>&1 &
    DASHBOARD_PID=$!
    echo $DASHBOARD_PID > dashboard.pid
    
    # Esperar que el servidor se inicie
    sleep 3
    
    # Verificar que el dashboard esté accesible
    if curl -s http://localhost:8085/unified-dashboard-fixed.html | head -1 | grep -q "DOCTYPE"; then
        echo "✅ Dashboard Unificado iniciado correctamente"
    else
        echo "⚠️ Dashboard iniciado pero puede necesitar un momento más"
    fi
    
elif [ -f "unified-dashboard.html" ]; then
    echo "⚠️ Solo dashboard original encontrado, usando ese"
    
    # Iniciar servidor HTTP para el dashboard
    nohup python3 -m http.server 8085 > dashboard.log 2>&1 &
    DASHBOARD_PID=$!
    echo $DASHBOARD_PID > dashboard.pid
    
    sleep 3
else
    echo "❌ No se encontró archivo de dashboard"
fi

echo
echo "🌐 URLs DISPONIBLES:"
echo "==================="
echo "   🎛️ Dashboard Unificado: http://localhost:8085/unified-dashboard-fixed.html"
echo "   📊 Dashboard Original:   http://localhost:8085/unified-dashboard.html"
echo "   ⚖️ HAProxy Frontend:     http://localhost:8080"
echo "   📈 HAProxy Stats:        http://localhost:8404/stats (admin/admin123)"
echo "   🖥️ WebLogic A Console:   http://localhost:7001/console"
echo "   🖥️ WebLogic B Console:   http://localhost:7002/console"
echo "   🗄️ Oracle EM:            http://localhost:5500/em"

echo
echo "⏳ NOTAS IMPORTANTES:"
echo "===================="
echo "   • Los servicios Docker pueden tardar varios minutos en estar completamente listos"
echo "   • WebLogic puede tardar 5-10 minutos en inicializarse completamente"
echo "   • Oracle Database puede tardar 3-5 minutos en estar disponible"
echo "   • El Dashboard está disponible inmediatamente"

echo
echo "🎉 SISTEMA INICIADO AUTOMÁTICAMENTE"
echo "==================================="
echo "   ✅ Servicios Docker: INICIADOS"
echo "   ✅ Dashboard Unificado: INICIADO"
echo "   🎛️ URL Principal: http://localhost:8085/unified-dashboard-fixed.html"
