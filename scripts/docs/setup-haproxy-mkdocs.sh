#!/bin/bash

# =============================================================================
# Setup HAProxy + MkDocs Integration
# =============================================================================
# Este script configura la integración entre HAProxy y MkDocs para servir
# documentación junto con las aplicaciones WebLogic
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables globales
HAPROXY_CONFIG=""

# Funciones de utilidad
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Verificar prerrequisitos
check_prerequisites() {
    print_header "Verificando Prerrequisitos"
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado"
        exit 1
    fi
    print_success "Docker encontrado"
    
    # Verificar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose no está instalado"
        exit 1
    fi
    print_success "Docker Compose encontrado"
    
    # Verificar que MkDocs esté configurado
    if [ ! -f "mkdocs.yml" ]; then
        print_error "mkdocs.yml no encontrado. Ejecuta ./setup-docs.sh primero"
        exit 1
    fi
    print_success "MkDocs configurado"
    
    # Verificar que HAProxy esté configurado
    if [ -f "haproxy/haproxy.cfg" ]; then
        HAPROXY_CONFIG="haproxy/haproxy.cfg"
        print_success "HAProxy configurado en haproxy/haproxy.cfg"
    elif [ -f "haproxy/config/haproxy.cfg" ]; then
        HAPROXY_CONFIG="haproxy/config/haproxy.cfg"
        print_success "HAProxy configurado en haproxy/config/haproxy.cfg"
    else
        print_error "Archivo de configuración HAProxy no encontrado"
        print_info "Buscado en: haproxy/haproxy.cfg y haproxy/config/haproxy.cfg"
        exit 1
    fi
}

# Crear Dockerfiles para MkDocs
create_mkdocs_dockerfiles() {
    print_header "Creando Dockerfiles para MkDocs"
    
    # Dockerfile para producción
    cat > Dockerfile.mkdocs << 'EOF'
FROM nginx:alpine

# Copiar sitio construido
COPY site/ /usr/share/nginx/html/

# Configuración nginx para MkDocs
COPY nginx/mkdocs.conf /etc/nginx/conf.d/default.conf

EXPOSE 8000

CMD ["nginx", "-g", "daemon off;"]
EOF
    print_success "Dockerfile.mkdocs creado"
    
    # Dockerfile para desarrollo
    cat > Dockerfile.mkdocs-dev << 'EOF'
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
EOF
    print_success "Dockerfile.mkdocs-dev creado"
}

