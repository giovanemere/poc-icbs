#!/bin/bash
# Script para compilar y desplegar la aplicación feature-flags

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directorio del proyecto
PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/war-projects/feature-flags"
DEPLOY_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/deploy"
ROOT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"

echo -e "${YELLOW}Compilando la aplicación feature-flags...${NC}"

# Navegar al directorio del proyecto
cd "$PROJECT_DIR" || { echo -e "${RED}Error: No se pudo acceder al directorio del proyecto${NC}"; exit 1; }

# Compilar con Maven
mvn clean package || { echo -e "${RED}Error: Falló la compilación con Maven${NC}"; exit 1; }

# Copiar el archivo WAR al directorio de despliegue
cp target/feature-flags.war "$DEPLOY_DIR/" || { echo -e "${RED}Error: No se pudo copiar el archivo WAR${NC}"; exit 1; }

echo -e "${GREEN}Aplicación feature-flags compilada y copiada a $DEPLOY_DIR/feature-flags.war${NC}"

# Navegar al directorio raíz
cd "$ROOT_DIR" || { echo -e "${RED}Error: No se pudo acceder al directorio raíz${NC}"; exit 1; }

# Preguntar si se desea hacer un redespliegue limpio
echo -e "${YELLOW}¿Deseas hacer un redespliegue limpio? (s/n)${NC}"
read -r response

if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
    echo -e "${YELLOW}Realizando redespliegue limpio...${NC}"
    ./scripts/deploy/clean-redeploy.sh feature-flags
else
    echo -e "${YELLOW}Realizando despliegue normal...${NC}"
    ./scripts/deploy/deploy-war.sh deploy/feature-flags.war
fi

echo -e "${GREEN}¡Proceso completado!${NC}"
echo -e "Accede a la aplicación en: ${YELLOW}http://localhost:8080/feature-flags/${NC}"
