#!/bin/bash

# =============================================================================
# Script Unificado para Iniciar Todo el Sistema WebLogic
# Combina: start-complete-system.sh + manage-admin-panel.sh start
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Banner
echo -e "${PURPLE}"
echo "============================================================================="
echo "🚀 INICIANDO SISTEMA COMPLETO WEBLOGIC UNIFICADO"
echo "============================================================================="
echo -e "${NC}"

# =============================================================================
# FASE 1: VERIFICACIÓN DE PREREQUISITOS
# =============================================================================
log "FASE 1: Verificando prerequisitos..."

if ! command -v docker &> /dev/null; then
    error "Docker no está instalado"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose no está instalado"
    exit 1
fi

if ! docker info &> /dev/null; then
    error "Docker no está corriendo"
    exit 1
fi

success "Docker está disponible y corriendo"

# Verificar archivos necesarios
if [ ! -f "config/docker-compose.yml" ]; then
    error "No se encontró config/docker-compose.yml"
    exit 1
fi

if [ ! -f ".env" ]; then
    warning "No se encontró .env, usando valores por defecto"
fi

success "Archivos de configuración encontrados"

# Verificar imágenes Docker
log "Verificando imágenes Docker..."
if [ -f "./check-images.sh" ]; then
    ./check-images.sh
    success "Todas las imágenes están disponibles"
else
    warning "Script check-images.sh no encontrado, continuando..."
fi

# =============================================================================
# FASE 2: LIMPIEZA DE CONTENEDORES EXISTENTES
# =============================================================================
log "FASE 2: Limpiando contenedores existentes..."

# Parar servicios existentes
docker-compose -f config/docker-compose.yml down --remove-orphans 2>/dev/null || true

# Limpiar contenedores huérfanos específicos
docker stop haproxy weblogic-a weblogic-b orcldb haproxy-integrated weblogic-a-integrated weblogic-b-integrated orcldb-integrated 2>/dev/null || true
docker rm haproxy weblogic-a weblogic-b orcldb haproxy-integrated weblogic-a-integrated weblogic-b-integrated orcldb-integrated 2>/dev/null || true

success "Contenedores existentes limpiados"

# Limpiar redes huérfanas
log "Limpiando redes..."
docker network prune -f 2>/dev/null || true
success "Redes limpiadas"

# =============================================================================
# FASE 3: PREPARACIÓN DEL ENTORNO
# =============================================================================
log "FASE 3: Preparando entorno..."

# Crear directorios necesarios
mkdir -p autodeploy deploy logs/{oracle,weblogic-a,weblogic-b,haproxy}
success "Directorios creados"

# =============================================================================
# FASE 4: INICIO DE SERVICIOS DOCKER
# =============================================================================
log "FASE 4: Iniciando servicios Docker..."
echo -e "${CYAN}Usando: config/docker-compose.yml${NC}"

# Iniciar en modo detached
if docker-compose -f config/docker-compose.yml up -d; then
    success "Servicios Docker iniciados correctamente"
else
    error "Error al iniciar servicios Docker"
    exit 1
fi

# =============================================================================
# FASE 5: ESPERA E INICIALIZACIÓN
# =============================================================================
log "FASE 5: Esperando inicialización de servicios..."

# Función para verificar si un servicio está listo
wait_for_service() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=1
    
    echo -n "Esperando $service_name"
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo ""
            success "$service_name está listo"
            return 0
        fi
        echo -n "."
        sleep 5
        ((attempt++))
    done
    echo ""
    warning "$service_name no respondió después de $((max_attempts * 5)) segundos"
    return 1
}

# Esperar por Oracle DB
wait_for_service "Oracle Database" "http://localhost:5500" || true

# Esperar por WebLogic A
wait_for_service "WebLogic A" "http://localhost:7001/console" || true

# Esperar por WebLogic B
wait_for_service "WebLogic B" "http://localhost:7002/console" || true

# Esperar por HAProxy
wait_for_service "HAProxy Stats" "http://localhost:8404/stats" || true

# =============================================================================
# FASE 6: INICIO DE DASHBOARDS INDEPENDIENTES
# =============================================================================
log "FASE 6: Iniciando dashboards independientes..."

# Verificar que HAProxy esté corriendo
if ! curl -s -u admin:admin123 http://localhost:8404/stats > /dev/null 2>&1; then
    warning "HAProxy no está accesible. Iniciando servicios con funcionalidad limitada."
else
    success "HAProxy está accesible"
fi

# Iniciar Dashboard Unificado
log "Iniciando Dashboard Unificado..."
if [ -f "./manage-admin-panel.sh" ]; then
    # Ejecutar solo la parte del dashboard unificado del manage-admin-panel.sh
    ./manage-admin-panel.sh start > /dev/null 2>&1 || warning "Algunos dashboards pueden no haber iniciado correctamente"
    success "Dashboards independientes iniciados"
else
    warning "manage-admin-panel.sh no encontrado"
fi

# =============================================================================
# FASE 7: VERIFICACIÓN DE ESTADO
# =============================================================================
log "FASE 7: Verificando estado del sistema..."

# Mostrar estado de los contenedores
echo -e "${CYAN}Estado de los contenedores:${NC}"
docker-compose -f config/docker-compose.yml ps

# Verificar URLs principales
log "Verificando URLs principales..."

check_url() {
    local name=$1
    local url=$2
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
        success "$name: $url ✅"
    else
        warning "$name: $url ❌"
    fi
}

