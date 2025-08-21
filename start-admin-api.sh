#!/bin/bash

# Script para iniciar la API de administración HAProxy y el panel web

PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
API_FILE="$PROJECT_DIR/haproxy/admin-panel/api.py"
PANEL_FILE="$PROJECT_DIR/haproxy/admin-panel/serve-panel.py"
VENV_DIR="$PROJECT_DIR/haproxy-api-env"
API_PID_FILE="$PROJECT_DIR/haproxy-api.pid"
PANEL_PID_FILE="$PROJECT_DIR/haproxy-panel.pid"

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Iniciando HAProxy Deployment Manager...${NC}"

# Verificar si ya están corriendo
API_RUNNING=false
PANEL_RUNNING=false

if [ -f "$API_PID_FILE" ]; then
    API_PID=$(cat "$API_PID_FILE")
    if ps -p $API_PID > /dev/null 2>&1; then
        API_RUNNING=true
        echo -e "${YELLOW}⚠️  API ya está corriendo (PID: $API_PID)${NC}"
    else
        rm -f "$API_PID_FILE"
    fi
fi

if [ -f "$PANEL_PID_FILE" ]; then
    PANEL_PID=$(cat "$PANEL_PID_FILE")
    if ps -p $PANEL_PID > /dev/null 2>&1; then
        PANEL_RUNNING=true
        echo -e "${YELLOW}⚠️  Panel ya está corriendo (PID: $PANEL_PID)${NC}"
    else
        rm -f "$PANEL_PID_FILE"
    fi
fi

if [ "$API_RUNNING" = true ] && [ "$PANEL_RUNNING" = true ]; then
    echo -e "${GREEN}✅ Todos los servicios ya están corriendo${NC}"
    echo -e "${GREEN}📡 API disponible en: http://localhost:8093${NC}"
    echo -e "${GREEN}🎛️ Panel disponible en: http://localhost:8092/index-functional.html${NC}"
    exit 0
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
pip install flask requests flask-cors > /dev/null 2>&1

# Iniciar API si no está corriendo
if [ "$API_RUNNING" = false ]; then
    echo -e "${BLUE}🔧 Iniciando API de administración...${NC}"
    nohup python3 "$API_FILE" > haproxy-api.log 2>&1 &
    API_PID=$!
    echo $API_PID > "$API_PID_FILE"
    
    # Esperar un momento para que la API se inicie
    sleep 3
    
    if ps -p $API_PID > /dev/null 2>&1; then
        echo -e "${GREEN}✅ API iniciada correctamente (PID: $API_PID)${NC}"
    else
        echo -e "${RED}❌ Error al iniciar la API${NC}"
        rm -f "$API_PID_FILE"
        exit 1
    fi
fi

# Iniciar Panel si no está corriendo
if [ "$PANEL_RUNNING" = false ]; then
    echo -e "${BLUE}🎛️ Iniciando panel de administración...${NC}"
    nohup python3 "$PANEL_FILE" > haproxy-panel.log 2>&1 &
    PANEL_PID=$!
    echo $PANEL_PID > "$PANEL_PID_FILE"
    
    # Esperar un momento para que el panel se inicie
    sleep 3
    
    if ps -p $PANEL_PID > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Panel iniciado correctamente (PID: $PANEL_PID)${NC}"
    else
        echo -e "${RED}❌ Error al iniciar el panel${NC}"
        rm -f "$PANEL_PID_FILE"
        exit 1
    fi
fi

echo
echo -e "${GREEN}🎉 HAProxy Deployment Manager iniciado correctamente${NC}"
echo
echo -e "${BLUE}📋 URLs disponibles:${NC}"
echo -e "${GREEN}🎛️ Panel de Administración: http://localhost:8092/index-functional.html${NC}"
echo -e "${GREEN}📡 API de Administración:   http://localhost:8093${NC}"
echo -e "${GREEN}📊 HAProxy Stats:           http://localhost:8404/stats (admin/admin123)${NC}"
echo -e "${GREEN}🌐 Frontend Principal:      http://localhost:8100/${NC}"
echo
echo -e "${YELLOW}📝 Logs disponibles en:${NC}"
echo -e "   API: haproxy-api.log"
echo -e "   Panel: haproxy-panel.log"

# Probar conectividad
echo
echo -e "${BLUE}🧪 Probando conectividad...${NC}"
sleep 2

if curl -s http://localhost:8093/api/health > /dev/null; then
    echo -e "${GREEN}✅ API respondiendo correctamente${NC}"
else
    echo -e "${YELLOW}⚠️ API aún no responde (puede tardar unos segundos)${NC}"
fi

if curl -s http://localhost:8092/index-functional.html > /dev/null; then
    echo -e "${GREEN}✅ Panel web accesible${NC}"
else
    echo -e "${YELLOW}⚠️ Panel web aún no accesible${NC}"
fi

echo
echo -e "${GREEN}🚀 ¡Sistema listo para A/B Testing, Canary Deployment y Feature Flags!${NC}"
