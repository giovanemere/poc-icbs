#!/bin/bash

# Script para probar la sincronización del Dashboard

echo "🔄 Probando Sincronización del Dashboard"
echo "======================================="
echo

echo "1. Verificando Dashboard:"
if curl -s http://localhost:8085/unified-dashboard.html | head -1 | grep -q "DOCTYPE"; then
    echo "✅ Dashboard accesible"
else
    echo "❌ Dashboard no accesible"
    exit 1
fi

echo
echo "2. Probando A/B Testing - Cambios graduales:"

echo "   Configurando A/B 30/70..."
AB_30_RESPONSE=$(curl -s http://localhost:8084/api/ab/apply -X POST -H "Content-Type: application/json" -d '{"percentage_a": 30, "percentage_b": 70, "enabled": true}')
echo "   Respuesta: $(echo "$AB_30_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null || echo "$AB_30_RESPONSE")"

sleep 2

echo "   Configurando A/B 70/30..."
AB_70_RESPONSE=$(curl -s http://localhost:8084/api/ab/apply -X POST -H "Content-Type: application/json" -d '{"percentage_a": 70, "percentage_b": 30, "enabled": true}')
echo "   Respuesta: $(echo "$AB_70_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null || echo "$AB_70_RESPONSE")"

sleep 2

echo "   Configurando A/B 0/100 (100% para B)..."
AB_100_RESPONSE=$(curl -s http://localhost:8084/api/ab/apply -X POST -H "Content-Type: application/json" -d '{"percentage_a": 0, "percentage_b": 100, "enabled": true}')
echo "   Respuesta: $(echo "$AB_100_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null || echo "$AB_100_RESPONSE")"

echo
echo "3. Probando Canary - Cambios graduales:"

echo "   Configurando Canary 10%..."
CANARY_10_RESPONSE=$(curl -s http://localhost:8084/api/canary/apply -X POST -H "Content-Type: application/json" -d '{"percentage": 10, "enabled": true}')
echo "   Respuesta: $(echo "$CANARY_10_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null || echo "$CANARY_10_RESPONSE")"

sleep 2

echo "   Configurando Canary 50%..."
CANARY_50_RESPONSE=$(curl -s http://localhost:8084/api/canary/apply -X POST -H "Content-Type: application/json" -d '{"percentage": 50, "enabled": true}')
echo "   Respuesta: $(echo "$CANARY_50_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null || echo "$CANARY_50_RESPONSE")"

sleep 2

echo "   Configurando Canary 100%..."
CANARY_100_RESPONSE=$(curl -s http://localhost:8084/api/canary/apply -X POST -H "Content-Type: application/json" -d '{"percentage": 100, "enabled": true}')
echo "   Respuesta: $(echo "$CANARY_100_RESPONSE" | jq -r '.message // .error // "Error"' 2>/dev/null || echo "$CANARY_100_RESPONSE")"

echo
echo "4. Verificando estado final del sistema:"
FINAL_STATS=$(curl -s http://localhost:8084/api/stats)
echo "   A/B Testing habilitado: $(echo "$FINAL_STATS" | jq -r '.deployment.ab_testing.enabled // "false"' 2>/dev/null || echo "N/A")"
echo "   A/B Porcentaje A: $(echo "$FINAL_STATS" | jq -r '.deployment.ab_testing.percentage_a // "N/A"' 2>/dev/null || echo "N/A")"
echo "   A/B Porcentaje B: $(echo "$FINAL_STATS" | jq -r '.deployment.ab_testing.percentage_b // "N/A"' 2>/dev/null || echo "N/A")"
echo "   Canary habilitado: $(echo "$FINAL_STATS" | jq -r '.deployment.canary.enabled // "false"' 2>/dev/null || echo "N/A")"
echo "   Canary porcentaje: $(echo "$FINAL_STATS" | jq -r '.deployment.canary.percentage // "N/A"' 2>/dev/null || echo "N/A")"

echo
echo "5. Reseteando configuración:"
RESET_RESPONSE=$(curl -s http://localhost:8084/api/reset -X POST)
echo "   Reset: $(echo "$RESET_RESPONSE" | jq -r '.message // .error // "OK"' 2>/dev/null || echo "$RESET_RESPONSE")"

echo
echo "🎛️ Dashboard: http://localhost:8085/unified-dashboard.html"
echo
echo "📋 Lo que deberías ver ahora:"
echo
echo "   📊 GRÁFICO DE DISTRIBUCIÓN:"
echo "      • Se actualiza automáticamente con cada cambio"
echo "      • Muestra porcentajes correctos en las etiquetas"
echo "      • Colores cambian según la distribución"
echo
echo "   🔗 URLS ACTIVAS:"
echo "      • Cambian de color inmediatamente al mover sliders"
echo "      • 100% = Verde, 0% = Roja, 1-99% = Amarilla"
echo "      • URLs en color BLANCO y visibles"
echo
echo "   🎛️ CONTROLES:"
echo "      • Toggles activan/desactivan correctamente"
echo "      • Sliders actualizan en tiempo real"
echo "      • Notificaciones aparecen con cada cambio"
echo
echo "💡 Prueba manual:"
echo "   1. Abre el dashboard en el navegador"
echo "   2. Abre F12 > Console para ver logs"
echo "   3. Activa A/B Testing y mueve el slider"
echo "   4. Verifica que URLs y gráfico se actualicen"
echo "   5. Activa Canary y mueve el slider"
echo "   6. Verifica que todo se sincroniza correctamente"
