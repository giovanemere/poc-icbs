#!/bin/bash

# Script para compilar y desplegar la aplicación feature-flags

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Compilando la aplicación feature-flags...${NC}"

# Directorio del proyecto
PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/war-projects/feature-flags"

# Directorio de despliegue
DEPLOY_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/deploy"

# Compilar el proyecto con Maven
cd "$PROJECT_DIR" || { echo -e "${RED}Error: No se pudo acceder al directorio del proyecto${NC}"; exit 1; }

# Compilar con Maven
mvn clean package || { echo -e "${RED}Error: Falló la compilación con Maven${NC}"; exit 1; }

# Copiar el archivo WAR al directorio de despliegue
cp target/feature-flags.war "$DEPLOY_DIR/" || { echo -e "${RED}Error: No se pudo copiar el archivo WAR${NC}"; exit 1; }

echo -e "${GREEN}Aplicación feature-flags compilada y copiada a $DEPLOY_DIR/feature-flags.war${NC}"

# Desplegar en WebLogic
echo -e "${YELLOW}Desplegando en WebLogic...${NC}"

# Copiar al directorio autodeploy de WebLogic
docker cp "$DEPLOY_DIR/feature-flags.war" weblogic-a:/u01/oracle/user_projects/domains/base_domain/autodeploy/
docker cp "$DEPLOY_DIR/feature-flags.war" weblogic-b:/u01/oracle/user_projects/domains/base_domain/autodeploy/

echo -e "${GREEN}Aplicación feature-flags desplegada en WebLogic A y B${NC}"
echo -e "${YELLOW}Espere unos momentos mientras WebLogic procesa el despliegue...${NC}"

# Esperar a que se complete el despliegue
sleep 10

echo -e "${GREEN}¡Despliegue completado!${NC}"
echo -e "Acceda a la aplicación en: ${YELLOW}http://localhost:8080/feature-flags/${NC}"
