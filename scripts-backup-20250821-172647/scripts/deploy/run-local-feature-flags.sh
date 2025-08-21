#!/bin/bash
# Script para ejecutar la aplicación feature-flags localmente

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directorio del proyecto
ROOT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"

echo -e "${YELLOW}Iniciando la aplicación feature-flags localmente...${NC}"

# Crear una versión simple de feature-flags
echo -e "${YELLOW}Creando una versión simple de feature-flags...${NC}"
$ROOT_DIR/scripts/deploy/create-simple-feature-flags.sh

# Crear un servidor web simple con Python
echo -e "${GREEN}Iniciando servidor web en el puerto 9090...${NC}"
echo -e "${GREEN}La aplicación estará disponible en: http://localhost:9090/feature-flags/${NC}"
echo -e "${YELLOW}Presiona Ctrl+C para detener el servidor${NC}"

# Crear un directorio temporal para el servidor
TEMP_DIR=$(mktemp -d)
mkdir -p $TEMP_DIR/feature-flags

# Extraer el WAR al directorio temporal
cd $TEMP_DIR
jar -xf $ROOT_DIR/deploy/feature-flags.war -C feature-flags

# Iniciar el servidor web
cd $TEMP_DIR
python3 -m http.server 9090
