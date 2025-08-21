#!/bin/bash
#
# Script maestro para limpiar todas las cachés
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Limpiando todas las cachés del sistema ===${NC}"
echo ""

# Obtener el directorio del script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Limpiar caché de HAProxy
echo -e "${BLUE}Paso 1: Limpiando caché de HAProxy${NC}"
$SCRIPT_DIR/clear-haproxy-cache.sh
echo ""

# Limpiar caché de WebLogic (sin preguntar por reinicio)
echo -e "${BLUE}Paso 2: Limpiando caché de WebLogic${NC}"
echo "n" | $SCRIPT_DIR/clear-weblogic-cache.sh "$1"
echo ""

# Generar herramienta para limpiar caché de navegadores
echo -e "${BLUE}Paso 3: Generando herramienta para limpiar caché de navegadores${NC}"
$SCRIPT_DIR/clear-browser-cache.sh
echo ""

# Preguntar si se desea reiniciar los contenedores
read -p "¿Desea reiniciar todos los contenedores? (s/n): " restart_containers

if [[ $restart_containers =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Reiniciando todos los contenedores...${NC}"
    
    # Reiniciar HAProxy
    if docker ps | grep -q haproxy; then
        echo -e "${YELLOW}Reiniciando HAProxy...${NC}"
        docker restart haproxy
    fi
    
    # Reiniciar WebLogic
    if docker ps | grep -q weblogic-a; then
        echo -e "${YELLOW}Reiniciando weblogic-a...${NC}"
        docker restart weblogic-a
    fi
    
    if docker ps | grep -q weblogic-b; then
        echo -e "${YELLOW}Reiniciando weblogic-b...${NC}"
        docker restart weblogic-b
    fi
    
    echo -e "${YELLOW}Esperando a que los contenedores se inicien...${NC}"
    sleep 30
    
    # Verificar estado de los contenedores
    echo -e "${YELLOW}Verificando estado de los contenedores...${NC}"
    docker ps
else
    echo -e "${YELLOW}No se reiniciarán los contenedores${NC}"
fi

echo -e "${GREEN}=== Limpieza de todas las cachés completada ===${NC}"
echo ""
echo -e "Para verificar que todo funciona correctamente, ejecute:"
echo -e "${YELLOW}  ./scripts/check-urls.sh${NC}"
echo ""
echo -e "Para limpiar la caché del navegador, abra la herramienta generada:"
echo -e "${YELLOW}  cd deploy/cache-cleaner && ./open-cleaner.sh${NC}"
echo ""
