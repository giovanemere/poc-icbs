#!/bin/bash

# =============================================================================
# BUILD ORACLE EXPRESS DB - DOCKER HUB IMAGE
# =============================================================================
# Script para construir y publicar la imagen Oracle Express DB en Docker Hub
# Cuarta imagen de la suite Docker WebLogic Oracle

set -euo pipefail

# =============================================================================
# CONFIGURACIÓN
# =============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Información de la imagen
IMAGE_NAME="edissonz8809/oracle-express-db"
VERSION="v1.1.0"
BUILD_DATE=$(date +%Y%m%d)
DOCKERFILE_PATH="applications/oracle-express-db"

# Verificar directorio del proyecto
PROJECT_ROOT="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
if [[ ! -d "$PROJECT_ROOT" ]]; then
    echo -e "${RED}❌ Error: Directorio del proyecto no encontrado: $PROJECT_ROOT${NC}"
    exit 1
fi

cd "$PROJECT_ROOT"

# =============================================================================
# FUNCIONES AUXILIARES
# =============================================================================

print_header() {
    echo -e "${CYAN}"
    echo "============================================================================="
    echo "  🐳 BUILD ORACLE EXPRESS DB - DOCKER HUB IMAGE"
    echo "============================================================================="
    echo -e "${NC}"
    echo -e "${BLUE}📦 Imagen:${NC} $IMAGE_NAME"
    echo -e "${BLUE}🏷️  Versión:${NC} $VERSION"
    echo -e "${BLUE}📅 Build Date:${NC} $BUILD_DATE"
    echo -e "${BLUE}📁 Dockerfile:${NC} $DOCKERFILE_PATH/Dockerfile"
    echo ""
}

