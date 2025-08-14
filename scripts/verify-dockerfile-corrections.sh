#!/bin/bash

# Script to verify Dockerfile corrections
# Based on DOCKERFILES-CORREGIDOS.md

echo "🔍 Verificando correcciones en Dockerfiles..."
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if file exists
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} $description: $file"
        return 0
    else
        echo -e "${RED}❌${NC} $description: $file (NO ENCONTRADO)"
        return 1
    fi
}

# Function to check if directory exists
check_directory() {
    local dir="$1"
    local description="$2"
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅${NC} $description: $dir"
        return 0
    else
        echo -e "${RED}❌${NC} $description: $dir (NO ENCONTRADO)"
        return 1
    fi
}

# Function to check COPY statements in Dockerfile
check_dockerfile_copy() {
    local dockerfile="$1"
    local expected_pattern="$2"
    local description="$3"
    
    if grep -q "$expected_pattern" "$dockerfile"; then
        echo -e "${GREEN}✅${NC} $description: Ruta COPY corregida"
        return 0
    else
        echo -e "${RED}❌${NC} $description: Ruta COPY no encontrada o incorrecta"
        return 1
    fi
}

echo "1. Verificando Dockerfile de WebLogic..."
echo "----------------------------------------"

# Check WebLogic Dockerfile exists
check_file "docker/Dockerfile" "Dockerfile de WebLogic"

# Check corrected COPY paths in WebLogic Dockerfile
if [ -f "docker/Dockerfile" ]; then
    check_dockerfile_copy "docker/Dockerfile" "oracle/installers/sqlcl-25.2.2.199.0918.zip" "SQLcl path"
    check_dockerfile_copy "docker/Dockerfile" "oracle/scripts/setup/demo_oracle.ddl" "Demo DDL path"
    check_dockerfile_copy "docker/Dockerfile" "deploy/" "Deploy directory path"
fi

echo ""
echo "2. Verificando archivos referenciados por WebLogic Dockerfile..."
echo "----------------------------------------------------------------"

# Check referenced files exist (or have placeholders)
check_directory "oracle/installers" "Directorio de instaladores Oracle"
check_file "oracle/scripts/setup/demo_oracle.ddl" "Script DDL de demostración"
check_directory "container-scripts" "Scripts de contenedor"
check_directory "deploy" "Directorio de despliegue"

echo ""
echo "3. Verificando Dockerfile de HAProxy..."
echo "---------------------------------------"

# Check HAProxy Dockerfile exists
check_file "haproxy/Dockerfile" "Dockerfile de HAProxy"

echo ""
echo "4. Verificando archivos referenciados por HAProxy Dockerfile..."
echo "--------------------------------------------------------------"

# Check HAProxy referenced files
check_file "haproxy/config/haproxy-advanced.cfg" "Configuración avanzada de HAProxy"
check_file "haproxy/scripts/dynamic_routing.lua" "Script Lua de routing dinámico"
check_file "haproxy/scripts/admin_api.py" "API de administración"
check_file "haproxy/scripts/admin_ui.py" "UI de administración"
check_file "haproxy/scripts/start-haproxy.sh" "Script de inicio de HAProxy"
check_directory "haproxy/scripts/templates" "Templates de HAProxy"
check_directory "haproxy/scripts/static" "Archivos estáticos de HAProxy"

echo ""
echo "5. Verificando mejoras adicionales..."
echo "------------------------------------"

# Check additional improvements
check_file ".dockerignore" "Archivo .dockerignore"
check_file "deploy/.gitkeep" "Placeholder en directorio deploy"

echo ""
echo "6. Resumen de verificación..."
echo "----------------------------"

# Count successful checks
total_checks=0
passed_checks=0

# Re-run checks silently to count
files_to_check=(
    "docker/Dockerfile"
    "oracle/scripts/setup/demo_oracle.ddl"
    "haproxy/Dockerfile"
    "haproxy/config/haproxy-advanced.cfg"
    "haproxy/scripts/dynamic_routing.lua"
    "haproxy/scripts/admin_api.py"
    "haproxy/scripts/admin_ui.py"
    "haproxy/scripts/start-haproxy.sh"
    ".dockerignore"
    "deploy/.gitkeep"
)

dirs_to_check=(
    "oracle/installers"
    "container-scripts"
    "deploy"
    "haproxy/scripts/templates"
    "haproxy/scripts/static"
)

for file in "${files_to_check[@]}"; do
    total_checks=$((total_checks + 1))
    if [ -f "$file" ]; then
        passed_checks=$((passed_checks + 1))
    fi
done

for dir in "${dirs_to_check[@]}"; do
    total_checks=$((total_checks + 1))
    if [ -d "$dir" ]; then
        passed_checks=$((passed_checks + 1))
    fi
done

echo "Verificaciones pasadas: $passed_checks/$total_checks"

if [ $passed_checks -eq $total_checks ]; then
    echo -e "${GREEN}🎉 Todas las correcciones han sido implementadas correctamente!${NC}"
    echo ""
    echo "Próximos pasos:"
    echo "1. Descargar archivos requeridos de Oracle (ver oracle/installers/README.md)"
    echo "2. Ejecutar ./start-all.sh para construir y desplegar"
    exit 0
else
    echo -e "${YELLOW}⚠️  Algunas verificaciones fallaron. Revisa los elementos marcados arriba.${NC}"
    exit 1
fi
