#!/bin/bash

# Script de inicio rápido que usa la gestión integrada Docker Compose
# Reemplaza la necesidad de ejecutar manualmente comandos complejos

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                              ║${NC}"
echo -e "${BLUE}║        🚀 INICIO RÁPIDO INTEGRADO - ORACLE WEBLOGIC         ║${NC}"
echo -e "${BLUE}║                                                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Verificar que estamos en el directorio correcto
if [ ! -f "manage-integrated.sh" ]; then
    echo -e "${RED}❌ Error: Debe ejecutar este script desde el directorio raíz del proyecto${NC}"
    echo -e "${YELLOW}Ejecute: cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic${NC}"
    exit 1
fi

echo -e "${YELLOW}🎯 Este script ejecutará automáticamente:${NC}"
echo -e "   1. ✅ Limpieza del entorno (light)"
echo -e "   2. ✅ Inicio de todos los servicios Docker"
echo -e "   3. ✅ Actualización automática de IPs"
echo -e "   4. ✅ Configuración de HAProxy Deployment Manager"
echo -e "   5. ✅ Inicio del Dashboard profesional"
echo -e "   6. ✅ Verificación de todos los servicios"
echo

read -p "¿Continuar con el inicio integrado? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Operación cancelada por el usuario${NC}"
    exit 0
fi

echo -e "${BLUE}=== Paso 1: Iniciando servicios con gestión integrada ===${NC}"
./manage-integrated.sh start

echo
echo -e "${BLUE}=== Paso 2: Ejecutando comando integrado completo ===${NC}"
./manage-integrated.sh run-integrated

echo
echo -e "${BLUE}=== Paso 3: Verificando estado de servicios ===${NC}"
./manage-integrated.sh status

echo
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║                    ✅ ¡INICIO COMPLETADO!                    ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"

echo
echo -e "${BLUE}🎉 Todos los servicios están funcionando correctamente!${NC}"
echo
echo -e "${YELLOW}📋 URLs de acceso principales:${NC}"
echo -e "   🌐 ${GREEN}HAProxy Frontend:${NC}     http://localhost:8080"
echo -e "   📊 ${GREEN}HAProxy Stats:${NC}        http://localhost:8404/stats"
echo -e "   ⚙️  ${GREEN}Panel Admin:${NC}          http://localhost:8082"
echo -e "   📈 ${GREEN}Dashboard:${NC}            http://localhost:8001"
echo -e "   🔧 ${GREEN}WebLogic A Console:${NC}   http://localhost:7001/console"
echo -e "   🔧 ${GREEN}WebLogic B Console:${NC}   http://localhost:7002/console"

echo
echo -e "${YELLOW}🛠️  Comandos útiles:${NC}"
echo -e "   ./manage-integrated.sh status          # Ver estado"
echo -e "   ./manage-integrated.sh logs haproxy    # Ver logs"
echo -e "   ./manage-integrated.sh dashboard       # Abrir dashboard"
echo -e "   ./manage-integrated.sh stop            # Detener todo"
echo -e "   ./manage-integrated.sh help            # Ver ayuda completa"

echo
echo -e "${GREEN}🎯 ¡El entorno está listo para Testing A/B, Canary Deployment y Feature Flags!${NC}"

# Opcional: Abrir dashboard automáticamente
read -p "¿Abrir el dashboard en el navegador? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./manage-integrated.sh dashboard
fi
