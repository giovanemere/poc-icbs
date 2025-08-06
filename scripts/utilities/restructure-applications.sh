#!/bin/bash

# ============================================================================
# Script de Reestructuración del Directorio Applications
# ============================================================================
# Descripción: Reorganiza el directorio applications/ usando variables centralizadas
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
║           Reestructuración Directorio Applications          ║
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

# Verificar variables críticas
REQUIRED_VARS=(
    "WEBLOGIC_APP_PATH"
    "HAPROXY_APP_PATH" 
    "MKDOCS_APP_PATH"
    "ORACLE_APP_PATH"
    "DOCKER_NAMESPACE"
)

log "Verificando variables críticas..."
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        error "Variable requerida no definida: $var"
        exit 1
    else
        info "$var = ${!var}"
    fi
done

# Crear backup de la estructura actual
BACKUP_DIR="$PROJECT_ROOT/backups/applications-$(date +%Y%m%d-%H%M%S)"
log "Creando backup en: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
if [[ -d "$PROJECT_ROOT/applications" ]]; then
    cp -r "$PROJECT_ROOT/applications" "$BACKUP_DIR/"
    success "Backup creado exitosamente"
fi

# Función para crear estructura de aplicación
create_app_structure() {
    local app_name="$1"
    local app_path="$2"
    local description="$3"
    
    log "Creando estructura para: $app_name"
    
    # Crear directorios base
    mkdir -p "$PROJECT_ROOT/$app_path"/{src,config,scripts,deploy,docs,tests}
    
    # Crear README específico de la aplicación
    cat > "$PROJECT_ROOT/$app_path/README.md" << EOF
# $app_name

## Descripción
$description

## Estructura del Proyecto
\`\`\`
$app_path/
├── src/                 # Código fuente de la aplicación
├── config/             # Archivos de configuración
├── scripts/            # Scripts específicos de la aplicación
├── deploy/             # Archivos de deployment
├── docs/               # Documentación específica
├── tests/              # Tests unitarios e integración
├── Dockerfile          # Dockerfile principal
├── docker-compose.yml  # Compose específico (si aplica)
└── README.md          # Esta documentación
\`\`\`

## Variables de Entorno
Las variables están centralizadas en \`scripts/.env\` y sus overrides por ambiente.

## Build y Deployment
\`\`\`bash
# Build de la imagen
docker build -t \${DOCKER_NAMESPACE}/$app_name:\${VERSION} .

# Run local
docker-compose up -d

# Deploy usando scripts centralizados
./scripts/services/manage-services.sh start
\`\`\`

## Documentación
- [Documentación Principal](../../docs/)
- [Variables Centralizadas](../../docs/VARIABLES-CENTRALIZADAS.md)
- [Plan de Implementación](../../docs/plan-implementacion.md)

---
**Generado automáticamente por**: scripts/utilities/restructure-applications.sh  
**Fecha**: $(date +'%Y-%m-%d %H:%M:%S')
EOF

    success "Estructura creada para $app_name"
}

# Función para mover archivos existentes
move_existing_files() {
    local source_dir="$1"
    local target_path="$2"
    local app_name="$3"
    
    if [[ -d "$PROJECT_ROOT/$source_dir" ]]; then
        log "Moviendo archivos existentes de $source_dir a $target_path"
        
        # Crear directorio destino si no existe
        mkdir -p "$PROJECT_ROOT/$target_path"
        
        # Mover archivos manteniendo estructura
        find "$PROJECT_ROOT/$source_dir" -mindepth 1 -maxdepth 1 -exec cp -r {} "$PROJECT_ROOT/$target_path/" \;
        
        success "Archivos movidos para $app_name"
    else
        warning "Directorio fuente no existe: $source_dir"
    fi
}

# Función para crear Dockerfile estándar
create_dockerfile() {
    local app_path="$1"
    local base_image="$2"
    local app_name="$3"
    
    cat > "$PROJECT_ROOT/$app_path/Dockerfile" << EOF
# Dockerfile para $app_name
# Generado automáticamente - Personalizar según necesidades

FROM $base_image

# Metadata
LABEL maintainer="DevOps Team"
LABEL version="\${VERSION:-latest}"
LABEL description="$app_name para Docker WebLogic Oracle Project"

# Variables de entorno (cargadas desde sistema centralizado)
ENV APP_NAME="$app_name"
ENV DOCKER_NAMESPACE="\${DOCKER_NAMESPACE}"
ENV VERSION="\${VERSION:-latest}"

# Directorio de trabajo
WORKDIR /app

# Copiar archivos de configuración
COPY config/ /app/config/
COPY scripts/ /app/scripts/

# Copiar código fuente
COPY src/ /app/src/

# Hacer scripts ejecutables
RUN find /app/scripts -name "*.sh" -exec chmod +x {} \;

# Exponer puertos (personalizar según aplicación)
# EXPOSE 8080

# Health check (personalizar según aplicación)
# HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
#   CMD curl -f http://localhost:8080/health || exit 1

# Comando por defecto (personalizar según aplicación)
CMD ["/app/scripts/start.sh"]
EOF

    success "Dockerfile creado para $app_name"
}

# Función para crear docker-compose específico
create_docker_compose() {
    local app_path="$1"
    local app_name="$2"
    local service_name="$3"
    
    cat > "$PROJECT_ROOT/$app_path/docker-compose.yml" << EOF
# Docker Compose para $app_name
# Generado automáticamente - Personalizar según necesidades

version: '3.8'

services:
  $service_name:
    build:
      context: .
      dockerfile: Dockerfile
    image: \${DOCKER_NAMESPACE}/$app_name:\${VERSION:-latest}
    container_name: \${COMPOSE_PROJECT_NAME}-$service_name
    restart: unless-stopped
    
    # Variables de entorno (cargadas desde sistema centralizado)
    env_file:
      - ../../scripts/.env
      - ../../scripts/.env.\${ENVIRONMENT:-development}
    
    # Redes (usar red principal del proyecto)
    networks:
      - weblogic-network
    
    # Volúmenes (personalizar según necesidades)
    volumes:
      - ./config:/app/config:ro
      - ./logs:/app/logs
    
    # Puertos (personalizar según aplicación)
    # ports:
    #   - "\${APP_EXTERNAL_PORT}:8080"
    
    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    
    # Dependencias (personalizar según necesidades)
    # depends_on:
    #   - oracle-db

# Usar red externa del proyecto principal
networks:
  weblogic-network:
    external: true
    name: \${COMPOSE_PROJECT_NAME}_weblogic-network

# Volúmenes (si se requieren volúmenes específicos)
volumes:
  ${service_name}-logs:
    driver: local
EOF

    success "Docker Compose creado para $app_name"
}

# ============================================================================
# INICIO DE LA REESTRUCTURACIÓN
# ============================================================================

log "Iniciando reestructuración del directorio applications/"

# 1. WebLogic Feature Flags Application
log "=== Reestructurando WebLogic Feature Flags ==="
create_app_structure "weblogic-feature-flags" "$WEBLOGIC_APP_PATH" "Aplicación WebLogic con sistema de Feature Flags para A/B Testing"

# Mover archivos existentes si existen
if [[ -d "$PROJECT_ROOT/applications/weblogic-feature-flags" ]]; then
    # Los archivos ya están en la ubicación correcta, solo reorganizar
    log "Reorganizando archivos existentes de WebLogic"
    
    # Mover Dockerfiles si existen en el root
    if [[ -f "$PROJECT_ROOT/Dockerfile.weblogic" ]]; then
        mv "$PROJECT_ROOT/Dockerfile.weblogic" "$PROJECT_ROOT/$WEBLOGIC_APP_PATH/Dockerfile"
        success "Dockerfile.weblogic movido"
    fi
    
    # Mover archivos de weblogic/ si existe
    if [[ -d "$PROJECT_ROOT/weblogic" ]]; then
        cp -r "$PROJECT_ROOT/weblogic/"* "$PROJECT_ROOT/$WEBLOGIC_APP_PATH/src/" 2>/dev/null || true
        success "Archivos de weblogic/ copiados"
    fi
fi

create_dockerfile "$WEBLOGIC_APP_PATH" "vulhub/weblogic:12.2.1.3-2018" "weblogic-feature-flags"
create_docker_compose "$WEBLOGIC_APP_PATH" "weblogic-feature-flags" "weblogic-app"

# 2. HAProxy Advanced Application
log "=== Reestructurando HAProxy Advanced ==="
create_app_structure "haproxy-advanced" "$HAPROXY_APP_PATH" "Load Balancer HAProxy con configuración avanzada, admin UI y A/B testing"

# Mover archivos existentes
if [[ -d "$PROJECT_ROOT/haproxy" ]]; then
    cp -r "$PROJECT_ROOT/haproxy/"* "$PROJECT_ROOT/$HAPROXY_APP_PATH/src/" 2>/dev/null || true
    success "Archivos de haproxy/ copiados"
fi

if [[ -f "$PROJECT_ROOT/Dockerfile.haproxy" ]]; then
    mv "$PROJECT_ROOT/Dockerfile.haproxy" "$PROJECT_ROOT/$HAPROXY_APP_PATH/Dockerfile"
    success "Dockerfile.haproxy movido"
fi

create_dockerfile "$HAPROXY_APP_PATH" "haproxy:2.6" "haproxy-advanced"
create_docker_compose "$HAPROXY_APP_PATH" "haproxy-advanced" "haproxy"

# 3. MkDocs Documentation Server
log "=== Reestructurando MkDocs Server ==="
create_app_structure "mkdocs-server" "$MKDOCS_APP_PATH" "Servidor de documentación MkDocs con auto-reload y navegación optimizada"

# Mover archivos de documentación
if [[ -d "$PROJECT_ROOT/docs" ]]; then
    cp -r "$PROJECT_ROOT/docs" "$PROJECT_ROOT/$MKDOCS_APP_PATH/"
    success "Documentación copiada"
fi

if [[ -f "$PROJECT_ROOT/mkdocs.yml" ]]; then
    cp "$PROJECT_ROOT/mkdocs.yml" "$PROJECT_ROOT/$MKDOCS_APP_PATH/"
    success "mkdocs.yml copiado"
fi

if [[ -f "$PROJECT_ROOT/Dockerfile.mkdocs" ]]; then
    mv "$PROJECT_ROOT/Dockerfile.mkdocs" "$PROJECT_ROOT/$MKDOCS_APP_PATH/Dockerfile"
elif [[ -f "$PROJECT_ROOT/Dockerfile.mkdocs-fixed" ]]; then
    mv "$PROJECT_ROOT/Dockerfile.mkdocs-fixed" "$PROJECT_ROOT/$MKDOCS_APP_PATH/Dockerfile"
    success "Dockerfile.mkdocs movido"
fi

create_dockerfile "$MKDOCS_APP_PATH" "python:3.11-slim" "mkdocs-server"
create_docker_compose "$MKDOCS_APP_PATH" "mkdocs-server" "mkdocs"

# 4. Oracle Database Setup
log "=== Reestructurando Oracle Setup ==="
create_app_structure "oracle-setup" "$ORACLE_APP_PATH" "Configuración y scripts para Oracle Database Express con health checks"

# Mover archivos de Oracle
if [[ -d "$PROJECT_ROOT/oracle" ]]; then
    cp -r "$PROJECT_ROOT/oracle/"* "$PROJECT_ROOT/$ORACLE_APP_PATH/src/" 2>/dev/null || true
    success "Archivos de oracle/ copiados"
fi

if [[ -f "$PROJECT_ROOT/Dockerfile.oracle" ]]; then
    mv "$PROJECT_ROOT/Dockerfile.oracle" "$PROJECT_ROOT/$ORACLE_APP_PATH/Dockerfile"
    success "Dockerfile.oracle movido"
fi

create_dockerfile "$ORACLE_APP_PATH" "container-registry.oracle.com/database/express:latest" "oracle-setup"
create_docker_compose "$ORACLE_APP_PATH" "oracle-setup" "oracle-db"

# 5. Crear archivo de configuración principal de applications
log "=== Creando configuración principal ==="
cat > "$PROJECT_ROOT/applications/README.md" << EOF
# Applications Directory

Este directorio contiene todas las aplicaciones del proyecto Docker WebLogic Oracle organizadas de manera estándar.

## Estructura General

\`\`\`
applications/
├── weblogic-feature-flags/    # Aplicación WebLogic con Feature Flags
├── haproxy-advanced/          # Load Balancer HAProxy avanzado
├── mkdocs-server/             # Servidor de documentación
├── oracle-setup/              # Configuración Oracle Database
└── README.md                  # Esta documentación
\`\`\`

## Variables Centralizadas

Todas las aplicaciones utilizan el sistema de variables centralizadas:
- **Base**: \`scripts/.env\`
- **Por ambiente**: \`scripts/.env.{development|staging|production}\`
- **Carga**: \`source scripts/core/load-env-enhanced.sh [environment]\`

## Paths de Aplicaciones

| Aplicación | Variable | Path |
|------------|----------|------|
| WebLogic | \`WEBLOGIC_APP_PATH\` | \`$WEBLOGIC_APP_PATH\` |
| HAProxy | \`HAPROXY_APP_PATH\` | \`$HAPROXY_APP_PATH\` |
| MkDocs | \`MKDOCS_APP_PATH\` | \`$MKDOCS_APP_PATH\` |
| Oracle | \`ORACLE_APP_PATH\` | \`$ORACLE_APP_PATH\` |

## Docker Hub Integration

Todas las imágenes están configuradas para el namespace: **$DOCKER_NAMESPACE**

| Aplicación | Imagen Completa |
|------------|-----------------|
| WebLogic | \`$WEBLOGIC_FULL_IMAGE\` |
| HAProxy | \`$HAPROXY_FULL_IMAGE\` |
| MkDocs | \`$MKDOCS_FULL_IMAGE\` |
| Oracle | \`$ORACLE_FULL_IMAGE\` |

## Build y Deployment

### Build Individual
\`\`\`bash
# Cargar variables
source scripts/core/load-env-enhanced.sh development

# Build aplicación específica
cd applications/weblogic-feature-flags
docker build -t \$WEBLOGIC_FULL_IMAGE .
\`\`\`

### Build Todas las Aplicaciones
\`\`\`bash
# Usar script centralizado (próximamente)
./scripts/build/build-all-applications.sh
\`\`\`

### Deployment
\`\`\`bash
# Usar script principal
./scripts/services/manage-services.sh start
\`\`\`

## Desarrollo

### Estructura Estándar por Aplicación
\`\`\`
app-name/
├── src/                 # Código fuente
├── config/             # Configuraciones
├── scripts/            # Scripts específicos
├── deploy/             # Archivos de deployment
├── docs/               # Documentación específica
├── tests/              # Tests
├── Dockerfile          # Dockerfile principal
├── docker-compose.yml  # Compose específico
└── README.md          # Documentación
\`\`\`

### Convenciones
- **Dockerfiles**: Un Dockerfile por aplicación
- **Variables**: Usar sistema centralizado
- **Puertos**: Definidos en variables centralizadas
- **Redes**: Usar red principal del proyecto
- **Volúmenes**: Nombrados consistentemente

## Próximos Pasos

1. **Build Scripts**: Crear scripts automatizados de build
2. **CI/CD Integration**: Integrar con pipeline
3. **Testing**: Implementar tests por aplicación
4. **Monitoring**: Agregar health checks avanzados

---
**Generado por**: scripts/utilities/restructure-applications.sh  
**Fecha**: $(date +'%Y-%m-%d %H:%M:%S')  
**Variables**: Sistema centralizado activo
EOF

success "Configuración principal de applications creada"

# 6. Crear script de build para todas las aplicaciones
log "=== Creando script de build centralizado ==="
mkdir -p "$PROJECT_ROOT/scripts/build"

cat > "$PROJECT_ROOT/scripts/build/build-all-applications.sh" << 'EOF'
#!/bin/bash

# Script para build de todas las aplicaciones
# Utiliza variables centralizadas

set -euo pipefail

# Cargar variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" ${1:-development}

echo "🏗️  Building all applications..."

# Array de aplicaciones
declare -A APPLICATIONS=(
    ["weblogic-feature-flags"]="$WEBLOGIC_APP_PATH"
    ["haproxy-advanced"]="$HAPROXY_APP_PATH"
    ["mkdocs-server"]="$MKDOCS_APP_PATH"
    ["oracle-setup"]="$ORACLE_APP_PATH"
)

# Build cada aplicación
for app_name in "${!APPLICATIONS[@]}"; do
    app_path="${APPLICATIONS[$app_name]}"
    echo "📦 Building $app_name..."
    
    if [[ -f "$PROJECT_ROOT/$app_path/Dockerfile" ]]; then
        cd "$PROJECT_ROOT/$app_path"
        
        # Obtener imagen completa desde variables
        case $app_name in
            "weblogic-feature-flags") image="$WEBLOGIC_FULL_IMAGE" ;;
            "haproxy-advanced") image="$HAPROXY_FULL_IMAGE" ;;
            "mkdocs-server") image="$MKDOCS_FULL_IMAGE" ;;
            "oracle-setup") image="$ORACLE_FULL_IMAGE" ;;
        esac
        
        docker build -t "$image" .
        echo "✅ $app_name built successfully"
    else
        echo "⚠️  Dockerfile not found for $app_name"
    fi
done

echo "🎉 All applications built successfully!"
EOF

chmod +x "$PROJECT_ROOT/scripts/build/build-all-applications.sh"
success "Script de build centralizado creado"

# 7. Actualizar docker-compose.yml principal para usar nuevas rutas
log "=== Actualizando docker-compose.yml principal ==="

# Crear backup del docker-compose actual
if [[ -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
    cp "$PROJECT_ROOT/docker-compose.yml" "$BACKUP_DIR/docker-compose.yml.backup"
    success "Backup de docker-compose.yml creado"
fi

# Actualizar referencias en docker-compose.yml
if [[ -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
    log "Actualizando referencias de paths en docker-compose.yml"
    
    # Crear versión actualizada
    sed -i.bak \
        -e "s|build: haproxy|build: $HAPROXY_APP_PATH|g" \
        -e "s|build: weblogic|build: $WEBLOGIC_APP_PATH|g" \
        -e "s|build: .|build: $MKDOCS_APP_PATH|g" \
        -e "s|dockerfile: Dockerfile.mkdocs|dockerfile: Dockerfile|g" \
        -e "s|dockerfile: Dockerfile.haproxy|dockerfile: Dockerfile|g" \
        -e "s|dockerfile: Dockerfile.weblogic|dockerfile: Dockerfile|g" \
        "$PROJECT_ROOT/docker-compose.yml"
    
    success "docker-compose.yml actualizado con nuevas rutas"
fi

# 8. Crear script de validación de estructura
log "=== Creando script de validación ==="
cat > "$PROJECT_ROOT/scripts/validation/validate-applications-structure.sh" << 'EOF'
#!/bin/bash

# Script de validación de estructura de applications
set -euo pipefail

# Cargar variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" development 2>/dev/null

echo "🔍 Validando estructura de applications..."

# Validar cada aplicación
APPS=("$WEBLOGIC_APP_PATH" "$HAPROXY_APP_PATH" "$MKDOCS_APP_PATH" "$ORACLE_APP_PATH")
REQUIRED_DIRS=("src" "config" "scripts" "deploy" "docs" "tests")
REQUIRED_FILES=("README.md" "Dockerfile")

for app_path in "${APPS[@]}"; do
    app_name=$(basename "$app_path")
    echo "📁 Validando $app_name..."
    
    if [[ -d "$PROJECT_ROOT/$app_path" ]]; then
        echo "  ✅ Directorio existe: $app_path"
        
        # Validar directorios requeridos
        for dir in "${REQUIRED_DIRS[@]}"; do
            if [[ -d "$PROJECT_ROOT/$app_path/$dir" ]]; then
                echo "  ✅ $dir/"
            else
                echo "  ⚠️  $dir/ (faltante)"
            fi
        done
        
        # Validar archivos requeridos
        for file in "${REQUIRED_FILES[@]}"; do
            if [[ -f "$PROJECT_ROOT/$app_path/$file" ]]; then
                echo "  ✅ $file"
            else
                echo "  ❌ $file (faltante)"
            fi
        done
    else
        echo "  ❌ Directorio no existe: $app_path"
    fi
    echo ""
done

echo "🎯 Validación completada"
EOF

chmod +x "$PROJECT_ROOT/scripts/validation/validate-applications-structure.sh"
success "Script de validación creado"

# ============================================================================
# RESUMEN FINAL
# ============================================================================

echo -e "${PURPLE}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    REESTRUCTURACIÓN COMPLETADA              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

success "Reestructuración del directorio applications/ completada exitosamente"

echo -e "${CYAN}=== RESUMEN DE CAMBIOS ===${NC}"
echo "📁 Aplicaciones reestructuradas:"
echo "  • weblogic-feature-flags → $WEBLOGIC_APP_PATH"
echo "  • haproxy-advanced → $HAPROXY_APP_PATH"  
echo "  • mkdocs-server → $MKDOCS_APP_PATH"
echo "  • oracle-setup → $ORACLE_APP_PATH"
echo ""
echo "📄 Archivos creados:"
echo "  • 4 README.md específicos por aplicación"
echo "  • 4 Dockerfiles estándar"
echo "  • 4 docker-compose.yml específicos"
echo "  • 1 README.md principal de applications/"
echo "  • 1 script de build centralizado"
echo "  • 1 script de validación de estructura"
echo ""
echo "💾 Backup creado en: $BACKUP_DIR"
echo ""
echo -e "${CYAN}=== PRÓXIMOS PASOS ===${NC}"
echo "1. Validar estructura: ./scripts/validation/validate-applications-structure.sh"
echo "2. Build aplicaciones: ./scripts/build/build-all-applications.sh"
echo "3. Test deployment: ./scripts/services/manage-services.sh restart"
echo ""
echo -e "${GREEN}🎉 Reestructuración completada exitosamente!${NC}"
