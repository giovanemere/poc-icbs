#!/usr/bin/python
#
# Script para configurar el despliegue canary en WebLogic
#

import sys

# Conectar al servidor de administración
connect('weblogic', 'welcome1', 't3://localhost:7001')

print('Configurando despliegue canary...')

# Verificar si las aplicaciones están desplegadas
def check_deployment(app_name):
    try:
        cd('/AppDeployments/' + app_name)
        return True
    except:
        return False

# Desplegar aplicaciones si no están desplegadas
if not check_deployment('weblogic-features-a'):
    print('Desplegando weblogic-features-a...')
    deploy('weblogic-features-a', '/u01/oracle/user_projects/domains/base_domain/autodeploy/weblogic-features-a.war', targets='AdminServer')

if not check_deployment('weblogic-features-b'):
    print('Desplegando weblogic-features-b...')
    deploy('weblogic-features-b', '/u01/oracle/user_projects/domains/base_domain/autodeploy/weblogic-features-b.war', targets='AdminServer')

# Configurar proxy HTTP para implementar canary
edit()
startEdit()

# Crear un servidor proxy virtual
cd('/')
try:
    cd('/VirtualTargets/canary-proxy')
    print('El proxy canary ya existe')
except:
    print('Creando proxy canary...')
    proxy = create('canary-proxy', 'VirtualTarget')
    proxy.setTargets(jarray.array([ObjectName('com.bea:Name=AdminServer,Type=Server')], ObjectName))
    proxy.setUriPrefix('/weblogic-features')

# Crear reglas de enrutamiento
cd('/')
try:
    cd('/HttpProxies/canary-router')
    print('El router canary ya existe')
except:
    print('Creando router canary...')
    router = create('canary-router', 'HttpProxy')
    router.setVirtualTarget('canary-proxy')
    
    # Regla para versión A (80%)
    ruleA = create('rule-version-a', 'HttpProxyRule')
    ruleA.setPattern('*')
    ruleA.setProbability(80)
    ruleA.setTargetUrl('http://localhost:7001/weblogic-features-a')
    
    # Regla para versión B (20%)
    ruleB = create('rule-version-b', 'HttpProxyRule')
    ruleB.setPattern('*')
    ruleB.setProbability(20)
    ruleB.setTargetUrl('http://localhost:7001/weblogic-features-b')

save()
activate()

print('Configuración de despliegue canary completada')
print('Aplicaciones disponibles en:')
print('- Versión A: http://localhost:7001/weblogic-features-a')
print('- Versión B: http://localhost:7001/weblogic-features-b')
print('- Canary: http://localhost:7001/weblogic-features')

exit()
