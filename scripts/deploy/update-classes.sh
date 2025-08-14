#!/bin/bash
# Script para actualizar solo las clases Java de una aplicación sin redespliegue completo

# Verificar argumentos
if [ $# -ne 1 ]; then
    echo "Uso: $0 <nombre-aplicacion>"
    echo "Ejemplo: $0 feature-flags"
    exit 1
fi

APP_NAME=$1
CLASS_DIR="war-projects/${APP_NAME}/WEB-INF/classes"

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar que el directorio de clases existe
if [ ! -d "$CLASS_DIR" ]; then
    echo -e "${RED}Error: El directorio $CLASS_DIR no existe${NC}"
    exit 1
fi

echo -e "${YELLOW}Iniciando actualización de clases para $APP_NAME...${NC}"

# 1. Encontrar el directorio de despliegue en WebLogic A
DEPLOY_DIR_A=$(docker exec -it weblogic-a find /u01/oracle/user_projects/domains/base_domain -name "$APP_NAME" -type d | grep -v "tmp" | grep -v "cache" | head -1)

if [ -z "$DEPLOY_DIR_A" ]; then
    echo -e "${RED}Error: No se encontró el directorio de despliegue para $APP_NAME en WebLogic A${NC}"
    exit 1
fi

echo -e "${YELLOW}Directorio de despliegue en WebLogic A: $DEPLOY_DIR_A${NC}"

# 2. Copiar las clases actualizadas a WebLogic A
echo -e "${YELLOW}Copiando clases actualizadas a WebLogic A...${NC}"
docker cp $CLASS_DIR/. weblogic-a:$DEPLOY_DIR_A/WEB-INF/classes/

# 3. Encontrar el directorio de despliegue en WebLogic B
DEPLOY_DIR_B=$(docker exec -it weblogic-b find /u01/oracle/user_projects/domains/base_domain -name "$APP_NAME" -type d | grep -v "tmp" | grep -v "cache" | head -1)

if [ -z "$DEPLOY_DIR_B" ]; then
    echo -e "${RED}Error: No se encontró el directorio de despliegue para $APP_NAME en WebLogic B${NC}"
    exit 1
fi

echo -e "${YELLOW}Directorio de despliegue en WebLogic B: $DEPLOY_DIR_B${NC}"

# 4. Copiar las clases actualizadas a WebLogic B
echo -e "${YELLOW}Copiando clases actualizadas a WebLogic B...${NC}"
docker cp $CLASS_DIR/. weblogic-b:$DEPLOY_DIR_B/WEB-INF/classes/

# 5. Tocar el archivo weblogic.xml para forzar una recarga
echo -e "${YELLOW}Forzando recarga de clases...${NC}"
docker exec -it weblogic-a touch $DEPLOY_DIR_A/WEB-INF/weblogic.xml
docker exec -it weblogic-b touch $DEPLOY_DIR_B/WEB-INF/weblogic.xml

echo -e "${GREEN}Actualización de clases completada para $APP_NAME${NC}"
echo -e "${YELLOW}Las clases se recargarán en la próxima solicitud a la aplicación${NC}"
