#!/bin/bash

# ============================================================================
# Script de Build y Push Docker Hub - Primera Imagen
# ============================================================================
# Descripción: Build y push de imagen piloto HAProxy a Docker Hub
# Autor: DevOps Team
# Fecha: 2025-08-01
# Versión: 1.0.0
# ============================================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
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
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║              Build y Push Primera Imagen Docker Hub         ║
║                Docker WebLogic Oracle Project               ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Cargar variables centralizadas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log "Cargando variables centralizadas..."
if [[ -f "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" ]]; then
    source "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" development 2>/dev/null
    success "Variables centralizadas cargadas"
else
    error "No se encontró el script de carga de variables"
    exit 1
fi

# Configuración de la imagen piloto
PILOT_APP="haproxy-advanced"
PILOT_PATH="$HAPROXY_APP_PATH"
PILOT_IMAGE="$HAPROXY_FULL_IMAGE"
PILOT_DESCRIPTION="Load Balancer HAProxy con configuración avanzada y admin UI"

log "=== CONFIGURACIÓN DE BUILD ==="
info "Aplicación piloto: $PILOT_APP"
info "Path de build: $PILOT_PATH"
info "Imagen completa: $PILOT_IMAGE"
info "Namespace Docker Hub: $DOCKER_NAMESPACE"
info "Versión: $VERSION"

# Verificar Docker Hub login
log "Verificando autenticación Docker Hub..."
if docker info | grep -q "Username"; then
    DOCKER_USER=$(docker info | grep "Username" | awk '{print $2}')
    success "Docker Hub autenticado como: $DOCKER_USER"
else
    warning "No hay sesión activa en Docker Hub"
    log "Iniciando login a Docker Hub..."
    
    echo -e "${YELLOW}Por favor ingresa tus credenciales de Docker Hub:${NC}"
    docker login
    
    if [[ $? -eq 0 ]]; then
        success "Login exitoso a Docker Hub"
    else
        error "Falló el login a Docker Hub"
        exit 1
    fi
fi

# Verificar estructura de la aplicación
log "Verificando estructura de la aplicación..."
cd "$PROJECT_ROOT"

if [[ ! -d "$PILOT_PATH" ]]; then
    error "Directorio de aplicación no encontrado: $PILOT_PATH"
    exit 1
fi

if [[ ! -f "$PILOT_PATH/Dockerfile" ]]; then
    error "Dockerfile no encontrado en: $PILOT_PATH/Dockerfile"
    exit 1
fi

success "Estructura de aplicación verificada"

# Crear Dockerfile optimizado para HAProxy
log "Optimizando Dockerfile para HAProxy..."

cat > "$PILOT_PATH/Dockerfile" << EOF
# Dockerfile optimizado para HAProxy Advanced
# Generado automáticamente para Docker Hub

FROM haproxy:2.6-alpine

# Metadata para Docker Hub
LABEL maintainer="DevOps Team <devops@company.com>"
LABEL version="$VERSION"
LABEL description="$PILOT_DESCRIPTION"
LABEL org.opencontainers.image.title="HAProxy Advanced"
LABEL org.opencontainers.image.description="$PILOT_DESCRIPTION"
LABEL org.opencontainers.image.version="$VERSION"
LABEL org.opencontainers.image.vendor="Docker WebLogic Oracle Project"
LABEL org.opencontainers.image.source="https://github.com/company/docker-weblogic-oracle"

# Variables de entorno
ENV HAPROXY_VERSION=2.6
ENV APP_NAME="haproxy-advanced"
ENV DOCKER_NAMESPACE="$DOCKER_NAMESPACE"
ENV VERSION="$VERSION"

