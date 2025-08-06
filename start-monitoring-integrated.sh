#!/bin/bash

# =============================================================================
# Script de inicio integrado para HAProxy + Sistema de Monitoreo
# =============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Iniciando sistema integrado HAProxy + Monitoreo..."

# 1. Iniciar sistema de monitoreo
echo "📊 Iniciando sistema de monitoreo..."
"$PROJECT_ROOT/scripts/monitoring/setup-complete-monitoring.sh"

# 2. Esperar a que el sistema esté listo
echo "⏳ Esperando a que el sistema esté listo..."
sleep 5

# 3. Verificar que todo está funcionando
echo "🔍 Verificando sistema..."
if curl -s http://localhost:8090/api/status > /dev/null; then
    echo "✅ Sistema de monitoreo OK"
else
    echo "❌ Error en sistema de monitoreo"
    exit 1
fi

if curl -s http://localhost:8085/api/status > /dev/null; then
    echo "✅ Integración HAProxy OK"
else
    echo "❌ Error en integración HAProxy"
    exit 1
fi

echo ""
echo "🎉 Sistema integrado iniciado exitosamente!"
echo ""
echo "📊 Endpoints disponibles:"
echo "  • Dashboard HAProxy:      http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}"
echo "  • Estado URLs:            http://localhost:8090/api/url-status"
echo "  • Integración:            http://localhost:8085/api/url-status"
echo "  • HAProxy Stats:          http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
echo ""
echo "🔧 Para detener:"
echo "  ./scripts/monitoring/stop-monitoring.sh"
echo ""
