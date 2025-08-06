#!/usr/bin/python
#
# Script para desplegar la aplicación weblogic-features con soporte para Canary Deployment
#

import os
import sys

# Obtener la ubicación del dominio desde las variables de entorno
domainName = os.environ.get('DOMAIN_NAME', 'base_domain')
adminServerName = os.environ.get('ADMIN_NAME', 'AdminServer')
adminPort = os.environ.get('ADMIN_PORT', '7001')
adminPortSSL = os.environ.get('ADMIN_PORT_SSL', '7002')
serverPort = os.environ.get('MANAGED_SERVER_PORT', '7003')
domainPath = os.environ.get('DOMAIN_HOME', '/u01/oracle/user_projects/domains/' + domainName)

# Conectar al servidor de administración
connect('weblogic', 'welcome1', 't3://' + adminServerName + ':' + adminPort)

# Crear el directorio de aplicaciones si no existe
appDir = domainPath + '/weblogic-features'
try:
    os.makedirs(appDir)
except OSError:
    pass

# Copiar los archivos de la aplicación al directorio de despliegue
os.system('cp -r /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/weblogic-features/* ' + appDir)

# Crear la aplicación weblogic-features
print('Creando la aplicación weblogic-features...')
edit()
startEdit()

# Crear el despliegue para la versión A
appPathA = appDir + '/versionA'
try:
    os.makedirs(appPathA)
except OSError:
    pass
os.system('cp ' + appDir + '/index.html ' + appPathA)

# Crear el despliegue para la versión B
appPathB = appDir + '/versionB'
try:
    os.makedirs(appPathB)
except OSError:
    pass
os.system('cp ' + appDir + '/index.html ' + appPathB)

# Configurar la aplicación para Canary Deployment
cd('/')
app1 = create('weblogic-features-A', 'AppDeployment')
app1.setSourcePath(appPathA)
app1.setStagingMode('nostage')
app1.setSecurityDDModel('DDOnly')

app2 = create('weblogic-features-B', 'AppDeployment')
app2.setSourcePath(appPathB)
app2.setStagingMode('nostage')
app2.setSecurityDDModel('DDOnly')

# Asignar la aplicación a los servidores
assign('AppDeployment', 'weblogic-features-A', 'Target', adminServerName)
assign('AppDeployment', 'weblogic-features-B', 'Target', adminServerName)

# Configurar el balanceador de carga para Canary Deployment
# Por defecto, 80% del tráfico va a la versión A y 20% a la versión B
cd('/LoadBalancer/' + domainName)
cmp = create('weblogic-features-canary', 'CanaryRouting')
cmp.setDefaultVersion('weblogic-features-A')
cmp.setVersionWeight('weblogic-features-A', '80')
cmp.setVersionWeight('weblogic-features-B', '20')

save()
activate()

print('Aplicación weblogic-features desplegada con éxito con soporte para Canary Deployment')
print('Accede a la aplicación en: http://localhost:7011/weblogic-features')

exit()
