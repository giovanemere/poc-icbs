#!/bin/bash

# Script para verificar prerequisitos del proyecto Docker Oracle WebLogic
# Autor: Sistema de Gestión de Prerequisitos
# Fecha: $(date +%Y-%m-%d)

set -e

echo "=============================================="
echo "  Verificación de Prerequisitos del Proyecto"
echo "  Docker Oracle WebLogic con Testing A/B"
echo "=============================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar éxito
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Función para mostrar error
error() {
    echo -e "${RED}✗${NC} $1"
}

# Función para mostrar advertencia
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Variables para tracking de errores
ERRORS=0
WARNINGS=0

echo "=== Verificación de Software ==="

# Verificar Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    success "Docker encontrado: $DOCKER_VERSION"
    
    # Verificar si Docker está corriendo
    if docker info &> /dev/null; then
        success "Docker daemon está corriendo"
    else
        error "Docker daemon no está corriendo"
        ERRORS=$((ERRORS + 1))
    fi
else
    error "Docker no encontrado"
    ERRORS=$((ERRORS + 1))
fi

# Verificar Docker Compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
    success "Docker Compose encontrado: $COMPOSE_VERSION"
else
    error "Docker Compose no encontrado"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "=== Verificación de Archivos Requeridos ==="

# Verificar WebLogic Server installer
if [ -f "docker/weblogic/installers/fmw_14.1.1.0.0_wls_Disk1_1of1.zip" ]; then
    FILE_SIZE=$(du -h "docker/weblogic/installers/fmw_14.1.1.0.0_wls_Disk1_1of1.zip" | cut -f1)
    success "WebLogic Server installer encontrado (${FILE_SIZE})"
else
    error "WebLogic Server installer no encontrado en docker/weblogic/installers/"
    echo "       Archivo esperado: fmw_14.1.1.0.0_wls_Disk1_1of1.zip"
    ERRORS=$((ERRORS + 1))
fi

# Verificar SQLcl installer
if [ -f "oracle/installers/sqlcl-25.2.2.199.0918.zip" ]; then
    FILE_SIZE=$(du -h "oracle/installers/sqlcl-25.2.2.199.0918.zip" | cut -f1)
    success "SQLcl installer encontrado (${FILE_SIZE})"
else
    error "SQLcl installer no encontrado en oracle/installers/"
    echo "       Archivo esperado: sqlcl-25.2.2.199.0918.zip"
    ERRORS=$((ERRORS + 1))
fi

# Verificar scripts de demo
if [ -f "oracle/scripts/setup/demo_oracle.ddl" ]; then
    FILE_SIZE=$(du -h "oracle/scripts/setup/demo_oracle.ddl" | cut -f1)
    success "Scripts de demo encontrados (${FILE_SIZE})"
else
    error "Scripts de demo no encontrados en oracle/scripts/setup/"
    echo "       Archivo esperado: demo_oracle.ddl"
    ERRORS=$((ERRORS + 1))
fi

# Verificar archivo .env
if [ -f ".env" ]; then
    FILE_SIZE=$(du -h ".env" | cut -f1)
    success "Archivo de configuración .env encontrado (${FILE_SIZE})"
    
    # Verificar variables críticas en .env
    if grep -q "ORACLE_PWD=" .env && grep -q "WEBLOGIC_A_ADMIN_PASSWORD=" .env; then
        success "Variables críticas encontradas en .env"
    else
        warning "Algunas variables críticas pueden faltar en .env"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    error "Archivo .env no encontrado en el directorio raíz"
    echo "       Este archivo contiene las variables de entorno necesarias"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "=== Verificación de Recursos del Sistema ==="

# Verificar RAM disponible
if command -v free &> /dev/null; then
    TOTAL_RAM=$(free -g | awk 'NR==2{print $2}')
    AVAILABLE_RAM=$(free -g | awk 'NR==2{print $7}')
    
    if [ "$AVAILABLE_RAM" -ge 8 ]; then
        success "RAM disponible: ${AVAILABLE_RAM}GB (Total: ${TOTAL_RAM}GB)"
    elif [ "$AVAILABLE_RAM" -ge 4 ]; then
        warning "RAM disponible: ${AVAILABLE_RAM}GB (Recomendado: 8GB+)"
        WARNINGS=$((WARNINGS + 1))
    else
        error "RAM insuficiente: ${AVAILABLE_RAM}GB (Mínimo: 8GB)"
        ERRORS=$((ERRORS + 1))
    fi
else
    warning "No se pudo verificar la RAM disponible"
    WARNINGS=$((WARNINGS + 1))
fi

# Verificar espacio en disco
AVAILABLE_DISK_KB=$(df . | awk 'NR==2{print $4}')
AVAILABLE_DISK_GB=$((AVAILABLE_DISK_KB / 1024 / 1024))

