#!/bin/bash

# Script para probar la lógica de 100% en A/B Testing y Canary

echo "🧪 Probando Lógica de 100% - A/B Testing y Canary"
echo "================================================="
echo

echo "1. Verificando Dashboard:"
if curl -s http://localhost:8085/unified-dashboard.html | head -1 | grep -q "DOCTYPE"; then
    echo "✅ Dashboard accesible"
else
    echo "❌ Dashboard no accesible"
    exit 1
fi

echo
echo "2. Probando A/B Testing al 100%:"
echo "Activando A/B Testing con 100% para Version B..."

# Activar A/B Testing con 100% para B (0% para A)
AB_RESPONSE=$(curl -s http://localhost:8084/api/ab/apply -X POST -H "Content-Type: application/json" -d '{"percentage_a": 0, "percentage_b": 100, "enabled": true}')
echo "Respuesta A/B: $AB_RESPONSE"

if echo "$AB_RESPONSE" | grep -q "success.*true"; then
    echo "✅ A/B Testing configurado al 100% para Version B"
    echo "   📊 Resultado esperado:"
    echo "      🔴 version-a: 0% (ROJA - deshabilitada)"
    echo "      🟢 version-b: 100% (VERDE - habilitada)"
else
    echo "❌ Error configurando A/B Testing"
fi

echo
echo "3. Probando Canary al 100%:"
echo "Activando Canary con 100% para WebLogic B..."

# Activar Canary con 100% para B (0% para A)
CANARY_RESPONSE=$(curl -s http://localhost:8084/api/canary/apply -X POST -H "Content-Type: application/json" -d '{"percentage": 100, "enabled": true}')
echo "Respuesta Canary: $CANARY_RESPONSE"

if echo "$CANARY_RESPONSE" | grep -q "success.*true"; then
    echo "✅ Canary configurado al 100% para WebLogic B"
    echo "   📊 Resultado esperado:"
    echo "      🔴 weblogic-a: 0% (ROJA - deshabilitada)"
    echo "      🟢 weblogic-b: 100% (VERDE - habilitada)"
else
    echo "❌ Error configurando Canary"
fi

echo
echo "4. Verificando estado actual del sistema:"
STATS_RESPONSE=$(curl -s http://localhost:8084/api/stats)
echo "A/B Testing habilitado: $(echo "$STATS_RESPONSE" | jq -r '.deployment.ab_testing.enabled // "false"' 2>/dev/null || echo "N/A")"
echo "A/B Porcentaje A: $(echo "$STATS_RESPONSE" | jq -r '.deployment.ab_testing.percentage_a // "N/A"' 2>/dev/null || echo "N/A")"
echo "A/B Porcentaje B: $(echo "$STATS_RESPONSE" | jq -r '.deployment.ab_testing.percentage_b // "N/A"' 2>/dev/null || echo "N/A")"
echo "Canary habilitado: $(echo "$STATS_RESPONSE" | jq -r '.deployment.canary.enabled // "false"' 2>/dev/null || echo "N/A")"
echo "Canary porcentaje: $(echo "$STATS_RESPONSE" | jq -r '.deployment.canary.percentage // "N/A"' 2>/dev/null || echo "N/A")"

echo
echo "5. Probando configuración 50/50:"
echo "Configurando A/B Testing 50/50..."

AB_50_RESPONSE=$(curl -s http://localhost:8084/api/ab/apply -X POST -H "Content-Type: application/json" -d '{"percentage_a": 50, "percentage_b": 50, "enabled": true}')
echo "Respuesta A/B 50/50: $AB_50_RESPONSE"

echo "Configurando Canary 20%..."
CANARY_20_RESPONSE=$(curl -s http://localhost:8084/api/canary/apply -X POST -H "Content-Type: application/json" -d '{"percentage": 20, "enabled": true}')
echo "Respuesta Canary 20%: $CANARY_20_RESPONSE"

echo
echo "6. Reseteando configuración:"
RESET_RESPONSE=$(curl -s http://localhost:8084/api/reset -X POST)
echo "Reset: $RESET_RESPONSE"

echo
echo "🎛️ Dashboard: http://localhost:8085/unified-dashboard.html"
echo
echo "📋 Instrucciones para probar manualmente:"
echo "   1. Abre el dashboard en el navegador"
echo "   2. Activa 'A/B Testing'"
echo "   3. Mueve el slider completamente a la DERECHA (100%)"
echo "   4. Verifica que:"
echo "      • version-a cambie a ROJA (0%)"
echo "      • version-b cambie a VERDE (100%)"
echo "   5. Activa 'Canary Deployment'"
echo "   6. Mueve el slider completamente a la DERECHA (100%)"
echo "   7. Verifica que:"
echo "      • weblogic-a cambie a ROJA (0%)"
echo "      • weblogic-b cambie a VERDE (100%)"
echo
echo "🔗 URLs ahora deberían aparecer en COLOR BLANCO con mejor contraste"
