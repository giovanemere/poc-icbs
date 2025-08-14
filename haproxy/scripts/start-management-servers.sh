#!/bin/bash

# Script para iniciar los servidores de gestión de HAProxy
# API Server (puerto 9001) y Web UI Server (puerto 9002)

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_SERVER="$SCRIPT_DIR/api-server.py"
WEB_UI_SERVER="$SCRIPT_DIR/web-ui-server.py"

# PIDs de los procesos
API_PID_FILE="/tmp/haproxy-api-server.pid"
WEB_UI_PID_FILE="/tmp/haproxy-web-ui-server.pid"

# Función para iniciar servidores
start_servers() {
    echo -e "${BLUE}=== Iniciando Servidores de Gestión HAProxy ===${NC}"
    
    # Verificar que Python3 esté disponible
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Error: Python3 no está instalado${NC}"
        exit 1
    fi
    
    # Iniciar API Server
    echo -e "${YELLOW}Iniciando API Server (puerto 9001)...${NC}"
    python3 "$API_SERVER" &
    API_PID=$!
    echo $API_PID > "$API_PID_FILE"
    echo -e "${GREEN}✓ API Server iniciado (PID: $API_PID)${NC}"
    
    # Iniciar Web UI Server
    echo -e "${YELLOW}Iniciando Web UI Server (puerto 9002)...${NC}"
    python3 "$WEB_UI_SERVER" &
    WEB_UI_PID=$!
    echo $WEB_UI_PID > "$WEB_UI_PID_FILE"
    echo -e "${GREEN}✓ Web UI Server iniciado (PID: $WEB_UI_PID)${NC}"
    
    echo
    echo -e "${GREEN}🎉 Servidores de gestión iniciados exitosamente${NC}"
    echo -e "${BLUE}📡 API disponible en: http://localhost:8081/api/${NC}"
    echo -e "${BLUE}🌐 Web UI disponible en: http://localhost:8082/${NC}"
    echo
    echo -e "${YELLOW}Para detener los servidores, ejecute: $0 stop${NC}"
}

# Función para detener servidores
stop_servers() {
    echo -e "${BLUE}=== Deteniendo Servidores de Gestión HAProxy ===${NC}"
    
    # Detener API Server
    if [ -f "$API_PID_FILE" ]; then
        API_PID=$(cat "$API_PID_FILE")
        if kill -0 "$API_PID" 2>/dev/null; then
            kill "$API_PID"
            echo -e "${GREEN}✓ API Server detenido (PID: $API_PID)${NC}"
        fi
        rm -f "$API_PID_FILE"
    fi
    
    # Detener Web UI Server
    if [ -f "$WEB_UI_PID_FILE" ]; then
        WEB_UI_PID=$(cat "$WEB_UI_PID_FILE")
        if kill -0 "$WEB_UI_PID" 2>/dev/null; then
            kill "$WEB_UI_PID"
            echo -e "${GREEN}✓ Web UI Server detenido (PID: $WEB_UI_PID)${NC}"
        fi
        rm -f "$WEB_UI_PID_FILE"
    fi
    
    # Limpiar procesos huérfanos
    pkill -f "api-server.py" 2>/dev/null || true
    pkill -f "web-ui-server.py" 2>/dev/null || true
    
    echo -e "${GREEN}✓ Servidores de gestión detenidos${NC}"
}

# Función para verificar estado
check_status() {
    echo -e "${BLUE}=== Estado de Servidores de Gestión ===${NC}"
    
    # Verificar API Server
    if [ -f "$API_PID_FILE" ]; then
        API_PID=$(cat "$API_PID_FILE")
        if kill -0 "$API_PID" 2>/dev/null; then
            echo -e "${GREEN}✓ API Server ejecutándose (PID: $API_PID)${NC}"
            echo -e "  📡 http://localhost:8081/api/"
        else
            echo -e "${RED}❌ API Server no está ejecutándose${NC}"
        fi
    else
        echo -e "${RED}❌ API Server no está ejecutándose${NC}"
    fi
    
    # Verificar Web UI Server
    if [ -f "$WEB_UI_PID_FILE" ]; then
        WEB_UI_PID=$(cat "$WEB_UI_PID_FILE")
        if kill -0 "$WEB_UI_PID" 2>/dev/null; then
            echo -e "${GREEN}✓ Web UI Server ejecutándose (PID: $WEB_UI_PID)${NC}"
            echo -e "  🌐 http://localhost:8082/"
        else
            echo -e "${RED}❌ Web UI Server no está ejecutándose${NC}"
        fi
    else
        echo -e "${RED}❌ Web UI Server no está ejecutándose${NC}"
    fi
    
    # Verificar conectividad
    echo
    echo -e "${YELLOW}Verificando conectividad...${NC}"
    
    if curl -s http://localhost:8081/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API Server responde correctamente${NC}"
    else
        echo -e "${RED}❌ API Server no responde${NC}"
    fi
    
    if curl -s http://localhost:8082/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Web UI Server responde correctamente${NC}"
    else
        echo -e "${RED}❌ Web UI Server no responde${NC}"
    fi
}

# Función para reiniciar servidores
restart_servers() {
    echo -e "${BLUE}=== Reiniciando Servidores de Gestión ===${NC}"
    stop_servers
    sleep 2
    start_servers
}

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Gestión de Servidores HAProxy ===${NC}"
    echo
    echo -e "${YELLOW}Uso:${NC} $0 [COMANDO]"
    echo
    echo -e "${YELLOW}Comandos disponibles:${NC}"
    echo -e "  ${GREEN}start${NC}    - Iniciar servidores de gestión"
    echo -e "  ${GREEN}stop${NC}     - Detener servidores de gestión"
    echo -e "  ${GREEN}restart${NC}  - Reiniciar servidores de gestión"
    echo -e "  ${GREEN}status${NC}   - Ver estado de servidores"
    echo -e "  ${GREEN}help${NC}     - Mostrar esta ayuda"
    echo
    echo -e "${BLUE}URLs de acceso:${NC}"
    echo -e "  API REST:     http://localhost:8081/api/"
    echo -e "  Web UI:       http://localhost:8082/"
    echo -e "  HAProxy Stats: http://localhost:8404/stats"
}

# Función principal
main() {
    case "${1:-help}" in
        "start")
            start_servers
            ;;
        "stop")
            stop_servers
            ;;
        "restart")
            restart_servers
            ;;
        "status")
            check_status
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Manejar señales para limpieza
trap 'stop_servers; exit 0' SIGINT SIGTERM

# Ejecutar función principal
main "$@"
