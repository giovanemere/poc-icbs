# HAProxy para Documentación MkDocs

Esta guía explica cómo configurar HAProxy para servir la documentación MkDocs junto con las aplicaciones WebLogic, permitiendo acceso unificado y balanceado.

## 🎯 Casos de Uso

### Escenarios Comunes

1. **Documentación en Producción**: Servir docs estáticas junto con aplicaciones
2. **Documentación Versionada**: Múltiples versiones de docs simultáneas
3. **Documentación por Ambiente**: Docs diferentes para dev/staging/prod
4. **Documentación con Autenticación**: Proteger docs internas
5. **Documentación Multi-idioma**: Servir docs en diferentes idiomas

## 🔧 Configuración Básica

### 1. Configuración HAProxy para MkDocs

Agrega esta configuración a `haproxy/haproxy.cfg`:

```haproxy
# Frontend principal con routing de documentación
frontend weblogic_frontend
    bind *:8080
    bind *:443 ssl crt /etc/ssl/certs/weblogic.pem
    
    # Capturar información de request
    capture request header Host len 32
    capture request header User-Agent len 64
    
    # === ROUTING DE DOCUMENTACIÓN ===
    
    # Documentación principal
    acl is_docs path_beg /docs
    use_backend mkdocs_main if is_docs
    
    # Documentación por versión
    acl is_docs_v1 path_beg /docs/v1
    acl is_docs_v2 path_beg /docs/v2
    use_backend mkdocs_v1 if is_docs_v1
    use_backend mkdocs_v2 if is_docs_v2
    
    # Documentación por ambiente
    acl is_docs_dev path_beg /docs/dev
    acl is_docs_staging path_beg /docs/staging
    use_backend mkdocs_dev if is_docs_dev
    use_backend mkdocs_staging if is_docs_staging
    
    # API de documentación (para búsqueda, etc.)
    acl is_docs_api path_beg /docs-api
    use_backend mkdocs_api if is_docs_api
    
    # === ROUTING DE APLICACIONES ===
    
    # Health checks
    acl is_health path_beg /health
    use_backend health_check if is_health
    
    # Aplicaciones WebLogic (default)
    default_backend weblogic_main

# === BACKENDS DE DOCUMENTACIÓN ===

# Documentación principal (producción)
backend mkdocs_main
    balance roundrobin
    option httpchk GET /docs/
    
    # Reescribir path para MkDocs
    http-request set-path %[path,regsub(^/docs,/)]
    
    # Headers para documentación
    http-response set-header Cache-Control "public, max-age=3600"
    http-response set-header X-Content-Type-Options nosniff
    
    server mkdocs-prod mkdocs-server:8000 check

# Documentación versión 1
backend mkdocs_v1
    balance roundrobin
    option httpchk GET /
    
    http-request set-path %[path,regsub(^/docs/v1,/)]
    http-response set-header Cache-Control "public, max-age=86400"
    
    server mkdocs-v1 mkdocs-v1-server:8000 check

# Documentación versión 2
backend mkdocs_v2
    balance roundrobin
    option httpchk GET /
    
    http-request set-path %[path,regsub(^/docs/v2,/)]
    http-response set-header Cache-Control "public, max-age=86400"
    
    server mkdocs-v2 mkdocs-v2-server:8000 check

# Documentación desarrollo
backend mkdocs_dev
    balance roundrobin
    option httpchk GET /
    
    http-request set-path %[path,regsub(^/docs/dev,/)]
    http-response set-header Cache-Control "no-cache, no-store"
    
    server mkdocs-dev mkdocs-dev-server:8000 check

# API de documentación
backend mkdocs_api
    balance roundrobin
    option httpchk GET /health
    
    http-request set-path %[path,regsub(^/docs-api,/api)]
    
    server mkdocs-api mkdocs-api-server:8001 check

# === BACKENDS DE APLICACIONES ===

# Backend principal WebLogic
backend weblogic_main
    balance roundrobin
    option httpchk GET /health
    
    server weblogic-1 weblogic-managed-1:7003 check
    server weblogic-2 weblogic-managed-2:7005 check

# Health check endpoint
backend health_check
    http-request return status 200 content-type text/plain string "OK"
```

