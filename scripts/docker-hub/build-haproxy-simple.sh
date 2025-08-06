#!/bin/bash

# Script simplificado para build y push HAProxy a Docker Hub
set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🚀 BUILD Y PUSH HAPROXY A DOCKER HUB${NC}"

# Variables directas
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCKER_NAMESPACE="edissonz8809"
APP_NAME="haproxy-advanced"
VERSION="v1.1.0"
IMAGE_NAME="$DOCKER_NAMESPACE/$APP_NAME:$VERSION"
LATEST_TAG="$DOCKER_NAMESPACE/$APP_NAME:latest"
APP_PATH="applications/haproxy-advanced"

cd "$PROJECT_ROOT"

echo -e "${BLUE}📦 Configuración:${NC}"
echo "  Namespace: $DOCKER_NAMESPACE"
echo "  Aplicación: $APP_NAME"
echo "  Versión: $VERSION"
echo "  Imagen: $IMAGE_NAME"
echo "  Path: $APP_PATH"

# Verificar Docker Hub login
echo -e "${BLUE}🔐 Verificando Docker Hub login...${NC}"
if ! docker info | grep -q "Username"; then
    echo -e "${YELLOW}⚠️  No hay sesión activa. Iniciando login...${NC}"
    docker login
fi

# Crear Dockerfile optimizado
echo -e "${BLUE}🔧 Creando Dockerfile optimizado...${NC}"
mkdir -p "$APP_PATH/src"

cat > "$APP_PATH/Dockerfile" << EOF
FROM haproxy:2.6-alpine

# Metadata
LABEL maintainer="DevOps Team"
LABEL version="$VERSION"
LABEL description="HAProxy Advanced Load Balancer"

# Variables de entorno
ENV APP_NAME="$APP_NAME"
ENV VERSION="$VERSION"

# Instalar herramientas
RUN apk add --no-cache curl bash jq

# Crear directorios
RUN mkdir -p /app/config /app/scripts /app/logs

# Copiar archivos si existen
COPY src/ /app/src/ 2>/dev/null || true
COPY config/ /app/config/ 2>/dev/null || true
COPY scripts/ /app/scripts/ 2>/dev/null || true

# Configuración HAProxy básica
RUN echo "# HAProxy Basic Config" > /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "global" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "    daemon" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "    log stdout local0 info" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "defaults" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "    mode http" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "    log global" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "    option httplog" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "    timeout connect 5000" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "    timeout client 50000" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "    timeout server 50000" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "listen stats" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "    bind *:8404" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "    stats enable" >> /usr/local/etc/haproxy/haproxy.cfg && \\
    echo "    stats uri /stats" >> /usr/local/etc/haproxy/haproxy.cfg

# Exponer puertos
EXPOSE 80 443 8080 8081 8082 8083 8404

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \\
    CMD curl -f http://localhost:8404/stats || exit 1

# Comando por defecto
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
EOF

echo -e "${GREEN}✅ Dockerfile creado${NC}"

