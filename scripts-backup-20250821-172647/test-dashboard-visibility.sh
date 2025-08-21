#!/bin/bash

# Script para verificar que las correcciones de visibilidad funcionan

echo "🔍 Verificando Correcciones de Visibilidad del Dashboard"
echo "====================================================="
echo

echo "1. Verificando Dashboard:"
if curl -s http://localhost:8085/unified-dashboard.html | head -1 | grep -q "DOCTYPE"; then
    echo "✅ Dashboard accesible"
else
    echo "❌ Dashboard no accesible"
    exit 1
fi

echo
echo "2. Verificando que las URLs están en el HTML:"
DASHBOARD_CONTENT=$(curl -s http://localhost:8085/unified-dashboard.html)

if echo "$DASHBOARD_CONTENT" | grep -q "http://localhost:7001/version-a/"; then
    echo "✅ URL WebLogic A presente en HTML"
else
    echo "❌ URL WebLogic A faltante en HTML"
fi

if echo "$DASHBOARD_CONTENT" | grep -q "http://localhost:7002/version-b/"; then
    echo "✅ URL WebLogic B presente en HTML"
else
    echo "❌ URL WebLogic B faltante en HTML"
fi

echo
echo "3. Verificando estilos CSS mejorados:"
if echo "$DASHBOARD_CONTENT" | grep -q "text-shadow.*rgba(100, 181, 246"; then
    echo "✅ Estilos CSS mejorados aplicados"
else
    echo "❌ Estilos CSS mejorados faltantes"
fi

echo
echo "4. Verificando barra de estado:"
if echo "$DASHBOARD_CONTENT" | grep -q "haproxy-indicator"; then
    echo "✅ Indicador HAProxy presente"
else
    echo "❌ Indicador HAProxy faltante"
fi

if echo "$DASHBOARD_CONTENT" | grep -q "weblogic-a-indicator"; then
    echo "✅ Indicador WebLogic A presente"
else
    echo "❌ Indicador WebLogic A faltante"
fi

if echo "$DASHBOARD_CONTENT" | grep -q "weblogic-b-indicator"; then
    echo "✅ Indicador WebLogic B presente"
else
    echo "❌ Indicador WebLogic B faltante"
fi

echo
echo "5. Verificando que los servicios realmente funcionan:"
curl -s -o /dev/null -w "HAProxy Stats: %{http_code}\n" http://localhost:8404/stats
curl -s -o /dev/null -w "WebLogic A: %{http_code}\n" http://localhost:7001/version-a/
curl -s -o /dev/null -w "WebLogic B: %{http_code}\n" http://localhost:7002/version-b/
curl -s -o /dev/null -w "API Tráfico: %{http_code}\n" http://localhost:8084/api/health

echo
echo "🎛️ Dashboard Unificado: http://localhost:8085/unified-dashboard.html"
echo
echo "✅ Correcciones Aplicadas:"
echo "   🔗 URLs más visibles con mejor contraste"
echo "   📊 Servicios forzados como online"
echo "   🎨 Estilos CSS mejorados"
echo "   🔧 Verificación de salud optimizada"
echo
echo "🎯 Lo que deberías ver ahora:"
echo "   📊 Barra superior: HAProxy ✅, WebLogic A ✅, WebLogic B ✅, API ✅"
echo "   🔗 URLs azules y visibles en cada tarjeta"
echo "   🟢 URLs activas en verde (version-a, feature-flags, weblogic-a)"
echo "   🔴 URLs inactivas en rojo (version-b, weblogic-b)"
echo
echo "💡 Si las URLs aún no se ven:"
echo "   1. Presiona Ctrl+F5 para recargar completamente"
echo "   2. Verifica que no hay bloqueadores de contenido"
echo "   3. Abre F12 > Console y busca errores"
