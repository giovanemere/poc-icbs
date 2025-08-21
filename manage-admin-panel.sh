#!/bin/bash

# Script de gestión completo para el Panel de Administración HAProxy y Dashboard Unificado

PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
API_PID_FILE="$PROJECT_DIR/haproxy-api.pid"
PANEL_PID_FILE="$PROJECT_DIR/haproxy-panel.pid"
TRAFFIC_PID_FILE="$PROJECT_DIR/traffic-dashboard.pid"
UNIFIED_PID_FILE="$PROJECT_DIR/unified-dashboard.pid"

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${BLUE}🎛️  Dashboard Unificado - WebLogic Deployment Manager${NC}"
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos principales:"
    echo -e "  ${GREEN}start${NC}         - Iniciar sistema completo (API + Dashboard Unificado)"
    echo -e "  ${RED}stop${NC}          - Detener todos los servicios"
    echo -e "  ${YELLOW}restart${NC}       - Reiniciar todos los servicios"
    echo -e "  ${CYAN}status${NC}        - Ver el estado de todos los servicios"
    echo -e "  ${BLUE}test${NC}          - Probar funcionalidad completa (APIs + Dashboard)"
    echo -e "  ${GREEN}urls${NC}         - Mostrar todas las URLs importantes"
    echo -e "  ${YELLOW}logs${NC}         - Ver los logs de los servicios"
    echo ""
    echo "Comandos específicos:"
    echo -e "  ${PURPLE}unified${NC}       - Gestionar Dashboard Unificado"
    echo -e "  ${PURPLE}api${NC}          - Gestionar solo APIs"
    echo -e "  ${PURPLE}build${NC}        - Construir imágenes y WARs"
    echo -e "  ${PURPLE}deploy${NC}       - Desplegar aplicaciones"
    echo ""
    echo "Subcomandos para unified:"
    echo -e "  ${PURPLE}unified start${NC}  - Iniciar Dashboard Unificado"
    echo -e "  ${PURPLE}unified stop${NC}   - Detener Dashboard Unificado"
    echo -e "  ${PURPLE}unified test${NC}   - Probar Dashboard Unificado"
    echo -e "  ${PURPLE}unified fixed${NC}  - Usar versión corregida"
    echo ""
    echo "Subcomandos para build:"
    echo -e "  ${PURPLE}build images${NC}   - Construir imágenes Docker"
    echo -e "  ${PURPLE}build wars${NC}     - Construir archivos WAR"
    echo -e "  ${PURPLE}build all${NC}      - Construir todo"
    echo ""
    echo "URLs principales:"
    echo -e "  ${CYAN}Dashboard Unificado${NC}: http://localhost:8085/unified-dashboard-fixed.html"
    echo -e "  ${CYAN}Panel HAProxy${NC}:      http://localhost:8082"
    echo -e "  ${CYAN}API de Control${NC}:     http://localhost:8084/api"
    echo ""
    echo "Ejemplos:"
    echo "  $0 start           # Iniciar sistema completo"
    echo "  $0 unified fixed   # Usar dashboard corregido"
    echo "  $0 build all       # Construir imágenes y WARs"
    echo "  $0 test            # Probar funcionalidad completa"
    echo ""
}

show_urls() {
    echo -e "${BLUE}🌐 URLs del Sistema Completo${NC}"
    echo ""
    echo -e "${GREEN}🎛️ Dashboard Unificado (RECOMENDADO):${NC}"
    echo -e "  ${PURPLE}http://localhost:8085/unified-dashboard.html${NC}  ⭐ Dashboard Principal"
    echo -e "  ${CYAN}📊 Control A/B Testing + Canary + URLs Activas + Métricas${NC}"
    echo ""
    echo -e "${GREEN}📊 Dashboard de Tráfico WebLogic:${NC}"
    echo -e "  ${PURPLE}http://localhost:8084/${NC}                    📊 Dashboard de Tráfico"
    echo -e "  ${CYAN}http://localhost:8084/api/stats${NC}            📊 API de Estadísticas"
    echo -e "  ${CYAN}http://localhost:8084/api/health${NC}           🔍 Health Check"
    echo -e "  ${CYAN}http://localhost:8084/api/ab/enable${NC}        🎯 A/B Testing API"
    echo -e "  ${CYAN}http://localhost:8084/api/canary/enable${NC}    🚀 Canary Deployment API"
    echo -e "  ${CYAN}http://localhost:8084/api/reset${NC}            🔄 Reset Stats API"
    echo ""
    echo -e "${GREEN}🎛️ Panel de Administración HAProxy:${NC}"
    echo "  http://localhost:8092/index-functional.html"
    echo "  http://localhost:8092/"
    echo ""
    echo -e "${GREEN}📡 API de Administración:${NC}"
    echo "  http://localhost:8093/api/health"
    echo "  http://localhost:8093/api/status"
    echo ""
    echo -e "${GREEN}📈 Estadísticas HAProxy:${NC}"
    echo "  http://localhost:8404/stats (admin/admin123)"
    echo ""
    echo -e "${GREEN}🌐 Frontend Principal:${NC}"
    echo "  http://localhost:8100/"
    echo ""
    echo -e "${GREEN}🚀 Aplicaciones de Prueba:${NC}"
    echo "  http://localhost:8100/version-a/"
    echo "  http://localhost:8100/version-b/"
    echo "  http://localhost:8100/feature-flags/"
    echo "  http://localhost:8100/ff4j-simple/"
    echo ""
    echo -e "${GREEN}🔧 Consolas WebLogic:${NC}"
    echo "  http://localhost:7001/console (weblogic/welcome1)"
    echo "  http://localhost:7002/console (weblogic/welcome1)"
    echo ""
}

