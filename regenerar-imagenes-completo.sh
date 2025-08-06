#!/bin/bash

echo "🔄 REGENERACIÓN COMPLETA DE IMÁGENES Y CONFIGURACIONES"
echo "======================================================"
echo "Fecha: $(date)"
echo ""

# Función para logging
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# Función para verificar errores
check_error() {
    if [ $? -ne 0 ]; then
        log "❌ ERROR: $1"
        exit 1
    fi
}

# =============================================================================
# PASO 1: DETENER Y LIMPIAR SERVICIOS ACTUALES
# =============================================================================
log "🛑 Deteniendo servicios actuales..."
docker-compose -f config/docker-compose.yml down --remove-orphans --volumes
check_error "Error al detener servicios"

log "🧹 Limpiando imágenes existentes..."
docker rmi -f $(docker images | grep -E "(haproxy|mkdocs-server|weblogic-feature-flags)" | awk '{print $3}') 2>/dev/null || true

# =============================================================================
# PASO 2: REGENERAR CONFIGURACIÓN HAPROXY COMPLETA
# =============================================================================
log "⚖️ Regenerando configuración HAProxy completa..."

cat > haproxy/config/haproxy.cfg << 'EOF'
# =============================================================================
# HAProxy Configuration - WebLogic Load Balancer COMPLETO
# Configuración avanzada con todas las funcionalidades
# =============================================================================

global
    daemon
    log stdout local0 info
    stats socket /var/run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy

defaults
    mode http
    log global
    option httplog
    option dontlognull
    option forwardfor
    option http-server-close
    timeout connect 5000
    timeout client 50000
    timeout server 50000
    timeout http-request 10s
    timeout http-keep-alive 2s
    timeout check 10s
    retries 3

# =============================================================================
# Frontend - Load Balancer Entry Point
# =============================================================================
frontend weblogic_frontend
    bind *:80
    
    # Health check endpoint
    acl health_check path_beg /health
    http-request return status 200 content-type text/plain string "HAProxy Load Balancer OK" if health_check
    
    # WebLogic Console routing
    acl console_path path_beg /console
    use_backend weblogic_console if console_path
    
    # Feature flags routing
    acl feature_flags_path path_beg /feature-flags
    use_backend feature_flags_backend if feature_flags_path
    
    # Version A/B routing
    acl version_a_path path_beg /version-a
    acl version_b_path path_beg /version-b
    use_backend version_a_backend if version_a_path
    use_backend version_b_backend if version_b_path
    
    # Default backend
    default_backend weblogic_backend

# =============================================================================
# Backend - WebLogic Servers Principal
# =============================================================================
backend weblogic_backend
    balance roundrobin
    option httpchk GET /console
    http-check expect status 200,302,401
    
    # WebLogic Server A
    server weblogic-a weblogic-a:7001 check inter 30s rise 2 fall 3 weight 50
    
    # WebLogic Server B  
    server weblogic-b weblogic-b:7001 check inter 30s rise 2 fall 3 weight 50

# =============================================================================
# Backend - WebLogic Console
# =============================================================================
backend weblogic_console
    balance roundrobin
    option httpchk GET /console
    http-check expect status 200,302,401
    
    server weblogic-a weblogic-a:7001 check inter 30s
    server weblogic-b weblogic-b:7001 check inter 30s

# =============================================================================
# Backend - Feature Flags
# =============================================================================
backend feature_flags_backend
    balance roundrobin
    option httpchk GET /feature-flags
    http-check expect status 200,404
    
    server weblogic-a weblogic-a:7001 check inter 30s
    server weblogic-b weblogic-b:7001 check inter 30s

# =============================================================================
# Backend - Version A
# =============================================================================
backend version_a_backend
    option httpchk GET /version-a
    http-check expect status 200,404
    
    server weblogic-a weblogic-a:7001 check inter 30s

# =============================================================================
# Backend - Version B
# =============================================================================
backend version_b_backend
    option httpchk GET /version-b
    http-check expect status 200,404
    
    server weblogic-b weblogic-b:7001 check inter 30s

# =============================================================================
# Statistics Interface - COMPLETA
# =============================================================================
frontend stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
    stats show-legends
    stats show-node
    stats realm HAProxy\ Statistics
    stats auth admin:admin123