# Crear configuración Nginx
create_nginx_config() {
    print_header "Creando Configuración Nginx"
    
    mkdir -p nginx
    
    cat > nginx/mkdocs.conf << 'EOF'
server {
    listen 8000;
    server_name _;
    
    root /usr/share/nginx/html;
    index index.html;
    
    # Configuración para MkDocs
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers de cache para HTML
        expires 1h;
        add_header Cache-Control "public";
        add_header X-Content-Type-Options nosniff;
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
EOF
    print_success "Configuración Nginx creada"
}

# Actualizar HAProxy configuración
update_haproxy_config() {
    print_header "Actualizando Configuración HAProxy"
    
    # Backup configuración actual
    cp "$HAPROXY_CONFIG" "${HAPROXY_CONFIG}.backup"
    print_info "Backup creado: ${HAPROXY_CONFIG}.backup"
    
    # Crear nueva configuración con soporte para MkDocs
    HAPROXY_DIR=$(dirname "$HAPROXY_CONFIG")
    cat > "$HAPROXY_DIR/haproxy-mkdocs.cfg" << 'EOF'
global
    daemon
    maxconn 4096
    log stdout local0
    stats socket /var/run/haproxy.sock mode 600 level admin

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option httplog
    option dontlognull
    retries 3

# Frontend - Punto de entrada con routing de documentación
frontend weblogic_frontend
    bind *:8080
    
    # Logging
    capture request header Host len 32
    capture request header User-Agent len 64
    
    # === ROUTING DE DOCUMENTACIÓN ===
    
    # Documentación principal
    acl is_docs path_beg /docs
    use_backend mkdocs_main if is_docs
    
    # Documentación de desarrollo
    acl is_docs_dev path_beg /docs/dev
    use_backend mkdocs_dev if is_docs_dev
    
    # Documentación versionada
    acl is_docs_v1 path_beg /docs/v1
    use_backend mkdocs_v1 if is_docs_v1
    
    # === ROUTING DE APLICACIONES ===
    
    # Health check endpoint
    acl is_health path_beg /health
    use_backend health_check if is_health
    
    # Default backend para aplicaciones WebLogic
    default_backend weblogic_main

# === BACKENDS DE DOCUMENTACIÓN ===

# Documentación principal (producción)
backend mkdocs_main
    balance roundrobin
    option httpchk GET /
    
    # Reescribir path para MkDocs
    http-request set-path %[path,regsub(^/docs,/)]
    
    # Headers para documentación estática
    http-response set-header Cache-Control "public, max-age=3600"
    http-response set-header X-Content-Type-Options nosniff
    
    server mkdocs-prod mkdocs-server:8000 check

# Documentación desarrollo (sin cache)
backend mkdocs_dev
    balance roundrobin
    option httpchk GET /
    
    http-request set-path %[path,regsub(^/docs/dev,/)]
    http-response set-header Cache-Control "no-cache, no-store"
    
    server mkdocs-dev mkdocs-dev-server:8000 check

# Documentación versionada v1
backend mkdocs_v1
    balance roundrobin
    option httpchk GET /
    
    http-request set-path %[path,regsub(^/docs/v1,/)]
    http-response set-header Cache-Control "public, max-age=86400"
    
    server mkdocs-v1 mkdocs-v1-server:8000 check

# === BACKENDS DE APLICACIONES ===

# Backend principal WebLogic
backend weblogic_main
    balance roundrobin
    option httpchk GET /health
    
    server weblogic-1 weblogic-managed-1:7003 check
    server weblogic-2 weblogic-managed-2:7005 check

# Backend canary (opcional)
backend weblogic_canary
    balance roundrobin
    option httpchk GET /health
    
    server canary-1 weblogic-canary-1:7007 check
    server canary-2 weblogic-canary-2:7009 check

# Health check endpoint
backend health_check
    http-request return status 200 content-type text/plain string "OK"

# Stats interface
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
    stats show-desc "WebLogic + MkDocs Load Balancer"
EOF
    
    print_success "Nueva configuración HAProxy creada: $HAPROXY_DIR/haproxy-mkdocs.cfg"
    print_warning "Revisa la configuración antes de aplicarla"
}

# Actualizar Docker Compose
update_docker_compose() {
    print_header "Actualizando Docker Compose"
    
    # Backup docker-compose actual
    cp docker-compose.yml docker-compose.yml.backup
    print_info "Backup creado: docker-compose.yml.backup"
    
    # Agregar servicios MkDocs al docker-compose existente
    cat >> docker-compose.yml << 'EOF'

  # === SERVICIOS DE DOCUMENTACIÓN ===
  
  # Documentación principal
  mkdocs-server:
    build:
      context: .
      dockerfile: Dockerfile.mkdocs
    container_name: mkdocs-server
    volumes:
      - ./site:/usr/share/nginx/html:ro
    ports:
      - "8000:8000"
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
      - ./mkdocs-dev.yml:/app/mkdocs-dev.yml
    ports:
      - "8001:8000"
    networks:
      - weblogic-network
    restart: unless-stopped
    command: mkdocs serve --dev-addr 0.0.0.0:8000

  # Documentación versionada v1 (opcional)
  mkdocs-v1-server:
    build:
      context: .
      dockerfile: Dockerfile.mkdocs
    container_name: mkdocs-v1-server
    volumes:
      - ./site-v1:/usr/share/nginx/html:ro
    ports:
      - "8002:8000"
    networks:
      - weblogic-network
    restart: unless-stopped
EOF
    
    print_success "Docker Compose actualizado con servicios MkDocs"
}

# Crear scripts de gestión
create_management_scripts() {
    print_header "Creando Scripts de Gestión"
    
    # Script de gestión de documentación
    cat > manage-docs-haproxy.sh << 'EOF'
#!/bin/bash

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
    "deploy")
        print_info "Desplegando documentación..."
        
        # Construir documentación
        ./build-docs.sh build
        
        # Reiniciar contenedor
        docker-compose restart mkdocs-server
        
        print_success "Documentación desplegada en: http://localhost:8080/docs"
        ;;
        
    "deploy-dev")
        print_info "Desplegando documentación de desarrollo..."
        
        docker-compose restart mkdocs-dev-server
        
        print_success "Docs de desarrollo en: http://localhost:8080/docs/dev"
        ;;
        
    "status")
        print_info "Estado de servicios de documentación:"
        docker-compose ps | grep mkdocs
        
        echo -e "\n📈 Tráfico de documentación:"
        curl -s http://localhost:8404/stats 2>/dev/null | grep mkdocs | \
            awk -F',' '{printf "%-20s: %8s requests\n", $1, $8}' || \
            print_warning "HAProxy stats no disponible"
        ;;
        
    "start")
        print_info "Iniciando servicios de documentación..."
        docker-compose up -d mkdocs-server mkdocs-dev-server
        print_success "Servicios iniciados"
        ;;
        
    "stop")
        print_info "Deteniendo servicios de documentación..."
        docker-compose stop mkdocs-server mkdocs-dev-server mkdocs-v1-server
        print_success "Servicios detenidos"
        ;;
        
    "logs")
        print_info "Logs de servicios de documentación:"
        docker-compose logs --tail=50 mkdocs-server mkdocs-dev-server
        ;;
        
    "update-haproxy")
        print_info "Actualizando configuración HAProxy..."
        
        # Validar configuración
        if docker exec haproxy-lb haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg; then
            print_success "Configuración válida"
            
            # Recargar HAProxy sin downtime
            docker exec haproxy-lb kill -USR2 1
            print_success "HAProxy recargado exitosamente"
        else
            print_warning "Error en configuración HAProxy"
            exit 1
        fi
        ;;
        
    *)
        echo "Uso: $0 {deploy|deploy-dev|status|start|stop|logs|update-haproxy}"
        echo
        echo "Comandos:"
        echo "  deploy         - Desplegar documentación de producción"
        echo "  deploy-dev     - Desplegar documentación de desarrollo"
        echo "  status         - Ver estado de servicios y tráfico"
        echo "  start          - Iniciar servicios de documentación"
        echo "  stop           - Detener servicios de documentación"
        echo "  logs           - Ver logs de servicios"
        echo "  update-haproxy - Recargar configuración HAProxy"
        echo
        echo "URLs de acceso:"
        echo "  http://localhost:8080/docs     - Documentación principal"
        echo "  http://localhost:8080/docs/dev - Documentación desarrollo"
        echo "  http://localhost:8404/stats    - HAProxy stats"
        exit 1
        ;;