check_api_status() {
    if [ -f "$API_PID_FILE" ]; then
        PID=$(cat "$API_PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            return 0  # API corriendo
        else
            rm -f "$API_PID_FILE"
            return 1  # API no corriendo
        fi
    else
        return 1  # No hay PID file
    fi
}

check_panel_status() {
    if [ -f "$PANEL_PID_FILE" ]; then
        PID=$(cat "$PANEL_PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            return 0  # Panel corriendo
        else
            rm -f "$PANEL_PID_FILE"
            return 1  # Panel no corriendo
        fi
    else
        return 1  # No hay PID file
    fi
}

check_unified_status() {
    if [ -f "$UNIFIED_PID_FILE" ]; then
        PID=$(cat "$UNIFIED_PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            return 0  # Unified dashboard corriendo
        else
            rm -f "$UNIFIED_PID_FILE"
            return 1  # Unified dashboard no corriendo
        fi
    else
        return 1  # No hay PID file
    fi
}

check_traffic_status() {
    if [ -f "$TRAFFIC_PID_FILE" ]; then
        PID=$(cat "$TRAFFIC_PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            return 0  # Traffic dashboard corriendo
        else
            rm -f "$TRAFFIC_PID_FILE"
            return 1  # Traffic dashboard no corriendo
        fi
    else
        return 1  # No hay PID file
    fi
}

start_real_dashboard() {
    echo -e "${PURPLE}🚀 Iniciando Dashboard de Tráfico REAL...${NC}"
    
    # Verificar si ya está corriendo
    if check_traffic_status; then
        echo -e "${YELLOW}⚠️  Dashboard de Tráfico ya está corriendo${NC}"
        return 0
    fi
    
    # Verificar que el script existe
    if [ ! -f "$REAL_DASHBOARD_SCRIPT" ]; then
        echo -e "${RED}❌ Error: No se encontró el script del dashboard real en $REAL_DASHBOARD_SCRIPT${NC}"
        return 1
    fi
    
    # Verificar que HAProxy esté corriendo
    if ! curl -s -u admin:admin123 http://localhost:8404/stats > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  HAProxy no está accesible. El dashboard funcionará con funcionalidad limitada.${NC}"
    fi
    
    # Verificar que socat esté instalado en el contenedor HAProxy
    if ! docker exec haproxy which socat > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Instalando socat en contenedor HAProxy...${NC}"
        docker exec haproxy sh -c 'apt-get update && apt-get install -y socat' > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ socat instalado correctamente${NC}"
        else
            echo -e "${RED}❌ Error instalando socat. El dashboard tendrá funcionalidad limitada.${NC}"
        fi
    fi
    
    # Cambiar al directorio del proyecto
    cd "$PROJECT_DIR"
    
    # Iniciar el dashboard real
    echo -e "${CYAN}Iniciando dashboard real en puerto 8084...${NC}"
    nohup python3 "$REAL_DASHBOARD_SCRIPT" > "$PROJECT_DIR/real-dashboard.log" 2>&1 &
    DASHBOARD_PID=$!
    
    # Guardar PID
    echo $DASHBOARD_PID > "$TRAFFIC_PID_FILE"
    
    # Esperar un momento para verificar que se inició correctamente
    sleep 3
    
    if check_traffic_status; then
        echo -e "${GREEN}✅ Dashboard de Tráfico REAL iniciado correctamente (PID: $DASHBOARD_PID)${NC}"
        echo -e "${GREEN}📊 Disponible en: http://localhost:8084${NC}"
        
        # Verificar conectividad
        if curl -s http://localhost:8084/api/health > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Dashboard respondiendo correctamente${NC}"
            
            # Verificar conexión con HAProxy
            HEALTH_RESPONSE=$(curl -s http://localhost:8084/api/health)
            if echo "$HEALTH_RESPONSE" | grep -q '"haproxy_connected":true'; then
                echo -e "${GREEN}✅ Dashboard conectado con HAProxy${NC}"
            else
                echo -e "${YELLOW}⚠️  Dashboard iniciado pero con conexión limitada a HAProxy${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Dashboard iniciado pero no responde inmediatamente${NC}"
        fi
        
        return 0
    else
        echo -e "${RED}❌ Error: El dashboard no se inició correctamente${NC}"
        echo -e "${CYAN}Verificando logs...${NC}"
        if [ -f "$PROJECT_DIR/real-dashboard.log" ]; then
            tail -5 "$PROJECT_DIR/real-dashboard.log"
        fi
        return 1
    fi
}

test_api() {
    echo -e "${BLUE}🧪 Probando funcionalidad de las APIs...${NC}"
    echo ""
    
    # Test Dashboard de Tráfico REAL (Principal)
    echo -e "${PURPLE}=== Dashboard de Tráfico REAL (8084) ===${NC}"
    
    # Test 1: Health check
    echo -e "${CYAN}1. Health Check Dashboard Real:${NC}"
    HEALTH_RESPONSE=$(curl -s http://localhost:8084/api/health 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$HEALTH_RESPONSE" ]; then
        echo -e "   ${GREEN}✅ Dashboard Real respondiendo${NC}"
        if echo "$HEALTH_RESPONSE" | grep -q '"haproxy_connected":true'; then
            echo -e "   ${GREEN}✅ Conectado con HAProxy${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Conexión limitada con HAProxy${NC}"
        fi
    else
        echo -e "   ${RED}❌ Dashboard Real no responde${NC}"
        return 1
    fi
    
    # Test 2: Estadísticas reales
    echo -e "${CYAN}2. Estadísticas Reales de HAProxy:${NC}"
    STATS_RESPONSE=$(curl -s http://localhost:8084/api/stats 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$STATS_RESPONSE" ]; then
        echo -e "   ${GREEN}✅ Estadísticas obtenidas${NC}"
        # Verificar si hay datos de backends
        if echo "$STATS_RESPONSE" | grep -q '"backends"'; then
            echo -e "   ${GREEN}✅ Datos de backends disponibles${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Datos de backends limitados${NC}"
        fi
    else
        echo -e "   ${RED}❌ Error al obtener estadísticas${NC}"
    fi
    
    # Test 3: A/B Testing REAL
    echo -e "${CYAN}3. A/B Testing Real:${NC}"
    AB_RESULT=$(curl -s -X POST -H "Content-Type: application/json" \
        -d '{"percentage":75}' \
        http://localhost:8084/api/ab/apply 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$AB_RESULT" ]; then
        if echo "$AB_RESULT" | grep -q '"success":true'; then
            echo -e "   ${GREEN}✅ A/B Testing aplicado correctamente (75% A, 25% B)${NC}"
            
            # Verificar en HAProxy
            sleep 1
            HAPROXY_WEIGHTS=$(docker exec haproxy sh -c 'echo "show stat" | socat stdio /var/run/haproxy.sock 2>/dev/null' | grep "weblogic_main_backend,weblogic-" | cut -d, -f1,2,19 2>/dev/null)
            if [ -n "$HAPROXY_WEIGHTS" ]; then
                echo -e "   ${GREEN}✅ Pesos verificados en HAProxy:${NC}"
                echo "$HAPROXY_WEIGHTS" | while read line; do
                    echo -e "      ${CYAN}$line${NC}"
                done
            fi
        else
            echo -e "   ${YELLOW}⚠️  A/B Testing con errores: $AB_RESULT${NC}"
        fi
    else
        echo -e "   ${RED}❌ Error en A/B Testing${NC}"
    fi
    
    # Test 4: Canary Deployment REAL
    echo -e "${CYAN}4. Canary Deployment Real:${NC}"
    CANARY_RESULT=$(curl -s -X POST -H "Content-Type: application/json" \
        -d '{"percentage":20}' \
        http://localhost:8084/api/canary/apply 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$CANARY_RESULT" ]; then
        if echo "$CANARY_RESULT" | grep -q '"success":true'; then
            echo -e "   ${GREEN}✅ Canary Deployment aplicado correctamente (20% canary, 80% stable)${NC}"
            
            # Verificar en HAProxy
            sleep 1
            HAPROXY_WEIGHTS=$(docker exec haproxy sh -c 'echo "show stat" | socat stdio /var/run/haproxy.sock 2>/dev/null' | grep "weblogic_main_backend,weblogic-" | cut -d, -f1,2,19 2>/dev/null)
            if [ -n "$HAPROXY_WEIGHTS" ]; then
                echo -e "   ${GREEN}✅ Pesos verificados en HAProxy:${NC}"
                echo "$HAPROXY_WEIGHTS" | while read line; do
                    echo -e "      ${CYAN}$line${NC}"
                done
            fi
        else
            echo -e "   ${YELLOW}⚠️  Canary Deployment con errores: $CANARY_RESULT${NC}"
        fi
    else
        echo -e "   ${RED}❌ Error en Canary Deployment${NC}"
    fi
    
    # Test 5: Reset de pesos
    echo -e "${CYAN}5. Reset de Pesos:${NC}"
    RESET_RESULT=$(curl -s -X POST http://localhost:8084/api/reset 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$RESET_RESULT" ]; then
        if echo "$RESET_RESULT" | grep -q '"success":true'; then
            echo -e "   ${GREEN}✅ Pesos reseteados correctamente (50/50)${NC}"
            
            # Verificar en HAProxy
            sleep 1
            HAPROXY_WEIGHTS=$(docker exec haproxy sh -c 'echo "show stat" | socat stdio /var/run/haproxy.sock 2>/dev/null' | grep "weblogic_main_backend,weblogic-" | cut -d, -f1,2,19 2>/dev/null)
            if [ -n "$HAPROXY_WEIGHTS" ]; then
                echo -e "   ${GREEN}✅ Pesos verificados en HAProxy:${NC}"
                echo "$HAPROXY_WEIGHTS" | while read line; do
                    echo -e "      ${CYAN}$line${NC}"
                done
            fi
        else
            echo -e "   ${YELLOW}⚠️  Reset con errores: $RESET_RESULT${NC}"
        fi
    else
        echo -e "   ${RED}❌ Error en Reset${NC}"
    fi
    
    echo ""
    
    # Test API de Administración (si está disponible)
    if curl -s http://localhost:8093/api/health > /dev/null 2>&1; then
        echo -e "${CYAN}=== API de Administración (8093) ===${NC}"
        
        echo -e "${CYAN}6. Health Check API Admin:${NC}"
        if curl -s http://localhost:8093/api/health > /dev/null; then
            echo -e "   ${GREEN}✅ API Admin respondiendo${NC}"
        else
            echo -e "   ${RED}❌ API Admin no responde${NC}"
        fi
        
        echo -e "${CYAN}7. Estado del Sistema:${NC}"
        STATUS=$(curl -s http://localhost:8093/api/status 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$STATUS" ]; then
            echo -e "   ${GREEN}✅ Estado obtenido correctamente${NC}"
        else
            echo -e "   ${RED}❌ Error al obtener estado${NC}"
        fi
        echo ""
    fi
    
    echo -e "${GREEN}🎉 Pruebas completadas${NC}"
    echo -e "${YELLOW}💡 Tip: Visita http://localhost:8084 para usar el dashboard interactivo${NC}"
}

show_status() {
    echo -e "${BLUE}📊 Estado del Sistema Completo${NC}"
    echo ""
    
    # Estado del Dashboard Unificado (Principal)
    if check_unified_status; then
        PID=$(cat "$UNIFIED_PID_FILE")
        echo -e "${GREEN}✅ Dashboard Unificado: CORRIENDO (PID: $PID)${NC}"
        
        # Verificar conectividad del dashboard
        if curl -s http://localhost:8085/unified-dashboard.html > /dev/null 2>&1; then
            echo -e "${GREEN}   🎛️ Dashboard accesible en http://localhost:8085/unified-dashboard.html${NC}"
        else
            echo -e "${YELLOW}   ⚠️  Dashboard no responde${NC}"
        fi
    else
        echo -e "${RED}❌ Dashboard Unificado: DETENIDO${NC}"
    fi
    
    # Estado del Dashboard de Tráfico
    if check_traffic_status; then
        PID=$(cat "$TRAFFIC_PID_FILE")
        echo -e "${GREEN}✅ Dashboard de Tráfico: CORRIENDO (PID: $PID)${NC}"
        
        # Verificar conectividad del dashboard
        if curl -s http://localhost:8084/api/health > /dev/null 2>&1; then
            echo -e "${GREEN}   📊 Dashboard accesible en http://localhost:8084${NC}"
            
            # Verificar conexión con HAProxy
            HEALTH_RESPONSE=$(curl -s http://localhost:8084/api/health 2>/dev/null)
            if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
                echo -e "${GREEN}   🔗 API funcionando correctamente${NC}"
            else
                echo -e "${YELLOW}   ⚠️  API con funcionalidad limitada${NC}"
            fi
        else
            echo -e "${YELLOW}   ⚠️  Dashboard no responde${NC}"
        fi
    else
        echo -e "${RED}❌ Dashboard de Tráfico: DETENIDO${NC}"
    fi
    
    # Estado de la API de Administración
    if check_api_status; then
        PID=$(cat "$API_PID_FILE")
        echo -e "${GREEN}✅ API de Administración: CORRIENDO (PID: $PID)${NC}"
    else
        echo -e "${RED}❌ API de Administración: DETENIDA${NC}"
    fi
    
    # Estado del Panel Web
    if check_panel_status; then
        PID=$(cat "$PANEL_PID_FILE")
        echo -e "${GREEN}✅ Panel Web: CORRIENDO (PID: $PID)${NC}"
    else
        echo -e "${RED}❌ Panel Web: DETENIDO${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}🌐 Conectividad de Servicios:${NC}"
    
    # Estado de HAProxy
    if curl -s -u admin:admin123 http://localhost:8404/stats > /dev/null 2>&1; then
        echo -e "${GREEN}✅ HAProxy: CORRIENDO${NC}"
        
        # Mostrar pesos actuales si el dashboard está corriendo
        if check_traffic_status; then
            HAPROXY_WEIGHTS=$(docker exec haproxy sh -c 'echo "show stat" | socat stdio /var/run/haproxy.sock 2>/dev/null' | grep "weblogic_main_backend,weblogic-" | cut -d, -f1,2,19 2>/dev/null)
            if [ -n "$HAPROXY_WEIGHTS" ]; then
                echo -e "${CYAN}   📊 Pesos actuales:${NC}"
                echo "$HAPROXY_WEIGHTS" | while read line; do
                    echo -e "      ${CYAN}$line${NC}"
                done
            fi
        fi
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
    
    # Estado del Frontend
    if curl -s http://localhost:8100/ > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend Principal: CORRIENDO${NC}"
    else
        echo -e "${RED}❌ Frontend Principal: NO ACCESIBLE${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}💡 Tip: Usa '$0 test' para probar todas las funcionalidades${NC}"
}

show_logs() {
    echo -e "${BLUE}📝 Logs del Sistema${NC}"
    echo ""
    
    # Logs de API
    API_LOG_FILE="$PROJECT_DIR/haproxy-api.log"
    if [ -f "$API_LOG_FILE" ]; then
        echo -e "${CYAN}=== API de Administración (últimas 10 líneas) ===${NC}"
        tail -10 "$API_LOG_FILE"
        echo ""
    else
        echo -e "${YELLOW}⚠️  No se encontró log de API${NC}"
    fi
    
    # Logs de Panel
    PANEL_LOG_FILE="$PROJECT_DIR/haproxy-panel.log"
    if [ -f "$PANEL_LOG_FILE" ]; then
        echo -e "${CYAN}=== Panel Web (últimas 10 líneas) ===${NC}"
        tail -10 "$PANEL_LOG_FILE"
        echo ""
    else
        echo -e "${YELLOW}⚠️  No se encontró log de Panel${NC}"
    fi
    
    # Logs de Dashboard de Tráfico
    TRAFFIC_LOG_FILE="$PROJECT_DIR/traffic-dashboard.log"
    if [ -f "$TRAFFIC_LOG_FILE" ]; then
        echo -e "${CYAN}=== Dashboard de Tráfico (últimas 10 líneas) ===${NC}"
        tail -10 "$TRAFFIC_LOG_FILE"
        echo ""
    else
        echo -e "${YELLOW}⚠️  No se encontró log de Dashboard de Tráfico${NC}"
    fi
}

manage_traffic() {
    case "$1" in
        start)
            start_real_dashboard
            ;;
        stop)
            echo -e "${PURPLE}🛑 Deteniendo Dashboard de Tráfico REAL...${NC}"
            if check_traffic_status; then
                PID=$(cat "$TRAFFIC_PID_FILE")
                kill $PID 2>/dev/null
                rm -f "$TRAFFIC_PID_FILE"
                echo -e "${GREEN}✅ Dashboard de Tráfico REAL detenido${NC}"
            else
                echo -e "${YELLOW}⚠️  Dashboard de Tráfico no estaba corriendo${NC}"
            fi
            ;;
        test)
            echo -e "${PURPLE}🧪 Probando Dashboard de Tráfico REAL...${NC}"
            if check_traffic_status; then
                echo -e "${CYAN}Health Check:${NC}"
                HEALTH_RESPONSE=$(curl -s http://localhost:8084/api/health 2>/dev/null)
                if [ -n "$HEALTH_RESPONSE" ]; then
                    echo "$HEALTH_RESPONSE" | jq . 2>/dev/null || echo "$HEALTH_RESPONSE"
                    
                    if echo "$HEALTH_RESPONSE" | grep -q '"haproxy_connected":true'; then
                        echo -e "${GREEN}✅ Conectado con HAProxy${NC}"
                    else
                        echo -e "${YELLOW}⚠️  Conexión limitada con HAProxy${NC}"
                    fi
                else
                    echo -e "${RED}❌ No hay respuesta${NC}"
                fi
                
                echo ""
                echo -e "${CYAN}Estadísticas:${NC}"
                STATS_RESPONSE=$(curl -s http://localhost:8084/api/stats 2>/dev/null)
                if [ -n "$STATS_RESPONSE" ]; then
                    echo "$STATS_RESPONSE" | jq '.services' 2>/dev/null || echo "Error parsing JSON"
                else
                    echo -e "${RED}❌ Error obteniendo estadísticas${NC}"
                fi
            else
                echo -e "${RED}❌ Dashboard de Tráfico no está corriendo${NC}"
            fi
            ;;
        status)
            if check_traffic_status; then
                PID=$(cat "$TRAFFIC_PID_FILE")
                echo -e "${GREEN}✅ Dashboard de Tráfico REAL: CORRIENDO (PID: $PID)${NC}"
                echo -e "${GREEN}📊 URL: http://localhost:8084${NC}"
                
                # Verificar conectividad
                if curl -s http://localhost:8084/api/health > /dev/null 2>&1; then
                    echo -e "${GREEN}✅ Dashboard accesible${NC}"
                else
                    echo -e "${YELLOW}⚠️  Dashboard no responde${NC}"
                fi
            else
                echo -e "${RED}❌ Dashboard de Tráfico REAL: DETENIDO${NC}"
            fi
            ;;
        *)
            echo -e "${RED}❌ Comando traffic no reconocido: $1${NC}"
            echo "Uso: $0 traffic [start|stop|test|status]"
            ;;
    esac
}

manage_unified() {
    case "$1" in
        start)
            echo -e "${PURPLE}🎛️ Iniciando Dashboard Unificado...${NC}"
            start_unified_dashboard
            ;;
        fixed|corregido)
            echo -e "${PURPLE}🎛️ Iniciando Dashboard Unificado (Versión Corregida)...${NC}"
            start_unified_dashboard "fixed"
            ;;
        original)
            echo -e "${PURPLE}🎛️ Iniciando Dashboard Unificado (Versión Original)...${NC}"
            start_unified_dashboard "original"
            ;;
        simple|test)
            echo -e "${PURPLE}🎛️ Iniciando Dashboard Unificado (Versión Simple)...${NC}"
            start_unified_dashboard "simple"
            ;;
        stop)
            echo -e "${PURPLE}🛑 Deteniendo Dashboard Unificado...${NC}"
            if check_unified_status; then
                PID=$(cat "$UNIFIED_PID_FILE")
                kill $PID 2>/dev/null
                pkill -f "http.server 8085" 2>/dev/null || true
                rm -f "$UNIFIED_PID_FILE"
                echo -e "${GREEN}✅ Dashboard Unificado detenido${NC}"
            else
                echo -e "${YELLOW}⚠️  Dashboard Unificado no estaba corriendo${NC}"
            fi
            ;;
        test)
            echo -e "${PURPLE}🧪 Probando Dashboard Unificado...${NC}"
            if check_unified_status; then
                echo -e "${CYAN}Probando versiones disponibles:${NC}"
                
                # Probar versión corregida
                if curl -s http://localhost:8085/unified-dashboard-fixed.html | head -1 | grep -q "DOCTYPE"; then
                    echo -e "${GREEN}✅ Versión Corregida accesible${NC}"
                    echo -e "${GREEN}   🎛️ http://localhost:8085/unified-dashboard-fixed.html${NC}"
                else
                    echo -e "${RED}❌ Versión Corregida no accesible${NC}"
                fi
                
                # Probar versión original
                if curl -s http://localhost:8085/unified-dashboard.html | head -1 | grep -q "DOCTYPE"; then
                    echo -e "${GREEN}✅ Versión Original accesible${NC}"
                    echo -e "${GREEN}   🎛️ http://localhost:8085/unified-dashboard.html${NC}"
                else
                    echo -e "${YELLOW}⚠️ Versión Original no accesible${NC}"
                fi
                
                # Probar versión simple
                if curl -s http://localhost:8085/test-simple-functionality.html | head -1 | grep -q "DOCTYPE"; then
                    echo -e "${GREEN}✅ Versión Simple accesible${NC}"
                    echo -e "${GREEN}   🎛️ http://localhost:8085/test-simple-functionality.html${NC}"
                else
                    echo -e "${YELLOW}⚠️ Versión Simple no accesible${NC}"
                fi
                
            else
                echo -e "${RED}❌ Dashboard Unificado no está corriendo${NC}"
            fi
            ;;
        status)
            if check_unified_status; then
                PID=$(cat "$UNIFIED_PID_FILE")
                echo -e "${GREEN}✅ Dashboard Unificado: CORRIENDO (PID: $PID)${NC}"
                echo -e "${GREEN}📋 URLs Disponibles:${NC}"
                echo -e "${GREEN}   🎛️ Corregida: http://localhost:8085/unified-dashboard-fixed.html${NC}"
                echo -e "${YELLOW}   🎛️ Original:  http://localhost:8085/unified-dashboard.html${NC}"
                echo -e "${BLUE}   🎛️ Simple:    http://localhost:8085/test-simple-functionality.html${NC}"
            else
                echo -e "${RED}❌ Dashboard Unificado: DETENIDO${NC}"
            fi
            ;;
        *)
            echo -e "${RED}❌ Comando unified no reconocido: $1${NC}"
            echo "Uso: $0 unified [start|fixed|original|simple|stop|test|status]"
            echo ""
            echo "Versiones disponibles:"
            echo "  start    - Iniciar versión por defecto (corregida)"
            echo "  fixed    - Iniciar versión corregida (recomendada)"
            echo "  original - Iniciar versión original"
            echo "  simple   - Iniciar versión simple de prueba"
            ;;
    esac
}

start_unified_dashboard() {
    local version="${1:-fixed}"  # Por defecto usar versión corregida
    
    # Verificar si ya está corriendo
    if check_unified_status; then
        echo -e "${YELLOW}⚠️  Dashboard Unificado ya está corriendo${NC}"
        return 0
    fi
    
    # Determinar archivo a usar
    local dashboard_file
    case "$version" in
        "fixed"|"corregido")
            dashboard_file="unified-dashboard-fixed.html"
            ;;
        "original")
            dashboard_file="unified-dashboard.html"
            ;;
        "simple"|"test")
            dashboard_file="test-simple-functionality.html"
            ;;
        *)
            dashboard_file="unified-dashboard-fixed.html"
            ;;
    esac
    
    # Verificar que el archivo existe
    if [ ! -f "$PROJECT_DIR/$dashboard_file" ]; then
        echo -e "${RED}❌ Error: No se encontró $dashboard_file${NC}"
        echo -e "${YELLOW}💡 Archivos disponibles:${NC}"
        ls -la "$PROJECT_DIR"/*.html 2>/dev/null | grep -E "(unified|test)" || echo "   No hay archivos de dashboard"
        return 1
    fi
    
    # Limpiar puerto si está ocupado
    pkill -f "http.server 8085" 2>/dev/null || true
    fuser -k 8085/tcp 2>/dev/null || true
    
    # Esperar un momento
    sleep 2
    
    # Iniciar servidor HTTP simple
    cd "$PROJECT_DIR"
    nohup python3 -m http.server 8085 > unified-dashboard.log 2>&1 &
    UNIFIED_PID=$!
    echo $UNIFIED_PID > "$UNIFIED_PID_FILE"
    
    # Esperar y verificar
    sleep 3
    
    if ps -p $UNIFIED_PID > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Dashboard Unificado iniciado correctamente (PID: $UNIFIED_PID)${NC}"
        echo -e "${GREEN}🎛️ URL Principal: http://localhost:8085/$dashboard_file${NC}"
        
        # Mostrar URLs adicionales
        echo -e "${CYAN}📋 URLs Disponibles:${NC}"
        echo -e "   ${GREEN}Dashboard Corregido${NC}: http://localhost:8085/unified-dashboard-fixed.html"
        echo -e "   ${YELLOW}Dashboard Original${NC}:  http://localhost:8085/unified-dashboard.html"
        echo -e "   ${BLUE}Versión Simple${NC}:      http://localhost:8085/test-simple-functionality.html"
        
        return 0
    else
        echo -e "${RED}❌ Error al iniciar Dashboard Unificado${NC}"
        rm -f "$UNIFIED_PID_FILE"
        return 1
    fi
}

# Función para construir imágenes Docker
build_images() {
    echo -e "${BLUE}🐳 Construyendo imágenes Docker...${NC}"
    
    if [ -f "$PROJECT_DIR/build-latest.sh" ]; then
        cd "$PROJECT_DIR"
        echo -e "${CYAN}Ejecutando build-latest.sh...${NC}"
        ./build-latest.sh
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Imágenes Docker construidas exitosamente${NC}"
        else
            echo -e "${RED}❌ Error al construir imágenes Docker${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Script build-latest.sh no encontrado${NC}"
        return 1
    fi
}

# Función para construir archivos WAR
build_wars() {
    echo -e "${BLUE}📦 Construyendo archivos WAR...${NC}"
    
    if [ -f "$PROJECT_DIR/scripts/build/build-wars.sh" ]; then
        cd "$PROJECT_DIR"
        echo -e "${CYAN}Ejecutando build-wars.sh...${NC}"
        ./scripts/build/build-wars.sh
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Archivos WAR construidos exitosamente${NC}"
            echo -e "${CYAN}📋 Archivos generados:${NC}"
            ls -la "$PROJECT_DIR/deploy/"*.war 2>/dev/null || echo "   No se encontraron archivos WAR"
        else
            echo -e "${RED}❌ Error al construir archivos WAR${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Script build-wars.sh no encontrado${NC}"
        return 1
    fi
}

# Función para desplegar aplicaciones
deploy_applications() {
    echo -e "${BLUE}🚀 Desplegando aplicaciones...${NC}"
    
    if [ -f "$PROJECT_DIR/scripts/deploy/deploy-war.sh" ]; then
        cd "$PROJECT_DIR"
        echo -e "${CYAN}Desplegando todas las aplicaciones...${NC}"
        ./scripts/deploy/deploy-war.sh --all
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Aplicaciones desplegadas exitosamente${NC}"
        else
            echo -e "${RED}❌ Error al desplegar aplicaciones${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Script deploy-war.sh no encontrado${NC}"
        return 1
    fi
}

# Función para probar funcionalidad completa
test_complete_functionality() {
    echo -e "${BLUE}🧪 Probando funcionalidad completa...${NC}"
    echo ""
    
    # Probar Dashboard Unificado
    echo -e "${CYAN}1. Probando Dashboard Unificado...${NC}"
    if curl -s http://localhost:8085/unified-dashboard-fixed.html | head -1 | grep -q "DOCTYPE"; then
        echo -e "${GREEN}✅ Dashboard Unificado accesible${NC}"
    else
        echo -e "${RED}❌ Dashboard Unificado NO accesible${NC}"
    fi
    
    # Probar APIs
    echo -e "${CYAN}2. Probando APIs...${NC}"
    if curl -s http://localhost:8084/api/health | grep -q "healthy\|status"; then
        echo -e "${GREEN}✅ API de control accesible${NC}"
    else
        echo -e "${RED}❌ API de control NO accesible${NC}"
    fi
    
    # Probar HAProxy Stats
    echo -e "${CYAN}3. Probando HAProxy Stats...${NC}"
    if curl -s -u admin:admin123 http://localhost:8404/stats | grep -q "HAProxy"; then
        echo -e "${GREEN}✅ HAProxy Stats accesible${NC}"
    else
        echo -e "${RED}❌ HAProxy Stats NO accesible${NC}"
    fi
    
    # Probar aplicaciones principales
    echo -e "${CYAN}4. Probando aplicaciones principales...${NC}"
    local apps=("version-a" "version-b" "feature-flags")
    for app in "${apps[@]}"; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8100/$app/ | grep -q "200\|302"; then
            echo -e "${GREEN}✅ $app accesible${NC}"
        else
            echo -e "${YELLOW}⚠️ $app no accesible (puede ser normal si no está desplegada)${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}🎯 URLs principales para probar manualmente:${NC}"
    echo -e "   ${CYAN}Dashboard Unificado${NC}: http://localhost:8085/unified-dashboard-fixed.html"
    echo -e "   ${CYAN}Panel HAProxy${NC}:      http://localhost:8082"
    echo -e "   ${CYAN}API de Control${NC}:     http://localhost:8084/api"
    echo -e "   ${CYAN}HAProxy Stats${NC}:      http://localhost:8404/stats (admin/admin123)"
}

case "$1" in
    start)
        echo -e "${BLUE}🚀 Iniciando Sistema Completo de Administración...${NC}"
        echo ""
        
        # Verificar prerequisitos
        echo -e "${CYAN}0. Verificando prerequisitos...${NC}"
        
        # Verificar que HAProxy esté corriendo
        if ! curl -s -u admin:admin123 http://localhost:8404/stats > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  HAProxy no está accesible. Iniciando servicios con funcionalidad limitada.${NC}"
        else
            echo -e "${GREEN}✅ HAProxy accesible${NC}"
        fi
        
        # Verificar que Docker esté corriendo
        if ! docker ps > /dev/null 2>&1; then
            echo -e "${RED}❌ Docker no está accesible. Algunos servicios pueden no funcionar.${NC}"
        else
            echo -e "${GREEN}✅ Docker accesible${NC}"
        fi
        
        echo ""
        echo -e "${CYAN}1. Iniciando Dashboard Unificado (PRINCIPAL)...${NC}"
        start_unified_dashboard
        
        echo ""
        echo -e "${CYAN}2. Iniciando Dashboard de Tráfico...${NC}"
        start_real_dashboard
        
        echo ""
        echo -e "${CYAN}3. Iniciando API y Panel de Administración...${NC}"
        if [ -f "$PROJECT_DIR/start-admin-api.sh" ]; then
            "$PROJECT_DIR/start-admin-api.sh"
        else
            echo -e "${YELLOW}⚠️  Script start-admin-api.sh no encontrado. Saltando API de administración.${NC}"
        fi
        
        echo ""
        echo -e "${GREEN}🎉 Sistema completo iniciado${NC}"
        echo ""
        echo -e "${PURPLE}🎯 DASHBOARD PRINCIPAL:${NC}"
        echo -e "${GREEN}   🎛️ http://localhost:8085/unified-dashboard.html${NC}"
        echo -e "${GREEN}   📊 http://localhost:8084/${NC}"
        echo ""
        show_urls
        ;;
    stop)
        echo -e "${RED}🛑 Deteniendo Sistema Completo...${NC}"
        
        # Detener Dashboard Unificado
        if check_unified_status; then
            PID=$(cat "$UNIFIED_PID_FILE")
            kill $PID 2>/dev/null
            rm -f "$UNIFIED_PID_FILE"
            echo -e "${GREEN}✅ Dashboard Unificado detenido${NC}"
        fi
        
        # Detener Dashboard de Tráfico
        if check_traffic_status; then
            PID=$(cat "$TRAFFIC_PID_FILE")
            kill $PID 2>/dev/null
            rm -f "$TRAFFIC_PID_FILE"
            echo -e "${GREEN}✅ Dashboard de Tráfico detenido${NC}"
        fi
        
        # Detener API
        if check_api_status; then
            PID=$(cat "$API_PID_FILE")
            kill $PID 2>/dev/null
            rm -f "$API_PID_FILE"
            echo -e "${GREEN}✅ API de Administración detenida${NC}"
        fi
        
        # Detener Panel
        if check_panel_status; then
            PID=$(cat "$PANEL_PID_FILE")
            kill $PID 2>/dev/null
            rm -f "$PANEL_PID_FILE"
            echo -e "${GREEN}✅ Panel Web detenido${NC}"
        fi
        if check_traffic_status; then
            PID=$(cat "$TRAFFIC_PID_FILE")
            kill $PID 2>/dev/null
            rm -f "$TRAFFIC_PID_FILE"
            echo -e "${GREEN}✅ Dashboard de Tráfico detenido${NC}"
        fi
        
        echo -e "${GREEN}🎉 Todos los servicios detenidos${NC}"
        ;;
    restart)
        echo -e "${YELLOW}🔄 Reiniciando Sistema Completo...${NC}"
        $0 stop
        sleep 3
        $0 start
        ;;
    status)
        show_status
        ;;
    test)
        if check_api_status || check_traffic_status; then
            test_api
        else
            echo -e "${RED}❌ Ningún servicio está corriendo. Usa '$0 start' para iniciarlos.${NC}"
        fi
        ;;
    urls)
        show_urls
        ;;
    logs)
        show_logs
        ;;
    traffic)
        manage_traffic "$2"
        ;;
    unified)
        manage_unified "$2"
        ;;
    build)
        case "$2" in
            images)
                build_images
                ;;
            wars)
                build_wars
                ;;
            all)
                echo -e "${BLUE}🔨 Construyendo todo (imágenes + WARs)...${NC}"
                build_images && build_wars
                ;;
            *)
                echo -e "${YELLOW}Uso: $0 build [images|wars|all]${NC}"
                echo ""
                echo "Comandos de construcción:"
                echo "  images  - Construir imágenes Docker"
                echo "  wars    - Construir archivos WAR"
                echo "  all     - Construir todo"
                ;;
        esac
        ;;
    deploy)
        deploy_applications
        ;;
    test)
        test_complete_functionality
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
