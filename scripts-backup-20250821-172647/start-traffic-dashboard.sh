#!/bin/bash

# Script para iniciar el Dashboard de Tráfico WebLogic

PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
TRAFFIC_API_FILE="$PROJECT_DIR/haproxy/dashboard/traffic-api.py"
VENV_DIR="$PROJECT_DIR/haproxy-api-env"
TRAFFIC_PID_FILE="$PROJECT_DIR/traffic-dashboard.pid"

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Iniciando Dashboard de Tráfico WebLogic...${NC}"

# Verificar si ya está corriendo
if [ -f "$TRAFFIC_PID_FILE" ]; then
    TRAFFIC_PID=$(cat "$TRAFFIC_PID_FILE")
    if ps -p $TRAFFIC_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Dashboard de Tráfico ya está corriendo (PID: $TRAFFIC_PID)${NC}"
        echo -e "${GREEN}📊 Dashboard disponible en: http://localhost:8084${NC}"
        echo -e "${GREEN}📡 API disponible en: http://localhost:8084/api/stats${NC}"
        exit 0
    else
        rm -f "$TRAFFIC_PID_FILE"
    fi
fi

cd "$PROJECT_DIR"

# Crear entorno virtual si no existe
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${BLUE}📦 Creando entorno virtual...${NC}"
    python3 -m venv "$VENV_DIR"
fi

# Activar entorno virtual
source "$VENV_DIR/bin/activate"

# Instalar dependencias
echo -e "${BLUE}📦 Instalando dependencias...${NC}"
pip install flask requests flask-cors > /dev/null 2>&1

# Verificar que el archivo del dashboard existe
if [ ! -f "$PROJECT_DIR/haproxy/dashboard/traffic-dashboard.html" ]; then
    echo -e "${YELLOW}⚠️  Archivo traffic-dashboard.html no encontrado, creando versión básica...${NC}"
    # Aquí podríamos crear una versión básica si no existe
fi

# Iniciar Dashboard de Tráfico
echo -e "${BLUE}📊 Iniciando Dashboard de Tráfico...${NC}"
nohup python3 "$TRAFFIC_API_FILE" > traffic-dashboard.log 2>&1 &
TRAFFIC_PID=$!
echo $TRAFFIC_PID > "$TRAFFIC_PID_FILE"

# Esperar un momento para que el dashboard se inicie
sleep 3

if ps -p $TRAFFIC_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Dashboard de Tráfico iniciado correctamente (PID: $TRAFFIC_PID)${NC}"
else
    echo -e "${RED}❌ Error al iniciar el Dashboard de Tráfico${NC}"
    rm -f "$TRAFFIC_PID_FILE"
    exit 1
fi

echo
echo -e "${GREEN}🎉 Dashboard de Tráfico WebLogic iniciado correctamente${NC}"
echo
echo -e "${BLUE}📋 URLs disponibles:${NC}"
echo -e "${GREEN}📊 Dashboard de Tráfico:     http://localhost:8084${NC}"
echo -e "${GREEN}📡 API de Estadísticas:     http://localhost:8084/api/stats${NC}"
echo -e "${GREEN}🔧 API A/B Testing:         http://localhost:8084/api/ab/enable${NC}"
echo -e "${GREEN}🚀 API Canary Deployment:   http://localhost:8084/api/canary/enable${NC}"
echo
echo -e "${YELLOW}📝 Log disponible en: traffic-dashboard.log${NC}"

# Probar conectividad
echo
echo -e "${BLUE}🧪 Probando conectividad...${NC}"
sleep 2

if curl -s http://localhost:8084/api/health > /dev/null; then
    echo -e "${GREEN}✅ Dashboard respondiendo correctamente${NC}"
    
    # Mostrar estadísticas iniciales
    echo -e "${BLUE}📈 Estadísticas iniciales:${NC}"
    curl -s http://localhost:8084/api/stats | jq -r '
        "   🔄 RPS Actual: " + (.metrics.current_rps | tostring) +
        "\n   📊 Total Requests: " + (.metrics.total_requests | tostring) +
        "\n   ⏱️  Tiempo Respuesta: " + (.metrics.avg_response_time | tostring) + "ms" +
        "\n   🎯 A/B Testing: " + (if .deployment.ab_testing.enabled then "Activo" else "Inactivo" end) +
        "\n   🚀 Canary: " + (if .deployment.canary.enabled then "Activo" else "Inactivo" end)
    '
else
    echo -e "${YELLOW}⚠️ Dashboard aún no responde (puede tardar unos segundos)${NC}"
fi

echo
echo -e "${GREEN}🎛️ ¡Dashboard de Tráfico listo para análisis en tiempo real!${NC}"
echo -e "${BLUE}💡 Características:${NC}"
echo -e "   📈 Análisis de tráfico en tiempo real"
echo -e "   🎯 Gestión de A/B Testing"
echo -e "   🚀 Control de Canary Deployment"
echo -e "   📊 Estado de backends"
echo -e "   📡 API REST completa"