echo ""
echo -e "${PURPLE}🌐 URLs del Sistema:${NC}"
echo ""

echo -e "${GREEN}🎛️ Dashboards Principales:${NC}"
check_url "Dashboard Unificado" "http://localhost:8085/unified-dashboard-fixed.html"
check_url "Dashboard de Tráfico" "http://localhost:8084/"

echo ""
echo -e "${GREEN}🔧 Administración HAProxy:${NC}"
check_url "Panel HAProxy" "http://localhost:8092/"
check_url "API Admin" "http://localhost:8093/api/health"
check_url "HAProxy Stats" "http://localhost:8404/stats"

echo ""
echo -e "${GREEN}🌐 Frontend y Aplicaciones:${NC}"
check_url "Frontend Principal" "http://localhost:8100/"
check_url "Version A" "http://localhost:8100/version-a/"
check_url "Version B" "http://localhost:8100/version-b/"
check_url "Feature Flags" "http://localhost:8100/feature-flags/"

echo ""
echo -e "${GREEN}🔧 Consolas WebLogic:${NC}"
check_url "WebLogic A Console" "http://localhost:7001/console"
check_url "WebLogic B Console" "http://localhost:7002/console"

echo ""
echo -e "${GREEN}🗄️ Oracle Database:${NC}"
check_url "Oracle Enterprise Manager" "http://localhost:5500/em"

# =============================================================================
# FASE 8: RESUMEN FINAL
# =============================================================================
echo ""
echo -e "${PURPLE}=============================================================================${NC}"
echo -e "${GREEN}🎉 SISTEMA COMPLETO INICIADO CORRECTAMENTE${NC}"
echo -e "${PURPLE}=============================================================================${NC}"
echo ""

echo -e "${CYAN}📋 URLs Principales:${NC}"
echo -e "   🎛️ Dashboard Principal: ${YELLOW}http://localhost:8085/unified-dashboard-fixed.html${NC}"
echo -e "   📊 Dashboard de Tráfico: ${YELLOW}http://localhost:8084/${NC}"
echo -e "   🌐 Frontend Principal: ${YELLOW}http://localhost:8100/${NC}"
echo -e "   📈 HAProxy Stats: ${YELLOW}http://localhost:8404/stats${NC} (admin/admin123)"
echo ""

echo -e "${CYAN}🔧 Comandos útiles:${NC}"
echo -e "   Ver logs: ${YELLOW}docker-compose -f config/docker-compose.yml logs -f${NC}"
echo -e "   Parar todo: ${YELLOW}docker-compose -f config/docker-compose.yml down${NC}"
echo -e "   Reiniciar: ${YELLOW}./start-unified-system.sh${NC}"
echo -e "   Estado: ${YELLOW}docker-compose -f config/docker-compose.yml ps${NC}"
echo ""

echo -e "${GREEN}🎯 URLs Completas del Sistema:${NC}"
echo ""
echo -e "${GREEN}🎛️ Dashboard Unificado (RECOMENDADO):${NC}"
echo -e "  ${PURPLE}http://localhost:8085/unified-dashboard-fixed.html${NC}  ⭐ Dashboard Principal"
echo -e "  ${CYAN}📊 Control A/B Testing + Canary + URLs Activas + Métricas${NC}"
echo ""
echo -e "${GREEN}📊 Dashboard de Tráfico WebLogic:${NC}"
echo -e "  ${PURPLE}http://localhost:8084/${NC}                    📊 Dashboard de Tráfico"
echo -e "  ${CYAN}http://localhost:8084/api/stats${NC}            📊 API de Estadísticas"
echo -e "  ${CYAN}http://localhost:8084/api/health${NC}           🔍 Health Check"
echo -e "  ${CYAN}http://localhost:8084/api/ab/enable${NC}        🎯 A/B Testing API"
echo -e "  ${CYAN}http://localhost:8084/api/canary/enable${NC}    🚀 Canary Deployment API"
echo -e "  ${CYAN}http://localhost:8084/api/reset${NC}            🔄 Reset Stats API"
echo ""
echo -e "${GREEN}🎛️ Panel de Administración HAProxy:${NC}"
echo "  http://localhost:8092/index-functional.html"
echo "  http://localhost:8092/"
echo ""
echo -e "${GREEN}📡 API de Administración:${NC}"
echo "  http://localhost:8093/api/health"
echo "  http://localhost:8093/api/status"
echo ""
echo -e "${GREEN}📈 Estadísticas HAProxy:${NC}"
echo "  http://localhost:8404/stats (admin/admin123)"
echo ""
echo -e "${GREEN}🌐 Frontend Principal:${NC}"
echo "  http://localhost:8100/"
echo ""
echo -e "${GREEN}🚀 Aplicaciones de Prueba:${NC}"
echo "  http://localhost:8100/version-a/"
echo "  http://localhost:8100/version-b/"
echo "  http://localhost:8100/feature-flags/"
echo "  http://localhost:8100/ff4j-simple/"
echo ""
echo -e "${GREEN}🔧 Consolas WebLogic:${NC}"
echo "  http://localhost:7001/console (weblogic/welcome1)"
echo "  http://localhost:7002/console (weblogic/welcome1)"
echo ""

echo -e "${CYAN}💡 Tip: Los dashboards independientes (8084, 8085, 8092, 8093) son los más confiables${NC}"
echo -e "${CYAN}    y funcionan independientemente de HAProxy.${NC}"
echo ""

echo -e "${GREEN}✨ ¡Sistema completo listo para usar!${NC}"
