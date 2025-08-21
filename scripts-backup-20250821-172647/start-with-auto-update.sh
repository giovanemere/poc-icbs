#!/bin/bash
#
# Script wrapper para iniciar docker-compose y actualizar automáticamente HAProxy
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
COMPOSE_FILE="$PROJECT_DIR/config/docker-compose.yml"

echo -e "${BLUE}=== Iniciando servicios con auto-actualización de HAProxy ===${NC}"

# Función para limpiar en caso de interrupción
cleanup() {
    echo -e "\n${YELLOW}Limpiando...${NC}"
    exit 0
}

# Capturar señales de interrupción
trap cleanup SIGINT SIGTERM

# Cambiar al directorio del proyecto
cd "$PROJECT_DIR" || {
    echo -e "${RED}Error: No se puede acceder al directorio del proyecto${NC}"
    exit 1
}

# Verificar que existe el archivo docker-compose
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: No se encuentra el archivo docker-compose.yml en $COMPOSE_FILE${NC}"
    exit 1
fi

# Parar servicios existentes si están corriendo
echo -e "${YELLOW}Deteniendo servicios existentes...${NC}"
docker-compose -f "$COMPOSE_FILE" down

# Iniciar los servicios
echo -e "${YELLOW}Iniciando servicios...${NC}"
docker-compose -f "$COMPOSE_FILE" up -d

# Verificar que los servicios se iniciaron correctamente
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Falló el inicio de los servicios${NC}"
    exit 1
fi

echo -e "${GREEN}Servicios iniciados correctamente${NC}"

# Esperar un momento para que los contenedores se estabilicen
echo -e "${YELLOW}Esperando a que los servicios se estabilicen...${NC}"
sleep 10

# Ejecutar el script de auto-actualización de HAProxy
echo -e "${YELLOW}Ejecutando auto-actualización de HAProxy...${NC}"
if [ -f "$PROJECT_DIR/scripts/auto-update-haproxy.sh" ]; then
    "$PROJECT_DIR/scripts/auto-update-haproxy.sh"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}=== Inicio completado exitosamente ===${NC}"
        echo -e "${BLUE}Servicios disponibles:${NC}"
        echo -e "  • WebLogic A: http://localhost:7001/console"
        echo -e "  • WebLogic B: http://localhost:7002/console"
        echo -e "  • HAProxy Load Balancer: http://localhost:8080"
        echo -e "  • HAProxy Stats: http://localhost:8404/stats"
        echo -e "  • HAProxy Admin UI: http://localhost:8082"
        echo -e "  • Oracle Database: localhost:1521 (XE)"
        echo -e "  • Oracle EM Express: https://localhost:5500/em"
        echo ""
        echo -e "${YELLOW}Para ver los logs en tiempo real:${NC}"
        echo -e "  docker-compose -f $COMPOSE_FILE logs -f"
        echo ""
        echo -e "${YELLOW}Para detener todos los servicios:${NC}"
        echo -e "  docker-compose -f $COMPOSE_FILE down"
    else
        echo -e "${RED}Error en la auto-actualización de HAProxy${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: No se encuentra el script de auto-actualización${NC}"
    exit 1
fi