# =============================================================================
# Admin API Interface - COMPLETA
# =============================================================================
frontend admin_api
    bind *:8082
    
    # Health endpoint
    acl api_health path_beg /health
    http-request return status 200 content-type application/json string '{"status":"healthy","timestamp":"'$(date -Iseconds)'"}' if api_health
    
    # Status endpoint
    acl api_status path_beg /status
    http-request return status 200 content-type application/json string '{"status":"active","backends":4,"servers":2}' if api_status
    
    # Backends endpoint
    acl api_backends path_beg /backends
    http-request return status 200 content-type application/json string '{"backends":["weblogic_backend","weblogic_console","feature_flags_backend","version_a_backend","version_b_backend"]}' if api_backends
    
    # Default API response
    http-request return status 200 content-type application/json string '{"api":"haproxy-admin","version":"2.6","endpoints":["/health","/status","/backends"]}'

# =============================================================================
# Admin UI Interface - COMPLETA
# =============================================================================
frontend admin_ui
    bind *:8084
    
    # Main UI
    http-request return status 200 content-type text/html string '<!DOCTYPE html>
<html>
<head>
    <title>HAProxy Admin Dashboard</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: #2c3e50; color: white; padding: 15px; margin: -20px -20px 20px -20px; border-radius: 8px 8px 0 0; }
        .status { display: flex; gap: 20px; margin: 20px 0; }
        .card { flex: 1; padding: 15px; background: #ecf0f1; border-radius: 5px; text-align: center; }
        .card.healthy { background: #d5f4e6; }
        .card.warning { background: #fef9e7; }
        .links { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
        .link { padding: 15px; background: #3498db; color: white; text-decoration: none; border-radius: 5px; text-align: center; transition: background 0.3s; }
        .link:hover { background: #2980b9; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #bdc3c7; color: #7f8c8d; text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔧 HAProxy Admin Dashboard</h1>
            <p>WebLogic Load Balancer Management Interface</p>
        </div>
        
        <div class="status">
            <div class="card healthy">
                <h3>✅ Status</h3>
                <p>Active & Healthy</p>
            </div>
            <div class="card healthy">
                <h3>🎯 Backends</h3>
                <p>5 Configured</p>
            </div>
            <div class="card healthy">
                <h3>🖥️ Servers</h3>
                <p>2 WebLogic Instances</p>
            </div>
            <div class="card warning">
                <h3>📊 Load</h3>
                <p>Balanced</p>
            </div>
        </div>
        
        <div class="links">
            <a href="http://localhost:8404/stats" class="link">📈 Statistics Dashboard</a>
            <a href="http://localhost:8082/status" class="link">🔌 API Status</a>
            <a href="http://localhost:7001/console" class="link">🎛️ WebLogic A Console</a>
            <a href="http://localhost:7002/console" class="link">🎛️ WebLogic B Console</a>
            <a href="http://localhost:8000/" class="link">📚 Documentation</a>
            <a href="http://localhost:80/health" class="link">💚 Health Check</a>
        </div>
        
        <div class="footer">
            <p>HAProxy Load Balancer v2.6 | WebLogic Oracle Docker Project</p>
            <p>Last updated: '$(date)'</p>
        </div>
    </div>
</body>
</html>'
EOF

check_error "Error al crear configuración HAProxy"

# =============================================================================
# PASO 3: REGENERAR CONFIGURACIÓN MKDOCS COMPLETA
# =============================================================================
log "📚 Regenerando configuración MkDocs completa..."

cat > applications/mkdocs-server/mkdocs.yml << 'EOF'
site_name: Docker Oracle WebLogic - Documentación Completa
site_description: Documentación técnica completa para el proyecto Docker Oracle WebLogic con HAProxy, despliegues canary y feature flags
site_author: ICBS Development Team
site_url: http://localhost:8000

# Repository
repo_name: docker-for-oracle-weblogic
repo_url: https://github.com/icbs/docker-for-oracle-weblogic
edit_uri: edit/main/docs/

# Configuration
theme:
  name: material
  language: es
  palette:
    # Palette toggle for light mode
    - scheme: default
      primary: blue
      accent: light-blue
      toggle:
        icon: material/brightness-7
        name: Cambiar a modo oscuro
    # Palette toggle for dark mode
    - scheme: slate
      primary: blue
      accent: light-blue
      toggle:
        icon: material/brightness-4
        name: Cambiar a modo claro
  
  features:
    - navigation.tabs
    - navigation.tabs.sticky
    - navigation.sections
    - navigation.expand
    - navigation.path
    - navigation.top
    - navigation.indexes
    - search.highlight
    - search.share
    - search.suggest
    - content.code.copy
    - content.code.annotate
    - content.tabs.link
    - content.tooltips
    - toc.follow
    - toc.integrate

# Plugins
plugins:
  - search:
      lang: es
  - minify:
      minify_html: true

# Extensions
markdown_extensions:
  - abbr
  - admonition
  - attr_list
  - def_list
  - footnotes
  - md_in_html
  - toc:
      permalink: true
      title: Contenido
  - pymdownx.arithmatex:
      generic: true
  - pymdownx.betterem:
      smart_enable: all
  - pymdownx.caret
  - pymdownx.details
  - pymdownx.emoji:
      emoji_generator: !!python/name:material.extensions.emoji.to_svg
      emoji_index: !!python/name:material.extensions.emoji.twemoji
  - pymdownx.highlight:
      anchor_linenums: true
      line_spans: __span
      pygments_lang_class: true
  - pymdownx.inlinehilite
  - pymdownx.keys
  - pymdownx.magiclink:
      repo_url_shorthand: true
      user: icbs
      repo: docker-for-oracle-weblogic
  - pymdownx.mark
  - pymdownx.smartsymbols
  - pymdownx.superfences:
      custom_fences:
        - name: mermaid
          class: mermaid
          format: !!python/name:pymdownx.superfences.fence_code_format
  - pymdownx.tabbed:
      alternate_style: true
  - pymdownx.tasklist:
      custom_checkbox: true
  - pymdownx.tilde

# Navigation - Estructura Completa y Organizada
nav:
  - 🏠 Inicio: 
    - Bienvenida: index.md
    - Primeros Pasos: getting-started.md
    - Estado del Proyecto: seguimiento-progreso.md
  
  - 🏗️ Arquitectura: 
    - Visión General: arquitectura.md
    - Detalles Técnicos: architecture/index.md
    - Plan de Implementación: plan-implementacion.md
  
  - 📦 Despliegue:
    - Guía Rápida: deployment.md
    - Despliegue Básico: deployment/basic-deployment.md
    - Despliegue Avanzado: deployment/advanced-guide.md
    - Guía Completa: DEPLOYMENT_GUIDE.md
  
  - 🎯 Canary y Features:
    - Introducción: canary-and-features.md
    - Guía Canary Completa: CANARY_GUIDE.md
    - Guía Canary Detallada: deployment/canary-guide.md
  
  - ⚖️ HAProxy:
    - Configuración Básica: haproxy.md
    - Setup Avanzado: guides/haproxy-setup.md
    - Integración MkDocs: mkdocs-haproxy-integration.md
    - Corrección de Backends: haproxy-backend-fix.md
    - Resumen de Correcciones: resumen-correccion-haproxy.md
  
  - 📜 Scripts y Automatización:
    - Índice de Scripts: scripts/index.md
    - Guía de Uso: scripts/usage-guide.md
    - Referencia Completa: scripts/reference.md
  
  - 📚 Guías y Soporte:
    - Troubleshooting: TROUBLESHOOTING.md
    - Troubleshooting Detallado: guides/troubleshooting.md
    - Guía de Cache: user-guides/browser-cache-guide.md
    - Soporte Técnico: support.md
    - Enlaces Corregidos: ENLACES_CORREGIDOS.md
  
  - 📊 Monitoreo y Variables:
    - Integración de Monitoreo: URL_MONITORING_INTEGRATION.md
    - Variables Centralizadas: VARIABLES-CENTRALIZADAS.md
  
  - 🔐 Seguridad:
    - Autenticación HAProxy: security/haproxy-authentication.md
    - Resumen de Autenticación: security/authentication-summary.md

# Extra
extra:
  social:
    - icon: fontawesome/brands/github
      link: https://github.com/icbs/docker-for-oracle-weblogic
    - icon: fontawesome/brands/docker
      link: https://hub.docker.com/repositories/edissonz8809
  version:
    provider: mike
  analytics:
    provider: google
    property: !ENV GOOGLE_ANALYTICS_KEY

# Copyright
copyright: Copyright &copy; 2025 ICBS Development Team - Docker Oracle WebLogic Project
EOF

check_error "Error al crear configuración MkDocs"

# =============================================================================
# PASO 4: REGENERAR DOCKERFILE HAPROXY
# =============================================================================
log "🐳 Regenerando Dockerfile HAProxy..."

cat > docker/Dockerfile.haproxy << 'EOF'
FROM haproxy:2.6-alpine

# Instalar dependencias adicionales
RUN apk add --no-cache \
    curl \
    bash \
    python3 \
    py3-pip \
    && pip3 install --no-cache-dir flask requests

# Crear directorios necesarios
RUN mkdir -p /var/run/haproxy \
    && mkdir -p /var/log/haproxy \
    && mkdir -p /usr/local/etc/haproxy \
    && mkdir -p /etc/ssl/certs

# Copiar configuración
COPY haproxy/config/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY haproxy/ssl/ /etc/ssl/certs/
COPY haproxy/scripts/ /usr/local/bin/

# Permisos
RUN chmod +x /usr/local/bin/*.sh \
    && chmod +x /usr/local/bin/*.py \
    && chown -R haproxy:haproxy /var/run/haproxy \
    && chown -R haproxy:haproxy /var/log/haproxy

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8404/stats || exit 1

# Exponer puertos
EXPOSE 80 443 8082 8084 8404

# Comando de inicio
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg", "-D"]
EOF

check_error "Error al crear Dockerfile HAProxy"

# =============================================================================
# PASO 5: REGENERAR DOCKERFILE MKDOCS
# =============================================================================
log "📖 Regenerando Dockerfile MkDocs..."

cat > docker/Dockerfile.mkdocs << 'EOF'
FROM python:3.11-slim

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /app

# Copiar requirements
COPY applications/mkdocs-server/requirements.txt .

# Instalar dependencias Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar configuración y documentos
COPY applications/mkdocs-server/mkdocs.yml .
COPY docs/ ./docs/

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

check_error "Error al crear Dockerfile MkDocs"

# =============================================================================
# PASO 6: ACTUALIZAR REQUIREMENTS MKDOCS
# =============================================================================
log "📋 Actualizando requirements MkDocs..."

cat > applications/mkdocs-server/requirements.txt << 'EOF'
mkdocs>=1.5.3
mkdocs-material>=9.4.0
mkdocs-minify-plugin>=0.7.1
pymdown-extensions>=10.3.1
markdown>=3.5.1
jinja2>=3.1.2
markupsafe>=2.1.3
EOF

check_error "Error al crear requirements MkDocs"

# =============================================================================
# PASO 7: CONSTRUIR IMÁGENES
# =============================================================================
log "🔨 Construyendo imágenes..."

# Construir HAProxy
log "⚖️ Construyendo imagen HAProxy..."
docker build -f docker/Dockerfile.haproxy -t haproxy-advanced:latest .
check_error "Error al construir imagen HAProxy"

# Construir MkDocs
log "📚 Construyendo imagen MkDocs..."
docker build -f docker/Dockerfile.mkdocs -t mkdocs-server:latest .
check_error "Error al construir imagen MkDocs"

# =============================================================================
# PASO 8: INICIAR SERVICIOS
# =============================================================================
log "🚀 Iniciando servicios..."
docker-compose -f config/docker-compose.yml up -d
check_error "Error al iniciar servicios"

# =============================================================================
# PASO 9: VERIFICAR SERVICIOS
# =============================================================================
log "🔍 Verificando servicios..."
sleep 30

echo ""
echo "=== VERIFICACIÓN DE SERVICIOS ==="

# Verificar HAProxy
echo -n "HAProxy Stats (8404): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8404/stats | grep -q "200"; then
    echo "✅ OK"
else
    echo "❌ FAIL"
fi

echo -n "HAProxy API (8082): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/status | grep -q "200"; then
    echo "✅ OK"
else
    echo "❌ FAIL"
fi

echo -n "HAProxy Admin UI (8081): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/ | grep -q "200"; then
    echo "✅ OK"
else
    echo "❌ FAIL"
fi

echo -n "HAProxy Load Balancer (8083): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8083/health | grep -q "200"; then
    echo "✅ OK"
else
    echo "❌ FAIL"
fi

# Verificar MkDocs
echo -n "MkDocs Server (8000): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ | grep -q "200"; then
    echo "✅ OK"
else
    echo "❌ FAIL"
fi

# Verificar WebLogic
echo -n "WebLogic A (7001): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:7001/console | grep -q "302"; then
    echo "✅ OK"
else
    echo "❌ FAIL"
fi

echo -n "WebLogic B (7002): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:7002/console | grep -q "302"; then
    echo "✅ OK"
else
    echo "❌ FAIL"
fi

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
log "✅ Regeneración completa finalizada!"
echo "🎉 Todas las imágenes y configuraciones han sido regeneradas"
echo "📊 Revisa los enlaces anteriores para verificar el funcionamiento"
