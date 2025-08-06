#!/bin/bash
# Script wrapper para iniciar docker-compose y actualizar automáticamente HAProxy

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)"

echo -e "${BLUE}=== Iniciando servicios con auto-actualización de HAProxy ===${NC}"

# Función para limpiar en caso de interrupción
cleanup() {
    echo -e "\n${YELLOW}Limpiando...${NC}"
    exit 0
}

# Capturar señales de interrupción
trap cleanup SIGINT SIGTERM

# Cargar variables de entorno
echo -e "${YELLOW}Cargando variables de entorno...${NC}"
source "$PROJECT_ROOT/scripts/core/load-env.sh"
load_env

echo -e "${GREEN}Variables de entorno cargadas correctamente${NC}"

# Parar servicios existentes si están corriendo
echo -e "${YELLOW}Deteniendo servicios existentes...${NC}"
"$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" down

# Iniciar los servicios
echo -e "${YELLOW}Iniciando servicios...${NC}"
"$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" up -d

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
if [ -f "$PROJECT_ROOT/scripts/maintenance/auto-update-haproxy.sh" ]; then
    "$PROJECT_ROOT/scripts/maintenance/auto-update-haproxy.sh"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Auto-actualización de HAProxy completada${NC}"
    else
        echo -e "${RED}Error en la auto-actualización de HAProxy${NC}"
        # No salir aquí, continuar con port-forwards
    fi
else
    echo -e "${YELLOW}Script de auto-actualización no encontrado, continuando...${NC}"
fi

# Iniciar port-forwards de Minikube si está disponible
echo ""
echo -e "${BLUE}=== Verificando Minikube ===${NC}"
if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
    echo -e "${YELLOW}Minikube detectado, iniciando port-forwards...${NC}"
    if [ -f "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" ]; then
        "$PROJECT_ROOT/scripts/services/minikube-port-forwards.sh" start
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Port-forwards de Minikube iniciados${NC}"
        else
            echo -e "${YELLOW}Algunos port-forwards de Minikube fallaron (normal si los servicios no existen)${NC}"
        fi
    else
        echo -e "${YELLOW}Script de port-forwards no encontrado${NC}"
    fi
else
    echo -e "${YELLOW}Minikube no está corriendo o no está instalado${NC}"
    echo -e "${YELLOW}Solo se iniciaron los servicios Docker${NC}"
fi

echo ""
echo -e "${GREEN}=== Inicio completado ===${NC}"
echo -e "${BLUE}Servicios Docker disponibles:${NC}"
echo -e "  • WebLogic A: http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/console"
echo -e "  • WebLogic B: http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/console"
echo -e "  • HAProxy Load Balancer: http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}"
echo -e "  • HAProxy Stats: http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
echo -e "  • HAProxy Admin UI: http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}"
echo -e "  • Oracle Database: localhost:${ORACLE_EXTERNAL_PORT:-1521} (XE)"
echo -e "  • Oracle EM Express: https://localhost:${ORACLE_EM_EXTERNAL_PORT:-5500}/em"
echo -e "  • Documentación: http://localhost:${MKDOCS_EXTERNAL_PORT:-8000}/"

if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
    echo ""
    echo -e "${BLUE}Servicios Minikube (si están disponibles):${NC}"
    echo -e "  • Backstage: http://localhost:3000"
    echo -e "  • Backstage Simple: http://localhost:3001"
    echo -e "  • Jenkins: http://localhost:8090"
    echo -e "  • Kubernetes Dashboard: http://localhost:8443"
fi

echo ""
echo -e "${YELLOW}Para ver los logs en tiempo real:${NC}"
echo -e "  ./scripts/core/docker-compose-wrapper.sh logs -f"
echo ""
echo -e "${YELLOW}Para detener todos los servicios:${NC}"
echo -e "  ./manage-services.sh stop"