if [ "$AVAILABLE_DISK_GB" -ge 20 ]; then
    success "Espacio en disco disponible: ${AVAILABLE_DISK_GB}GB"
elif [ "$AVAILABLE_DISK_GB" -ge 10 ]; then
    warning "Espacio en disco disponible: ${AVAILABLE_DISK_GB}GB (Recomendado: 20GB+)"
    WARNINGS=$((WARNINGS + 1))
else
    error "Espacio en disco insuficiente: ${AVAILABLE_DISK_GB}GB (Mínimo: 20GB)"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "=== Verificación de Puertos ==="

# Lista de puertos que el proyecto necesita
REQUIRED_PORTS=(8080 8443 8404 8081 8082 7001 7002 1521 5500)

for port in "${REQUIRED_PORTS[@]}"; do
    if command -v netstat &> /dev/null; then
        if netstat -tuln | grep -q ":$port "; then
            warning "Puerto $port ya está en uso"
            WARNINGS=$((WARNINGS + 1))
        else
            success "Puerto $port disponible"
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln | grep -q ":$port "; then
            warning "Puerto $port ya está en uso"
            WARNINGS=$((WARNINGS + 1))
        else
            success "Puerto $port disponible"
        fi
    else
        warning "No se pudo verificar disponibilidad del puerto $port"
        WARNINGS=$((WARNINGS + 1))
        break
    fi
done

echo ""
echo "=== Verificación de Imágenes Docker ==="

# Lista de imágenes requeridas
REQUIRED_IMAGES=(
    "edissonz8809/weblogic-feature-flags:v1.1.0"
    "edissonz8809/haproxy-advanced:v1.1.0"
    "edissonz8809/oracle-express-db:v1.1.0"
)

for image in "${REQUIRED_IMAGES[@]}"; do
    if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^$image$"; then
        success "Imagen Docker encontrada: $image"
    else
        error "Imagen Docker no encontrada: $image"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "=== Verificación de Dockerfiles ==="

# Verificar si se están usando imágenes preexistentes
if grep -q "image: edissonz8809/" config/docker-compose.yml; then
    success "Usando imágenes Docker preexistentes - Dockerfiles no requeridos"
else
    # Verificar Dockerfile de WebLogic solo si no se usan imágenes preexistentes
    if [ -f "docker/Dockerfile" ]; then
        success "Dockerfile de WebLogic encontrado"
        
        # Verificar que las rutas COPY sean correctas
        if grep -q "oracle/installers/sqlcl" docker/Dockerfile && grep -q "oracle/scripts/setup/demo_oracle.ddl" docker/Dockerfile; then
            success "Rutas COPY en Dockerfile de WebLogic son correctas"
        else
            error "Rutas COPY en Dockerfile de WebLogic son incorrectas"
            ERRORS=$((ERRORS + 1))
        fi
    else
        error "Dockerfile de WebLogic no encontrado en docker/"
        ERRORS=$((ERRORS + 1))
    fi

    # Verificar Dockerfile de HAProxy
    if [ -f "haproxy/Dockerfile" ]; then
        success "Dockerfile de HAProxy encontrado"
        
        # Verificar archivos referenciados
        if [ -f "haproxy/config/haproxy-advanced.cfg" ] && [ -d "haproxy/scripts" ]; then
            success "Archivos referenciados por Dockerfile de HAProxy existen"
        else
            error "Algunos archivos referenciados por Dockerfile de HAProxy no existen"
            ERRORS=$((ERRORS + 1))
        fi
    else
        error "Dockerfile de HAProxy no encontrado en haproxy/"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Verificar directorios principales
REQUIRED_DIRS=(
    "config"
    "docker/weblogic/installers"
    "oracle/installers"
    "oracle/scripts/setup"
    "haproxy"
    "scripts"
    "deploy"
    "autodeploy"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        success "Directorio $dir existe"
    else
        error "Directorio $dir no existe"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "=============================================="
echo "  Resumen de Verificación"
echo "=============================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Todos los prerequisitos están cumplidos${NC}"
    echo "El proyecto está listo para ser desplegado."
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Prerequisitos cumplidos con $WARNINGS advertencia(s)${NC}"
    echo "El proyecto puede funcionar, pero revisa las advertencias."
else
    echo -e "${RED}✗ Se encontraron $ERRORS error(es) y $WARNINGS advertencia(s)${NC}"
    echo "Corrige los errores antes de continuar."
fi

echo ""
echo "=== Próximos Pasos ==="
if [ $ERRORS -eq 0 ]; then
    echo "1. Ejecutar: ./start-all.sh"
    echo "2. Verificar servicios: docker-compose -f config/docker-compose.yml ps"
    echo "3. Acceder al panel: http://localhost:8082"
else
    echo "1. Corregir los errores mostrados arriba"
    echo "2. Volver a ejecutar este script"
    echo "3. Consultar docs/prerequisites.md para más información"
fi

echo ""
exit $ERRORS
