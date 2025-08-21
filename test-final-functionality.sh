#!/bin/bash

# Script de prueba final para URLs y Gráfico

echo "🧪 PRUEBA FINAL - URLs Activas y Gráfico"
echo "========================================"
echo

echo "1. Verificando Dashboard:"
if curl -s http://localhost:8085/unified-dashboard.html | head -1 | grep -q "DOCTYPE"; then
    echo "✅ Dashboard accesible"
else
    echo "❌ Dashboard NO accesible"
    exit 1
fi

echo
echo "2. Verificando elementos HTML críticos:"
DASHBOARD_HTML=$(curl -s http://localhost:8085/unified-dashboard.html)

# Verificar elementos críticos
ELEMENTS_OK=0
ELEMENTS_TOTAL=0

for element in "traffic-version-a" "traffic-version-b" "traffic-weblogic-a" "traffic-weblogic-b" "url-version-a" "url-version-b" "url-weblogic-a" "url-weblogic-b" "trafficChart"; do
    ELEMENTS_TOTAL=$((ELEMENTS_TOTAL + 1))
    if echo "$DASHBOARD_HTML" | grep -q "id=\"$element\""; then
        echo "   ✅ $element"
        ELEMENTS_OK=$((ELEMENTS_OK + 1))
    else
        echo "   ❌ $element FALTANTE"
    fi
done

echo "   Elementos: $ELEMENTS_OK/$ELEMENTS_TOTAL OK"

echo
echo "3. Verificando funciones JavaScript críticas:"
FUNCTIONS_OK=0
FUNCTIONS_TOTAL=0

for func in "updateTrafficPercentages" "updateChartWithCurrentData" "testURLsAndChart"; do
    FUNCTIONS_TOTAL=$((FUNCTIONS_TOTAL + 1))
    if echo "$DASHBOARD_HTML" | grep -q "function $func"; then
        echo "   ✅ $func presente"
        FUNCTIONS_OK=$((FUNCTIONS_OK + 1))
    else
        echo "   ❌ $func FALTANTE"
    fi
done

echo "   Funciones: $FUNCTIONS_OK/$FUNCTIONS_TOTAL OK"

echo
echo "4. Verificando Chart.js:"
if echo "$DASHBOARD_HTML" | grep -q "chart.min.js"; then
    echo "   ✅ Chart.js incluido"
else
    echo "   ❌ Chart.js NO incluido"
fi

echo
echo "5. Probando APIs para verificar backend:"
echo "   Reseteando configuración..."
RESET_RESPONSE=$(curl -s http://localhost:8084/api/reset -X POST)
echo "   Reset: $(echo "$RESET_RESPONSE" | jq -r '.message // "OK"' 2>/dev/null || echo "$RESET_RESPONSE")"

echo
echo "🎛️ Dashboard: http://localhost:8085/unified-dashboard.html"
echo
echo "📋 RESUMEN DE ESTADO:"
echo "===================="
if [ $ELEMENTS_OK -eq $ELEMENTS_TOTAL ] && [ $FUNCTIONS_OK -eq $FUNCTIONS_TOTAL ]; then
    echo "✅ TODOS LOS ELEMENTOS Y FUNCIONES PRESENTES"
    echo
    echo "🧪 PRUEBAS MANUALES REQUERIDAS:"
    echo "==============================="
    echo
    echo "🔗 PARA PROBAR URLs ACTIVAS DEL SISTEMA:"
    echo "   1. Abre: http://localhost:8085/unified-dashboard.html"
    echo "   2. Busca la sección '🔗 URLs Activas del Sistema'"
    echo "   3. Estado inicial esperado:"
    echo "      🟢 version-a: 100% (tarjeta verde)"
    echo "      🔴 version-b: 0% (tarjeta roja)"
    echo "      🟢 weblogic-a: 100% (tarjeta verde)"
    echo "      🔴 weblogic-b: 0% (tarjeta roja)"
    echo "      🟢 feature-flags: 100% (tarjeta verde)"
    echo
    echo "   4. Activa el toggle 'A/B Testing'"
    echo "   5. Mueve el slider A/B y observa:"
    echo "      • Los porcentajes deben cambiar INMEDIATAMENTE"
    echo "      • Los colores de las tarjetas deben cambiar:"
    echo "        - 100% = Verde"
    echo "        - 0% = Roja"
    echo "        - 1-99% = Amarilla"
    echo
    echo "   6. Activa el toggle 'Canary Deployment'"
    echo "   7. Mueve el slider Canary y observa:"
    echo "      • weblogic-a y weblogic-b deben cambiar colores"
    echo "      • Los porcentajes deben actualizarse"
    echo
    echo "📊 PARA PROBAR DISTRIBUCIÓN DE TRÁFICO EN TIEMPO REAL:"
    echo "   1. Busca la sección '📊 Distribución de Tráfico en Tiempo Real'"
    echo "   2. Debe mostrar un gráfico de dona con 4 segmentos"
    echo "   3. Al mover los sliders, el gráfico debe:"
    echo "      • Cambiar INMEDIATAMENTE (sin delay)"
    echo "      • Actualizar los porcentajes en las etiquetas"
    echo "      • Cambiar los colores de los segmentos"
    echo
    echo "🔍 DEBUGGING EN CONSOLE:"
    echo "   1. Abre F12 > Console"
    echo "   2. Ejecuta: testURLsAndChart()"
    echo "   3. Deberías ver logs detallados y cambios visuales"
    echo "   4. Ejecuta: updateTrafficPercentages()"
    echo "   5. Ejecuta: updateChartWithCurrentData()"
    echo
    echo "✅ SI TODO FUNCIONA CORRECTAMENTE:"
    echo "   • URLs cambian color inmediatamente al mover sliders"
    echo "   • Gráfico se actualiza en tiempo real"
    echo "   • No hay errores en la console"
    echo "   • Los porcentajes se muestran correctamente"
else
    echo "❌ FALTAN ELEMENTOS O FUNCIONES CRÍTICAS"
    echo "   Elementos faltantes: $((ELEMENTS_TOTAL - ELEMENTS_OK))"
    echo "   Funciones faltantes: $((FUNCTIONS_TOTAL - FUNCTIONS_OK))"
    echo
    echo "🔧 NECESITA CORRECCIÓN ANTES DE PROBAR"
fi