### 2. Docker Compose para MkDocs

Agrega estos servicios a `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # === SERVICIOS DE DOCUMENTACIÓN ===
  
  # Documentación principal
  mkdocs-server:
    build:
      context: .
      dockerfile: Dockerfile.mkdocs
    container_name: mkdocs-server
    volumes:
      - ./site:/app/site:ro
      - ./docs:/app/docs:ro
    ports:
      - "8000:8000"
    environment:
      - MKDOCS_ENV=production
    networks:
      - weblogic-network
    restart: unless-stopped

  # Documentación desarrollo
  mkdocs-dev-server:
    build:
      context: .
      dockerfile: Dockerfile.mkdocs-dev
    container_name: mkdocs-dev-server
    volumes:
      - ./docs:/app/docs
      - ./mkdocs.yml:/app/mkdocs.yml
    ports:
      - "8001:8000"
    environment:
      - MKDOCS_ENV=development
    networks:
      - weblogic-network
    restart: unless-stopped
    command: mkdocs serve --dev-addr 0.0.0.0:8000

  # Documentación versionada v1
  mkdocs-v1-server:
    build:
      context: .
      dockerfile: Dockerfile.mkdocs
    container_name: mkdocs-v1-server
    volumes:
      - ./site-v1:/app/site:ro
    ports:
      - "8002:8000"
    environment:
      - MKDOCS_ENV=production
      - MKDOCS_VERSION=v1
    networks:
      - weblogic-network
    restart: unless-stopped

  # Documentación versionada v2
  mkdocs-v2-server:
    build:
      context: .
      dockerfile: Dockerfile.mkdocs
    container_name: mkdocs-v2-server
    volumes:
      - ./site-v2:/app/site:ro
    ports:
      - "8003:8000"
    environment:
      - MKDOCS_ENV=production
      - MKDOCS_VERSION=v2
    networks:
      - weblogic-network
    restart: unless-stopped

  # === SERVICIOS WEBLOGIC EXISTENTES ===
  
  haproxy-lb:
    image: haproxy:2.8
    container_name: haproxy-lb
    ports:
      - "8080:8080"
      - "8404:8404"
      - "443:443"
    volumes:
      - ./haproxy:/usr/local/etc/haproxy:ro
      - ./ssl:/etc/ssl/certs:ro
    networks:
      - weblogic-network
    depends_on:
      - weblogic-admin
      - mkdocs-server
      - mkdocs-dev-server
    restart: unless-stopped

networks:
  weblogic-network:
    driver: bridge
```

## 🐳 Dockerfiles para MkDocs

### 1. Dockerfile.mkdocs (Producción)

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements
COPY requirements.txt .

# Instalar dependencias Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar configuración nginx
COPY nginx/mkdocs.conf /etc/nginx/sites-available/default

# Copiar sitio construido
COPY site/ /app/site/

# Configurar nginx para servir archivos estáticos
RUN nginx -t

EXPOSE 8000

# Script de inicio
COPY scripts/start-mkdocs-prod.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
```

### 2. Dockerfile.mkdocs-dev (Desarrollo)

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar configuración
COPY mkdocs.yml .
COPY mkdocs-dev.yml .

# Crear directorio para docs
RUN mkdir -p docs

EXPOSE 8000

# Comando por defecto
CMD ["mkdocs", "serve", "--dev-addr", "0.0.0.0:8000"]
```

## 📝 Scripts de Gestión

### 1. Script de Construcción Multi-Versión

```bash
#!/bin/bash
# build-docs-versions.sh

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Configuración
VERSIONS=("v1" "v2" "main")
DOCS_BRANCHES=("release/v1" "release/v2" "main")

print_info "Construyendo documentación para múltiples versiones..."

# Activar entorno virtual
source mkdocs-env/bin/activate

for i in "${!VERSIONS[@]}"; do
    version="${VERSIONS[$i]}"
    branch="${DOCS_BRANCHES[$i]}"
    
    print_info "Construyendo versión: $version (branch: $branch)"
    
    # Cambiar a branch específico
    git stash
    git checkout "$branch"
    
    # Construir documentación
    if [ "$version" = "main" ]; then
        mkdocs build --site-dir "site"
    else
        mkdocs build --site-dir "site-$version"
    fi
    
    print_success "Versión $version construida"
done

# Volver a branch principal
git checkout main
git stash pop || true

print_success "Todas las versiones construidas"
```

