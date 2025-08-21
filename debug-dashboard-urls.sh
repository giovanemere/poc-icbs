#!/bin/bash

# Script para debuggear el estado de URLs en el Dashboard Unificado

echo "🐛 Debug del Dashboard Unificado - URLs Activas"
echo "==============================================="
echo

echo "1. Verificando Dashboard:"
if curl -s http://localhost:8085/unified-dashboard.html | head -1 | grep -q "DOCTYPE"; then
    echo "✅ Dashboard accesible"
else
    echo "❌ Dashboard no accesible"
    exit 1
fi

echo
echo "2. Verificando APIs necesarias:"
echo "API de Stats:"
STATS_RESPONSE=$(curl -s http://localhost:8084/api/stats)
if echo "$STATS_RESPONSE" | grep -q "backends"; then
    echo "✅ API de Stats funcionando"
else
    echo "❌ API de Stats no responde correctamente"
fi

echo "API de Health:"
HEALTH_RESPONSE=$(curl -s http://localhost:8084/api/health)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo "✅ API de Health funcionando"
else
    echo "❌ API de Health no responde correctamente"
fi

echo
echo "3. Estado actual del sistema:"
echo "A/B Testing: $(echo "$STATS_RESPONSE" | jq -r '.deployment.ab_testing.enabled // "false"' 2>/dev/null || echo "N/A")"
echo "Canary: $(echo "$STATS_RESPONSE" | jq -r '.deployment.canary.enabled // "false"' 2>/dev/null || echo "N/A")"

echo
echo "4. Estado de backends en HAProxy:"
echo "$STATS_RESPONSE" | jq -r '.backends | to_entries[] | select(.key | contains("version")) | "\(.key): \(.value.BACKEND.status)"' 2>/dev/null || echo "Error parsing backends"

echo
echo "5. URLs que deberían estar activas por defecto:"
echo "🟢 version-a: Debería estar VERDE (100% tráfico)"
echo "🔴 version-b: Debería estar ROJA (0% tráfico)"
echo "🟢 feature-flags: Debería estar VERDE (100% tráfico)"
echo "🟢 weblogic-a: Debería estar VERDE (100% tráfico)"
echo "🔴 weblogic-b: Debería estar ROJA (0% tráfico)"

echo
echo "6. Instrucciones para verificar en el navegador:"
echo "   a) Abre: http://localhost:8085/unified-dashboard.html"
echo "   b) Presiona F12 para abrir herramientas de desarrollador"
echo "   c) Ve a la pestaña 'Console'"
echo "   d) Ejecuta: debugURLStatus()"
echo "   e) Verifica que los porcentajes sean correctos"

echo
echo "7. Si las URLs aparecen desactivadas, ejecuta en la consola:"
echo "   updateTrafficPercentages()"
echo "   checkURLHealth()"

echo
echo "8. Para forzar actualización manual:"
echo "   - En la consola del navegador ejecuta:"
echo "   - urlHealthStatus = {'version-a': 'online', 'version-b': 'online', 'feature-flags': 'online', 'weblogic-a': 'online', 'weblogic-b': 'online'}"
echo "   - updateTrafficPercentages()"

echo
echo "🎛️ Dashboard: http://localhost:8085/unified-dashboard.html"
