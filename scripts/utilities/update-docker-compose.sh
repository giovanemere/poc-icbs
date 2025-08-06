#!/bin/bash

# Script para actualizar docker-compose.yml con nuevas rutas de applications
set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${CYAN}🔧 Actualizando docker-compose.yml con nuevas rutas${NC}"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

# Crear backup
BACKUP_FILE="backups/docker-compose-$(date +%Y%m%d-%H%M%S).yml"
echo -e "${BLUE}📦 Creando backup: $BACKUP_FILE${NC}"
mkdir -p backups
cp config/docker-compose.yml "$BACKUP_FILE"

# Actualizar referencias en docker-compose.yml
echo -e "${BLUE}🔄 Actualizando referencias de paths${NC}"

# Crear versión temporal
cp config/docker-compose.yml config/docker-compose.yml.tmp

# Actualizar paths de build context para usar applications/
sed -i \
    -e 's|dockerfile: docker/Dockerfile|dockerfile: applications/weblogic-feature-flags/Dockerfile|g' \
    -e 's|context: \.\.|context: .|g' \
    config/docker-compose.yml.tmp

# Verificar si hay servicios HAProxy y MkDocs para actualizar
if grep -q "haproxy" config/docker-compose.yml.tmp; then
    echo -e "${BLUE}🔄 Actualizando HAProxy build context${NC}"
    sed -i 's|build: haproxy|build: applications/haproxy-advanced|g' config/docker-compose.yml.tmp
fi

if grep -q "mkdocs" config/docker-compose.yml.tmp; then
    echo -e "${BLUE}🔄 Actualizando MkDocs build context${NC}"
    sed -i 's|dockerfile: Dockerfile.mkdocs|dockerfile: applications/mkdocs-server/Dockerfile|g' config/docker-compose.yml.tmp
fi

# Mover archivo actualizado
mv config/docker-compose.yml.tmp config/docker-compose.yml

echo -e "${GREEN}✅ docker-compose.yml actualizado${NC}"

# Mostrar diferencias
echo -e "${YELLOW}📋 Cambios realizados:${NC}"
echo "• Build context de WebLogic actualizado a applications/weblogic-feature-flags/"
echo "• Dockerfile paths actualizados"
echo "• Context principal cambiado de '..' a '.'"

echo -e "${CYAN}🎯 Próximos pasos:${NC}"
echo "1. Revisar cambios: diff $BACKUP_FILE config/docker-compose.yml"
echo "2. Test build: docker-compose build"
echo "3. Test deployment: ./scripts/services/manage-services.sh restart"

echo -e "${GREEN}🎉 Actualización completada${NC}"
