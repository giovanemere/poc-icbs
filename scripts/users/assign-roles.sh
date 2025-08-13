#!/bin/bash
# Script para asignar roles a usuarios en WebLogic

# Verificar argumentos
if [ $# -lt 2 ]; then
    echo "Uso: $0 <nombre-usuario> <rol>"
    echo "Ejemplo: $0 testuser Administrators"
    exit 1
fi

USERNAME=$1
ROLE=$2

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Asignando rol $ROLE al usuario $USERNAME en WebLogic A...${NC}"

# Asignar rol en WebLogic A
docker exec -it weblogic-a /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    cd('/SecurityConfiguration/base_domain/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
    if not cmo.userExists('$USERNAME'):
        print 'Error: El usuario $USERNAME no existe'
    else:
        cmo.addMemberToGroup('$ROLE', '$USERNAME')
        print 'Rol $ROLE asignado correctamente al usuario $USERNAME'
except Exception, e:
    print 'Error al asignar rol: ', e
disconnect()
exit()
"

echo -e "${YELLOW}Asignando rol $ROLE al usuario $USERNAME en WebLogic B...${NC}"

# Asignar rol en WebLogic B
docker exec -it weblogic-b /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    cd('/SecurityConfiguration/base_domain/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
    if not cmo.userExists('$USERNAME'):
        print 'Error: El usuario $USERNAME no existe'
    else:
        cmo.addMemberToGroup('$ROLE', '$USERNAME')
        print 'Rol $ROLE asignado correctamente al usuario $USERNAME'
except Exception, e:
    print 'Error al asignar rol: ', e
disconnect()
exit()
"

echo -e "${GREEN}Rol $ROLE asignado al usuario $USERNAME en ambos servidores WebLogic${NC}"
