#!/bin/bash

# Esperar a que WebLogic se inicie completamente
sleep 30

# Verificar que el directorio de logs exista
if [ ! -d "/u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs" ]; then
    echo "Creando directorio de logs..."
    mkdir -p /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs
    chown -R oracle:oracle /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs
    chmod -R 775 /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs
fi

# Verificar que el directorio de monitoreo exista
if [ ! -d "/u01/oracle/logs/weblogic-monitoring" ]; then
    echo "Creando directorio de monitoreo..."
    mkdir -p /u01/oracle/logs/weblogic-monitoring
    chown -R oracle:oracle /u01/oracle/logs/weblogic-monitoring
    chmod -R 775 /u01/oracle/logs/weblogic-monitoring
fi

# Verificar que WebLogic esté funcionando
while true; do
    sleep 60
    curl -s http://localhost:7001/console > /dev/null
    if [ $? -eq 0 ]; then
        echo "WebLogic está funcionando correctamente" >> /u01/oracle/logs/weblogic-monitoring/health.log
    else
        echo "WebLogic no responde, verificando logs..." >> /u01/oracle/logs/weblogic-monitoring/health.log
        if [ -f "/u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs/AdminServer.log" ]; then
            tail -20 /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/logs/AdminServer.log >> /u01/oracle/logs/weblogic-monitoring/health.log
        else
            echo "El archivo de log no existe" >> /u01/oracle/logs/weblogic-monitoring/health.log
        fi
    fi
done
