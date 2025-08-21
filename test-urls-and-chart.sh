#!/bin/bash

# Script para probar específicamente URLs y Gráfico

echo "🧪 PRUEBA ESPECÍFICA - URLs y Gráfico"
echo "====================================="
echo

echo "1. Verificando Dashboard accesible:"
if curl -s http://localhost:8085/unified-dashboard.html | head -1 | grep -q "DOCTYPE"; then
    echo "✅ Dashboard accesible"
else
    echo "❌ Dashboard NO accesible"
    exit 1
fi

echo
echo "2. Verificando Chart.js:"
DASHBOARD_HTML=$(curl -s http://localhost:8085/unified-dashboard.html)
if echo "$DASHBOARD_HTML" | grep -q "chart.min.js"; then
    echo "✅ Chart.js incluido (versión específica)"
else
    echo "⚠️ Chart.js puede no estar cargando correctamente"
fi

echo
echo "3. Verificando elementos HTML críticos:"
echo "   Elementos de tráfico:"
for element in "traffic-version-a" "traffic-version-b" "traffic-weblogic-a" "traffic-weblogic-b" "traffic-feature-flags"; do
    if echo "$DASHBOARD_HTML" | grep -q "id=\"$element\""; then
        echo "   ✅ $element presente"
    else
        echo "   ❌ $element FALTANTE"
    fi
done

echo
echo "   Elementos de URL cards:"
for element in "url-version-a" "url-version-b" "url-weblogic-a" "url-weblogic-b" "url-feature-flags"; do
    if echo "$DASHBOARD_HTML" | grep -q "id=\"$element\""; then
        echo "   ✅ $element presente"
    else
        echo "   ❌ $element FALTANTE"
    fi
done

echo
echo "4. Probando cambios de configuración para ver respuesta:"

echo "   4.1. Estado inicial (reset):"
RESET_RESPONSE=$(curl -s http://localhost:8084/api/reset -X POST)
echo "   Reset: $(echo "$RESET_RESPONSE" | jq -r '.message // "OK"' 2>/dev/null || echo "$RESET_RESPONSE")"

sleep 1

echo "   4.2. Activando A/B Testing 30/70:"
AB_30_RESPONSE=$(curl -s http://localhost:8084/api/ab/apply -X POST -H "Content-Type: application/json" -d '{"percentage_a": 30, "percentage_b": 70, "enabled": true}')
echo "   A/B 30/70: $(echo "$AB_30_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null || echo "$AB_30_RESPONSE")"

sleep 1

echo "   4.3. Verificando estado A/B:"
STATS_AB=$(curl -s http://localhost:8084/api/stats)
AB_ENABLED=$(echo "$STATS_AB" | jq -r '.deployment.ab_testing.enabled // false' 2>/dev/null || echo "N/A")
AB_PERCENT_A=$(echo "$STATS_AB" | jq -r '.deployment.ab_testing.percentage_a // "N/A"' 2>/dev/null || echo "N/A")
AB_PERCENT_B=$(echo "$STATS_AB" | jq -r '.deployment.ab_testing.percentage_b // "N/A"' 2>/dev/null || echo "N/A")
echo "   Estado A/B: Habilitado=$AB_ENABLED, A=$AB_PERCENT_A%, B=$AB_PERCENT_B%"

echo "   4.4. Activando Canary 25%:"
CANARY_25_RESPONSE=$(curl -s http://localhost:8084/api/canary/apply -X POST -H "Content-Type: application/json" -d '{"percentage": 25, "enabled": true}')
echo "   Canary 25%: $(echo "$CANARY_25_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null || echo "$CANARY_25_RESPONSE")"

sleep 1

echo "   4.5. Verificando estado Canary:"
STATS_CANARY=$(curl -s http://localhost:8084/api/stats)
CANARY_ENABLED=$(echo "$STATS_CANARY" | jq -r '.deployment.canary.enabled // false' 2>/dev/null || echo "N/A")
CANARY_PERCENT=$(echo "$STATS_CANARY" | jq -r '.deployment.canary.percentage // "N/A"' 2>/dev/null || echo "N/A")
echo "   Estado Canary: Habilitado=$CANARY_ENABLED, Porcentaje=$CANARY_PERCENT%"

echo
echo "5. Probando extremos (0% y 100%):"

echo "   5.1. A/B Testing 0/100:"
AB_100_RESPONSE=$(curl -s http://localhost:8084/api/ab/apply -X POST -H "Content-Type: application/json" -d '{"percentage_a": 0, "percentage_b": 100, "enabled": true}')
echo "   A/B 0/100: $(echo "$AB_100_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null || echo "$AB_100_RESPONSE")"

echo "   5.2. Canary 100%:"
CANARY_100_RESPONSE=$(curl -s http://localhost:8084/api/canary/apply -X POST -H "Content-Type: application/json" -d '{"percentage": 100, "enabled": true}')
echo "   Canary 100%: $(echo "$CANARY_100_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null || echo "$CANARY_100_RESPONSE")"

echo
echo "6. Reset final:"
FINAL_RESET=$(curl -s http://localhost:8084/api/reset -X POST)
echo "   Reset: $(echo "$FINAL_RESET" | jq -r '.message // "OK"' 2>/dev/null || echo "$FINAL_RESET")"

echo
echo "🎛️ Dashboard: http://localhost:8085/unified-dashboard.html"
echo
echo "📋 PRUEBAS MANUALES CRÍTICAS:"
echo "============================"
echo
echo "🔗 PARA PROBAR URLs ACTIVAS:"
echo "   1. Abre el dashboard"
echo "   2. Observa la sección '🔗 URLs Activas del Sistema'"
echo "   3. Estado inicial esperado:"
echo "      🟢 version-a: 100% (verde)"
echo "      🔴 version-b: 0% (roja)"
echo "      🟢 weblogic-a: 100% (verde)"
echo "      🔴 weblogic-b: 0% (roja)"
echo "      🟢 feature-flags: 100% (verde)"
echo
echo "   4. Activa 'A/B Testing' y mueve el slider:"
echo "      • Al 30%: version-a amarilla (30%), version-b amarilla (70%)"
echo "      • Al 0%: version-a roja (0%), version-b verde (100%)"
echo "      • Al 100%: version-a verde (100%), version-b roja (0%)"
echo
echo "   5. Activa 'Canary Deployment' y mueve el slider:"
echo "      • Al 25%: weblogic-a amarilla (75%), weblogic-b amarilla (25%)"
echo "      • Al 0%: weblogic-a verde (100%), weblogic-b roja (0%)"
echo "      • Al 100%: weblogic-a roja (0%), weblogic-b verde (100%)"
echo
echo "📊 PARA PROBAR GRÁFICO:"
echo "   1. Observa la sección '📊 Distribución de Tráfico en Tiempo Real'"
echo "   2. Debe mostrar un gráfico de dona con 4 segmentos"
echo "   3. Al mover sliders, el gráfico debe cambiar INMEDIATAMENTE"
echo "   4. Los porcentajes en las etiquetas deben actualizarse"
echo "   5. Los colores deben cambiar según el estado"
echo
echo "🔍 SI NO FUNCIONA:"
echo "   1. Abre F12 > Console"
echo "   2. Busca errores en rojo"
echo "   3. Busca logs que empiecen con 🎯, 📊, 🎨"
echo "   4. Ejecuta manualmente: updateTrafficPercentages()"
echo "   5. Ejecuta manualmente: updateChartWithCurrentData()"
