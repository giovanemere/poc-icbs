#!/bin/bash

# Crear directorio de logs si no existe
mkdir -p /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs
mkdir -p /u01/oracle/logs/weblogic-monitoring

# Asignar permisos correctos
chown -R oracle:oracle /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs
chmod -R 775 /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs
chown -R oracle:oracle /u01/oracle/logs/weblogic-monitoring
chmod -R 775 /u01/oracle/logs/weblogic-monitoring

echo "Monitoring setup completed. Logs directory is ready."