print_step() {
    echo -e "${PURPLE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# =============================================================================
# DOCKER LOGIN
# =============================================================================

docker_login() {
    print_step "Verificando login Docker Hub..."
    
    # Verificar si ya está logueado
    if docker info | grep -q "Username"; then
        print_success "Ya estás logueado en Docker Hub"
        return 0
    fi
    
    # Solicitar login
    echo -e "${YELLOW}🔐 Necesitas hacer login en Docker Hub${NC}"
    echo -e "${BLUE}Por favor, ingresa tus credenciales:${NC}"
    
    # Intentar login
    if docker login; then
        print_success "Login exitoso en Docker Hub"
    else
        print_error "Error en login Docker Hub"
        echo -e "${YELLOW}¿Continuar sin login? (y/N):${NC}"
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        print_warning "Continuando sin login - no se podrá hacer push"
    fi
}

# =============================================================================
# VERIFICACIONES PREVIAS
# =============================================================================

verify_prerequisites() {
    print_step "Verificando prerrequisitos..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado"
        exit 1
    fi
    
    # Verificar Dockerfile
    if [[ ! -f "$DOCKERFILE_PATH/Dockerfile" ]]; then
        print_error "Dockerfile no encontrado en $DOCKERFILE_PATH/"
        exit 1
    fi
    
    print_success "Prerrequisitos verificados"
}

# =============================================================================
# LIMPIEZA PREVIA
# =============================================================================

cleanup_previous() {
    print_step "Limpiando imágenes previas..."
    
    # Remover imágenes locales previas si existen
    if docker images | grep -q "$IMAGE_NAME"; then
        print_step "Removiendo imágenes locales previas..."
        docker rmi $(docker images "$IMAGE_NAME" -q) 2>/dev/null || true
    fi
    
    # Limpiar build cache
    docker builder prune -f > /dev/null 2>&1 || true
    
    print_success "Limpieza completada"
}

# =============================================================================
# BUILD DE LA IMAGEN
# =============================================================================

build_image() {
    print_step "Construyendo imagen Oracle Express DB..."
    
    # Cambiar al directorio de la aplicación
    cd "$DOCKERFILE_PATH"
    
    # Build con múltiples tags
    echo -e "${BLUE}🔨 Ejecutando docker build...${NC}"
    echo -e "${YELLOW}⚠️  Nota: Este build puede tomar varios minutos debido al tamaño de Oracle${NC}"
    
    # Build principal
    if docker build \
        --tag "$IMAGE_NAME:$VERSION" \
        --tag "$IMAGE_NAME:latest" \
        --tag "$IMAGE_NAME:$BUILD_DATE" \
        --label "build.date=$BUILD_DATE" \
        --label "build.version=$VERSION" \
        --label "build.project=docker-weblogic-oracle" \
        --no-cache \
        . ; then
        
        print_success "Imagen construida exitosamente"
        
        # Mostrar información de la imagen
        echo ""
        echo -e "${CYAN}📊 INFORMACIÓN DE LA IMAGEN:${NC}"
        docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
        
    else
        print_error "Error al construir la imagen"
        exit 1
    fi
    
    # Regresar al directorio del proyecto
    cd "$PROJECT_ROOT"
}

# =============================================================================
# TESTING DE LA IMAGEN
# =============================================================================

test_image() {
    print_step "Probando imagen construida..."
    
    # Test básico - verificar que la imagen se puede ejecutar
    echo -e "${BLUE}🧪 Ejecutando test básico...${NC}"
    
    # Crear contenedor de prueba (sin iniciar Oracle completamente)
    if docker run --rm --name oracle-test-build \
        -e ORACLE_PWD=Oracle123 \
        "$IMAGE_NAME:$VERSION" \
        /bin/bash -c "echo 'Oracle Express DB Image Test: OK' && ls -la /app && cat /app/VERSION" ; then
        
        print_success "Test básico completado exitosamente"
    else
        print_warning "Test básico falló, pero la imagen fue construida"
    fi
}

# =============================================================================
# PUSH A DOCKER HUB
# =============================================================================

push_to_dockerhub() {
    print_step "Publicando en Docker Hub..."
    
    # Verificar login antes de push
    if ! docker info | grep -q "Username"; then
        print_error "No estás logueado en Docker Hub. No se puede hacer push."
        return 1
    fi
    
    # Push de todas las tags
    echo -e "${BLUE}📤 Subiendo imagen con múltiples tags...${NC}"
    echo -e "${YELLOW}⚠️  Nota: El push puede tomar varios minutos debido al tamaño de la imagen${NC}"
    
    # Push version tag
    if docker push "$IMAGE_NAME:$VERSION"; then
        print_success "Tag $VERSION subida exitosamente"
    else
        print_error "Error al subir tag $VERSION"
        return 1
    fi
    
    # Push latest tag
    if docker push "$IMAGE_NAME:latest"; then
        print_success "Tag latest subida exitosamente"
    else
        print_error "Error al subir tag latest"
        return 1
    fi
    
    # Push date tag
    if docker push "$IMAGE_NAME:$BUILD_DATE"; then
        print_success "Tag $BUILD_DATE subida exitosamente"
    else
        print_error "Error al subir tag $BUILD_DATE"
        return 1
    fi
    
    print_success "Todas las tags subidas exitosamente a Docker Hub"
}

# =============================================================================
# VERIFICACIÓN PÚBLICA
# =============================================================================

verify_public_access() {
    print_step "Verificando acceso público..."
    
    # Esperar un momento para que Docker Hub procese
    sleep 5
    
    # Intentar pull de la imagen pública
    echo -e "${BLUE}🔍 Verificando pull público...${NC}"
    
    # Remover imagen local temporalmente
    docker rmi "$IMAGE_NAME:$VERSION" > /dev/null 2>&1 || true
    
    # Intentar pull público
    if docker pull "$IMAGE_NAME:$VERSION"; then
        print_success "Imagen accesible públicamente en Docker Hub"
        
        # Mostrar información final
        echo ""
        echo -e "${CYAN}🎉 IMAGEN ORACLE EXPRESS DB COMPLETADA:${NC}"
        echo -e "${GREEN}📦 Imagen:${NC} $IMAGE_NAME:$VERSION"
        echo -e "${GREEN}🌐 URL:${NC} https://hub.docker.com/r/edissonz8809/oracle-express-db"
        echo -e "${GREEN}📏 Tamaño:${NC} $(docker images "$IMAGE_NAME:$VERSION" --format "{{.Size}}")"
        echo -e "${GREEN}📅 Fecha:${NC} $BUILD_DATE"
        
    else
        print_error "Error: Imagen no accesible públicamente"
        return 1
    fi
}

# =============================================================================
# ACTUALIZAR DOCUMENTACIÓN
# =============================================================================

update_documentation() {
    print_step "Actualizando documentación..."
    
    # Obtener tamaño de la imagen
    IMAGE_SIZE=$(docker images "$IMAGE_NAME:$VERSION" --format "{{.Size}}")
    
    # Actualizar .env.registry
    if [[ -f ".env.registry" ]]; then
        # Actualizar estado de Oracle DB
        sed -i 's/ORACLE_STATUS=PLANNED/ORACLE_STATUS=AVAILABLE/' .env.registry
        sed -i "s/ORACLE_SIZE=TBD/ORACLE_SIZE=$IMAGE_SIZE/" .env.registry
        sed -i 's/TOTAL_IMAGES=3/TOTAL_IMAGES=4/' .env.registry
        sed -i 's/PROJECT_STATUS=95% Complete/PROJECT_STATUS=100% Complete/' .env.registry
        sed -i 's/PHASE_3_STATUS=100% Complete/PHASE_3_STATUS=100% Complete/' .env.registry
        
        print_success "Archivo .env.registry actualizado"
    fi
    
    # Actualizar README de la aplicación
    cat > "$DOCKERFILE_PATH/README.md" << EOF
# Oracle Express DB - Docker Hub Image

## 📋 Descripción
Imagen Docker Hub optimizada de Oracle Database Express 21c para desarrollo y testing, integrada con WebLogic Server.

## 🐳 Docker Hub
- **Imagen**: \`edissonz8809/oracle-express-db:$VERSION\`
- **Tamaño**: $IMAGE_SIZE
- **URL**: https://hub.docker.com/r/edissonz8809/oracle-express-db

## 🚀 Uso Rápido

### Pull desde Docker Hub
\`\`\`bash
docker pull edissonz8809/oracle-express-db:$VERSION
\`\`\`

### Ejecutar contenedor
\`\`\`bash
docker run -d \\
  --name oracle-express \\
  -p 1521:1521 \\
  -p 5500:5500 \\
  -e ORACLE_PWD=Oracle123 \\
  edissonz8809/oracle-express-db:$VERSION
\`\`\`

## 🔧 Características

### ✅ Optimizaciones Incluidas
- Oracle Database Express 21c
- Usuario de desarrollo preconfigurado (weblogic_dev)
- Tablas de ejemplo para Feature Flags
- Health checks automáticos
- Scripts de monitoreo
- Inicialización automática

### 🔗 Integración WebLogic
- Usuario: \`weblogic_dev\`
- Password: \`WebLogic123\`
- Tabla Feature Flags preconfigurada
- Conexión optimizada para WebLogic

### 📊 Monitoreo
- Health check endpoint
- Scripts de monitoreo incluidos
- Logs estructurados

## 🌐 URLs de Acceso
- **Oracle Database**: \`localhost:1521/XE\`
- **Enterprise Manager**: \`http://localhost:5500/em\`

## 🔐 Credenciales
- **System**: system/Oracle123
- **WebLogic Dev**: weblogic_dev/WebLogic123

## 📚 Documentación
Parte de la suite Docker WebLogic Oracle disponible en Docker Hub.

---
**Versión**: $VERSION  
**Build Date**: $BUILD_DATE  
**Mantenido por**: edissonz8809
EOF
    
    print_success "Documentación actualizada"
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

main() {
    print_header
    
    # Ejecutar pasos
    verify_prerequisites
    docker_login
    cleanup_previous
    build_image
    test_image
    
    # Preguntar si hacer push
    echo ""
    read -p "¿Subir imagen a Docker Hub? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        if push_to_dockerhub; then
            verify_public_access
            update_documentation
            
            echo ""
            echo -e "${GREEN}🎉 ¡ORACLE EXPRESS DB COMPLETADA EXITOSAMENTE!${NC}"
            echo -e "${CYAN}📦 Cuarta imagen de la suite Docker WebLogic Oracle${NC}"
            echo -e "${CYAN}🌐 Disponible públicamente en Docker Hub${NC}"
            echo ""
            echo -e "${BLUE}🔗 Enlaces útiles:${NC}"
            echo -e "   • Docker Hub: https://hub.docker.com/r/edissonz8809/oracle-express-db"
            echo -e "   • Pull command: docker pull edissonz8809/oracle-express-db:$VERSION"
            echo ""
            echo -e "${GREEN}✅ FASE 3 COMPLETADA AL 100% - TODAS LAS IMÁGENES DOCKER HUB LISTAS${NC}"
            
        else
            print_error "Error en el push a Docker Hub"
        fi
    else
        echo -e "${YELLOW}⏭️  Imagen construida localmente, no subida a Docker Hub${NC}"
    fi
}

# =============================================================================
# EJECUCIÓN
# =============================================================================

# Verificar si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
