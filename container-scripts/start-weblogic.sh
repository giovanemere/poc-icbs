#!/bin/bash
#
# Script para iniciar WebLogic Server
#

set -e

echo "=== Iniciando WebLogic Server ==="
echo "Ambiente: ${BUILD_ENV:-unknown}"
echo "Versión: ${VERSION:-unknown}"
echo "Dominio: ${DOMAIN_NAME:-base_domain}"
echo "Build Version: ${BUILD_VERSION:-unknown}"
echo "Build Date: ${BUILD_DATE:-unknown}"

# Configurar variables de entorno
export DOMAIN_HOME="/u01/oracle/user_projects/domains/base_domain"
export ADMIN_URL="t3://localhost:7001"

# Crear directorios necesarios
mkdir -p "$DOMAIN_HOME/servers/AdminServer/logs"
mkdir -p "/u01/oracle/logs/weblogic-monitoring"

# Configurar permisos
chown -R oracle:oracle "$DOMAIN_HOME/servers/AdminServer/logs"
chown -R oracle:oracle "/u01/oracle/logs/weblogic-monitoring"
chmod -R 775 "$DOMAIN_HOME/servers/AdminServer/logs"

echo "Cambiando al directorio del dominio: $DOMAIN_HOME"
cd "$DOMAIN_HOME"

# Verificar que el dominio existe
if [ ! -f "$DOMAIN_HOME/bin/startWebLogic.sh" ]; then
    echo "Error: No se encontró el script de inicio de WebLogic en $DOMAIN_HOME/bin/startWebLogic.sh"
    exit 1
fi

echo "Iniciando WebLogic Server en segundo plano..."
nohup ./bin/startWebLogic.sh > /u01/oracle/logs/weblogic-monitoring/weblogic-startup.log 2>&1 &

# Esperar un momento para que WebLogic inicie
sleep 10

echo "Configurando monitoreo..."
if [ -f "/u01/oracle/container-scripts/setup-monitoring.sh" ]; then
    /u01/oracle/container-scripts/setup-monitoring.sh &
else
    echo "Advertencia: No se encontró setup-monitoring.sh"
fi

echo "Configurando health check..."
if [ -f "/u01/oracle/container-scripts/health-check.sh" ]; then
    /u01/oracle/container-scripts/health-check.sh &
else
    echo "Advertencia: No se encontró health-check.sh"
fi

echo "WebLogic Server iniciado. Manteniendo contenedor activo..."
echo "Logs disponibles en:"
echo "  - Startup: /u01/oracle/logs/weblogic-monitoring/weblogic-startup.log"
echo "  - Server: $DOMAIN_HOME/servers/AdminServer/logs/"

# Mantener el contenedor ejecutándose
tail -f /dev/null
