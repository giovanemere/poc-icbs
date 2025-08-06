#!/bin/bash
# Script para compilar y actualizar solo las clases de feature-flags sin redespliegue completo

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directorio del proyecto
PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/war-projects/feature-flags"
ROOT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"

echo -e "${YELLOW}Compilando la aplicación feature-flags...${NC}"

# Navegar al directorio del proyecto
cd "$PROJECT_DIR" || { echo -e "${RED}Error: No se pudo acceder al directorio del proyecto${NC}"; exit 1; }

# Compilar con Maven
mvn clean compile || { echo -e "${RED}Error: Falló la compilación con Maven${NC}"; exit 1; }

echo -e "${GREEN}Aplicación feature-flags compilada${NC}"

# Navegar al directorio raíz
cd "$ROOT_DIR" || { echo -e "${RED}Error: No se pudo acceder al directorio raíz${NC}"; exit 1; }

# Actualizar las clases
echo -e "${YELLOW}Actualizando clases en WebLogic...${NC}"
./scripts/deploy/update-classes.sh feature-flags

echo -e "${GREEN}¡Proceso completado!${NC}"
echo -e "Las clases se recargarán en la próxima solicitud a la aplicación"
echo -e "Accede a la aplicación en: ${YELLOW}http://localhost:8080/feature-flags/${NC}"
