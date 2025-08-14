#!/bin/bash

# Script para construir y desplegar el dashboard profesional
# Autor: Sistema de Gestión de Tráfico
# Fecha: $(date)

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
DASHBOARD_DIR="$PROJECT_DIR/haproxy/dashboard"

echo -e "${BLUE}=== Construyendo Dashboard Profesional ===${NC}"
echo

# Función para mostrar estado
show_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        exit 1
    fi
}

# Cambiar al directorio del proyecto
cd "$PROJECT_DIR"

echo "1. Verificando estructura del dashboard..."
echo

# Verificar que existan los archivos necesarios
required_files=(
    "$DASHBOARD_DIR/Dockerfile"
    "$DASHBOARD_DIR/serve-dashboard.py"
    "$DASHBOARD_DIR/traffic-dashboard.html"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        show_status 0 "Archivo $(basename "$file") existe"
    else
        show_status 1 "Archivo $(basename "$file") NO existe"
    fi
done

echo
echo "2. Construyendo imagen del dashboard..."
echo

# Construir la imagen del dashboard
if docker build -t dashboard-professional:latest "$DASHBOARD_DIR"; then
    show_status 0 "Imagen del dashboard construida exitosamente"
else
    show_status 1 "Error al construir la imagen del dashboard"
fi

echo
echo "3. Verificando imagen construida..."
echo

# Verificar que la imagen se haya creado
if docker images | grep -q "dashboard-professional"; then
    show_status 0 "Imagen dashboard-professional encontrada"
    docker images | grep dashboard-professional
else
    show_status 1 "Imagen dashboard-professional NO encontrada"
fi

echo
echo "4. Desplegando dashboard..."
echo

# Detener contenedor existente si existe
if docker ps -a | grep -q "dashboard"; then
    echo "Deteniendo contenedor dashboard existente..."
    docker stop dashboard 2>/dev/null || true
    docker rm dashboard 2>/dev/null || true
    show_status 0 "Contenedor dashboard anterior removido"
fi

# Desplegar usando docker-compose
if docker-compose -f config/docker-compose-images.yml up -d dashboard; then
    show_status 0 "Dashboard desplegado exitosamente"
else
    show_status 1 "Error al desplegar el dashboard"
fi

echo
echo "5. Verificando despliegue..."
echo

# Esperar un momento para que el contenedor inicie
sleep 5

# Verificar que el contenedor esté ejecutándose
if docker ps | grep -q "dashboard"; then
    show_status 0 "Contenedor dashboard está ejecutándose"
else
    show_status 1 "Contenedor dashboard NO está ejecutándose"
fi

# Verificar health check
echo "Esperando health check..."
sleep 10

if docker exec dashboard curl -f http://localhost:8000/api/health >/dev/null 2>&1; then
    show_status 0 "Health check del dashboard exitoso"
else
    show_status 1 "Health check del dashboard falló"
fi

echo
echo "6. Probando conectividad..."
echo

# Probar acceso directo
if curl -s --max-time 5 http://localhost:8001/api/health >/dev/null 2>&1; then
    show_status 0 "Acceso directo al dashboard funciona (puerto 8001)"
else
    show_status 1 "Acceso directo al dashboard NO funciona (puerto 8001)"
fi

# Probar acceso a través de HAProxy (si está ejecutándose)
if docker ps | grep -q "haproxy"; then
    if curl -s --max-time 5 http://localhost:8080/dashboard/api/health >/dev/null 2>&1; then
        show_status 0 "Acceso vía HAProxy funciona (puerto 8080/dashboard)"
    else
        show_status 1 "Acceso vía HAProxy NO funciona (puerto 8080/dashboard)"
    fi
else
    echo -e "${YELLOW}⚠${NC} HAProxy no está ejecutándose, no se puede probar acceso vía proxy"
fi

echo
echo -e "${GREEN}=== Dashboard Profesional Desplegado Exitosamente ===${NC}"
echo
echo -e "${BLUE}URLs de Acceso:${NC}"
echo -e "  Dashboard directo:     ${GREEN}http://localhost:8001/${NC}"
echo -e "  Dashboard vía HAProxy: ${GREEN}http://localhost:8080/dashboard/${NC}"
echo -e "  API Health Check:      ${GREEN}http://localhost:8001/api/health${NC}"
echo -e "  API Estadísticas:      ${GREEN}http://localhost:8001/api/stats${NC}"
echo
echo -e "${YELLOW}Nota:${NC} Para probar completamente el dashboard, ejecuta:"
echo -e "  ${BLUE}./scripts/test-dashboard.sh${NC}"
echo
