#!/bin/bash
#
# Script para copiar check-urls.sh al contenedor de HAProxy
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Copiando check-urls.sh al contenedor de HAProxy ===${NC}"

# Verificar si el contenedor de HAProxy está en ejecución
if ! docker ps | grep -q haproxy; then
    echo -e "${RED}El contenedor HAProxy no está en ejecución${NC}"
    exit 1
fi

# Copiar el script al contenedor
echo -e "${YELLOW}Copiando scripts/check-urls.sh a /scripts/ en el contenedor haproxy...${NC}"
docker cp "$(dirname "$0")/check-urls.sh" haproxy:/scripts/

# Dar permisos de ejecución
echo -e "${YELLOW}Dando permisos de ejecución...${NC}"
docker exec haproxy chmod +x /scripts/check-urls.sh

echo -e "${GREEN}Script copiado correctamente${NC}"

# Copiar los scripts de Python actualizados
echo -e "${YELLOW}Copiando scripts de Python actualizados...${NC}"
docker cp "$(dirname "$0")/../haproxy/scripts/admin_api.py" haproxy:/scripts/
docker cp "$(dirname "$0")/../haproxy/scripts/admin_ui.py" haproxy:/scripts/
docker cp "$(dirname "$0")/../haproxy/scripts/url_status.py" haproxy:/scripts/
docker cp "$(dirname "$0")/../haproxy/scripts/templates/url_status.html" haproxy:/etc/haproxy/templates/

# Dar permisos de ejecución
echo -e "${YELLOW}Dando permisos de ejecución a los scripts de Python...${NC}"
docker exec haproxy chmod +x /scripts/admin_api.py /scripts/admin_ui.py /scripts/url_status.py

# Reiniciar el contenedor HAProxy
echo -e "${YELLOW}Reiniciando el contenedor HAProxy...${NC}"
docker restart haproxy

echo -e "${GREEN}=== Proceso completado ===${NC}"
echo -e "${YELLOW}El dashboard de HAProxy estará disponible en: http://localhost:8082${NC}"
echo -e "${YELLOW}El estado de las URLs estará disponible en: http://localhost:8082/url-status${NC}"
