#!/bin/bash

# Script de inicio rápido para el Dashboard Unificado

PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}🚀 INICIO RÁPIDO - Dashboard Unificado WebLogic${NC}"
echo -e "${BLUE}===============================================${NC}"
echo

# Verificar directorio
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ Directorio del proyecto no encontrado: $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

echo -e "${CYAN}1. Verificando prerequisitos...${NC}"

# Verificar Docker
if ! docker ps > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker no está corriendo. Iniciando Docker...${NC}"
    sudo systemctl start docker 2>/dev/null || echo -e "${YELLOW}⚠️ No se pudo iniciar Docker automáticamente${NC}"
    sleep 3
fi

if docker ps > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker funcionando${NC}"
else
    echo -e "${RED}❌ Docker no accesible. Verifica la instalación.${NC}"
    exit 1
fi

# Verificar archivos principales
if [ ! -f "manage-admin-panel.sh" ]; then
    echo -e "${RED}❌ Script principal no encontrado${NC}"
    exit 1
fi

if [ ! -f "unified-dashboard-fixed.html" ]; then
    echo -e "${RED}❌ Dashboard corregido no encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Archivos principales presentes${NC}"
echo

echo -e "${CYAN}2. Iniciando servicios Docker...${NC}"

# Verificar si los contenedores están corriendo
if ! docker-compose -f config/docker-compose.yml ps | grep -q "Up"; then
    echo -e "${YELLOW}⚠️ Contenedores no están corriendo. Iniciando...${NC}"
    docker-compose -f config/docker-compose.yml up -d
    
    echo -e "${CYAN}Esperando que los servicios se inicialicen...${NC}"
    sleep 15
    
    # Verificar que HAProxy esté respondiendo
    for i in {1..10}; do
        if curl -s http://localhost:8404 > /dev/null 2>&1; then
            echo -e "${GREEN}✅ HAProxy iniciado${NC}"
            break
        fi
        echo -e "${YELLOW}⏳ Esperando HAProxy... ($i/10)${NC}"
        sleep 3
    done
else
    echo -e "${GREEN}✅ Contenedores ya están corriendo${NC}"
fi
echo

echo -e "${CYAN}3. Iniciando Dashboard Unificado...${NC}"

# Usar el script de gestión para iniciar el dashboard
chmod +x manage-admin-panel.sh
./manage-admin-panel.sh unified fixed

echo

echo -e "${CYAN}4. Verificando funcionalidad...${NC}"

# Verificar que todo esté funcionando
sleep 3

# Verificar Dashboard
if curl -s http://localhost:8085/unified-dashboard-fixed.html | head -1 | grep -q "DOCTYPE"; then
    echo -e "${GREEN}✅ Dashboard Unificado: FUNCIONANDO${NC}"
else
    echo -e "${RED}❌ Dashboard Unificado: NO FUNCIONANDO${NC}"
fi

# Verificar API
if curl -s http://localhost:8084/api/health 2>/dev/null | grep -q "healthy\|status"; then
    echo -e "${GREEN}✅ API de Control: FUNCIONANDO${NC}"
else
    echo -e "${YELLOW}⚠️ API de Control: NO FUNCIONANDO (puede ser normal)${NC}"
fi

# Verificar HAProxy
if curl -s -u admin:admin123 http://localhost:8404/stats 2>/dev/null | grep -q "HAProxy"; then
    echo -e "${GREEN}✅ HAProxy Stats: FUNCIONANDO${NC}"
else
    echo -e "${YELLOW}⚠️ HAProxy Stats: NO FUNCIONANDO${NC}"
fi

echo

echo -e "${PURPLE}🎉 SISTEMA INICIADO${NC}"
echo -e "${PURPLE}==================${NC}"
echo

echo -e "${GREEN}🎛️ DASHBOARD PRINCIPAL:${NC}"
echo -e "${GREEN}   http://localhost:8085/unified-dashboard-fixed.html${NC}"
echo

echo -e "${CYAN}📋 OTRAS URLS IMPORTANTES:${NC}"
echo -e "${CYAN}   Panel HAProxy:    http://localhost:8082${NC}"
echo -e "${CYAN}   API de Control:   http://localhost:8084/api${NC}"
echo -e "${CYAN}   HAProxy Stats:    http://localhost:8404/stats (admin/admin123)${NC}"
echo -e "${CYAN}   Aplicaciones:     http://localhost:8080${NC}"
echo

echo -e "${BLUE}🧪 PARA PROBAR EL DASHBOARD:${NC}"
echo -e "${BLUE}1. Abre: http://localhost:8085/unified-dashboard-fixed.html${NC}"
echo -e "${BLUE}2. Activa 'A/B Testing' y mueve el slider${NC}"
echo -e "${BLUE}3. Activa 'Canary Deployment' y mueve el slider${NC}"
echo -e "${BLUE}4. Observa que URLs y gráfico cambien inmediatamente${NC}"
echo

echo -e "${YELLOW}🔧 COMANDOS ÚTILES:${NC}"
echo -e "${YELLOW}   Ver estado:       ./manage-admin-panel.sh status${NC}"
echo -e "${YELLOW}   Reiniciar:        ./manage-admin-panel.sh restart${NC}"
echo -e "${YELLOW}   Construir WARs:   ./manage-admin-panel.sh build wars${NC}"
echo -e "${YELLOW}   Probar sistema:   ./manage-admin-panel.sh test${NC}"
echo -e "${YELLOW}   Verificar todo:   ./verify-complete-system.sh${NC}"
echo

# Abrir navegador automáticamente si está disponible
if command -v xdg-open > /dev/null 2>&1; then
    echo -e "${CYAN}🌐 Abriendo Dashboard en el navegador...${NC}"
    xdg-open "http://localhost:8085/unified-dashboard-fixed.html" 2>/dev/null &
elif command -v open > /dev/null 2>&1; then
    echo -e "${CYAN}🌐 Abriendo Dashboard en el navegador...${NC}"
    open "http://localhost:8085/unified-dashboard-fixed.html" 2>/dev/null &
fi

echo -e "${GREEN}✅ ¡Sistema listo para usar!${NC}"
