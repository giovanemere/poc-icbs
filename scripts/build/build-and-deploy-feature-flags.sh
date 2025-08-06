#!/bin/bash
#
# Script para construir y desplegar la aplicación feature-flags con modo oscuro
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Construyendo y desplegando Feature Flags con modo oscuro ===${NC}"
echo ""

# Directorio base
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.."
WAR_PROJECT_DIR="$BASE_DIR/war-projects/feature-flags"
DEPLOY_DIR="$BASE_DIR/deploy"

# Verificar si Maven está instalado
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}Error: Maven no está instalado${NC}"
    echo "Por favor, instale Maven con:"
    echo -e "${YELLOW}  sudo apt-get install maven${NC}"
    exit 1
fi

# Crear directorio de despliegue si no existe
mkdir -p "$DEPLOY_DIR"

# Paso 1: Construir el proyecto
echo -e "${BLUE}Paso 1: Construyendo el proyecto feature-flags...${NC}"
(cd "$WAR_PROJECT_DIR" && mvn clean package -DskipTests)

# Verificar si la construcción fue exitosa
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: La construcción de feature-flags falló${NC}"
    exit 1
fi

# Paso 2: Copiar el archivo WAR al directorio de despliegue
echo -e "${BLUE}Paso 2: Copiando el archivo WAR al directorio de despliegue...${NC}"
WAR_FILE=$(find "$WAR_PROJECT_DIR/target" -name "*.war" | head -n 1)

if [ -z "$WAR_FILE" ]; then
    echo -e "${RED}Error: No se encontró el archivo WAR en $WAR_PROJECT_DIR/target${NC}"
    exit 1
fi

cp "$WAR_FILE" "$DEPLOY_DIR/feature-flags.war"
echo -e "${GREEN}Archivo WAR copiado correctamente a $DEPLOY_DIR/feature-flags.war${NC}"

# Paso 3: Limpiar todas las cachés
echo -e "${BLUE}Paso 3: Limpiando todas las cachés...${NC}"
"$BASE_DIR/scripts/deploy/clear-all-caches.sh"

# Paso 4: Desplegar el archivo WAR
echo -e "${BLUE}Paso 4: Desplegando el archivo WAR...${NC}"
"$BASE_DIR/scripts/deploy/deploy-war.sh" "$DEPLOY_DIR/feature-flags.war"

# Paso 5: Verificar que la aplicación esté disponible
echo -e "${BLUE}Paso 5: Verificando que la aplicación esté disponible...${NC}"
echo -e "${YELLOW}Esperando 10 segundos para que la aplicación se despliegue...${NC}"
sleep 10

# Verificar la URL
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/feature-flags/)

if [ "$STATUS_CODE" == "200" ]; then
    echo -e "${GREEN}La aplicación feature-flags está disponible correctamente${NC}"
else
    echo -e "${RED}Error: La aplicación feature-flags no está disponible (código $STATUS_CODE)${NC}"
    echo -e "${YELLOW}Intenta acceder manualmente a http://localhost:8080/feature-flags/${NC}"
fi

echo ""
echo -e "${GREEN}=== Proceso completado ===${NC}"
echo ""
echo -e "Para acceder a la aplicación feature-flags:"
echo -e "${YELLOW}  http://localhost:8080/feature-flags/${NC}"
echo ""
echo -e "Para verificar todas las URLs:"
echo -e "${YELLOW}  ./scripts/check-urls.sh${NC}"
echo ""