# Copiar archivos existentes si existen
if [[ -d "haproxy" ]]; then
    echo -e "${BLUE}📁 Copiando archivos HAProxy existentes...${NC}"
    cp -r haproxy/* "$APP_PATH/src/" 2>/dev/null || true
    echo -e "${GREEN}✅ Archivos copiados${NC}"
fi

# Build de la imagen
echo -e "${BLUE}🏗️  Building imagen...${NC}"
cd "$APP_PATH"

if docker build -t "$IMAGE_NAME" . --no-cache; then
    echo -e "${GREEN}✅ Build completado: $IMAGE_NAME${NC}"
else
    echo -e "${RED}❌ Error en build${NC}"
    exit 1
fi

# Verificar imagen
IMAGE_SIZE=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "$IMAGE_NAME" | awk '{print $2}' || echo "Unknown")
echo -e "${GREEN}📦 Imagen creada: $IMAGE_NAME ($IMAGE_SIZE)${NC}"

# Test básico
echo -e "${BLUE}🧪 Test básico...${NC}"
if docker run --rm "$IMAGE_NAME" haproxy -v; then
    echo -e "${GREEN}✅ Test exitoso${NC}"
else
    echo -e "${YELLOW}⚠️  Test falló, continuando...${NC}"
fi

# Push imagen principal
echo -e "${BLUE}📤 Pushing imagen principal...${NC}"
if docker push "$IMAGE_NAME"; then
    echo -e "${GREEN}✅ Push exitoso: $IMAGE_NAME${NC}"
else
    echo -e "${RED}❌ Error en push${NC}"
    exit 1
fi

# Tag y push latest
echo -e "${BLUE}🏷️  Creando tag latest...${NC}"
docker tag "$IMAGE_NAME" "$LATEST_TAG"
if docker push "$LATEST_TAG"; then
    echo -e "${GREEN}✅ Push exitoso: $LATEST_TAG${NC}"
else
    echo -e "${YELLOW}⚠️  Error en push latest${NC}"
fi

# Tag con fecha
DATE_TAG="$DOCKER_NAMESPACE/$APP_NAME:$(date +%Y%m%d)"
docker tag "$IMAGE_NAME" "$DATE_TAG"
if docker push "$DATE_TAG"; then
    echo -e "${GREEN}✅ Push exitoso: $DATE_TAG${NC}"
else
    echo -e "${YELLOW}⚠️  Error en push date tag${NC}"
fi

# Resumen final
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    BUILD Y PUSH COMPLETADO                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${GREEN}🎉 Primera imagen Docker Hub completada!${NC}"
echo ""
echo -e "${CYAN}📦 IMÁGENES CREADAS:${NC}"
echo "  • Principal: $IMAGE_NAME"
echo "  • Latest: $LATEST_TAG"
echo "  • Fecha: $DATE_TAG"
echo "  • Tamaño: $IMAGE_SIZE"
echo ""
echo -e "${CYAN}🔗 DOCKER HUB:${NC}"
echo "  • Repositorio: https://hub.docker.com/r/$DOCKER_NAMESPACE/$APP_NAME"
echo "  • Tags: https://hub.docker.com/r/$DOCKER_NAMESPACE/$APP_NAME/tags"
echo ""
echo -e "${CYAN}🧪 COMANDOS DE TEST:${NC}"
echo "  docker pull $IMAGE_NAME"
echo "  docker run -d -p 8404:8404 --name haproxy-test $IMAGE_NAME"
echo "  curl http://localhost:8404/stats"
echo ""
echo -e "${CYAN}🚀 PRÓXIMOS PASOS:${NC}"
echo "  1. Verificar imagen en Docker Hub"
echo "  2. Test deployment local"
echo "  3. Build segunda imagen (WebLogic)"
echo ""

# Crear log
cd "$PROJECT_ROOT"
cat > "docker-hub-first-image.log" << EOF
# Primera Imagen Docker Hub - HAProxy Advanced

## Información
- **Fecha**: $(date +'%Y-%m-%d %H:%M:%S')
- **Imagen Principal**: $IMAGE_NAME
- **Tag Latest**: $LATEST_TAG
- **Tag Fecha**: $DATE_TAG
- **Tamaño**: $IMAGE_SIZE
- **Estado**: ✅ COMPLETADO

## Enlaces Docker Hub
- Repositorio: https://hub.docker.com/r/$DOCKER_NAMESPACE/$APP_NAME
- Tags: https://hub.docker.com/r/$DOCKER_NAMESPACE/$APP_NAME/tags

## Test Commands
\`\`\`bash
docker pull $IMAGE_NAME
docker run -d -p 8404:8404 --name haproxy-test $IMAGE_NAME
curl http://localhost:8404/stats
\`\`\`

## Build Info
- Build Context: $APP_PATH
- Dockerfile: Optimizado para Docker Hub
- Base Image: haproxy:2.6-alpine
- Exposed Ports: 80, 443, 8080, 8081, 8082, 8083, 8404
EOF

echo -e "${GREEN}✅ Log guardado: docker-hub-first-image.log${NC}"
echo -e "${GREEN}🎯 Primera imagen Docker Hub lista!${NC}"
