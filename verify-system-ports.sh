#!/bin/bash

# Script de verificación completa del sistema con puertos actualizados

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                              ║${NC}"
echo -e "${BLUE}║     🔍 VERIFICACIÓN COMPLETA DEL SISTEMA                    ║${NC}"
echo -e "${BLUE}║        Puertos actualizados y servicios                     ║${NC}"
echo -e "${BLUE}║                                                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Función para verificar URL
check_url() {
    local name="$1"
    local url="$2"
    local timeout="${3:-5}"
    
    echo -n -e "${CYAN}Verificando $name...${NC} "
    
    if curl -s --max-time $timeout "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FALLO${NC}"
        return 1
    fi
}

# Función para verificar puerto
check_port() {
    local name="$1"
    local port="$2"
    
    echo -n -e "${CYAN}Verificando puerto $port ($name)...${NC} "
    
    if nc -z localhost $port 2>/dev/null; then
        echo -e "${GREEN}✅ ABIERTO${NC}"
        return 0
    else
        echo -e "${RED}❌ CERRADO${NC}"
        return 1
    fi
}

echo -e "${YELLOW}=== Verificación de Puertos ===${NC}"
check_port "HAProxy Frontend" 8100
check_port "HAProxy Stats" 8404
check_port "HAProxy Admin Panel" 8103
check_port "WebLogic A" 7001
check_port "WebLogic B" 7002
check_port "Oracle DB" 1521
check_port "Oracle EM" 5500

echo
echo -e "${YELLOW}=== Verificación de URLs Principales ===${NC}"
check_url "Frontend Principal" "http://localhost:8100/" 10
check_url "HAProxy Stats" "http://localhost:8404/stats" 5
check_url "WebLogic A Console" "http://localhost:7001/console" 10
check_url "WebLogic B Console" "http://localhost:7002/console" 10

echo
echo -e "${YELLOW}=== Verificación de Aplicaciones ===${NC}"
check_url "Version A" "http://localhost:8100/version-a/" 10
check_url "Version B" "http://localhost:8100/version-b/" 10
check_url "Feature Flags" "http://localhost:8100/feature-flags/" 10
check_url "FF4J Simple" "http://localhost:8100/ff4j-simple/" 10

echo
echo -e "${YELLOW}=== Estado de Contenedores Docker ===${NC}"
docker-compose -f config/docker-compose-network-flexible.yml ps

echo
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║                ✅ VERIFICACIÓN COMPLETADA                    ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"

echo
echo -e "${BLUE}📋 URLs de Acceso Actualizadas:${NC}"
echo -e "   🌐 ${GREEN}Frontend Principal:${NC}       http://localhost:8100/"
echo -e "   📊 ${GREEN}HAProxy Stats:${NC}            http://localhost:8404/stats (admin/admin123)"
echo -e "   ⚙️  ${GREEN}HAProxy Admin Panel:${NC}     http://localhost:8103 (admin/admin123)"
echo -e "   🔧 ${GREEN}WebLogic A Console:${NC}       http://localhost:7001/console (weblogic/welcome1)"
echo -e "   🔧 ${GREEN}WebLogic B Console:${NC}       http://localhost:7002/console (weblogic/welcome1)"

echo
echo -e "${YELLOW}🎯 Para gestionar el sistema:${NC}"
echo -e "   ${BLUE}./manage-admin-panel.sh start${NC}     # Iniciar panel de administración"
echo -e "   ${BLUE}./manage-admin-panel.sh status${NC}    # Ver estado del sistema"
echo -e "   ${BLUE}./manage-services.sh status${NC}       # Estado de servicios Docker"

echo
echo -e "${GREEN}🎉 ¡El sistema está listo para Testing A/B, Canary Deployment y Feature Flags!${NC}"
