#!/bin/bash

# Script que ejecuta exactamente tu comando original:
# cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start-with-images.sh start ./start-with-images.sh start dashboard

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Ejecutando Comando Original Paso a Paso ===${NC}"
echo

# Paso 1: Cambiar al directorio
echo -e "${BLUE}Paso 1: Cambiando al directorio del proyecto...${NC}"
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
echo -e "${GREEN}✓ Directorio actual: $(pwd)${NC}"
echo

# Paso 2: Ejecutar start general
echo -e "${BLUE}Paso 2: Ejecutando ./start-with-images.sh start${NC}"
if ./start-with-images.sh start; then
    echo -e "${GREEN}✓ Comando 'start' ejecutado exitosamente${NC}"
else
    echo -e "${RED}✗ Error en comando 'start'${NC}"
    exit 1
fi

echo
echo -e "${YELLOW}Esperando 5 segundos antes del siguiente comando...${NC}"
sleep 5

# Paso 3: Ejecutar start dashboard específico
echo
echo -e "${BLUE}Paso 3: Ejecutando ./start-with-images.sh start dashboard${NC}"
if ./start-with-images.sh start dashboard; then
    echo -e "${GREEN}✓ Comando 'start dashboard' ejecutado exitosamente${NC}"
else
    echo -e "${RED}✗ Error en comando 'start dashboard'${NC}"
    exit 1
fi

echo
echo -e "${GREEN}=== Comando Original Completado Exitosamente ===${NC}"
echo
echo -e "${BLUE}Comando ejecutado:${NC}"
echo -e "${YELLOW}cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start-with-images.sh start && ./start-with-images.sh start dashboard${NC}"
echo
echo -e "${BLUE}Estado final de los servicios:${NC}"
./start-with-images.sh status
