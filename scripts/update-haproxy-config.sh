#!/bin/bash
#
# Script para actualizar la configuración de HAProxy
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Actualizando configuración de HAProxy ===${NC}"

# Verificar si el contenedor de HAProxy está en ejecución
if ! docker ps | grep -q haproxy; then
    echo -e "${RED}El contenedor HAProxy no está en ejecución${NC}"
    exit 1
fi

# Hacer una copia de seguridad de la configuración actual
echo -e "${YELLOW}Haciendo copia de seguridad de la configuración actual...${NC}"
cp -f /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/config/haproxy.cfg /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/config/haproxy.cfg.bak

# Copiar la nueva configuración
echo -e "${YELLOW}Copiando la nueva configuración...${NC}"
cp -f /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/config/haproxy-fixed.cfg /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/config/haproxy.cfg

# Reiniciar el contenedor HAProxy
echo -e "${YELLOW}Reiniciando el contenedor HAProxy...${NC}"
docker restart haproxy

echo -e "${GREEN}=== Configuración actualizada ===${NC}"
echo -e "${YELLOW}La configuración anterior se ha guardado en: /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/config/haproxy.cfg.bak${NC}"
echo -e "${YELLOW}El dashboard de HAProxy estará disponible en: http://localhost:8082${NC}"
echo -e "${YELLOW}El estado de las URLs estará disponible en: http://localhost:8082/url-status${NC}"
