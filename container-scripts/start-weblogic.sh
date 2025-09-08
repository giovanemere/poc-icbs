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
export ADMIN_USERNAME="${ADMIN_USER:-weblogic}"
export ADMIN_PASSWORD="${ADMIN_PASSWORD:-welcome1}"

echo "Usando dominio preexistente en: $DOMAIN_HOME"

# Crear directorios necesarios
mkdir -p "$DOMAIN_HOME/servers/AdminServer/logs"
mkdir -p "$DOMAIN_HOME/servers/AdminServer/security"
mkdir -p "/u01/oracle/logs/weblogic-monitoring"

# Crear archivo boot.properties con las credenciales correctas
echo "username=$ADMIN_USERNAME" > "$DOMAIN_HOME/servers/AdminServer/security/boot.properties"
echo "password=$ADMIN_PASSWORD" >> "$DOMAIN_HOME/servers/AdminServer/security/boot.properties"

# Configurar permisos
chown -R oracle:oracle "$DOMAIN_HOME" 2>/dev/null || true
chown -R oracle:oracle "/u01/oracle/logs/weblogic-monitoring" 2>/dev/null || true
chmod 600 "$DOMAIN_HOME/servers/AdminServer/security/boot.properties"

echo "Cambiando al directorio del dominio: $DOMAIN_HOME"
cd "$DOMAIN_HOME"

# Asegurar que se inicie como AdminServer, no como servidor gestionado
unset ADMIN_URL
export SERVER_NAME=AdminServer

echo "Iniciando WebLogic Server como AdminServer..."
exec ./bin/startWebLogic.sh
