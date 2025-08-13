#!/usr/bin/python
#
# Script para cambiar la distribución de tráfico entre versiones A y B
#

import sys

# Verificar argumentos
if len(sys.argv) != 3:
    print('Uso: switch-canary.py <porcentaje-version-A> <porcentaje-version-B>')
    print('Ejemplo: switch-canary.py 50 50')
    exit(1)

# Obtener los porcentajes de las versiones
versionA_percent = int(sys.argv[1])
versionB_percent = int(sys.argv[2])

# Validar que los porcentajes sumen 100
if versionA_percent + versionB_percent != 100:
    print('Error: Los porcentajes deben sumar 100')
    exit(1)

# Conectar al servidor de administración
connect('weblogic', 'welcome1', 't3://localhost:7001')

# Actualizar la configuración de Canary Deployment
edit()
startEdit()

cd('/HttpProxies/canary-router/HttpProxyRules/rule-version-a')
set('Probability', versionA_percent)

cd('/HttpProxies/canary-router/HttpProxyRules/rule-version-b')
set('Probability', versionB_percent)

save()
activate()

print('Distribución de tráfico actualizada:')
print('- Versión A: ' + str(versionA_percent) + '%')
print('- Versión B: ' + str(versionB_percent) + '%')

exit()
