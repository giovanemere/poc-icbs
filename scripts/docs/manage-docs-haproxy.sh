#!/bin/bash

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Función para ejecutar docker-compose desde el directorio correcto
docker_compose() {
    if [ -f "docker-compose.yml" ]; then
        docker-compose "$@"
    elif [ -f "config/docker-compose.yml" ]; then
        cd config && docker-compose "$@" && cd ..
    else
        echo -e "${RED}❌ docker-compose.yml no encontrado${NC}"
        exit 1
    fi
}

case "$1" in
    "deploy")
        echo -e "${BLUE}🚀 Desplegando documentación de producción...${NC}"
        ./build-docs.sh
        docker_compose up -d --build mkdocs-server
        echo -e "${GREEN}✅ Documentación desplegada en http://localhost:8080/docs${NC}"
        ;;
    "deploy-dev")
        echo -e "${BLUE}🔧 Desplegando documentación de desarrollo...${NC}"
        docker_compose up -d --build mkdocs-dev-server
        echo -e "${GREEN}✅ Documentación de desarrollo desplegada en http://localhost:8080/docs/dev${NC}"
        ;;
    "status")
        echo -e "${BLUE}ℹ️  Estado de servicios de documentación:${NC}"
        echo
        docker_compose ps mkdocs-server mkdocs-dev-server mkdocs-v1-server haproxy 2>/dev/null || echo "Servicios no iniciados"
        echo
        echo "📈 Tráfico de documentación:"
        if command -v curl >/dev/null 2>&1; then
            echo "  • /docs: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/docs 2>/dev/null || echo "No disponible")"
            echo "  • /docs/dev: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/docs/dev 2>/dev/null || echo "No disponible")"
        else
            echo "  • curl no disponible para verificar endpoints"
        fi
        ;;
    "start")
        echo -e "${BLUE}▶️  Iniciando servicios de documentación...${NC}"
        docker_compose up -d mkdocs-server mkdocs-dev-server
        echo -e "${GREEN}✅ Servicios iniciados${NC}"
        ;;
    "stop")
        echo -e "${YELLOW}⏹️  Deteniendo servicios de documentación...${NC}"
        docker_compose stop mkdocs-server mkdocs-dev-server mkdocs-v1-server
        echo -e "${GREEN}✅ Servicios detenidos${NC}"
        ;;
    "logs")
        echo -e "${BLUE}📋 Logs de servicios de documentación:${NC}"
        docker_compose logs -f mkdocs-server mkdocs-dev-server
        ;;
    "update-haproxy")
        echo -e "${BLUE}🔄 Recargando configuración HAProxy...${NC}"
        docker_compose restart haproxy
        echo -e "${GREEN}✅ HAProxy recargado${NC}"
        ;;
    *)
        echo "Uso: $0 {deploy|deploy-dev|status|start|stop|logs|update-haproxy}"
        echo
        echo "Comandos:"
        echo "  deploy         - Desplegar documentación de producción"
        echo "  deploy-dev     - Desplegar documentación de desarrollo"
        echo "  status         - Ver estado de servicios y tráfico"
        echo "  start          - Iniciar servicios de documentación"
        echo "  stop           - Detener servicios de documentación"
        echo "  logs           - Ver logs de servicios"
        echo "  update-haproxy - Recargar configuración HAProxy"
        echo
        echo "URLs de acceso:"
        echo "  http://localhost:8080/docs     - Documentación principal"
        echo "  http://localhost:8080/docs/dev - Documentación desarrollo"
        echo "  http://localhost:8404/stats    - HAProxy stats"
        exit 1
        ;;
esac