esac
EOF
    
    chmod +x manage-docs-haproxy.sh
    print_success "Script manage-docs-haproxy.sh creado"
    
    # Script de aplicación de configuración
    cat > apply-haproxy-mkdocs.sh << 'EOF'
#!/bin/bash

echo "🔄 Aplicando configuración HAProxy + MkDocs..."

# Verificar que existe la nueva configuración
if [ ! -f "haproxy/haproxy-mkdocs.cfg" ]; then
    echo "❌ haproxy/haproxy-mkdocs.cfg no encontrado"
    exit 1
fi

# Backup configuración actual
cp haproxy/haproxy.cfg haproxy/haproxy.cfg.backup.$(date +%Y%m%d_%H%M%S)

# Aplicar nueva configuración
cp haproxy/haproxy-mkdocs.cfg haproxy/haproxy.cfg

echo "✅ Configuración aplicada"
echo "💡 Ejecuta 'docker-compose restart haproxy-lb' para aplicar cambios"
EOF
    
    chmod +x apply-haproxy-mkdocs.sh
    print_success "Script apply-haproxy-mkdocs.sh creado"
}

# Construir documentación inicial
build_initial_docs() {
    print_header "Construyendo Documentación Inicial"
    
    if [ -f "build-docs.sh" ]; then
        print_info "Construyendo sitio MkDocs..."
        ./build-docs.sh build
        print_success "Documentación construida en site/"
    else
        print_warning "build-docs.sh no encontrado, construyendo manualmente..."
        if command -v mkdocs &> /dev/null; then
            mkdocs build
            print_success "Documentación construida"
        else
            print_error "MkDocs no disponible. Ejecuta ./setup-docs.sh primero"
            exit 1
        fi
    fi
}

