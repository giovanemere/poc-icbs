#!/bin/bash
# Script para crear usuarios automáticamente en WebLogic

# Verificar argumentos
if [ $# -lt 2 ]; then
    echo "Uso: $0 <nombre-usuario> <contraseña> [descripción]"
    echo "Ejemplo: $0 testuser password123 \"Usuario de prueba\""
    exit 1
fi

USERNAME=$1
PASSWORD=$2
DESCRIPTION=${3:-"Usuario creado automáticamente"}

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Creando usuario $USERNAME en WebLogic A...${NC}"

# Crear usuario en WebLogic A
docker exec -it weblogic-a /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    cd('/SecurityConfiguration/base_domain/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
    if cmo.userExists('$USERNAME'):
        print 'El usuario $USERNAME ya existe, actualizando...'
        cmo.removeUser('$USERNAME')
    cmo.createUser('$USERNAME', '$PASSWORD', '$DESCRIPTION')
    print 'Usuario $USERNAME creado correctamente'
except Exception, e:
    print 'Error al crear usuario: ', e
disconnect()
exit()
"

echo -e "${YELLOW}Creando usuario $USERNAME en WebLogic B...${NC}"

# Crear usuario en WebLogic B
docker exec -it weblogic-b /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    cd('/SecurityConfiguration/base_domain/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
    if cmo.userExists('$USERNAME'):
        print 'El usuario $USERNAME ya existe, actualizando...'
        cmo.removeUser('$USERNAME')
    cmo.createUser('$USERNAME', '$PASSWORD', '$DESCRIPTION')
    print 'Usuario $USERNAME creado correctamente'
except Exception, e:
    print 'Error al crear usuario: ', e
disconnect()
exit()
"

echo -e "${GREEN}Usuario $USERNAME creado en ambos servidores WebLogic${NC}"