### 2. Script de Despliegue de Documentación

```bash
#!/bin/bash
# deploy-docs.sh

set -e

ACTION="$1"
VERSION="${2:-main}"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

case "$ACTION" in
    "build")
        print_info "Construyendo documentación versión: $VERSION"
        
        # Activar entorno
        source mkdocs-env/bin/activate
        
        # Construir según versión
        if [ "$VERSION" = "main" ]; then
            mkdocs build --site-dir site
        else
            mkdocs build --site-dir "site-$VERSION"
        fi
        
        print_success "Documentación construida"
        ;;
        
    "deploy")
        print_info "Desplegando documentación versión: $VERSION"
        
        # Construir primero
        ./deploy-docs.sh build "$VERSION"
        
        # Reiniciar contenedor correspondiente
        if [ "$VERSION" = "main" ]; then
            docker-compose restart mkdocs-server
        else
            docker-compose restart "mkdocs-$VERSION-server"
        fi
        
        print_success "Documentación desplegada"
        ;;
        
    "serve-all")
        print_info "Iniciando todos los servidores de documentación"
        
        docker-compose up -d mkdocs-server mkdocs-dev-server mkdocs-v1-server mkdocs-v2-server
        
        print_success "Servidores iniciados:"
        print_info "  - Producción: http://localhost:8080/docs"
        print_info "  - Desarrollo: http://localhost:8080/docs/dev"
        print_info "  - Versión 1: http://localhost:8080/docs/v1"
        print_info "  - Versión 2: http://localhost:8080/docs/v2"
        ;;
        
    "stop-all")
        print_info "Deteniendo servidores de documentación"
        
        docker-compose stop mkdocs-server mkdocs-dev-server mkdocs-v1-server mkdocs-v2-server
        
        print_success "Servidores detenidos"
        ;;
        
    *)
        echo "Uso: $0 {build|deploy|serve-all|stop-all} [version]"
        echo
        echo "Comandos:"
        echo "  build [version]    - Construir documentación"
        echo "  deploy [version]   - Desplegar documentación"
        echo "  serve-all          - Iniciar todos los servidores"
        echo "  stop-all           - Detener todos los servidores"
        echo
        echo "Versiones disponibles: main, v1, v2, dev"
        exit 1
        ;;
esac
```

## 🔒 Configuración con Autenticación

### 1. HAProxy con Autenticación Básica

```haproxy
# Frontend con autenticación para docs internas
frontend weblogic_frontend
    bind *:8080
    
    # Documentación pública (sin auth)
    acl is_public_docs path_beg /docs/public
    use_backend mkdocs_public if is_public_docs
    
    # Documentación interna (con auth)
    acl is_internal_docs path_beg /docs/internal
    acl is_authenticated http_auth(docs-users)
    
    http-request auth realm "Documentación Interna" if is_internal_docs !is_authenticated
    use_backend mkdocs_internal if is_internal_docs is_authenticated
    
    # Default
    default_backend weblogic_main

# Lista de usuarios para documentación
userlist docs-users
    user admin password $6$rounds=10000$salt$hash
    user developer password $6$rounds=10000$salt$hash
    user viewer password $6$rounds=10000$salt$hash

# Backend documentación interna
backend mkdocs_internal
    http-request set-path %[path,regsub(^/docs/internal,/)]
    server mkdocs-internal mkdocs-internal-server:8000 check

# Backend documentación pública
backend mkdocs_public
    http-request set-path %[path,regsub(^/docs/public,/)]
    server mkdocs-public mkdocs-public-server:8000 check
```

### 2. Generar Passwords para HAProxy

