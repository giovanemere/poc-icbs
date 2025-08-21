#!/bin/bash
# Script para limpiar la caché y forzar el redespliegue de una aplicación

# Verificar argumentos
if [ $# -ne 1 ]; then
    echo "Uso: $0 <nombre-aplicacion>"
    echo "Ejemplo: $0 feature-flags"
    exit 1
fi

APP_NAME=$1
WAR_FILE="deploy/${APP_NAME}.war"

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar que el archivo WAR existe
if [ ! -f "$WAR_FILE" ]; then
    echo -e "${RED}Error: El archivo $WAR_FILE no existe${NC}"
    exit 1
fi

echo -e "${YELLOW}Iniciando proceso de limpieza y redespliegue para $APP_NAME...${NC}"

# 1. Detener la aplicación en WebLogic A
echo -e "${YELLOW}Deteniendo $APP_NAME en WebLogic A...${NC}"
docker exec -it weblogic-a /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    stopApplication('$APP_NAME', timeout=60000)
    print 'Aplicación detenida correctamente'
except:
    print 'La aplicación no estaba en ejecución o no existe'
disconnect()
exit()
"

# 2. Eliminar la aplicación de WebLogic A
echo -e "${YELLOW}Eliminando $APP_NAME de WebLogic A...${NC}"
docker exec -it weblogic-a /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    undeploy('$APP_NAME')
    print 'Aplicación eliminada correctamente'
except:
    print 'La aplicación no existía'
disconnect()
exit()
"

# 3. Limpiar directorios de caché en WebLogic A
echo -e "${YELLOW}Limpiando directorios de caché en WebLogic A...${NC}"
docker exec -it weblogic-a rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/tmp/$APP_NAME
docker exec -it weblogic-a rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/cache/$APP_NAME

# 4. Desplegar la aplicación en WebLogic A
echo -e "${YELLOW}Desplegando $APP_NAME en WebLogic A...${NC}"
docker cp $WAR_FILE weblogic-a:/u01/oracle/user_projects/domains/base_domain/autodeploy/

# 5. Repetir el proceso para WebLogic B
echo -e "${YELLOW}Deteniendo $APP_NAME en WebLogic B...${NC}"
docker exec -it weblogic-b /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    stopApplication('$APP_NAME', timeout=60000)
    print 'Aplicación detenida correctamente'
except:
    print 'La aplicación no estaba en ejecución o no existe'
disconnect()
exit()
"

echo -e "${YELLOW}Eliminando $APP_NAME de WebLogic B...${NC}"
docker exec -it weblogic-b /u01/oracle/oracle_common/common/bin/wlst.sh -c "
connect('weblogic', 'welcome1', 't3://localhost:7001')
try:
    undeploy('$APP_NAME')
    print 'Aplicación eliminada correctamente'
except:
    print 'La aplicación no existía'
disconnect()
exit()
"

echo -e "${YELLOW}Limpiando directorios de caché en WebLogic B...${NC}"
docker exec -it weblogic-b rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/tmp/$APP_NAME
docker exec -it weblogic-b rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/cache/$APP_NAME

echo -e "${YELLOW}Desplegando $APP_NAME en WebLogic B...${NC}"
docker cp $WAR_FILE weblogic-b:/u01/oracle/user_projects/domains/base_domain/autodeploy/

echo -e "${GREEN}Proceso de limpieza y redespliegue completado para $APP_NAME${NC}"
echo -e "${YELLOW}Espere unos momentos mientras WebLogic procesa el despliegue...${NC}"

# Esperar a que se complete el despliegue
sleep 10

echo -e "${GREEN}¡Despliegue completado!${NC}"
echo -e "Acceda a la aplicación en: ${YELLOW}http://localhost:8080/$APP_NAME/${NC}"
