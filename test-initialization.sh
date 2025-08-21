#!/bin/bash

# Script para probar la inicialización del Dashboard

echo "🔍 PRUEBA DE INICIALIZACIÓN DEL DASHBOARD"
echo "========================================"
echo

echo "1. Verificando acceso básico:"
if curl -s http://localhost:8085/unified-dashboard.html | head -1 | grep -q "DOCTYPE"; then
    echo "✅ Dashboard accesible"
else
    echo "❌ Dashboard NO accesible"
    exit 1
fi

echo
echo "2. Verificando que no se quede en 'Verificando...':"
DASHBOARD_CONTENT=$(curl -s http://localhost:8085/unified-dashboard.html)

# Contar cuántas veces aparece "Verificando..."
VERIFICANDO_COUNT=$(echo "$DASHBOARD_CONTENT" | grep -o "Verificando..." | wc -l)
echo "   Instancias de 'Verificando...': $VERIFICANDO_COUNT"

if [ $VERIFICANDO_COUNT -gt 0 ]; then
    echo "⚠️ Aún hay texto 'Verificando...' en el HTML"
    echo "   Esto puede causar que se quede en estado de carga"
else
    echo "✅ No hay texto 'Verificando...' problemático"
fi

echo
echo "3. Verificando elementos críticos de inicialización:"

if echo "$DASHBOARD_CONTENT" | grep -q "forceInitialState"; then
    echo "✅ Función forceInitialState presente"
else
    echo "❌ Función forceInitialState faltante"
fi

if echo "$DASHBOARD_CONTENT" | grep -q "DOMContentLoaded"; then
    echo "✅ Event listener DOMContentLoaded presente"
else
    echo "❌ Event listener DOMContentLoaded faltante"
fi

if echo "$DASHBOARD_CONTENT" | grep -q "initializeChart"; then
    echo "✅ Función initializeChart presente"
else
    echo "❌ Función initializeChart faltante"
fi

echo
echo "4. Verificando que Chart.js esté incluido:"
if echo "$DASHBOARD_CONTENT" | grep -q "chart.js"; then
    echo "✅ Chart.js incluido"
else
    echo "❌ Chart.js NO incluido - Gráfico no funcionará"
fi

echo
echo "5. Verificando elementos HTML de estado:"
if echo "$DASHBOARD_CONTENT" | grep -q "haproxy-status"; then
    echo "✅ Elemento haproxy-status presente"
else
    echo "❌ Elemento haproxy-status faltante"
fi

if echo "$DASHBOARD_CONTENT" | grep -q "traffic-version-a"; then
    echo "✅ Elemento traffic-version-a presente"
else
    echo "❌ Elemento traffic-version-a faltante"
fi

echo
echo "6. Probando APIs backend:"
echo "   API Stats:"
STATS_RESPONSE=$(curl -s http://localhost:8084/api/stats)
if echo "$STATS_RESPONSE" | grep -q "deployment\|backends"; then
    echo "   ✅ API Stats funciona"
else
    echo "   ❌ API Stats no funciona"
    echo "   Respuesta: $STATS_RESPONSE"
fi

echo
echo "7. Verificando JavaScript sin errores de sintaxis:"
# Intentar extraer y verificar JavaScript básico
JS_ERRORS=$(echo "$DASHBOARD_CONTENT" | grep -i "error\|undefined\|null" | head -3)
if [ -n "$JS_ERRORS" ]; then
    echo "⚠️ Posibles errores en JavaScript:"
    echo "$JS_ERRORS"
else
    echo "✅ No se detectan errores obvios en JavaScript"
fi

echo
echo "🎛️ Dashboard: http://localhost:8085/unified-dashboard.html"
echo
echo "📋 INSTRUCCIONES PARA VERIFICAR MANUALMENTE:"
echo "==========================================="
echo
echo "1. Abre el Dashboard en tu navegador"
echo "2. Verifica que NO aparezca 'Verificando...' por más de 2 segundos"
echo "3. Verifica que las URLs aparezcan como 'Online' (no 'Offline')"
echo "4. Verifica que el gráfico se muestre correctamente"
echo "5. Abre F12 > Console y verifica que no haya errores en rojo"
echo
echo "🔍 LOGS ESPERADOS EN LA CONSOLA:"
echo "   🎛️ Dashboard Unificado cargando..."
echo "   🔧 Estableciendo estado inicial forzado..."
echo "   ✅ Estado inicial establecido"
echo "   ✅ Dashboard Unificado completamente cargado"
echo
echo "❌ SI AÚN HAY PROBLEMAS:"
echo "   1. Verifica que no haya errores JavaScript en F12 > Console"
echo "   2. Recarga la página con Ctrl+F5"
echo "   3. Ejecuta en la consola: forceInitialState()"
