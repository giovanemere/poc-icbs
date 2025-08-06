#!/bin/bash

# Push Script para WebLogic Feature Flags - Docker Hub
# Push de imagen ya construida localmente
set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🚀 PUSH TERCERA IMAGEN DOCKER HUB - WEBLOGIC FEATURE FLAGS${NC}"

# Configuración
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

# Configuración de la imagen
IMAGE_NAME="weblogic-feature-flags"
DOCKER_REGISTRY="edissonz8809"
VERSION="v1.1.0"
BUILD_DATE=$(date +%Y%m%d)

# Tags múltiples
FULL_IMAGE_NAME="${DOCKER_REGISTRY}/${IMAGE_NAME}"
TAG_VERSION="${FULL_IMAGE_NAME}:${VERSION}"
TAG_LATEST="${FULL_IMAGE_NAME}:latest"
TAG_DATE="${FULL_IMAGE_NAME}:${BUILD_DATE}"

echo -e "${BLUE}📋 Configuración de Push:${NC}"
echo "  • Imagen: ${IMAGE_NAME}"
echo "  • Registry: ${DOCKER_REGISTRY}"
echo "  • Versión: ${VERSION}"
echo "  • Tags: ${VERSION}, latest, ${BUILD_DATE}"

# Verificar que la imagen existe localmente
echo -e "${BLUE}🔍 Verificando imagen local...${NC}"
if ! docker images "$TAG_VERSION" --format "{{.Repository}}" | grep -q "$FULL_IMAGE_NAME"; then
    echo -e "${RED}❌ Error: Imagen $TAG_VERSION no encontrada localmente${NC}"
    echo -e "${YELLOW}💡 Ejecuta primero: ./scripts/docker-hub/build-weblogic-local.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Imagen encontrada localmente${NC}"
docker images "$FULL_IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Error: Docker no está instalado${NC}"
    exit 1
fi

# Intentar login a Docker Hub
echo -e "${BLUE}🔐 Configurando autenticación Docker Hub...${NC}"

# Opción 1: Login interactivo
echo -e "${YELLOW}🔑 Necesitas autenticarte en Docker Hub${NC}"
echo -e "${BLUE}Opciones:${NC}"
echo "1. Login interactivo (recomendado)"
echo "2. Usar variable de entorno DOCKER_PASSWORD"
echo ""
read -p "Selecciona opción (1 o 2): " auth_option

case $auth_option in
    1)
        echo -e "${BLUE}Iniciando login interactivo...${NC}"
        docker login
        ;;
    2)
        if [[ -n "${DOCKER_PASSWORD}" ]]; then
            echo -e "${BLUE}Usando variable de entorno DOCKER_PASSWORD...${NC}"
            echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_REGISTRY}" --password-stdin
        else
            echo -e "${RED}❌ Error: DOCKER_PASSWORD no configurado${NC}"
            echo -e "${YELLOW}💡 Configura: export DOCKER_PASSWORD=\"tu_token\"${NC}"
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}❌ Opción inválida${NC}"
        exit 1
        ;;
esac

# Verificar autenticación
if docker info | grep -q "Username"; then
    echo -e "${GREEN}✅ Autenticación exitosa${NC}"
else
    echo -e "${RED}❌ Error: Autenticación falló${NC}"
    exit 1
fi

# Push a Docker Hub
echo -e "${BLUE}📤 Subiendo imagen a Docker Hub...${NC}"

# Tiempo de inicio
START_TIME=$(date +%s)

echo -e "${CYAN}Pushing ${TAG_VERSION}...${NC}"
docker push "$TAG_VERSION"

echo -e "${CYAN}Pushing ${TAG_LATEST}...${NC}"
docker push "$TAG_LATEST"

echo -e "${CYAN}Pushing ${TAG_DATE}...${NC}"
docker push "$TAG_DATE"

if [[ $? -eq 0 ]]; then
    END_TIME=$(date +%s)
    PUSH_TIME=$((END_TIME - START_TIME))
    echo -e "${GREEN}✅ Imagen subida exitosamente a Docker Hub en ${PUSH_TIME}s${NC}"
else
    echo -e "${RED}❌ Error al subir imagen a Docker Hub${NC}"
    exit 1
fi

# Verificación final
echo -e "${BLUE}🔍 Verificación final - Pull test desde Docker Hub...${NC}"
docker rmi "$TAG_VERSION" > /dev/null 2>&1 || true
docker pull "$TAG_VERSION"

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Pull test exitoso - Imagen disponible públicamente${NC}"
else
    echo -e "${RED}❌ Error en pull test${NC}"
    exit 1
fi

# Resumen final
echo -e "${GREEN}🎉 PUSH COMPLETADO EXITOSAMENTE${NC}"
echo -e "${BLUE}📊 Resumen:${NC}"
echo "  • Imagen: ${TAG_VERSION}"
echo "  • Tamaño: $(docker images "$TAG_VERSION" --format "{{.Size}}")"
echo "  • Tags subidos: 3 (version, latest, date)"
echo "  • Docker Hub: https://hub.docker.com/r/${DOCKER_REGISTRY}/${IMAGE_NAME}"
echo "  • Tiempo de push: ${PUSH_TIME}s"

# Información de uso
echo -e "${CYAN}🚀 Comandos para usar la imagen desde Docker Hub:${NC}"
echo "  # Pull desde Docker Hub:"
echo "  docker pull ${TAG_VERSION}"
echo ""
echo "  # Run container:"
echo "  docker run -d -p 7001:7001 -p 7002:7002 \\"
echo "    --name weblogic-features \\"
echo "    ${TAG_VERSION}"
echo ""
echo "  # Acceder a WebLogic Console:"
echo "  http://localhost:7001/console"

# Actualizar documentación
echo -e "${BLUE}📝 Actualizando documentación...${NC}"
cat > "DOCKER-HUB-WEBLOGIC-PUSH-COMPLETADO.md" << EOF
# WebLogic Feature Flags - Docker Hub Push COMPLETADO

## ✅ Push Exitoso
- **Fecha**: $(date)
- **Imagen**: ${TAG_VERSION}
- **Tamaño**: $(docker images "$TAG_VERSION" --format "{{.Size}}")
- **Tags**: ${VERSION}, latest, ${BUILD_DATE}
- **Docker Hub**: https://hub.docker.com/r/${DOCKER_REGISTRY}/${IMAGE_NAME}
- **Tiempo de Push**: ${PUSH_TIME}s

## 🚀 Características
- WebLogic Server 12.2.1.3
- Feature Flags system integrado
- Health checks automáticos
- Soporte canary deployment
- A/B testing ready

## 📊 Métricas
- Tiempo de push: ${PUSH_TIME}s
- Pull test: ✅ Exitoso
- Disponibilidad: ✅ Pública en Docker Hub

## 🎯 Estado
✅ Tercera imagen Docker Hub completada y disponible públicamente

## 🔗 Enlaces
- Docker Hub: https://hub.docker.com/r/${DOCKER_REGISTRY}/${IMAGE_NAME}
- Tags: ${VERSION}, latest, ${BUILD_DATE}
EOF

echo -e "${GREEN}✅ Documentación actualizada: DOCKER-HUB-WEBLOGIC-PUSH-COMPLETADO.md${NC}"
echo -e "${CYAN}🎯 Tercera imagen Docker Hub disponible públicamente${NC}"
echo -e "${BLUE}🌐 Verifica en: https://hub.docker.com/r/${DOCKER_REGISTRY}/${IMAGE_NAME}${NC}"
