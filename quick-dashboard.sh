#!/bin/bash

# Script de acceso rápido al Dashboard Real de HAProxy

echo "🚀 Dashboard Real de HAProxy - Acceso Rápido"
echo ""
echo "Iniciando dashboard si no está corriendo..."

# Cambiar al directorio del proyecto
cd "$(dirname "$0")"

# Usar el script principal
./manage-admin-panel.sh traffic start

echo ""
echo "🎯 DASHBOARD PRINCIPAL:"
echo "   📊 http://localhost:8084/"
echo ""
echo "🔧 Comandos útiles:"
echo "   ./manage-admin-panel.sh status    # Ver estado"
echo "   ./manage-admin-panel.sh test      # Probar funcionalidad"
echo "   ./manage-admin-panel.sh stop      # Detener todo"
echo ""
echo "💡 El dashboard permite control REAL de A/B Testing y Canary Deployment"
