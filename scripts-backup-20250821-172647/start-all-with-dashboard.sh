#!/bin/bash

# Script de conveniencia para iniciar todos los servicios incluyendo el dashboard
# Autor: Sistema de Gestión de Tráfico
# Fecha: $(date)

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"

echo -e "${BLUE}=== Iniciando Entorno Completo con Dashboard ===${NC}"
echo

# Cambiar al directorio del proyecto
cd "$PROJECT_DIR"

# Función para mostrar estado
show_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        return 1
    fi
}

echo "1. Iniciando todos los servicios base..."
echo

# Iniciar todos los servicios
if ./start-with-images.sh start; then
    show_status 0 "Servicios base iniciados correctamente"
else
    show_status 1 "Error al iniciar servicios base"
    exit 1
fi

echo
echo "2. Verificando que el dashboard esté incluido..."
echo

# Verificar que el dashboard esté ejecutándose
sleep 5
if docker ps | grep -q "dashboard"; then
    show_status 0 "Dashboard está ejecutándose"
else
    echo -e "${YELLOW}⚠${NC} Dashboard no detectado, iniciando específicamente..."
    if ./start-with-images.sh start dashboard; then
        show_status 0 "Dashboard iniciado correctamente"
    else
        show_status 1 "Error al iniciar dashboard"
    fi
fi

echo
echo "3. Verificando conectividad del dashboard..."
echo

# Esperar un momento para que los servicios estén completamente listos
echo "Esperando que los servicios estén completamente listos..."
sleep 10

# Verificar acceso directo al dashboard
if curl -s --max-time 10 http://localhost:8001/api/health >/dev/null 2>&1; then
    show_status 0 "Dashboard accesible directamente (puerto 8001)"
else
    show_status 1 "Dashboard NO accesible directamente"
fi

# Verificar acceso vía HAProxy
if curl -s --max-time 10 http://localhost:8080/dashboard/api/health >/dev/null 2>&1; then
    show_status 0 "Dashboard accesible vía HAProxy (puerto 8080/dashboard)"
else
    show_status 1 "Dashboard NO accesible vía HAProxy"
fi

echo
echo "4. Mostrando estado final de todos los servicios..."
echo

# Mostrar estado final
./start-with-images.sh status

echo
echo -e "${GREEN}=== Entorno Completo Iniciado Exitosamente ===${NC}"
echo
echo -e "${BLUE}=== URLs Principales ===${NC}"
echo -e "🌐 HAProxy Frontend:           ${YELLOW}http://localhost:8080${NC}"
echo -e "📊 Dashboard Profesional:      ${YELLOW}http://localhost:8080/dashboard/${NC}"
echo -e "📈 HAProxy Stats:              ${YELLOW}http://localhost:8404/stats${NC}"
echo -e "⚙️  HAProxy Admin UI:           ${YELLOW}http://localhost:8082${NC}"
echo -e "🔧 Dashboard Directo:          ${YELLOW}http://localhost:8001/${NC}"
echo
echo -e "${BLUE}=== Consolas de Administración ===${NC}"
echo -e "🅰️  WebLogic A:                 ${YELLOW}http://localhost:7001/console${NC}"
echo -e "🅱️  WebLogic B:                 ${YELLOW}http://localhost:7002/console${NC}"
echo -e "🚩 WebLogic Feature Flags:     ${YELLOW}http://localhost:7003/console${NC}"
echo -e "🗄️  Oracle Database EM:         ${YELLOW}http://localhost:5500/em${NC}"
echo
echo -e "${BLUE}=== Aplicaciones de Prueba ===${NC}"
echo -e "🔄 Version A:                  ${YELLOW}http://localhost:8080/version-a/${NC}"
echo -e "🔄 Version B:                  ${YELLOW}http://localhost:8080/version-b/${NC}"
echo -e "🚩 Feature Flags:              ${YELLOW}http://localhost:8080/feature-flags/${NC}"
echo -e "🧪 FF4J Simple:                ${YELLOW}http://localhost:8080/ff4j-simple/${NC}"
echo
echo -e "${YELLOW}💡 Comandos útiles:${NC}"
echo -e "   Ver logs del dashboard:     ${BLUE}./start-with-images.sh logs dashboard${NC}"
echo -e "   Probar dashboard completo:  ${BLUE}./scripts/test-dashboard.sh${NC}"
echo -e "   Ver estado de servicios:    ${BLUE}./start-with-images.sh status${NC}"
echo -e "   Reiniciar solo dashboard:   ${BLUE}./start-with-images.sh restart dashboard${NC}"
echo
