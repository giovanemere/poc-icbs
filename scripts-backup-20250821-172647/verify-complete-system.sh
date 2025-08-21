#!/bin/bash

# Script de verificación completa del sistema Dashboard Unificado

PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}🔍 VERIFICACIÓN COMPLETA DEL SISTEMA${NC}"
echo -e "${BLUE}====================================${NC}"
echo

# 1. Verificar archivos principales
echo -e "${CYAN}1. Verificando archivos principales...${NC}"
files_check=0
files_total=0

declare -A files=(
    ["unified-dashboard-fixed.html"]="Dashboard Unificado (Corregido)"
    ["unified-dashboard.html"]="Dashboard Unificado (Original)"
    ["test-simple-functionality.html"]="Dashboard Simple"
    ["manage-admin-panel.sh"]="Script de Gestión Principal"
    ["build-latest.sh"]="Script Build Imágenes"
    ["scripts/build/build-wars.sh"]="Script Build WARs"
    ["scripts/deploy/deploy-war.sh"]="Script Deploy"
    ["config/docker-compose.yml"]="Configuración Docker"
)

for file in "${!files[@]}"; do
    files_total=$((files_total + 1))
    if [ -f "$PROJECT_DIR/$file" ]; then
        echo -e "   ✅ ${files[$file]}"
        files_check=$((files_check + 1))
    else
        echo -e "   ❌ ${files[$file]} - FALTANTE"
    fi
done

echo -e "   📊 Archivos: $files_check/$files_total OK"
echo

# 2. Verificar servicios Docker
echo -e "${CYAN}2. Verificando servicios Docker...${NC}"
if docker ps > /dev/null 2>&1; then
    echo -e "   ✅ Docker accesible"
    
    # Verificar contenedores específicos
    containers=("haproxy" "weblogic-a" "weblogic-b" "oracle-db")
    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "$container"; then
            echo -e "   ✅ Contenedor $container: CORRIENDO"
        else
            echo -e "   ⚠️ Contenedor $container: NO CORRIENDO"
        fi
    done
else
    echo -e "   ❌ Docker NO accesible"
fi
echo

# 3. Verificar puertos
echo -e "${CYAN}3. Verificando puertos principales...${NC}"
ports=("8085:Dashboard" "8084:API" "8082:Panel" "8404:Stats" "8080:HAProxy" "7001:WebLogic-A" "7002:WebLogic-B")

for port_desc in "${ports[@]}"; do
    port=$(echo $port_desc | cut -d: -f1)
    desc=$(echo $port_desc | cut -d: -f2)
    
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "   ✅ Puerto $port ($desc): OCUPADO"
    else
        echo -e "   ⚠️ Puerto $port ($desc): LIBRE"
    fi
done
echo

# 4. Verificar URLs principales
echo -e "${CYAN}4. Verificando URLs principales...${NC}"
urls=(
    "http://localhost:8085/unified-dashboard-fixed.html:Dashboard Corregido"
    "http://localhost:8085/unified-dashboard.html:Dashboard Original"
    "http://localhost:8085/test-simple-functionality.html:Dashboard Simple"
    "http://localhost:8084/api/health:API Health"
    "http://localhost:8082:Panel HAProxy"
    "http://localhost:8404/stats:HAProxy Stats"
)

for url_desc in "${urls[@]}"; do
    url=$(echo $url_desc | cut -d: -f1-2)
    desc=$(echo $url_desc | cut -d: -f3)
    
    if curl -s "$url" > /dev/null 2>&1; then
        echo -e "   ✅ $desc: ACCESIBLE"
    else
        echo -e "   ❌ $desc: NO ACCESIBLE"
    fi
done
echo

# 5. Verificar funcionalidad del Dashboard
echo -e "${CYAN}5. Verificando funcionalidad del Dashboard...${NC}"

# Verificar que el dashboard corregido tenga los elementos necesarios
if [ -f "$PROJECT_DIR/unified-dashboard-fixed.html" ]; then
    dashboard_content=$(cat "$PROJECT_DIR/unified-dashboard-fixed.html")
    
    elements=("ab-toggle" "ab-slider" "canary-toggle" "canary-slider" "trafficChart" "url-version-a" "traffic-version-a")
    
    for element in "${elements[@]}"; do
        if echo "$dashboard_content" | grep -q "id=\"$element\""; then
            echo -e "   ✅ Elemento $element: PRESENTE"
        else
            echo -e "   ❌ Elemento $element: FALTANTE"
        fi
    done
    
    # Verificar funciones JavaScript críticas
    functions=("updateTrafficPercentages" "updateChartWithCurrentData" "testAll")
    
    for func in "${functions[@]}"; do
        if echo "$dashboard_content" | grep -q "function $func"; then
            echo -e "   ✅ Función $func: PRESENTE"
        else
            echo -e "   ❌ Función $func: FALTANTE"
        fi
    done
