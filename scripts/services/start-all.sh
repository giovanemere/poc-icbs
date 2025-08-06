#!/bin/bash
# Script para iniciar todos los servicios con configuración centralizada

set -e

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Iniciando servicios WebLogic con HAProxy para Canary Deployment y A/B Testing..."

# Cargar variables de entorno
echo "🔧 Cargando variables de entorno..."
source "$PROJECT_ROOT/scripts/core/load-env.sh"
load_env

echo "✅ Variables de entorno cargadas correctamente"

# Construir las imágenes
echo "🏗️ Construyendo imágenes..."
"$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" build

# Iniciar los servicios
echo "🐳 Iniciando servicios..."
"$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" up -d

# Esperar a que los servicios estén listos
echo "⏳ Esperando a que los servicios estén listos..."
sleep 30

# Verificar el estado de los servicios
echo "🔍 Verificando el estado de los servicios..."
"$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" ps

echo ""
echo "🎉 Servicios iniciados correctamente."
echo ""
echo "🌐 URLs de acceso:"
echo "   • Load Balancer:     http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
echo "   • HAProxy Stats:     http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats (usuario: ${HAPROXY_STATS_USER:-admin}, contraseña: ${HAPROXY_STATS_PASSWORD:-admin123})"
echo "   • HAProxy Admin UI:  http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}/"
echo "   • HAProxy HTTPS:     https://localhost:${HAPROXY_HTTPS_EXTERNAL_PORT:-8444}/"
echo "   • WebLogic A:        http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/console"
echo "   • WebLogic B:        http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/console"
echo "   • Oracle DB:         localhost:${ORACLE_EXTERNAL_PORT:-1521} (XE)"
echo "   • Oracle EM Express: https://localhost:${ORACLE_EM_EXTERNAL_PORT:-5500}/em"
echo "   • Documentación:     http://localhost:${MKDOCS_EXTERNAL_PORT:-8000}/"
echo ""
echo "🎛️ Para gestionar el tráfico entre versiones:"
echo "   ./scripts/canary/manage-traffic.sh canary 20  # Envía 20% del tráfico a la versión B"
echo "   ./scripts/canary/manage-traffic.sh ab 50      # Envía 50% del tráfico a la versión B para A/B testing"
echo ""
echo "📊 Para simular tráfico:"
echo "   ./scripts/canary/simulate-traffic.sh 100 0.5  # Simula 100 solicitudes con un intervalo de 0.5 segundos"
echo ""
echo "🔧 Para gestionar servicios:"
echo "   ./manage-services.sh status    # Ver estado de servicios"
echo "   ./manage-services.sh logs      # Ver logs"
echo "   ./manage-services.sh stop      # Detener servicios"
