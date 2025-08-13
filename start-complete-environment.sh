#!/bin/bash

# Script de comando único para iniciar el entorno completo con HAProxy Deployment Manager
# Equivale a: cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./cleanup-environment.sh light && ./start-dashboard-integrated.sh

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Iniciando Entorno Completo con HAProxy Deployment Manager ===${NC}"
echo

# Cambiar al directorio del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

echo -e "${BLUE}Directorio actual: $(pwd)${NC}"
echo

# Función para mostrar estado
show_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        return 1
    fi
}

# Paso 1: Limpieza del entorno
echo -e "${BLUE}=== Paso 1: Limpieza del Entorno ===${NC}"
echo

if ./cleanup-environment.sh light; then
    show_status 0 "Limpieza del entorno completada"
else
    show_status 1 "Error en la limpieza del entorno"
    echo -e "${YELLOW}Continuando con el inicio...${NC}"
fi

echo
echo -e "${BLUE}=== Paso 2: Iniciando Servicios Integrados ===${NC}"
echo

# Paso 2: Iniciar servicios integrados
if ./start-dashboard-integrated.sh; then
    show_status 0 "Servicios integrados iniciados exitosamente"
else
    show_status 1 "Error al iniciar servicios integrados"
    exit 1
fi

echo
echo -e "${GREEN}=== 🎉 Entorno Completo Iniciado Exitosamente ===${NC}"
echo

echo -e "${BLUE}=== 🌟 Resumen de Servicios Disponibles ===${NC}"
echo
echo -e "${YELLOW}🎛️  HAProxy Deployment Manager:${NC}"
echo -e "   Panel Principal:            ${GREEN}http://localhost:8082${NC}"
echo -e "   API de Administración:      ${GREEN}http://localhost:8081/api${NC}"
echo -e "   Estadísticas HAProxy:       ${GREEN}http://localhost:8404/stats${NC}"
echo
echo -e "${YELLOW}📊 Dashboards y Monitoreo:${NC}"
echo -e "   Dashboard Profesional:      ${GREEN}http://localhost:8080/dashboard/${NC}"
echo -e "   Dashboard Directo:          ${GREEN}http://localhost:8001/${NC}"
echo -e "   HAProxy Frontend:           ${GREEN}http://localhost:8080${NC}"
echo
echo -e "${YELLOW}🖥️  Consolas de Administración:${NC}"
echo -e "   WebLogic A:                 ${GREEN}http://localhost:7001/console${NC}"
echo -e "   WebLogic B:                 ${GREEN}http://localhost:7002/console${NC}"
echo -e "   WebLogic Feature Flags:     ${GREEN}http://localhost:7003/console${NC}"
echo -e "   Oracle Enterprise Manager:  ${GREEN}http://localhost:5500/em${NC}"
echo
echo -e "${YELLOW}🚀 Aplicaciones de Prueba:${NC}"
echo -e "   Version A:                  ${GREEN}http://localhost:8080/version-a/${NC}"
echo -e "   Version B:                  ${GREEN}http://localhost:8080/version-b/${NC}"
echo -e "   Feature Flags:              ${GREEN}http://localhost:8080/feature-flags/${NC}"
echo -e "   FF4J Simple:                ${GREEN}http://localhost:8080/ff4j-simple/${NC}"

echo
echo -e "${BLUE}=== 🎯 Funcionalidades del HAProxy Deployment Manager ===${NC}"
echo -e "✅ ${YELLOW}Testing A/B:${NC}                Configurar porcentajes de tráfico entre versiones"
echo -e "✅ ${YELLOW}Canary Deployment:${NC}          Despliegue gradual de nuevas versiones"
echo -e "✅ ${YELLOW}Gestión de Servidores:${NC}      Activar/desactivar servidores backend"
echo -e "✅ ${YELLOW}Monitoreo en Tiempo Real:${NC}   Estadísticas y métricas de rendimiento"
echo -e "✅ ${YELLOW}Configuración Dinámica:${NC}     Cambios sin reiniciar HAProxy"
echo -e "✅ ${YELLOW}Actualización de IPs:${NC}       IPs actualizadas automáticamente"

echo
echo -e "${BLUE}=== 🛠️  Comandos de Gestión ===${NC}"
echo -e "  Ver estado completo:        ${YELLOW}./start-multi-env.sh status${NC}"
echo -e "  Probar HAProxy Manager:     ${YELLOW}./start-haproxy-manager.sh${NC}"
echo -e "  Probar dashboard:           ${YELLOW}./scripts/test-dashboard.sh${NC}"
echo -e "  Ver logs de HAProxy:        ${YELLOW}docker logs haproxy -f${NC}"
echo -e "  Reiniciar HAProxy:          ${YELLOW}./start-multi-env.sh restart haproxy${NC}"
echo -e "  Detener todo:               ${YELLOW}./start-multi-env.sh stop${NC}"
echo -e "  Limpiar entorno:            ${YELLOW}./cleanup-environment.sh light${NC}"

echo
echo -e "${YELLOW}💡 Credenciales por defecto:${NC}"
echo -e "   Usuario HAProxy Stats:      ${BLUE}admin${NC}"
echo -e "   Contraseña HAProxy Stats:   ${BLUE}admin123${NC}"

echo
echo -e "${GREEN}🎉 ¡Todo listo! Tu entorno completo con HAProxy Deployment Manager está funcionando.${NC}"
echo -e "${BLUE}Accede al panel principal en: ${YELLOW}http://localhost:8082${NC}"
