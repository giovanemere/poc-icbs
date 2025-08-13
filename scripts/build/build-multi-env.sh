#!/bin/bash
#
# Script para construir imágenes Docker para diferentes ambientes
# Usa variables del archivo .env y argumentos de build
#

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función de ayuda
show_help() {
    echo "Uso: $0 [ambiente] [opciones]"
    echo ""
    echo "Ambientes disponibles:"
    echo "  version-a        Construir imagen para versión A (estable)"
    echo "  version-b        Construir imagen para versión B (canary/beta)"
    echo "  feature-flags    Construir imagen para feature flags"
    echo "  all             Construir todas las imágenes"
    echo ""
    echo "Opciones:"
    echo "  --no-cache      Construir sin usar caché"
    echo "  --force-rm      Eliminar contenedores intermedios"
    echo "  --pull          Actualizar imagen base antes de construir"
    echo "  --push          Subir imagen a registry después de construir"
    echo "  --tag TAG       Usar tag personalizado (por defecto: latest)"
    echo "  --help          Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 version-a                    # Construir solo versión A"
    echo "  $0 all --no-cache              # Construir todas sin caché"
    echo "  $0 feature-flags --tag v2.0.0  # Construir feature-flags con tag específico"
    echo ""
}

# Cargar variables del archivo .env
load_env_vars() {
    if [ -f ".env" ]; then
        echo -e "${BLUE}Cargando variables de entorno desde .env...${NC}"
        export $(grep -v '^#' .env | grep -v '^$' | xargs)
    else
        echo -e "${RED}Error: No se encontró el archivo .env${NC}"
        exit 1
    fi
}

# Verificar prerequisitos
check_prerequisites() {
    echo -e "${BLUE}Verificando prerequisitos...${NC}"
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker no está instalado${NC}"
        exit 1
    fi
    
    # Verificar archivos necesarios
    local required_files=(
        "install/fmw_14.1.1.0.0_wls_Disk1_1of1.zip"
        "install/sqlcl-25.2.2.199.0918.zip"
        "install/demo_oracle.ddl"
        "docker/Dockerfile"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            echo -e "${RED}Error: No se encontró el archivo requerido: $file${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}✓ Prerequisitos verificados${NC}"
}

# Construir imagen para un ambiente específico
build_environment() {
    local env=$1
    local tag=${2:-latest}
    local build_args=""
    
    echo -e "${GREEN}=== Construyendo imagen para ambiente: $env ===${NC}"
    
    # Configurar argumentos de build según el ambiente
    case $env in
        "version-a")
            build_args="--build-arg BUILD_ENV=version-a"
            build_args="$build_args --build-arg DOMAIN_NAME=${WEBLOGIC_A_DOMAIN_NAME:-base_domain_a}"
            build_args="$build_args --build-arg ADMIN_PASSWORD=${WEBLOGIC_A_ADMIN_PASSWORD:-welcome123}"
            build_args="$build_args --build-arg VERSION=A"
            build_args="$build_args --build-arg APP_VERSION=${APP_VERSION_A:-1.0.0}"
            IMAGE_NAME="weblogic-version-a"
            ;;
        "version-b")
            build_args="--build-arg BUILD_ENV=version-b"
            build_args="$build_args --build-arg DOMAIN_NAME=${WEBLOGIC_B_DOMAIN_NAME:-base_domain_b}"
            build_args="$build_args --build-arg ADMIN_PASSWORD=${WEBLOGIC_B_ADMIN_PASSWORD:-welcome123}"
            build_args="$build_args --build-arg VERSION=B"
            build_args="$build_args --build-arg APP_VERSION=${APP_VERSION_B:-2.0.0-beta}"
            IMAGE_NAME="weblogic-version-b"
            ;;
        "feature-flags")
            build_args="--build-arg BUILD_ENV=feature-flags"
            build_args="$build_args --build-arg DOMAIN_NAME=base_domain_ff"
            build_args="$build_args --build-arg ADMIN_PASSWORD=${WEBLOGIC_A_ADMIN_PASSWORD:-welcome123}"
            build_args="$build_args --build-arg VERSION=FF"
            build_args="$build_args --build-arg APP_VERSION=${BUILD_VERSION:-1.0.0}"
            IMAGE_NAME="weblogic-feature-flags"
            ;;
        *)
            echo -e "${RED}Error: Ambiente desconocido: $env${NC}"
            return 1
            ;;
    esac
    
    # Agregar argumentos de build comunes
    build_args="$build_args --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    build_args="$build_args --build-arg BUILD_VERSION=${BUILD_VERSION:-1.0.0}"
    build_args="$build_args --build-arg BUILD_COMMIT=${BUILD_COMMIT:-latest}"
    
    # Agregar opciones adicionales
    if [ "$NO_CACHE" = "true" ]; then
        build_args="$build_args --no-cache"
    fi
    
    if [ "$FORCE_RM" = "true" ]; then
        build_args="$build_args --force-rm"
    fi
    
    if [ "$PULL" = "true" ]; then
        build_args="$build_args --pull"
    fi
    
    # Construir la imagen
    echo -e "${YELLOW}Construyendo imagen: $IMAGE_NAME:$tag${NC}"
    echo -e "${BLUE}Argumentos de build: $build_args${NC}"
    
    docker build -f docker/Dockerfile -t "$IMAGE_NAME:$tag" $build_args .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Imagen $IMAGE_NAME:$tag construida exitosamente${NC}"
        
        # Mostrar información de la imagen
        echo -e "${BLUE}Información de la imagen:${NC}"
        docker images "$IMAGE_NAME:$tag" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
        
        # Subir imagen si se solicita
        if [ "$PUSH" = "true" ]; then
            echo -e "${YELLOW}Subiendo imagen al registry...${NC}"
            docker push "$IMAGE_NAME:$tag"
        fi
        
        return 0
    else
        echo -e "${RED}✗ Error al construir la imagen $IMAGE_NAME:$tag${NC}"
        return 1
    fi
}