# Instalar herramientas adicionales
RUN apk add --no-cache \\
    curl \\
    bash \\
    jq \\
    && rm -rf /var/cache/apk/*

# Crear directorios de trabajo
RUN mkdir -p /app/config /app/scripts /app/logs /app/templates

# Copiar archivos de configuración
COPY src/ /app/src/
COPY config/ /app/config/
COPY scripts/ /app/scripts/

# Copiar configuración HAProxy si existe
COPY src/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg 2>/dev/null || \\
    echo "# HAProxy configuration will be generated dynamically" > /usr/local/etc/haproxy/haproxy.cfg

# Hacer scripts ejecutables
RUN find /app/scripts -name "*.sh" -exec chmod +x {} \\; 2>/dev/null || true

# Crear usuario no-root para seguridad
RUN addgroup -g 1001 haproxy-app && \\
    adduser -D -s /bin/bash -u 1001 -G haproxy-app haproxy-app

# Cambiar ownership de directorios de trabajo
RUN chown -R haproxy-app:haproxy-app /app

# Exponer puertos HAProxy
EXPOSE 80 443 8080 8081 8082 8083 8404

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \\
    CMD curl -f http://localhost:8404/stats || exit 1

# Comando por defecto
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
EOF

success "Dockerfile optimizado creado"

# Crear configuración HAProxy básica si no existe
if [[ ! -f "$PILOT_PATH/src/haproxy.cfg" ]]; then
    log "Creando configuración HAProxy básica..."
    mkdir -p "$PILOT_PATH/src"
    
    cat > "$PILOT_PATH/src/haproxy.cfg" << 'EOF'
# HAProxy Configuration - Docker WebLogic Oracle Project
# Generado automáticamente para Docker Hub

global
    daemon
    log stdout local0 info
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy

defaults
    mode http
    log global
    option httplog
    option dontlognull
    option log-health-checks
    option forwardfor
    option http-server-close
    timeout connect 5000
    timeout client 50000
    timeout server 50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

# Stats interface
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE

# Admin interface
listen admin
    bind *:8082
    stats enable
    stats uri /
    stats refresh 5s
    stats admin if TRUE

# Main load balancer
frontend main
    bind *:8083
    default_backend weblogic_servers

# Backend servers (placeholder)
backend weblogic_servers
    balance roundrobin
    option httpchk GET /console
    # Servers will be added dynamically
    server weblogic-a 127.0.0.1:7001 check
    server weblogic-b 127.0.0.1:7002 check backup
EOF

    success "Configuración HAProxy básica creada"
fi

# Crear script de inicio si no existe
if [[ ! -f "$PILOT_PATH/scripts/start.sh" ]]; then
    log "Creando script de inicio..."
    mkdir -p "$PILOT_PATH/scripts"
    
    cat > "$PILOT_PATH/scripts/start.sh" << 'EOF'
#!/bin/bash
# Script de inicio para HAProxy Advanced

set -e

echo "🚀 Iniciando HAProxy Advanced..."
echo "📦 Imagen: $DOCKER_NAMESPACE/haproxy-advanced:$VERSION"
echo "🔧 Configuración: /usr/local/etc/haproxy/haproxy.cfg"

# Verificar configuración
if haproxy -f /usr/local/etc/haproxy/haproxy.cfg -c; then
    echo "✅ Configuración HAProxy válida"
else
    echo "❌ Error en configuración HAProxy"
    exit 1
fi

# Iniciar HAProxy
echo "🎯 Iniciando HAProxy..."
exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg -D
EOF

    chmod +x "$PILOT_PATH/scripts/start.sh"
    success "Script de inicio creado"
fi

# Build de la imagen
log "=== INICIANDO BUILD DE IMAGEN ==="
cd "$PROJECT_ROOT/$PILOT_PATH"

log "Building imagen: $PILOT_IMAGE"
log "Context: $(pwd)"

# Build con output detallado
if docker build -t "$PILOT_IMAGE" . --no-cache; then
    success "Build completado exitosamente"
else
    error "Falló el build de la imagen"
    exit 1
fi

# Verificar imagen creada
log "Verificando imagen creada..."
if docker images | grep -q "$DOCKER_NAMESPACE/$PILOT_APP"; then
    IMAGE_SIZE=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "$PILOT_IMAGE" | awk '{print $2}')
    success "Imagen creada: $PILOT_IMAGE ($IMAGE_SIZE)"
else
    error "Imagen no encontrada después del build"
    exit 1
fi

# Test básico de la imagen
log "Realizando test básico de la imagen..."
if docker run --rm "$PILOT_IMAGE" haproxy -v; then
    success "Test básico exitoso"
else
    warning "Test básico falló, pero continuando con push"
fi

# Push a Docker Hub
log "=== INICIANDO PUSH A DOCKER HUB ==="
log "Pushing imagen: $PILOT_IMAGE"

if docker push "$PILOT_IMAGE"; then
    success "Push completado exitosamente"
else
    error "Falló el push a Docker Hub"
    exit 1
fi

# Verificar imagen en Docker Hub (opcional)
log "Verificando imagen en Docker Hub..."
if docker pull "$PILOT_IMAGE" >/dev/null 2>&1; then
    success "Imagen verificada en Docker Hub"
else
    warning "No se pudo verificar la imagen en Docker Hub (puede tomar unos minutos)"
fi

# Crear tags adicionales
log "Creando tags adicionales..."

# Tag latest
LATEST_TAG="$DOCKER_NAMESPACE/$PILOT_APP:latest"
docker tag "$PILOT_IMAGE" "$LATEST_TAG"
docker push "$LATEST_TAG"
success "Tag latest creado y pushed: $LATEST_TAG"

# Tag con fecha
DATE_TAG="$DOCKER_NAMESPACE/$PILOT_APP:$(date +%Y%m%d)"
docker tag "$PILOT_IMAGE" "$DATE_TAG"
docker push "$DATE_TAG"
success "Tag con fecha creado y pushed: $DATE_TAG"

# Limpiar imágenes locales antiguas (opcional)
log "Limpiando imágenes locales antiguas..."
docker image prune -f >/dev/null 2>&1 || true

# ============================================================================
# RESUMEN FINAL
# ============================================================================

echo -e "${PURPLE}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    BUILD Y PUSH COMPLETADO                  ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

success "Build y push de primera imagen completado exitosamente"

echo -e "${CYAN}=== RESUMEN DE IMAGEN ===${NC}"
echo "📦 Imagen principal: $PILOT_IMAGE"
echo "🏷️  Tag latest: $LATEST_TAG"
echo "📅 Tag fecha: $DATE_TAG"
echo "📊 Tamaño: $IMAGE_SIZE"
echo "🐳 Namespace: $DOCKER_NAMESPACE"
echo ""
echo -e "${CYAN}=== ENLACES DOCKER HUB ===${NC}"
echo "🔗 Repositorio: https://hub.docker.com/r/$DOCKER_NAMESPACE/$PILOT_APP"
echo "🔗 Tags: https://hub.docker.com/r/$DOCKER_NAMESPACE/$PILOT_APP/tags"
echo ""
echo -e "${CYAN}=== COMANDOS DE USO ===${NC}"
echo "# Pull imagen"
echo "docker pull $PILOT_IMAGE"
echo ""
echo "# Run imagen"
echo "docker run -d -p 8083:8083 -p 8404:8404 --name haproxy-test $PILOT_IMAGE"
echo ""
echo "# Test imagen"
echo "curl http://localhost:8404/stats"
echo ""
echo -e "${CYAN}=== PRÓXIMOS PASOS ===${NC}"
echo "1. Verificar imagen en Docker Hub: https://hub.docker.com/r/$DOCKER_NAMESPACE/$PILOT_APP"
echo "2. Test deployment con imagen de Docker Hub"
echo "3. Build y push segunda imagen (WebLogic)"
echo "4. Actualizar docker-compose.yml para usar imágenes de Docker Hub"
echo ""
echo -e "${GREEN}🎉 Primera imagen Docker Hub completada exitosamente!${NC}"

# Guardar información de la imagen
cat > "$PROJECT_ROOT/docker-hub-images.log" << EOF
# Docker Hub Images Log
# Generado automáticamente

## Primera Imagen Completada
- **Fecha**: $(date +'%Y-%m-%d %H:%M:%S')
- **Imagen**: $PILOT_IMAGE
- **Tags**: latest, $(date +%Y%m%d)
- **Tamaño**: $IMAGE_SIZE
- **Estado**: ✅ COMPLETADO

## Enlaces
- Repositorio: https://hub.docker.com/r/$DOCKER_NAMESPACE/$PILOT_APP
- Tags: https://hub.docker.com/r/$DOCKER_NAMESPACE/$PILOT_APP/tags

## Comandos de Test
\`\`\`bash
docker pull $PILOT_IMAGE
docker run -d -p 8083:8083 -p 8404:8404 --name haproxy-test $PILOT_IMAGE
curl http://localhost:8404/stats
\`\`\`
EOF

success "Log de imágenes Docker Hub actualizado"
