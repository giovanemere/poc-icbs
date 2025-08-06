#!/bin/bash

echo "🔄 REGENERACIÓN SIMPLE DE IMÁGENES HAProxy y MkDocs"
echo "=================================================="
echo "Fecha: $(date)"
echo ""

# Función para logging
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# =============================================================================
# PASO 1: CREAR DOCKERFILE HAPROXY SIMPLIFICADO
# =============================================================================
log "⚖️ Creando Dockerfile HAProxy simplificado..."

cat > docker/Dockerfile.haproxy << 'EOF'
FROM haproxy:2.6

# Cambiar a usuario root
USER root

# Instalar curl para health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Crear directorios necesarios
RUN mkdir -p /var/run/haproxy \
    && mkdir -p /var/log/haproxy \
    && chown -R haproxy:haproxy /var/run/haproxy \
    && chown -R haproxy:haproxy /var/log/haproxy

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8404/stats || exit 1

# Exponer puertos
EXPOSE 80 443 8082 8084 8404

# Volver a usuario haproxy
USER haproxy

# Comando de inicio
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg", "-D"]
EOF

# =============================================================================
# PASO 2: CREAR DOCKERFILE MKDOCS SIMPLIFICADO
# =============================================================================
log "📚 Creando Dockerfile MkDocs simplificado..."

cat > docker/Dockerfile.mkdocs << 'EOF'
FROM python:3.11-slim

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /app

# Instalar MkDocs y dependencias
RUN pip install --no-cache-dir \
    mkdocs>=1.5.3 \
    mkdocs-material>=9.4.0 \
    pymdown-extensions>=10.3.1

# Crear usuario no-root
RUN useradd -m -u 1000 mkdocs && chown -R mkdocs:mkdocs /app
USER mkdocs

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Exponer puerto
EXPOSE 8000

# Comando de inicio
CMD ["mkdocs", "serve", "--dev-addr=0.0.0.0:8000", "--livereload"]
EOF

# =============================================================================
# PASO 3: CONSTRUIR IMÁGENES
# =============================================================================
log "🔨 Construyendo imagen HAProxy..."
docker build -f docker/Dockerfile.haproxy -t haproxy-advanced:latest . || {
    log "❌ Error construyendo HAProxy, usando imagen base..."
    docker tag haproxy:2.6 haproxy-advanced:latest
}

log "📖 Construyendo imagen MkDocs..."
docker build -f docker/Dockerfile.mkdocs -t mkdocs-server:latest . || {
    log "❌ Error construyendo MkDocs"
    exit 1
}

# =============================================================================
# PASO 4: ACTUALIZAR DOCKER-COMPOSE PARA USAR IMÁGENES LOCALES
# =============================================================================
log "🐳 Actualizando docker-compose..."

# Backup del docker-compose actual
cp config/docker-compose.yml config/docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)

# Actualizar referencias de imágenes
sed -i 's|image: haproxy:2.6|image: haproxy-advanced:latest|g' config/docker-compose.yml
sed -i 's|image: ${MKDOCS_IMAGE:-mkdocs-server}:${MKDOCS_VERSION:-latest}|image: mkdocs-server:latest|g' config/docker-compose.yml

# =============================================================================
# PASO 5: REINICIAR SERVICIOS
# =============================================================================
log "🔄 Reiniciando servicios..."

# Detener servicios actuales
docker-compose -f config/docker-compose.yml down

# Iniciar servicios con nuevas imágenes
docker-compose -f config/docker-compose.yml up -d

# =============================================================================
# PASO 6: VERIFICAR SERVICIOS
# =============================================================================
log "⏳ Esperando que los servicios se inicien..."
sleep 45

echo ""
echo "=== VERIFICACIÓN DE SERVICIOS ==="

# Función para verificar URL
check_url() {
    local url=$1
    local name=$2
    local expected=$3
    
    echo -n "$name: "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" = "$expected" ]; then
        echo "✅ HTTP $response (OK)"
        return 0
    elif [ "$response" = "000" ]; then
        echo "❌ NO RESPONDE"
        return 1
    else
        echo "⚠️ HTTP $response (Esperado: $expected)"
        return 1
    fi
}

# Verificar servicios principales
check_url "http://localhost:8404/stats" "HAProxy Stats (8404)" "200"
check_url "http://localhost:8082/status" "HAProxy API (8082)" "200"
check_url "http://localhost:8081/" "HAProxy Admin UI (8081)" "200"
check_url "http://localhost:8083/health" "HAProxy Load Balancer (8083)" "200"
check_url "http://localhost:8000/" "MkDocs Server (8000)" "200"
check_url "http://localhost:7001/console" "WebLogic A (7001)" "302"
check_url "http://localhost:7002/console" "WebLogic B (7002)" "302"

echo ""
echo "=== URLS PRINCIPALES ==="
echo "🔗 HAProxy Stats:      http://localhost:8404/stats"
echo "🔗 HAProxy API:        http://localhost:8082/status"
echo "🔗 HAProxy Admin UI:   http://localhost:8081/"
echo "🔗 HAProxy LB:         http://localhost:8083/health"
echo "🔗 MkDocs Docs:        http://localhost:8000/"
echo "🔗 WebLogic A Console: http://localhost:7001/console"
echo "🔗 WebLogic B Console: http://localhost:7002/console"

echo ""
log "✅ Regeneración simple completada!"
echo "📊 Revisa los enlaces anteriores para verificar el funcionamiento"

# Mostrar estado de contenedores
echo ""
echo "=== ESTADO DE CONTENEDORES ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
