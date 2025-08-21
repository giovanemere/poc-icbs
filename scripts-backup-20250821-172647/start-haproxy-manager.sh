#!/bin/bash

# Script para iniciar el HAProxy Deployment Manager
# Este es el sistema avanzado de gestión de despliegues que tenías

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Iniciando HAProxy Deployment Manager ===${NC}"
echo

# Cambiar al directorio del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Función para mostrar estado
show_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        return 1
    fi
}

# Verificar que HAProxy esté ejecutándose
echo -e "${BLUE}1. Verificando HAProxy...${NC}"
if docker ps | grep -q "haproxy"; then
    show_status 0 "HAProxy está ejecutándose"
else
    echo -e "${YELLOW}HAProxy no está ejecutándose. Iniciando...${NC}"
    if ./start-multi-env.sh start haproxy; then
        show_status 0 "HAProxy iniciado correctamente"
        sleep 5
    else
        show_status 1 "Error al iniciar HAProxy"
        exit 1
    fi
fi

# Verificar que los servicios de administración estén disponibles
echo
echo -e "${BLUE}2. Verificando servicios de administración...${NC}"

# Verificar API de administración (puerto 8081)
if curl -s --max-time 5 http://localhost:8081/api/config >/dev/null 2>&1; then
    show_status 0 "API de administración accesible (puerto 8081)"
else
    show_status 1 "API de administración no accesible"
    echo -e "${YELLOW}Verificando logs de HAProxy...${NC}"
    docker logs haproxy --tail 10
fi

# Verificar UI de administración (puerto 8082)
if curl -s --max-time 5 http://localhost:8082 >/dev/null 2>&1; then
    show_status 0 "UI de administración accesible (puerto 8082)"
else
    show_status 1 "UI de administración no accesible"
fi

# Verificar estadísticas de HAProxy (puerto 8404)
if curl -s --max-time 5 http://localhost:8404/stats >/dev/null 2>&1; then
    show_status 0 "Estadísticas de HAProxy accesibles (puerto 8404)"
else
    show_status 1 "Estadísticas de HAProxy no accesibles"
fi

echo
echo -e "${GREEN}=== HAProxy Deployment Manager Disponible ===${NC}"
echo
echo -e "${BLUE}=== 🌐 URLs del HAProxy Deployment Manager ===${NC}"
echo -e "🎛️  Panel Principal:            ${YELLOW}http://localhost:8082${NC}"
echo -e "📊 Estadísticas HAProxy:       ${YELLOW}http://localhost:8404/stats${NC}"
echo -e "🔧 API de Administración:      ${YELLOW}http://localhost:8081/api${NC}"
echo -e "🌐 HAProxy Frontend:           ${YELLOW}http://localhost:8080${NC}"

echo
echo -e "${BLUE}=== 🎯 Funcionalidades Disponibles ===${NC}"
echo -e "✅ Testing A/B:                Configurar porcentajes de tráfico entre versiones"
echo -e "✅ Canary Deployment:          Despliegue gradual de nuevas versiones"
echo -e "✅ Gestión de Servidores:      Activar/desactivar servidores backend"
echo -e "✅ Monitoreo en Tiempo Real:   Estadísticas y métricas de rendimiento"
echo -e "✅ Configuración Dinámica:     Cambios sin reiniciar HAProxy"

echo
echo -e "${BLUE}=== 🛠️  Comandos de Gestión ===${NC}"
echo -e "  Ver logs de HAProxy:        ${YELLOW}docker logs haproxy -f${NC}"
echo -e "  Reiniciar HAProxy:          ${YELLOW}./start-multi-env.sh restart haproxy${NC}"
echo -e "  Estado de servicios:        ${YELLOW}./start-multi-env.sh status${NC}"
echo -e "  Probar conectividad:        ${YELLOW}./scripts/check-urls.sh${NC}"

echo
echo -e "${YELLOW}💡 Credenciales por defecto:${NC}"
echo -e "   Usuario HAProxy Stats:     ${BLUE}admin${NC}"
echo -e "   Contraseña HAProxy Stats:  ${BLUE}admin123${NC}"

echo
echo -e "${GREEN}🎉 ¡HAProxy Deployment Manager listo para usar!${NC}"
echo -e "${BLUE}Accede a: ${YELLOW}http://localhost:8082${NC} ${BLUE}para comenzar${NC}"

# Verificación final
echo
echo -e "${BLUE}=== Verificación Final ===${NC}"
sleep 2

# Probar acceso al panel principal
if curl -s --max-time 5 http://localhost:8082 >/dev/null 2>&1; then
    show_status 0 "Panel principal accesible"
    echo -e "${GREEN}✅ Todo listo. Puedes acceder al HAProxy Deployment Manager${NC}"
else
    show_status 1 "Panel principal no accesible"
    echo
    echo -e "${YELLOW}🔍 Diagnóstico:${NC}"
    echo -e "1. Verificar que HAProxy esté ejecutándose: ${BLUE}docker ps | grep haproxy${NC}"
    echo -e "2. Verificar logs: ${BLUE}docker logs haproxy${NC}"
    echo -e "3. Verificar puertos: ${BLUE}netstat -tulpn | grep -E ':(8080|8081|8082|8404)'${NC}"
fi
