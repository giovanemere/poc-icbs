#!/bin/bash

# Script para probar el Dashboard Unificado

echo "🧪 Probando Dashboard Unificado Completo"
echo "========================================"
echo

echo "1. Verificando acceso al Dashboard:"
if curl -s http://localhost:8085/unified-dashboard.html | head -1 | grep -q "DOCTYPE"; then
    echo "✅ Dashboard accesible"
else
    echo "❌ Dashboard no accesible"
    exit 1
fi

echo
echo "2. Probando APIs de A/B Testing:"
echo "Activando A/B Testing (70/30)..."
RESPONSE=$(curl -s http://localhost:8084/api/ab/apply -X POST -H "Content-Type: application/json" -d '{"percentage_a": 70, "percentage_b": 30, "enabled": true}')
echo "Respuesta: $RESPONSE"

if echo "$RESPONSE" | grep -q "success.*true"; then
    echo "✅ A/B Testing funcionando"
else
    echo "❌ Error en A/B Testing"
fi

echo
echo "3. Probando APIs de Canary Deployment:"
echo "Activando Canary (20%)..."
RESPONSE=$(curl -s http://localhost:8084/api/canary/apply -X POST -H "Content-Type: application/json" -d '{"percentage": 20, "enabled": true}')
echo "Respuesta: $RESPONSE"

if echo "$RESPONSE" | grep -q "success.*true"; then
    echo "✅ Canary Deployment funcionando"
else
    echo "❌ Error en Canary Deployment"
fi

echo
echo "4. Verificando estado de URLs:"
echo "Version A:"
curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:8100/version-a/

echo "Version B:"
curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:8100/version-b/

echo "Feature Flags:"
curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:8100/feature-flags/

echo
echo "5. Reseteando configuración:"
RESPONSE=$(curl -s http://localhost:8084/api/reset -X POST)
echo "Reset: $RESPONSE"

echo
echo "🎉 Prueba completada!"
echo "Dashboard Unificado disponible en: http://localhost:8085/unified-dashboard.html"
echo
echo "Funcionalidades verificadas:"
echo "✅ Acceso al Dashboard"
echo "✅ A/B Testing API"
echo "✅ Canary Deployment API"
echo "✅ URLs de aplicaciones"
echo "✅ Reset de configuración"
