#!/bin/bash
#
# Script para hacer un build local de los proyectos WAR
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Build Local de Proyectos WAR ===${NC}"
echo ""

# Verificar si Maven está instalado
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}Error: Maven no está instalado${NC}"
    echo "Por favor, instale Maven con:"
    echo -e "${YELLOW}  sudo apt-get install maven${NC}"
    exit 1
fi

# Directorio base
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.."
WAR_PROJECTS_DIR="$BASE_DIR/war-projects"
DEPLOY_DIR="$BASE_DIR/deploy"

# Crear directorio de despliegue si no existe
mkdir -p "$DEPLOY_DIR"

# Función para construir un proyecto WAR
build_war() {
    local project_dir="$1"
    local project_name=$(basename "$project_dir")
    
    echo -e "${BLUE}=== Construyendo $project_name ===${NC}"
    
    # Verificar si el directorio existe
    if [ ! -d "$project_dir" ]; then
        echo -e "${RED}Error: El directorio $project_dir no existe${NC}"
        return 1
    fi
    
    # Verificar si existe el archivo pom.xml
    if [ ! -f "$project_dir/pom.xml" ]; then
        echo -e "${RED}Error: No se encontró el archivo pom.xml en $project_dir${NC}"
        return 1
    }
    
    # Construir el proyecto con Maven
    echo -e "${YELLOW}Ejecutando Maven clean install...${NC}"
    (cd "$project_dir" && mvn clean install -DskipTests)
    
    # Verificar si la construcción fue exitosa
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: La construcción de $project_name falló${NC}"
        return 1
    fi
    
    # Copiar el archivo WAR al directorio de despliegue
    local war_file=$(find "$project_dir/target" -name "*.war" | head -n 1)
    
    if [ -z "$war_file" ]; then
        echo -e "${RED}Error: No se encontró el archivo WAR en $project_dir/target${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Copiando $war_file a $DEPLOY_DIR/${project_name}.war${NC}"
    cp "$war_file" "$DEPLOY_DIR/${project_name}.war"
    
    echo -e "${GREEN}$project_name construido y copiado correctamente${NC}"
    echo ""
    
    return 0
}

# Función para construir todos los proyectos WAR
build_all() {
    echo -e "${YELLOW}Construyendo todos los proyectos WAR...${NC}"
    
    # Buscar todos los directorios que contienen un archivo pom.xml
    find "$WAR_PROJECTS_DIR" -name "pom.xml" -type f | while read -r pom_file; do
        project_dir=$(dirname "$pom_file")
        build_war "$project_dir"
    done
    
    echo -e "${GREEN}Todos los proyectos WAR han sido construidos${NC}"
}

# Función para mostrar ayuda
show_help() {
    echo -e "${GREEN}=== Script de Build Local para Proyectos WAR ===${NC}"
    echo ""
    echo -e "Uso: $0 [opciones] [proyecto]"
    echo ""
    echo -e "Opciones:"
    echo -e "  ${YELLOW}--all${NC}         Construir todos los proyectos WAR"
    echo -e "  ${YELLOW}--help${NC}        Mostrar esta ayuda"
    echo ""
    echo -e "Ejemplos:"
    echo -e "  $0 --all                # Construir todos los proyectos WAR"
    echo -e "  $0 feature-flags        # Construir solo el proyecto feature-flags"
    echo ""
}

# Procesar argumentos
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

case "$1" in
    --all)
        build_all
        ;;
    --help)
        show_help
        exit 0
        ;;
    *)
        project_dir="$WAR_PROJECTS_DIR/$1"
        if [ -d "$project_dir" ]; then
            build_war "$project_dir"
        else
            echo -e "${RED}Error: No se encontró el proyecto $1${NC}"
            echo "Los proyectos disponibles son:"
            find "$WAR_PROJECTS_DIR" -maxdepth 1 -type d | grep -v "^$WAR_PROJECTS_DIR\$" | while read -r dir; do
                echo -e "  ${YELLOW}$(basename "$dir")${NC}"
            done
            exit 1
        fi
        ;;
esac

echo ""
echo -e "${GREEN}=== Build completado ===${NC}"
echo ""
echo -e "Los archivos WAR están disponibles en: ${YELLOW}$DEPLOY_DIR${NC}"
echo ""
echo -e "Para desplegar los archivos WAR, ejecute:"
echo -e "${YELLOW}  ./scripts/deploy/deploy-war.sh --all${NC}"
echo ""
echo -e "Para limpiar todas las cachés y desplegar, ejecute:"
echo -e "${YELLOW}  ./scripts/deploy/deploy-war.sh --clean-all${NC}"
echo ""