# Construir todas las imágenes
build_all() {
    local tag=${1:-latest}
    local success_count=0
    local total_count=3
    
    echo -e "${GREEN}=== Construyendo todas las imágenes ===${NC}"
    
    # Construir cada ambiente
    for env in "version-a" "version-b" "feature-flags"; do
        if build_environment "$env" "$tag"; then
            ((success_count++))
        fi
        echo ""
    done
    
    # Resumen
    echo -e "${GREEN}=== Resumen de construcción ===${NC}"
    echo -e "Imágenes construidas exitosamente: $success_count/$total_count"
    
    if [ $success_count -eq $total_count ]; then
        echo -e "${GREEN}✓ Todas las imágenes se construyeron exitosamente${NC}"
        return 0
    else
        echo -e "${RED}✗ Algunas imágenes fallaron en la construcción${NC}"
        return 1
    fi
}

# Función principal
main() {
    # Cargar variables de entorno
    load_env_vars
    
    # Verificar prerequisitos
    check_prerequisites
    
    # Procesar argumentos
    ENVIRONMENT=""
    TAG="latest"
    NO_CACHE="false"
    FORCE_RM="false"
    PULL="false"
    PUSH="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            version-a|version-b|feature-flags|all)
                ENVIRONMENT="$1"
                shift
                ;;
            --no-cache)
                NO_CACHE="true"
                shift
                ;;
            --force-rm)
                FORCE_RM="true"
                shift
                ;;
            --pull)
                PULL="true"
                shift
                ;;
            --push)
                PUSH="true"
                shift
                ;;
            --tag)
                TAG="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Error: Opción desconocida: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Verificar que se especificó un ambiente
    if [ -z "$ENVIRONMENT" ]; then
        echo -e "${RED}Error: Debe especificar un ambiente${NC}"
        show_help
        exit 1
    fi
    
    # Crear directorio de despliegue si no existe
    mkdir -p deploy
    
    # Construir según el ambiente especificado
    if [ "$ENVIRONMENT" = "all" ]; then
        build_all "$TAG"
    else
        build_environment "$ENVIRONMENT" "$TAG"
    fi
}

# Ejecutar función principal
main "$@"
