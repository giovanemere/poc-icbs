#!/usr/bin/python
#
# Script para desplegar la aplicación de Feature Flags en WebLogic
#

import os
import sys

# Definir variables
username = 'weblogic'
password = 'welcome1'
adminURL = 't3://localhost:8001'
appName = 'feature-flags'
appPath = '/u01/oracle/user_projects/domains/base_domain/autodeploy/feature-flags.war'
targets = 'AdminServer'

# Conectar al servidor de administración
connect(username, password, adminURL)

# Desplegar la aplicación
print('Desplegando la aplicación ' + appName + '...')
deploy(appName, appPath, targets)

# Desconectar
disconnect()

# Salir
exit()
