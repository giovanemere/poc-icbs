#!/bin/bash

# Script de gestión completo para el Panel de Administración HAProxy

PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
PID_FILE="$PROJECT_DIR/haproxy-api.pid"

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${BLUE}🎛️  Panel de Administración HAProxy - Gestión${NC}"
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo -e "  ${GREEN}start${NC}     - Iniciar la API y el panel de administración"
    echo -e "  ${RED}stop${NC}      - Detener la API"
    echo -e "  ${YELLOW}restart${NC}   - Reiniciar la API"
    echo -e "  ${CYAN}status${NC}    - Ver el estado de la API y servicios"
    echo -e "  ${BLUE}test${NC}      - Probar la funcionalidad de la API"
    echo -e "  ${GREEN}urls${NC}     - Mostrar todas las URLs importantes"
    echo -e "  ${YELLOW}logs${NC}     - Ver los logs de la API"
    echo ""
    echo "Ejemplos:"
    echo "  $0 start    # Iniciar todo"
    echo "  $0 status   # Ver estado"
    echo "  $0 test     # Probar API"
    echo ""
}

show_urls() {
    echo -e "${BLUE}🌐 URLs del Sistema${NC}"
    echo ""
    echo -e "${GREEN}Panel de Administración HAProxy (Funcional):${NC}"
    echo "  http://localhost:8092/index-functional.html"
    echo ""
    echo -e "${GREEN}Panel de Administración HAProxy (Original):${NC}"
    echo "  http://localhost:8092/"
    echo ""
    echo -e "${GREEN}API de Administración:${NC}"
    echo "  http://localhost:8093/api/health"
    echo "  http://localhost:8093/api/status"
    echo ""
    echo -e "${GREEN}Estadísticas HAProxy:${NC}"
    echo "  http://localhost:8404/stats (admin/admin123)"
    echo ""
    echo -e "${GREEN}Frontend Principal:${NC}"
    echo "  http://localhost:8100/"
    echo ""
    echo -e "${GREEN}Aplicaciones de Prueba:${NC}"
    echo "  http://localhost:8100/version-a/"
    echo "  http://localhost:8100/version-b/"
    echo "  http://localhost:8100/feature-flags/"
    echo "  http://localhost:8100/ff4j-simple/"
    echo ""
}

check_api_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            return 0  # API corriendo
        else
            rm -f "$PID_FILE"
            return 1  # API no corriendo
        fi
    else
        return 1  # No hay PID file
    fi
}

test_api() {
    echo -e "${BLUE}🧪 Probando funcionalidad de la API...${NC}"
    echo ""
    
    # Test 1: Health check
    echo -e "${CYAN}1. Health Check:${NC}"
    if curl -s http://localhost:8093/api/health > /dev/null; then
        echo -e "   ${GREEN}✅ API respondiendo${NC}"
    else
        echo -e "   ${RED}❌ API no responde${NC}"
        return 1
    fi
    
    # Test 2: Status
    echo -e "${CYAN}2. Estado del Sistema:${NC}"
    STATUS=$(curl -s http://localhost:8093/api/status)
    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Estado obtenido correctamente${NC}"
        echo "   $STATUS" | jq . 2>/dev/null || echo "   $STATUS"
    else
        echo -e "   ${RED}❌ Error al obtener estado${NC}"
    fi
    
    # Test 3: Configuración A/B
    echo -e "${CYAN}3. Configuración A/B Testing:${NC}"
    AB_RESULT=$(curl -s -X POST -H "Content-Type: application/json" \
        -d '{"enabled":true,"version_a_percentage":70}' \
        http://localhost:8093/api/ab-testing)
    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ A/B Testing configurado${NC}"
        echo "   $AB_RESULT" | jq . 2>/dev/null || echo "   $AB_RESULT"
    else
        echo -e "   ${RED}❌ Error en configuración A/B${NC}"
    fi
    
    # Test 4: Configuración Canary
    echo -e "${CYAN}4. Configuración Canary:${NC}"
    CANARY_RESULT=$(curl -s -X POST -H "Content-Type: application/json" \
        -d '{"enabled":true,"percentage":15}' \
        http://localhost:8093/api/canary)
    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✅ Canary Deployment configurado${NC}"
        echo "   $CANARY_RESULT" | jq . 2>/dev/null || echo "   $CANARY_RESULT"
    else
        echo -e "   ${RED}❌ Error en configuración Canary${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Pruebas completadas${NC}"
}

show_status() {
    echo -e "${BLUE}📊 Estado del Sistema${NC}"
    echo ""
    
    # Estado de la API
    if check_api_status; then
        PID=$(cat "$PID_FILE")
        echo -e "${GREEN}✅ API de Administración: CORRIENDO (PID: $PID)${NC}"
    else
        echo -e "${RED}❌ API de Administración: DETENIDA${NC}"
    fi
    
    # Estado de HAProxy
    if curl -s http://localhost:8404/stats > /dev/null 2>&1; then
        echo -e "${GREEN}✅ HAProxy: CORRIENDO${NC}"
    else
        echo -e "${RED}❌ HAProxy: NO ACCESIBLE${NC}"
    fi
    
    # Estado de WebLogic A
    if curl -s http://localhost:7001/console > /dev/null 2>&1; then
        echo -e "${GREEN}✅ WebLogic A: CORRIENDO${NC}"
    else
        echo -e "${RED}❌ WebLogic A: NO ACCESIBLE${NC}"
    fi
    
    # Estado de WebLogic B
    if curl -s http://localhost:7002/console > /dev/null 2>&1; then
        echo -e "${GREEN}✅ WebLogic B: CORRIENDO${NC}"
    else
        echo -e "${RED}❌ WebLogic B: NO ACCESIBLE${NC}"
    fi
    
    echo ""
}

show_logs() {
    LOG_FILE="$PROJECT_DIR/haproxy-api.log"
    if [ -f "$LOG_FILE" ]; then
        echo -e "${BLUE}📝 Últimas 20 líneas del log:${NC}"
        echo ""
        tail -20 "$LOG_FILE"
    else
        echo -e "${YELLOW}⚠️  No se encontró archivo de log${NC}"
    fi
}

case "$1" in
    start)
        echo -e "${BLUE}🚀 Iniciando Panel de Administración HAProxy...${NC}"
        "$PROJECT_DIR/start-admin-api.sh"
        echo ""
        show_urls
        ;;
    stop)
        echo -e "${RED}🛑 Deteniendo Panel de Administración HAProxy...${NC}"
        "$PROJECT_DIR/stop-admin-api.sh"
        ;;
    restart)
        echo -e "${YELLOW}🔄 Reiniciando Panel de Administración HAProxy...${NC}"
        "$PROJECT_DIR/stop-admin-api.sh"
        sleep 2
        "$PROJECT_DIR/start-admin-api.sh"
        echo ""
        show_urls
        ;;
    status)
        show_status
        ;;
    test)
        if check_api_status; then
            test_api
        else
            echo -e "${RED}❌ La API no está corriendo. Usa '$0 start' para iniciarla.${NC}"
        fi
        ;;
    urls)
        show_urls
        ;;
    logs)
        show_logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Comando no reconocido: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
