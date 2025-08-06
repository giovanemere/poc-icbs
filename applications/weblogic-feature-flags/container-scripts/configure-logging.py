#!/usr/bin/python
#
# Script para configurar los logs de WebLogic para que sean visibles en el monitoring
#

import os
import sys

# Obtener la ubicación del dominio desde las variables de entorno
domainName = os.environ.get('DOMAIN_NAME', 'base_domain')
adminServerName = os.environ.get('ADMIN_NAME', 'AdminServer')
adminPort = os.environ.get('ADMIN_PORT', '7001')
domainPath = os.environ.get('DOMAIN_HOME', '/u01/oracle/user_projects/domains/' + domainName)

# Conectar al servidor de administración
connect('weblogic', 'welcome1', 't3://' + adminServerName + ':' + adminPort)

print('Configurando logs para WebLogic...')
edit()
startEdit()

# Configurar el log del servidor de administración
cd('/Servers/' + adminServerName + '/Log/' + adminServerName)
set('FileName', domainPath + '/servers/' + adminServerName + '/logs/' + adminServerName + '.log')
set('FileCount', 10)
set('FileMinSize', 5000)
set('RotationType', 'bySize')
set('LogFileSeverity', 'Info')
set('StdoutSeverity', 'Info')
set('RedirectStdoutToServerLogEnabled', true)
set('RedirectStderrToServerLogEnabled', true)
set('RotateLogOnStartup', true)
set('LogFileFormat', 'ODL-Text')
set('ODLFields', 'time,severity,servername,loggername,threadid,userid,requestid,ecid,rid,messageid,message')

# Configurar el log de acceso HTTP
cd('/Servers/' + adminServerName + '/WebServer/' + adminServerName + '/WebServerLog/' + adminServerName)
set('FileName', domainPath + '/servers/' + adminServerName + '/logs/' + adminServerName + '_access.log')
set('FileCount', 10)
set('FileMinSize', 5000)
set('RotationType', 'bySize')
set('RotateLogOnStartup', true)
set('LogFileFormat', 'common')
set('ELFFields', 'date time cs-method cs-uri sc-status')

# Configurar el log de diagnóstico
cd('/Servers/' + adminServerName + '/ServerDiagnosticConfig/' + adminServerName)
set('WldfDiagnosticVolume', 'High')
set('DiagnosticStoreDir', domainPath + '/servers/' + adminServerName + '/logs/diagnostic_images')

# Configurar el log de datos
cd('/Servers/' + adminServerName + '/DataSource/' + adminServerName)
set('ProfileType', 'WebLogic')
set('ProfileFile', domainPath + '/servers/' + adminServerName + '/logs/datasource.log')

# Configurar el log de JMS
cd('/JMSServers')
servers = ls(returnMap='true')
for server in servers:
    cd('/JMSServers/' + server)
    set('PersistentStore', domainPath + '/servers/' + adminServerName + '/logs/jms/' + server)

# Configurar el log de JDBC
cd('/JDBCSystemResources')
resources = ls(returnMap='true')
for resource in resources:
    cd('/JDBCSystemResources/' + resource)
    set('LogFileName', domainPath + '/servers/' + adminServerName + '/logs/jdbc/' + resource + '.log')

save()
activate()

# Crear directorios para logs si no existen
os.system('mkdir -p ' + domainPath + '/servers/' + adminServerName + '/logs/diagnostic_images')
os.system('mkdir -p ' + domainPath + '/servers/' + adminServerName + '/logs/jms')
os.system('mkdir -p ' + domainPath + '/servers/' + adminServerName + '/logs/jdbc')

print('Configuración de logs completada.')
print('Los logs están disponibles en: ' + domainPath + '/servers/' + adminServerName + '/logs/')

exit()