```bash
#!/bin/bash
# generate-docs-passwords.sh

# Función para generar password hash
generate_password() {
    local username="$1"
    local password="$2"
    
    # Generar salt aleatorio
    salt=$(openssl rand -base64 12)
    
    # Generar hash
    hash=$(echo -n "$password" | openssl passwd -6 -salt "$salt" -stdin)
    
    echo "user $username password $hash"
}

echo "# Usuarios para documentación HAProxy"
echo "userlist docs-users"

# Generar usuarios
generate_password "admin" "admin123"
generate_password "developer" "dev123"
generate_password "viewer" "view123"
```

## 📊 Monitoreo de Documentación

### 1. Métricas en HAProxy Stats

Agrega esta configuración para monitorear el tráfico de documentación:

```haproxy
# Stats con información de documentación
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
    
    # Mostrar información adicional
    stats show-legends
    stats show-desc "WebLogic + MkDocs Load Balancer"
    
    # Autenticación para stats
    stats auth admin:admin
```

### 2. Script de Monitoreo

```bash
#!/bin/bash
# monitor-docs-traffic.sh

while true; do
    clear
    echo "=== Tráfico de Documentación - $(date) ==="
    echo
    
    # Obtener estadísticas de HAProxy
    curl -s http://admin:admin@localhost:8404/stats | \
    grep -E "(mkdocs|docs)" | \
    awk -F',' '{
        printf "%-25s: %8s requests (%s req/s) - %s errors\n", 
        $1, $8, $9, $14
    }'
    
    echo
    echo "=== Servidores de Documentación ==="
    docker-compose ps | grep mkdocs
    
    sleep 30
done
```

## 🚀 Configuración de Producción

### 1. Nginx como Servidor de Archivos Estáticos

```nginx
# nginx/mkdocs.conf
server {
    listen 8000;
    server_name _;
    
    root /app/site;
    index index.html;
    
    # Configuración para MkDocs
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers de cache
        expires 1h;
        add_header Cache-Control "public, immutable";
    }
    
    # Assets estáticos con cache largo
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # API de búsqueda
    location /search/ {
        expires 5m;
        add_header Cache-Control "public";
    }
    
    # Logs
    access_log /var/log/nginx/mkdocs_access.log;
    error_log /var/log/nginx/mkdocs_error.log;
}
```

### 2. Script de Inicio para Producción

```bash
#!/bin/bash
# scripts/start-mkdocs-prod.sh

set -e

echo "🚀 Iniciando servidor MkDocs en modo producción..."

# Verificar que el sitio existe
if [ ! -d "/app/site" ]; then
    echo "❌ Directorio /app/site no encontrado"
    exit 1
fi

# Configurar nginx
echo "🔧 Configurando nginx..."
nginx -t

# Iniciar nginx
echo "▶️  Iniciando nginx..."
nginx -g "daemon off;" &

# Mantener contenedor activo
wait
```

## 📋 Checklist de Configuración

### ✅ Configuración Básica
- [ ] HAProxy configurado con routing de docs
- [ ] Docker Compose con servicios MkDocs
- [ ] Dockerfiles creados
- [ ] Scripts de gestión implementados

### ✅ Configuración Avanzada
- [ ] Múltiples versiones configuradas
- [ ] Autenticación implementada (si necesaria)
- [ ] Nginx para archivos estáticos
- [ ] Monitoreo configurado

### ✅ Testing
- [ ] Documentación accesible en `/docs`
- [ ] Versiones funcionando correctamente
- [ ] Autenticación funcionando (si aplicable)
- [ ] Métricas visibles en HAProxy stats

## 🎯 URLs de Acceso Final

Con esta configuración tendrás:

| Servicio | URL | Descripción |
|----------|-----|-------------|
| **Documentación Principal** | http://localhost:8080/docs | Docs de producción |
| **Documentación Desarrollo** | http://localhost:8080/docs/dev | Docs en desarrollo |
| **Documentación v1** | http://localhost:8080/docs/v1 | Versión 1 |
| **Documentación v2** | http://localhost:8080/docs/v2 | Versión 2 |
| **Aplicación Principal** | http://localhost:8080 | WebLogic apps |
| **HAProxy Stats** | http://localhost:8404/stats | Estadísticas |

¡Ahora tienes una configuración completa de HAProxy para manejar tanto tus aplicaciones WebLogic como tu documentación MkDocs de manera unificada y profesional! 🎉
