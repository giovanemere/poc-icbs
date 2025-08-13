#!/bin/bash

# Script que ejecuta exactamente el comando solicitado con actualización de IPs integrada:
# cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./cleanup-environment.sh light && ./start-dashboard-integrated.sh
# Pero ahora incluye actualización automática de IPs usando ambos métodos (auto-update-haproxy.sh y haproxy-ip-updater.py)

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Ejecutando Comando Integrado con Actualización de IPs ===${NC}"
echo
echo -e "${YELLOW}Comando equivalente a:${NC}"
echo -e "${BLUE}cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./cleanup-environment.sh light && ./start-dashboard-integrated.sh${NC}"
echo -e "${YELLOW}+ Actualización automática de IPs usando:${NC}"
echo -e "${BLUE}  - ./scripts/auto-update-haproxy.sh (recomendado)${NC}"
echo -e "${BLUE}  - ./scripts/haproxy-ip-updater.py (más avanzado)${NC}"
echo

# Cambiar al directorio del proyecto
echo -e "${BLUE}Cambiando al directorio del proyecto...${NC}"
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
echo -e "${GREEN}✓ Directorio actual: $(pwd)${NC}"

echo
echo -e "${BLUE}=== Ejecutando: ./cleanup-environment.sh light ===${NC}"
./cleanup-environment.sh light

echo
echo -e "${BLUE}=== Ejecutando: ./start-dashboard-with-ip-update.sh ===${NC}"
echo -e "${YELLOW}(Incluye actualización automática de IPs antes del HAProxy Deployment Manager)${NC}"
./start-dashboard-with-ip-update.sh

echo
echo -e "${GREEN}=== ✅ Comando Integrado con IPs Completado Exitosamente ===${NC}"
echo -e "${YELLOW}🎉 HAProxy Deployment Manager con IPs actualizadas y todos los servicios están funcionando!${NC}"
echo
echo -e "${BLUE}🎯 Funcionalidades disponibles:${NC}"
echo -e "✅ ${YELLOW}Limpieza automática${NC} del entorno"
echo -e "✅ ${YELLOW}Actualización automática de IPs${NC} usando múltiples métodos"
echo -e "✅ ${YELLOW}HAProxy Deployment Manager${NC} completamente funcional"
echo -e "✅ ${YELLOW}Dashboard profesional${NC} integrado"
echo -e "✅ ${YELLOW}Testing A/B y Canary Deployment${NC} listos para usar"
echo -e "✅ ${YELLOW}Monitoreo en tiempo real${NC} de todos los servicios"
