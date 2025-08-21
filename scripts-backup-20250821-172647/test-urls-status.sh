#!/bin/bash

# Script para probar el estado de las URLs en el Dashboard Unificado

echo "🔗 Probando Estado de URLs Activas"
echo "=================================="
echo

echo "1. Verificando acceso al Dashboard:"
if curl -s http://localhost:8085/unified-dashboard.html | head -1 | grep -q "DOCTYPE"; then
    echo "✅ Dashboard Unificado accesible"
else
    echo "❌ Dashboard no accesible"
    exit 1
fi

echo
echo "2. Verificando URLs directamente:"
echo "Version A (debería estar ACTIVA - 100%):"
STATUS_A=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/version-a/)
if [ "$STATUS_A" = "200" ]; then
    echo "  ✅ version-a: $STATUS_A - ONLINE"
else
    echo "  ❌ version-a: $STATUS_A - ERROR"
fi

echo "Version B (debería estar INACTIVA - 0% por defecto):"
STATUS_B=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/version-b/)
if [ "$STATUS_B" = "200" ]; then
    echo "  ✅ version-b: $STATUS_B - ONLINE (pero 0% tráfico por defecto)"
else
    echo "  ❌ version-b: $STATUS_B - ERROR"
fi

echo "Feature Flags (debería estar ACTIVA - 100%):"
STATUS_FF=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/feature-flags/)
if [ "$STATUS_FF" = "200" ]; then
    echo "  ✅ feature-flags: $STATUS_FF - ONLINE"
else
    echo "  ❌ feature-flags: $STATUS_FF - ERROR"
fi

echo "WebLogic A (debería estar ACTIVA - 100%):"
STATUS_WA=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7001/version-a/)
if [ "$STATUS_WA" = "200" ] || [ "$STATUS_WA" = "302" ]; then
    echo "  ✅ weblogic-a: $STATUS_WA - ONLINE"
else
    echo "  ❌ weblogic-a: $STATUS_WA - ERROR"
fi

echo "WebLogic B (debería estar INACTIVA - 0% por defecto):"
STATUS_WB=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7002/version-b/)
if [ "$STATUS_WB" = "200" ] || [ "$STATUS_WB" = "302" ]; then
    echo "  ✅ weblogic-b: $STATUS_WB - ONLINE (pero 0% tráfico por defecto)"
else
    echo "  ❌ weblogic-b: $STATUS_WB - ERROR"
fi

echo
echo "3. Estado esperado en el Dashboard:"
echo "🟢 version-a: 100% tráfico - ACTIVA (verde)"
echo "🔴 version-b: 0% tráfico - INACTIVA (roja)"
echo "🟢 feature-flags: 100% tráfico - ACTIVA (verde)"
echo "🟢 weblogic-a: 100% tráfico - ACTIVA (verde)"
echo "🔴 weblogic-b: 0% tráfico - INACTIVA (roja)"

echo
echo "4. Probando activación de A/B Testing:"
echo "Activando A/B Testing 70/30..."
RESPONSE=$(curl -s http://localhost:8084/api/ab/apply -X POST -H "Content-Type: application/json" -d '{"percentage_a": 70, "percentage_b": 30, "enabled": true}')
echo "Respuesta: $RESPONSE"

if echo "$RESPONSE" | grep -q "success.*true"; then
    echo "✅ A/B Testing activado"
    echo "🟡 Ahora version-a debería mostrar: 70% (amarillo)"
    echo "🟡 Ahora version-b debería mostrar: 30% (amarillo)"
else
    echo "❌ Error activando A/B Testing"
fi

echo
echo "5. Reseteando configuración:"
RESET_RESPONSE=$(curl -s http://localhost:8084/api/reset -X POST)
echo "Reset: $RESET_RESPONSE"

echo
echo "🎛️ Dashboard disponible en: http://localhost:8085/unified-dashboard.html"
echo "📊 Verifica visualmente que las URLs muestren los colores correctos"