# Mostrar información final
show_final_info() {
    print_header "Configuración Completada"
    
    echo -e "${GREEN}"
    cat << 'EOF'
🎉 ¡Integración HAProxy + MkDocs configurada exitosamente!

📁 Archivos creados:
   ├── Dockerfile.mkdocs              # Docker para docs producción
   ├── Dockerfile.mkdocs-dev          # Docker para docs desarrollo
   ├── nginx/mkdocs.conf              # Configuración Nginx
   ├── haproxy/haproxy-mkdocs.cfg     # Nueva config HAProxy
   ├── manage-docs-haproxy.sh         # Script de gestión
   └── apply-haproxy-mkdocs.sh        # Script de aplicación

🚀 Próximos pasos:
EOF
    echo -e "${NC}"
    
    echo -e "${BLUE}   1. Revisar configuración HAProxy:${NC}"
    echo -e "      cat haproxy/haproxy-mkdocs.cfg"
    echo
    echo -e "${BLUE}   2. Aplicar nueva configuración:${NC}"
    echo -e "      ./apply-haproxy-mkdocs.sh"
    echo
    echo -e "${BLUE}   3. Iniciar servicios:${NC}"
    echo -e "      docker-compose up -d --build"
    echo
    echo -e "${BLUE}   4. Verificar funcionamiento:${NC}"
    echo -e "      ./manage-docs-haproxy.sh status"
    echo
    echo -e "${YELLOW}📍 URLs de acceso:${NC}"
    echo -e "   • Documentación: ${BLUE}http://localhost:8080/docs${NC}"
    echo -e "   • Docs desarrollo: ${BLUE}http://localhost:8080/docs/dev${NC}"
    echo -e "   • Aplicaciones: ${BLUE}http://localhost:8080${NC}"
    echo -e "   • HAProxy stats: ${BLUE}http://localhost:8404/stats${NC}"
    echo
    print_success "¡Listo para servir documentación junto con aplicaciones WebLogic!"
}

# Función principal
main() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║              SETUP HAPROXY + MKDOCS INTEGRATION             ║
║                                                              ║
║  Este script configura HAProxy para servir documentación    ║
║  MkDocs junto con las aplicaciones WebLogic de manera       ║
║  unificada y profesional.                                   ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Ejecutar pasos de configuración
    check_prerequisites
    create_mkdocs_dockerfiles
    create_nginx_config
    update_haproxy_config
    update_docker_compose
    create_management_scripts
    build_initial_docs
    show_final_info
}

# Manejo de errores
trap 'print_error "Error en línea $LINENO. Configuración interrumpida."; exit 1' ERR

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml no encontrado. Ejecuta desde el directorio raíz del proyecto."
    exit 1
fi

# Ejecutar función principal
main "$@"
