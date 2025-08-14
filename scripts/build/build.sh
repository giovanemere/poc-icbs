#!/bin/bash
#
# Script para construir la imagen Docker de WebLogic
# Ahora soporta múltiples ambientes usando variables del .env
#

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Construyendo imágenes Docker para Oracle WebLogic ===${NC}"
echo ""

# Cargar variables del archivo .env de forma segura
load_env_vars() {
    if [ -f ".env" ]; then
        echo -e "${BLUE}Cargando variables de entorno desde .env...${NC}"
        
        # Cargar variables de forma segura, evitando problemas con espacios y caracteres especiales
        while IFS='=' read -r key value; do
            # Saltar líneas vacías y comentarios
            [[ $key =~ ^[[:space:]]*# ]] && continue
            [[ -z $key ]] && continue
            
            # Limpiar espacios en blanco
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            # Exportar solo si la clave es válida
            if [[ $key =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                export "$key=$value"
            fi
        done < .env
        
        # Configurar variables especiales que requieren procesamiento
        export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
        
    else
        echo -e "${YELLOW}Advertencia: No se encontró el archivo .env, usando valores por defecto${NC}"
        # Valores por defecto
        export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
        export BUILD_VERSION="1.0.0"
        export BUILD_COMMIT="latest"
    fi
}

echo -e "${GREEN}=== Construyendo imágenes Docker para Oracle WebLogic ===${NC}"
echo ""

# Cargar variables del archivo .env
load_env_vars

# Verificar archivos necesarios
echo -e "${BLUE}Verificando archivos necesarios...${NC}"
if [ ! -f "install/fmw_14.1.1.0.0_wls_Disk1_1of1.zip" ]; then
    echo -e "${RED}Error: No se encontró el archivo install/fmw_14.1.1.0.0_wls_Disk1_1of1.zip${NC}"
    echo "Por favor, descargue el archivo desde el sitio web de Oracle y colóquelo en el directorio install/ del proyecto."
    exit 1
fi

if [ ! -f "install/sqlcl-25.2.2.199.0918.zip" ]; then
    echo -e "${RED}Error: No se encontró el archivo install/sqlcl-25.2.2.199.0918.zip${NC}"
    echo "Por favor, descargue el archivo desde el sitio web de Oracle y colóquelo en el directorio install/ del proyecto."
    exit 1
fi

# Crear directorio de despliegue si no existe
mkdir -p deploy

# Limpiar directorio de despliegue
echo -e "${YELLOW}Limpiando directorio de despliegue...${NC}"
rm -f deploy/*.war

# Construir las aplicaciones WAR
echo -e "${YELLOW}Compilando aplicaciones WAR...${NC}"
if [ -f "scripts/build/build-wars.sh" ]; then
    ./scripts/build/build-wars.sh
else
    echo -e "${YELLOW}Advertencia: No se encontró build-wars.sh, saltando compilación de WARs${NC}"
fi

# Verificar que se hayan generado algunos archivos WAR
echo -e "${YELLOW}Verificando archivos WAR generados...${NC}"
REQUIRED_WARS=("feature-flags.war" "version-a.war" "version-b.war" "weblogic-features-a.war" "weblogic-features-b.war" "ff4j-simple.war")
MISSING_WARS=()

for war in "${REQUIRED_WARS[@]}"; do
    if [ ! -f "deploy/$war" ]; then
        MISSING_WARS+=("$war")
    fi
done

if [ ${#MISSING_WARS[@]} -gt 0 ]; then
    echo -e "${RED}Advertencia: No se generaron los siguientes archivos WAR:${NC}"
    for war in "${MISSING_WARS[@]}"; do
        echo -e "${RED}- $war${NC}"
    done
    
    echo -e "${YELLOW}Intentando generar los archivos WAR faltantes...${NC}"
    for war in "${MISSING_WARS[@]}"; do
        APP_NAME=${war%.war}
        echo -e "${YELLOW}Generando $APP_NAME...${NC}"
        if [ -f "scripts/build/create-simple-wars.sh" ]; then
            ./scripts/build/create-simple-wars.sh $APP_NAME
        fi
    done
fi

# Mostrar los archivos WAR generados
if ls deploy/*.war 1> /dev/null 2>&1; then
    echo -e "${GREEN}Archivos WAR generados:${NC}"
    ls -la deploy/*.war
else
    echo -e "${YELLOW}No se encontraron archivos WAR en el directorio deploy/${NC}"
fi

# Determinar qué método de construcción usar
BUILD_METHOD="compose"
ENVIRONMENT="all"

# Procesar argumentos de línea de comandos
while [[ $# -gt 0 ]]; do
    case $1 in
        --method)
            BUILD_METHOD="$2"
            shift 2
            ;;
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --help)
            echo "Uso: $0 [opciones]"
            echo ""
            echo "Opciones:"
            echo "  --method [compose|script]  Método de construcción (por defecto: compose)"
            echo "  --env [all|version-a|version-b|feature-flags]  Ambiente a construir (por defecto: all)"
            echo "  --no-cache                 Construir sin usar caché"
            echo "  --help                     Mostrar esta ayuda"
            echo ""
            echo "Ejemplos:"
            echo "  $0                         # Construir todas las imágenes con docker-compose"
            echo "  $0 --method script --env version-a  # Construir solo version-a con script"
            echo "  $0 --no-cache              # Construir sin caché"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Opción desconocida: $1${NC}"
            exit 1
            ;;
    esac
done

# Construir las imágenes según el método seleccionado
if [ "$BUILD_METHOD" = "script" ]; then
    echo -e "${YELLOW}Construyendo imágenes usando script multi-ambiente...${NC}"
    if [ -f "scripts/build/build-multi-env.sh" ]; then
        ./scripts/build/build-multi-env.sh $ENVIRONMENT $NO_CACHE
    else
        echo -e "${RED}Error: No se encontró el script build-multi-env.sh${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Construyendo imágenes usando Docker Compose...${NC}"
    
    # Exportar variables de build
    export BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    export BUILD_VERSION=${BUILD_VERSION:-1.0.0}
    export BUILD_COMMIT=${BUILD_COMMIT:-latest}
    
    # Construir según el ambiente
    if [ "$ENVIRONMENT" = "all" ]; then
        echo -e "${BLUE}Construyendo todas las imágenes...${NC}"
        docker-compose -f config/docker-compose-multi-env.yml build $NO_CACHE
    else
        echo -e "${BLUE}Construyendo imagen para ambiente: $ENVIRONMENT${NC}"
        case $ENVIRONMENT in
            "version-a")
                docker-compose -f config/docker-compose-multi-env.yml build $NO_CACHE weblogic-a
                ;;
            "version-b")
                docker-compose -f config/docker-compose-multi-env.yml build $NO_CACHE weblogic-b
                ;;
            "feature-flags")
                docker-compose -f config/docker-compose-multi-env.yml build $NO_CACHE weblogic-ff
                ;;
            *)
                echo -e "${RED}Error: Ambiente desconocido: $ENVIRONMENT${NC}"
                exit 1
                ;;
        esac
    fi
fi

echo ""
echo -e "${GREEN}=== Construcción completada ===${NC}"
echo ""
echo -e "Para iniciar los contenedores, ejecute:"
echo -e "${YELLOW}  docker-compose -f config/docker-compose-multi-env.yml up -d${NC}"
echo ""
echo -e "Para ver las imágenes construidas:"
echo -e "${YELLOW}  docker images | grep weblogic${NC}"
echo ""
