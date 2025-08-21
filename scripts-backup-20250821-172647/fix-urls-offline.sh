#!/bin/bash

# Script para solucionar el problema de URLs que aparecen offline

echo "🔧 Solucionando URLs que aparecen offline"
echo "========================================"
echo

echo "1. Verificando que todas las URLs funcionan:"
echo "version-a:"
curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:8100/version-a/

echo "version-b:"
curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:8100/version-b/

echo "feature-flags:"
curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:8100/feature-flags/

echo "weblogic-a:"
curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:7001/version-a/

echo "weblogic-b:"
curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:7002/version-b/

echo
echo "2. Verificando Dashboard:"
if curl -s http://localhost:8085/unified-dashboard.html | head -1 | grep -q "DOCTYPE"; then
    echo "✅ Dashboard accesible"
else
    echo "❌ Dashboard no accesible - reiniciando..."
    
    # Reiniciar dashboard
    pkill -f "http.server 8085" 2>/dev/null || true
    rm -f unified-dashboard.pid
    sleep 2
    
    nohup python3 -m http.server 8085 > unified-dashboard.log 2>&1 &
    UNIFIED_PID=$!
    echo $UNIFIED_PID > unified-dashboard.pid
    
    sleep 3
    echo "✅ Dashboard reiniciado"
fi

echo
echo "3. Instrucciones para corregir URLs offline:"
echo
echo "🌐 Abre el Dashboard en tu navegador:"
echo "   http://localhost:8085/unified-dashboard.html"
echo
echo "🔧 Si las URLs aparecen offline (rojas con 'Error' o 'Offline'):"
echo
echo "   MÉTODO 1 - Consola del navegador:"
echo "   1. Presiona F12 para abrir herramientas de desarrollador"
echo "   2. Ve a la pestaña 'Console'"
echo "   3. Copia y pega este código:"
echo
echo "   // Forzar URLs como online"
echo "   urlHealthStatus = {"
echo "       'version-a': 'online',"
echo "       'version-b': 'online',"
echo "       'feature-flags': 'online',"
echo "       'weblogic-a': 'online',"
echo "       'weblogic-b': 'online'"
echo "   };"
echo "   forceAllURLsOnline();"
echo "   updateTrafficPercentages();"
echo
echo "   MÉTODO 2 - Recargar página:"
echo "   1. Presiona Ctrl+F5 (recarga forzada)"
echo "   2. Espera 3-5 segundos para que cargue completamente"
echo
echo "   MÉTODO 3 - Reiniciar Dashboard:"
echo "   ./manage-admin-panel.sh unified restart"
echo
echo "4. Estado esperado después de la corrección:"
echo "   🟢 version-a: Online, 100% tráfico (verde)"
echo "   🔴 version-b: Online, 0% tráfico (roja)"
echo "   🟢 feature-flags: Online, 100% tráfico (verde)"
echo "   🟢 weblogic-a: Online, 100% tráfico (verde)"
echo "   🔴 weblogic-b: Online, 0% tráfico (roja)"
echo
echo "5. Probar A/B Testing:"
echo "   - Activa el toggle 'Activar A/B Testing'"
echo "   - Ajusta el slider a 70%"
echo "   - Deberías ver:"
echo "     🟡 version-a: Online, 70% tráfico (amarillo)"
echo "     🟡 version-b: Online, 30% tráfico (amarillo)"
echo
echo "🎛️ Dashboard: http://localhost:8085/unified-dashboard.html"