else
    echo -e "   ❌ Dashboard corregido NO encontrado"
fi
echo

# 6. Verificar APIs
echo -e "${CYAN}6. Verificando APIs...${NC}"

# API Health
if curl -s http://localhost:8084/api/health 2>/dev/null | grep -q "healthy\|status"; then
    echo -e "   ✅ API Health: FUNCIONANDO"
else
    echo -e "   ❌ API Health: NO FUNCIONANDO"
fi

# API Stats
if curl -s http://localhost:8084/api/stats 2>/dev/null | grep -q "deployment\|backends"; then
    echo -e "   ✅ API Stats: FUNCIONANDO"
else
    echo -e "   ❌ API Stats: NO FUNCIONANDO"
fi

# Probar cambio A/B
ab_response=$(curl -s http://localhost:8084/api/ab/apply -X POST -H "Content-Type: application/json" -d '{"percentage_a": 70, "percentage_b": 30, "enabled": true}' 2>/dev/null)
if echo "$ab_response" | grep -q "success\|message"; then
    echo -e "   ✅ API A/B Testing: FUNCIONANDO"
else
    echo -e "   ❌ API A/B Testing: NO FUNCIONANDO"
fi

# Reset para limpiar
curl -s http://localhost:8084/api/reset -X POST > /dev/null 2>&1
echo

# 7. Verificar scripts de gestión
echo -e "${CYAN}7. Verificando scripts de gestión...${NC}"

if [ -x "$PROJECT_DIR/manage-admin-panel.sh" ]; then
    echo -e "   ✅ manage-admin-panel.sh: EJECUTABLE"
else
    echo -e "   ❌ manage-admin-panel.sh: NO EJECUTABLE"
fi

if [ -x "$PROJECT_DIR/build-latest.sh" ]; then
    echo -e "   ✅ build-latest.sh: EJECUTABLE"
else
    echo -e "   ⚠️ build-latest.sh: NO EJECUTABLE"
fi

if [ -x "$PROJECT_DIR/scripts/build/build-wars.sh" ]; then
    echo -e "   ✅ build-wars.sh: EJECUTABLE"
else
    echo -e "   ⚠️ build-wars.sh: NO EJECUTABLE"
fi
echo

# 8. Resumen final
echo -e "${PURPLE}📋 RESUMEN DE VERIFICACIÓN${NC}"
echo -e "${PURPLE}==========================${NC}"
echo

if [ $files_check -eq $files_total ]; then
    echo -e "${GREEN}✅ ARCHIVOS: Todos los archivos principales presentes${NC}"
else
    echo -e "${YELLOW}⚠️ ARCHIVOS: Faltan $((files_total - files_check)) archivos${NC}"
fi

# Verificar estado general
if curl -s http://localhost:8085/unified-dashboard-fixed.html > /dev/null 2>&1; then
    echo -e "${GREEN}✅ DASHBOARD: Accesible y funcionando${NC}"
else
    echo -e "${RED}❌ DASHBOARD: NO accesible${NC}"
fi

if curl -s http://localhost:8084/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ APIS: Funcionando correctamente${NC}"
else
    echo -e "${RED}❌ APIS: NO funcionando${NC}"
fi

echo
echo -e "${BLUE}🎛️ URLS PRINCIPALES PARA USAR:${NC}"
echo -e "${GREEN}   Dashboard Unificado: http://localhost:8085/unified-dashboard-fixed.html${NC}"
echo -e "${CYAN}   Panel HAProxy:       http://localhost:8082${NC}"
echo -e "${CYAN}   API de Control:      http://localhost:8084/api${NC}"
echo -e "${CYAN}   HAProxy Stats:       http://localhost:8404/stats${NC}"
echo

echo -e "${BLUE}🚀 COMANDOS PRINCIPALES:${NC}"
echo -e "${GREEN}   Iniciar sistema:     ./manage-admin-panel.sh start${NC}"
echo -e "${CYAN}   Dashboard corregido: ./manage-admin-panel.sh unified fixed${NC}"
echo -e "${CYAN}   Construir todo:      ./manage-admin-panel.sh build all${NC}"
echo -e "${CYAN}   Probar sistema:      ./manage-admin-panel.sh test${NC}"
echo

# Verificación final
if curl -s http://localhost:8085/unified-dashboard-fixed.html > /dev/null 2>&1 && \
   curl -s http://localhost:8084/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}🎉 SISTEMA COMPLETAMENTE FUNCIONAL${NC}"
    echo -e "${GREEN}   ¡Listo para usar!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️ SISTEMA PARCIALMENTE FUNCIONAL${NC}"
    echo -e "${YELLOW}   Ejecuta: ./manage-admin-panel.sh start${NC}"
    exit 1
fi
