#!/bin/bash

# Script de inicio rápido completo que reemplaza completamente:
# cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./run-integrated-command.sh

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                              ║${NC}"
echo -e "${BLUE}║     🚀 INICIO RÁPIDO COMPLETO - ORACLE WEBLOGIC             ║${NC}"
echo -e "${BLUE}║        Reemplaza: cd /path && ./run-integrated-command.sh    ║${NC}"
echo -e "${BLUE}║                                                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Verificar que estamos en el directorio correcto
if [ ! -f "manage-complete-integrated.sh" ]; then
    echo -e "${RED}❌ Error: Debe ejecutar este script desde el directorio raíz del proyecto${NC}"
    echo -e "${YELLOW}Ejecute: cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic${NC}"
    exit 1
fi

echo -e "${YELLOW}🎯 Este script ejecutará automáticamente:${NC}"
echo -e "   1. ✅ Inicio de todos los servicios Docker Compose"
echo -e "   2. ✅ Servicio de gestión integrada"
echo -e "   3. ✅ Comando integrado completo (equivalente al original)"
echo -e "   4. ✅ Verificación de todos los servicios"
echo

echo -e "${YELLOW}📋 Opciones disponibles:${NC}"
echo -e "   ${GREEN}1${NC} - Ejecutar comando integrado original (./run-integrated-command.sh)"
echo -e "   ${GREEN}2${NC} - Ejecutar versión Docker Compose mejorada"
echo -e "   ${GREEN}3${NC} - Solo iniciar servicios y mostrar estado"
echo -e "   ${GREEN}q${NC} - Salir"
echo

read -p "Seleccione una opción (1/2/3/q): " -n 1 -r
echo

case $REPLY in
    1)
        echo -e "${BLUE}=== Opción 1: Comando Integrado Original ===${NC}"
        echo -e "${YELLOW}Ejecutando equivalente a: cd /path && ./run-integrated-command.sh${NC}"
        echo
        
        # Iniciar servicios
        ./manage-complete-integrated.sh start
        echo
        
        # Ejecutar comando integrado original
        ./manage-complete-integrated.sh run-integrated
        ;;
    2)
        echo -e "${BLUE}=== Opción 2: Versión Docker Compose Mejorada ===${NC}"
        echo -e "${YELLOW}Ejecutando versión mejorada con gestión completa de Docker Compose${NC}"
        echo
        
        # Iniciar servicios
        ./manage-complete-integrated.sh start
        echo
        
        # Ejecutar versión Docker Compose
        ./manage-complete-integrated.sh run-integrated-dc
        ;;
    3)
        echo -e "${BLUE}=== Opción 3: Solo Iniciar Servicios ===${NC}"
        echo -e "${YELLOW}Iniciando servicios y mostrando estado${NC}"
        echo
        
        # Solo iniciar servicios
        ./manage-complete-integrated.sh start
        ;;
    q|Q)
        echo -e "${YELLOW}Operación cancelada por el usuario${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Opción no válida. Ejecutando opción por defecto (1)${NC}"
        
        # Iniciar servicios
        ./manage-complete-integrated.sh start
        echo
        
        # Ejecutar comando integrado original
        ./manage-complete-integrated.sh run-integrated
        ;;
esac

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
echo -e "${YELLOW}🛠️  Comandos útiles para gestión continua:${NC}"
echo -e "   ./manage-complete-integrated.sh status          # Ver estado"
echo -e "   ./manage-complete-integrated.sh logs haproxy    # Ver logs"
echo -e "   ./manage-complete-integrated.sh dashboard       # Abrir dashboard"
echo -e "   ./manage-complete-integrated.sh shell           # Shell en contenedor"
echo -e "   ./manage-complete-integrated.sh stop            # Detener todo"
echo -e "   ./manage-complete-integrated.sh help            # Ver ayuda completa"

echo
echo -e "${GREEN}🎯 ¡El entorno está listo para Testing A/B, Canary Deployment y Feature Flags!${NC}"

# Opcional: Abrir dashboard automáticamente
echo
read -p "¿Abrir el dashboard en el navegador? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ./manage-complete-integrated.sh dashboard
fi
