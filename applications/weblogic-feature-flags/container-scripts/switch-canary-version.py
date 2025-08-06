#!/usr/bin/python
#
# Script para cambiar la distribución de tráfico entre versiones A y B
#

import os
import sys

# Verificar argumentos
if len(sys.argv) != 3:
    print('Uso: switch-canary-version.py <porcentaje-version-A> <porcentaje-version-B>')
    print('Ejemplo: switch-canary-version.py 50 50')
    exit(1)

# Obtener los porcentajes de las versiones
versionA_percent = sys.argv[1]
versionB_percent = sys.argv[2]

# Validar que los porcentajes sumen 100
if int(versionA_percent) + int(versionB_percent) != 100:
    print('Error: Los porcentajes deben sumar 100')
    exit(1)

# Obtener la ubicación del dominio desde las variables de entorno
domainName = os.environ.get('DOMAIN_NAME', 'base_domain')
adminServerName = os.environ.get('ADMIN_NAME', 'AdminServer')
adminPort = os.environ.get('ADMIN_PORT', '7001')

# Conectar al servidor de administración
connect('weblogic', 'welcome1', 't3://' + adminServerName + ':' + adminPort)

# Actualizar la configuración de Canary Deployment
edit()
startEdit()

cd('/LoadBalancer/' + domainName + '/CanaryRouting/weblogic-features-canary')
set('VersionWeight_weblogic-features-A', versionA_percent)
set('VersionWeight_weblogic-features-B', versionB_percent)

# Si el porcentaje de la versión A es 100%, establecerla como predeterminada
if versionA_percent == '100':
    set('DefaultVersion', 'weblogic-features-A')
# Si el porcentaje de la versión B es 100%, establecerla como predeterminada
elif versionB_percent == '100':
    set('DefaultVersion', 'weblogic-features-B')

save()
activate()

print('Distribución de tráfico actualizada:')
print('- Versión A: ' + versionA_percent + '%')
print('- Versión B: ' + versionB_percent + '%')

exit()
