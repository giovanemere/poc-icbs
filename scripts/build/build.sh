#!/bin/bash
#
# Script para construir la imagen Docker de WebLogic
#

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Construyendo imagen Docker para Oracle WebLogic ===${NC}"
echo ""

# Verificar archivos necesarios
if [ ! -f "install/fmw_14.1.1.0.0_wls_Disk1_1of1.zip" ]; then
    echo -e "${RED}Error: No se encontró el archivo install/fmw_14.1.1.0.0_wls_Disk1_1of1.zip${NC}"
    echo "Por favor, descargue el archivo desde el sitio web de Oracle y colóquelo en el directorio install/ del proyecto."
    exit 1
fi

if [ ! -f "install/sqlcl-25.2.2.199.0918.zip" ]; then
    echo -e "${RED}Error: No se encontró el archivo install/sqlcl-25.2.2.199.0918.zip${NC}"
    echo "Por favor, descargue el archivo desde el sitio web de Oracle y colóquelo en el directorio install/ del proyecto."
    exit 1
fi

# Crear directorio de despliegue si no existe
mkdir -p deploy

# Limpiar directorio de despliegue
echo -e "${YELLOW}Limpiando directorio de despliegue...${NC}"
rm -f deploy/*.war

# Construir las aplicaciones WAR
echo -e "${YELLOW}Compilando aplicaciones WAR...${NC}"
./scripts/build/build-wars.sh

# Verificar que se hayan generado todos los archivos WAR necesarios
echo -e "${YELLOW}Verificando archivos WAR generados...${NC}"
REQUIRED_WARS=("feature-flags.war" "version-a.war" "version-b.war" "weblogic-features-a.war" "weblogic-features-b.war" "ff4j-simple.war")
MISSING_WARS=()

for war in "${REQUIRED_WARS[@]}"; do
    if [ ! -f "deploy/$war" ]; then
        MISSING_WARS+=("$war")
    fi
done

if [ ${#MISSING_WARS[@]} -gt 0 ]; then
    echo -e "${RED}Advertencia: No se generaron los siguientes archivos WAR:${NC}"
    for war in "${MISSING_WARS[@]}"; do
        echo -e "${RED}- $war${NC}"
    done
    
    echo -e "${YELLOW}Intentando generar los archivos WAR faltantes...${NC}"
    for war in "${MISSING_WARS[@]}"; do
        APP_NAME=${war%.war}
        echo -e "${YELLOW}Generando $APP_NAME...${NC}"
        ./scripts/build/create-simple-wars.sh $APP_NAME
    done
fi

# Verificar nuevamente
MISSING_WARS=()
for war in "${REQUIRED_WARS[@]}"; do
    if [ ! -f "deploy/$war" ]; then
        MISSING_WARS+=("$war")
    fi
done

if [ ${#MISSING_WARS[@]} -gt 0 ]; then
    echo -e "${RED}Error: No se pudieron generar los siguientes archivos WAR:${NC}"
    for war in "${MISSING_WARS[@]}"; do
        echo -e "${RED}- $war${NC}"
    done
    echo -e "${RED}La construcción continuará, pero es posible que algunas funcionalidades no estén disponibles.${NC}"
fi

# Mostrar los archivos WAR generados
echo -e "${GREEN}Archivos WAR generados:${NC}"
ls -la deploy/*.war

# Construir la imagen Docker
echo -e "${YELLOW}Construyendo imagen Docker...${NC}"
docker-compose -f config/docker-compose.yml build

echo ""
echo -e "${GREEN}=== Construcción completada ===${NC}"
echo ""
echo -e "Para iniciar los contenedores, ejecute:"
echo -e "${YELLOW}  docker-compose -f config/docker-compose.yml up -d${NC}"
echo ""
