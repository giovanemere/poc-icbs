#!/bin/bash
#
# Script de ayuda para el sistema de build multi-ambiente
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Sistema de Build Multi-Ambiente para Oracle WebLogic ===${NC}"
echo ""
echo -e "${BLUE}Este proyecto ahora soporta construcción de imágenes para diferentes ambientes:${NC}"
echo -e "  • ${YELLOW}version-a${NC}      - Versión estable (producción)"
echo -e "  • ${YELLOW}version-b${NC}      - Versión canary/beta"
echo -e "  • ${YELLOW}feature-flags${NC}  - Ambiente para feature flags"
echo ""

echo -e "${BLUE}=== Archivos de Configuración ===${NC}"
echo -e "  • ${YELLOW}.env${NC}                                    - Variables de entorno"
echo -e "  • ${YELLOW}docker/Dockerfile${NC}                       - Dockerfile reutilizable"
echo -e "  • ${YELLOW}config/docker-compose-multi-env.yml${NC}     - Docker Compose multi-ambiente"
echo -e "  • ${YELLOW}scripts/build/build-multi-env.sh${NC}        - Script de build avanzado"
echo ""

echo -e "${BLUE}=== Métodos de Construcción ===${NC}"
echo ""
echo -e "${YELLOW}1. Usando el script principal (recomendado):${NC}"
echo -e "   ./build.sh                           # Construir todas las imágenes"
echo -e "   ./build.sh --env version-a           # Construir solo version-a"
echo -e "   ./build.sh --env version-b           # Construir solo version-b"
echo -e "   ./build.sh --env feature-flags       # Construir solo feature-flags"
echo -e "   ./build.sh --no-cache                # Construir sin caché"
echo ""

echo -e "${YELLOW}2. Usando el script multi-ambiente directamente:${NC}"
echo -e "   ./scripts/build/build-multi-env.sh version-a"
echo -e "   ./scripts/build/build-multi-env.sh version-b --no-cache"
echo -e "   ./scripts/build/build-multi-env.sh all --tag v2.0.0"
echo ""

echo -e "${YELLOW}3. Usando Docker Compose directamente:${NC}"
echo -e "   docker-compose -f config/docker-compose-multi-env.yml build"
echo -e "   docker-compose -f config/docker-compose-multi-env.yml build weblogic-a"
echo -e "   docker-compose -f config/docker-compose-multi-env.yml build --no-cache"
echo ""

echo -e "${BLUE}=== Variables de Entorno Importantes ===${NC}"
echo -e "Las siguientes variables del archivo ${YELLOW}.env${NC} son utilizadas:"
echo ""
echo -e "${YELLOW}WebLogic A (version-a):${NC}"
echo -e "  WEBLOGIC_A_DOMAIN_NAME=${WEBLOGIC_A_DOMAIN_NAME:-base_domain_a}"
echo -e "  WEBLOGIC_A_ADMIN_PASSWORD=${WEBLOGIC_A_ADMIN_PASSWORD:-welcome123}"
echo -e "  APP_VERSION_A=${APP_VERSION_A:-1.0.0}"
echo ""
echo -e "${YELLOW}WebLogic B (version-b):${NC}"
echo -e "  WEBLOGIC_B_DOMAIN_NAME=${WEBLOGIC_B_DOMAIN_NAME:-base_domain_b}"
echo -e "  WEBLOGIC_B_ADMIN_PASSWORD=${WEBLOGIC_B_ADMIN_PASSWORD:-welcome123}"
echo -e "  APP_VERSION_B=${APP_VERSION_B:-2.0.0-beta}"
echo ""
echo -e "${YELLOW}Build:${NC}"
echo -e "  BUILD_VERSION=${BUILD_VERSION:-1.0.0}"
echo -e "  BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
echo ""

echo -e "${BLUE}=== Despliegue ===${NC}"
echo -e "Después de construir las imágenes, puede desplegar con:"
echo -e "   ${YELLOW}docker-compose -f config/docker-compose-multi-env.yml up -d${NC}"
echo ""
echo -e "O desplegar servicios específicos:"
echo -e "   ${YELLOW}docker-compose -f config/docker-compose-multi-env.yml up -d weblogic-a haproxy${NC}"
echo ""

echo -e "${BLUE}=== Verificación ===${NC}"
echo -e "Para verificar las imágenes construidas:"
echo -e "   ${YELLOW}docker images | grep weblogic${NC}"
echo ""
echo -e "Para verificar los contenedores en ejecución:"
echo -e "   ${YELLOW}docker-compose -f config/docker-compose-multi-env.yml ps${NC}"
echo ""

echo -e "${BLUE}=== Logs y Debugging ===${NC}"
echo -e "Para ver logs de construcción:"
echo -e "   ${YELLOW}docker-compose -f config/docker-compose-multi-env.yml logs weblogic-a${NC}"
echo ""
echo -e "Para acceder a un contenedor:"
echo -e "   ${YELLOW}docker exec -it weblogic-a bash${NC}"
echo ""

echo -e "${GREEN}=== ¡Listo para usar! ===${NC}"
echo -e "El sistema está configurado para reutilizar el mismo Dockerfile con diferentes"
echo -e "configuraciones según el ambiente. Todas las variables se cargan desde el archivo .env"
echo ""
