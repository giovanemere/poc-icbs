#!/bin/bash

# Script integrado para iniciar servicios como lo solicitaste
# Equivale a: cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start-with-images.sh start ./start-with-images.sh start dashboard

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Ejecutando Comando Integrado ===${NC}"
echo

# Cambiar al directorio del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

echo -e "${BLUE}Directorio actual: $(pwd)${NC}"
echo

# Ejecutar el comando completo usando el nuevo comando 'full'
echo -e "${BLUE}Ejecutando: ./start-with-images.sh full${NC}"
echo

./start-with-images.sh full

echo
echo -e "${GREEN}=== Comando Integrado Completado ===${NC}"
echo -e "${YELLOW}Equivale a tu comando original:${NC}"
echo -e "${YELLOW}cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start-with-images.sh start && ./start-with-images.sh start dashboard${NC}"
