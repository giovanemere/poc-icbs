#!/bin/bash

# Script para probar TODAS las funcionalidades del Dashboard

echo "🧪 PRUEBA COMPLETA DE TODAS LAS FUNCIONALIDADES"
echo "=============================================="
echo

echo "1. Verificando acceso al Dashboard:"
if curl -s http://localhost:8085/unified-dashboard.html | head -1 | grep -q "DOCTYPE"; then
    echo "✅ Dashboard accesible"
else
    echo "❌ Dashboard NO accesible - FALLO CRÍTICO"
    exit 1
fi

echo
echo "2. Verificando que Chart.js esté cargado:"
DASHBOARD_HTML=$(curl -s http://localhost:8085/unified-dashboard.html)
if echo "$DASHBOARD_HTML" | grep -q "chart.js"; then
    echo "✅ Chart.js incluido"
else
    echo "❌ Chart.js NO incluido - Gráfico no funcionará"
fi

echo
echo "3. Probando APIs paso a paso:"

echo "   3.1. Reseteando configuración inicial:"
RESET_RESPONSE=$(curl -s http://localhost:8084/api/reset -X POST)
echo "   Reset: $(echo "$RESET_RESPONSE" | jq -r '.message // "OK"' 2>/dev/null || echo "$RESET_RESPONSE")"

echo "   3.2. Probando A/B Testing 30/70:"
AB_30_RESPONSE=$(curl -s http://localhost:8084/api/ab/apply -X POST -H "Content-Type: application/json" -d '{"percentage_a": 30, "percentage_b": 70, "enabled": true}')
echo "   A/B 30/70: $(echo "$AB_30_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null)"

sleep 1

echo "   3.3. Verificando estado A/B:"
STATS_AB=$(curl -s http://localhost:8084/api/stats)
AB_ENABLED=$(echo "$STATS_AB" | jq -r '.deployment.ab_testing.enabled // false' 2>/dev/null)
AB_PERCENT_A=$(echo "$STATS_AB" | jq -r '.deployment.ab_testing.percentage_a // "N/A"' 2>/dev/null)
AB_PERCENT_B=$(echo "$STATS_AB" | jq -r '.deployment.ab_testing.percentage_b // "N/A"' 2>/dev/null)
echo "   Estado A/B: Habilitado=$AB_ENABLED, A=$AB_PERCENT_A%, B=$AB_PERCENT_B%"

echo "   3.4. Probando Canary 25%:"
CANARY_25_RESPONSE=$(curl -s http://localhost:8084/api/canary/apply -X POST -H "Content-Type: application/json" -d '{"percentage": 25, "enabled": true}')
echo "   Canary 25%: $(echo "$CANARY_25_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null)"

sleep 1

echo "   3.5. Verificando estado Canary:"
STATS_CANARY=$(curl -s http://localhost:8084/api/stats)
CANARY_ENABLED=$(echo "$STATS_CANARY" | jq -r '.deployment.canary.enabled // false' 2>/dev/null)
CANARY_PERCENT=$(echo "$STATS_CANARY" | jq -r '.deployment.canary.percentage // "N/A"' 2>/dev/null)
echo "   Estado Canary: Habilitado=$CANARY_ENABLED, Porcentaje=$CANARY_PERCENT%"

echo
echo "4. Probando extremos (0% y 100%):"

echo "   4.1. A/B Testing 0/100 (100% para B):"
AB_100_RESPONSE=$(curl -s http://localhost:8084/api/ab/apply -X POST -H "Content-Type: application/json" -d '{"percentage_a": 0, "percentage_b": 100, "enabled": true}')
echo "   A/B 0/100: $(echo "$AB_100_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null)"

echo "   4.2. Canary 100%:"
CANARY_100_RESPONSE=$(curl -s http://localhost:8084/api/canary/apply -X POST -H "Content-Type: application/json" -d '{"percentage": 100, "enabled": true}')
echo "   Canary 100%: $(echo "$CANARY_100_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null)"

echo
echo "5. Verificando URLs directamente:"
echo "   version-a:"
curl -s -o /dev/null -w "     Status: %{http_code}, Tiempo: %{time_total}s\n" http://localhost:8100/version-a/

echo "   version-b:"
curl -s -o /dev/null -w "     Status: %{http_code}, Tiempo: %{time_total}s\n" http://localhost:8100/version-b/

echo "   feature-flags:"
curl -s -o /dev/null -w "     Status: %{http_code}, Tiempo: %{time_total}s\n" http://localhost:8100/feature-flags/

echo "   weblogic-a:"
curl -s -o /dev/null -w "     Status: %{http_code}, Tiempo: %{time_total}s\n" http://localhost:7001/version-a/

echo "   weblogic-b:"
curl -s -o /dev/null -w "     Status: %{http_code}, Tiempo: %{time_total}s\n" http://localhost:7002/version-b/

echo
echo "6. Reseteando configuración final:"
FINAL_RESET=$(curl -s http://localhost:8084/api/reset -X POST)
echo "   Reset final: $(echo "$FINAL_RESET" | jq -r '.message // "OK"' 2>/dev/null)"

echo
echo "🎛️ Dashboard: http://localhost:8085/unified-dashboard.html"
echo
echo "📋 RESUMEN DE FUNCIONALIDADES A PROBAR MANUALMENTE:"
echo "================================================="
echo
echo "✅ FUNCIONALIDADES QUE DEBERÍAN FUNCIONAR:"
echo "   📊 Gráfico de distribución se actualiza con sliders"
echo "   🔗 URLs cambian de color según porcentajes"
echo "   🎛️ Toggles activan/desactivan correctamente"
echo "   📈 Métricas se actualizan en tiempo real"
echo "   🔔 Notificaciones aparecen con cambios"
echo
echo "🧪 PRUEBAS MANUALES RECOMENDADAS:"
echo "   1. Activa A/B Testing → URLs version-a y version-b deben activarse"
echo "   2. Mueve slider A/B → Gráfico y URLs deben cambiar inmediatamente"
echo "   3. Pon slider A/B al 100% → version-a debe ponerse roja (0%)"
echo "   4. Activa Canary → URLs weblogic-a y weblogic-b deben activarse"
echo "   5. Mueve slider Canary → Gráfico y URLs deben cambiar"
echo "   6. Pon slider Canary al 100% → weblogic-a debe ponerse roja (0%)"
echo
echo "🔍 SI ALGO NO FUNCIONA:"
echo "   1. Abre F12 > Console"
echo "   2. Busca errores en rojo"
echo "   3. Ejecuta: debugURLStatus()"
echo "   4. Ejecuta: updateTrafficPercentages()"
echo "   5. Ejecuta: updateChartWithCurrentData()"
echo
echo "📝 ARCHIVO DE PRUEBA JAVASCRIPT:"
echo "   Usa: test-specific-functionality.js en la consola del navegador"
