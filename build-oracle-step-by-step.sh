#!/bin/bash

# =============================================================================
# BUILD ORACLE EXPRESS DB - PASO A PASO
# =============================================================================

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🐳 CREANDO IMAGEN ORACLE EXPRESS DB - PASO A PASO${NC}"
echo "=================================================================="

# Paso 1: Docker Login
echo -e "${YELLOW}📋 PASO 1: Docker Login${NC}"
echo "Por favor, haz login en Docker Hub:"
docker login

# Paso 2: Build de la imagen
echo -e "${YELLOW}📋 PASO 2: Construyendo imagen...${NC}"
cd applications/oracle-express-db

echo "Iniciando build (esto puede tomar 10-15 minutos)..."
docker build \
    --tag edissonz8809/oracle-express-db:v1.1.0 \
    --tag edissonz8809/oracle-express-db:latest \
    --tag edissonz8809/oracle-express-db:$(date +%Y%m%d) \
    --no-cache \
    .

echo -e "${GREEN}✅ Build completado${NC}"

# Paso 3: Verificar imagen
echo -e "${YELLOW}📋 PASO 3: Verificando imagen construida...${NC}"
docker images edissonz8809/oracle-express-db

# Paso 4: Test básico
echo -e "${YELLOW}📋 PASO 4: Test básico de la imagen...${NC}"
docker run --rm --name oracle-test \
    -e ORACLE_PWD=Oracle123 \
    edissonz8809/oracle-express-db:v1.1.0 \
    /bin/bash -c "echo 'Test OK' && ls -la /app && cat /app/VERSION"

echo -e "${GREEN}✅ Test completado${NC}"

# Paso 5: Push a Docker Hub
echo -e "${YELLOW}📋 PASO 5: Subiendo a Docker Hub...${NC}"
echo "Subiendo imagen (esto puede tomar 15-20 minutos debido al tamaño)..."

docker push edissonz8809/oracle-express-db:v1.1.0
docker push edissonz8809/oracle-express-db:latest
docker push edissonz8809/oracle-express-db:$(date +%Y%m%d)

echo -e "${GREEN}✅ Push completado${NC}"

# Paso 6: Verificación pública
echo -e "${YELLOW}📋 PASO 6: Verificando acceso público...${NC}"
docker rmi edissonz8809/oracle-express-db:v1.1.0 || true
docker pull edissonz8809/oracle-express-db:v1.1.0

echo -e "${GREEN}🎉 ¡ORACLE EXPRESS DB COMPLETADA EXITOSAMENTE!${NC}"
echo -e "${BLUE}📦 Imagen: edissonz8809/oracle-express-db:v1.1.0${NC}"
echo -e "${BLUE}🌐 URL: https://hub.docker.com/r/edissonz8809/oracle-express-db${NC}"
echo -e "${BLUE}📏 Tamaño: $(docker images edissonz8809/oracle-express-db:v1.1.0 --format "{{.Size}}")${NC}"

echo ""
echo -e "${GREEN}✅ FASE 3 COMPLETADA AL 100% - TODAS LAS 4 IMÁGENES DOCKER HUB LISTAS${NC}"
echo "=================================================================="
