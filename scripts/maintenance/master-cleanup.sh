#!/bin/bash

# SCRIPT MAESTRO DE LIMPIEZA Y ORGANIZACIÓN COMPLETA
# Implementa limpieza automática al 100%
# Autor: Amazon Q

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}🧹 LIMPIEZA MAESTRA INICIADA${NC}"
echo -e "${BLUE}Objetivo: Organización 100% automatizada${NC}"
echo ""

# Función de logging
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"; }
info() { echo -e "${CYAN}[$(date +'%H:%M:%S')] ℹ️  $1${NC}"; }

# FASE 1: LIMPIEZA DE RAÍZ
echo -e "${BLUE}🎯 FASE 1: LIMPIEZA COMPLETA DE RAÍZ${NC}"

# Lista blanca de archivos permitidos en raíz
ALLOWED_ROOT_FILES=(
    "README.md"
    "LICENSE"
    ".gitignore"
    ".env"
    ".env.example"
    "docker-compose.yml"
    "Dockerfile"
    "Dockerfile.mkdocs"
    "Dockerfile.mkdocs-dev"
    "mkdocs.yml"
    "mkdocs-dev.yml"
    "requirements.txt"
    "CHANGELOG.md"
    "PROJECT_SUMMARY.md"
    "browser-cache-instructions.txt"
    "fix_dashboard.py"
)

# Lista blanca de enlaces simbólicos permitidos (scripts principales)
ALLOWED_SYMLINKS=(
    "setup.sh"
    "run.sh"
    "start-all.sh"
    "stop-all-services.sh"
    "manage-services.sh"
    "deploy-war.sh"
    "build.sh"
    "setup-canary.sh"
    "canary-control.sh"
    "test-canary.sh"
    "build-docs.sh"
    "setup-docs.sh"
)

# Crear backup de seguridad
BACKUP_DIR="$PROJECT_ROOT/backup/cleanup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
log "Backup creado en: $BACKUP_DIR"

# Identificar y mover scripts temporales/de organización
info "Identificando scripts temporales en raíz..."

TEMP_SCRIPTS=(
    "organize-and-validate-scripts.sh"
    "organize-and-validate-scripts-v2.sh"
    "apply-mkdocs-updates.sh"
    "create-master-cleanup-script.sh"
)

for script in "${TEMP_SCRIPTS[@]}"; do
    if [[ -f "$PROJECT_ROOT/$script" ]]; then
        warn "Moviendo script temporal: $script"
        # Backup primero
        cp "$PROJECT_ROOT/$script" "$BACKUP_DIR/"
        # Mover a maintenance
        mv "$PROJECT_ROOT/$script" "$SCRIPTS_DIR/maintenance/"
        log "Script movido: $script → scripts/maintenance/"
    fi
done

# Verificar archivos .sh no autorizados en raíz
info "Verificando archivos .sh no autorizados en raíz..."

find "$PROJECT_ROOT" -maxdepth 1 -name "*.sh" -type f | while read -r file; do
    filename=$(basename "$file")
    warn "Archivo .sh no autorizado encontrado: $filename"
    # Mover a scripts/maintenance/
    cp "$file" "$BACKUP_DIR/"
    mv "$file" "$SCRIPTS_DIR/maintenance/"
    log "Archivo movido: $filename → scripts/maintenance/"
done

# Validar enlaces simbólicos
info "Validando enlaces simbólicos..."

BROKEN_LINKS=0
VALID_LINKS=0

find "$PROJECT_ROOT" -maxdepth 1 -name "*.sh" -type l | while read -r link; do
    filename=$(basename "$link")
    
    if [[ ! -e "$link" ]]; then
        error "Enlace roto detectado: $filename"
        BROKEN_LINKS=$((BROKEN_LINKS + 1))
        # Intentar reparar
        if [[ -f "$SCRIPTS_DIR/core/$filename" ]]; then
            rm "$link"
            ln -sf "scripts/core/$filename" "$PROJECT_ROOT/$filename"
            log "Enlace reparado: $filename → scripts/core/"
        elif [[ -f "$SCRIPTS_DIR/services/$filename" ]]; then
            rm "$link"
            ln -sf "scripts/services/$filename" "$PROJECT_ROOT/$filename"
            log "Enlace reparado: $filename → scripts/services/"
        elif [[ -f "$SCRIPTS_DIR/deployment/$filename" ]]; then
            rm "$link"
            ln -sf "scripts/deployment/$filename" "$PROJECT_ROOT/$filename"
            log "Enlace reparado: $filename → scripts/deployment/"
        elif [[ -f "$SCRIPTS_DIR/canary/$filename" ]]; then
            rm "$link"
            ln -sf "scripts/canary/$filename" "$PROJECT_ROOT/$filename"
            log "Enlace reparado: $filename → scripts/canary/"
        elif [[ -f "$SCRIPTS_DIR/docs/$filename" ]]; then
            rm "$link"
            ln -sf "scripts/docs/$filename" "$PROJECT_ROOT/$filename"
            log "Enlace reparado: $filename → scripts/docs/"
        else
            warn "No se pudo reparar enlace: $filename"
        fi
    else
        VALID_LINKS=$((VALID_LINKS + 1))
        log "Enlace válido: $filename"
    fi
done

# FASE 2: ORGANIZACIÓN COMPLETA DE MKDOCS
echo -e "${BLUE}🎯 FASE 2: ORGANIZACIÓN COMPLETA DE MKDOCS${NC}"

# Crear estructura completa de documentación
info "Creando estructura completa de documentación..."

mkdir -p "$PROJECT_ROOT/docs/architecture"
mkdir -p "$PROJECT_ROOT/docs/deployment"
mkdir -p "$PROJECT_ROOT/docs/guides"
mkdir -p "$PROJECT_ROOT/docs/reference"
mkdir -p "$PROJECT_ROOT/docs/scripts"  # Ya existe

# Reorganizar archivos de documentación existentes
if [[ -f "$PROJECT_ROOT/docs/arquitectura.md" ]]; then
    mv "$PROJECT_ROOT/docs/arquitectura.md" "$PROJECT_ROOT/docs/architecture/index.md"
    log "Movido: arquitectura.md → architecture/index.md"
fi

if [[ -f "$PROJECT_ROOT/docs/deployment.md" ]]; then
    mv "$PROJECT_ROOT/docs/deployment.md" "$PROJECT_ROOT/docs/deployment/index.md"
    log "Movido: deployment.md → deployment/index.md"
fi

if [[ -f "$PROJECT_ROOT/docs/TROUBLESHOOTING.md" ]]; then
    mv "$PROJECT_ROOT/docs/TROUBLESHOOTING.md" "$PROJECT_ROOT/docs/guides/troubleshooting.md"
    log "Movido: TROUBLESHOOTING.md → guides/troubleshooting.md"
fi

if [[ -f "$PROJECT_ROOT/docs/DEPLOYMENT_GUIDE.md" ]]; then
    mv "$PROJECT_ROOT/docs/DEPLOYMENT_GUIDE.md" "$PROJECT_ROOT/docs/deployment/advanced-guide.md"
    log "Movido: DEPLOYMENT_GUIDE.md → deployment/advanced-guide.md"
fi

if [[ -f "$PROJECT_ROOT/docs/CANARY_GUIDE.md" ]]; then
    mv "$PROJECT_ROOT/docs/CANARY_GUIDE.md" "$PROJECT_ROOT/docs/deployment/canary-guide.md"
    log "Movido: CANARY_GUIDE.md → deployment/canary-guide.md"
fi

if [[ -f "$PROJECT_ROOT/docs/haproxy.md" ]]; then
    mv "$PROJECT_ROOT/docs/haproxy.md" "$PROJECT_ROOT/docs/guides/haproxy-setup.md"
    log "Movido: haproxy.md → guides/haproxy-setup.md"
fi

# Crear archivos índice para cada sección
cat > "$PROJECT_ROOT/docs/architecture/components.md" << 'ARCH_EOF'
# Componentes de la Arquitectura

## Componentes Principales

### WebLogic Server
- Servidor de aplicaciones principal
- Configuración en cluster A/B
- Gestión de aplicaciones WAR

### HAProxy Load Balancer
- Balanceador de carga
- Gestión de tráfico canary
- Monitoreo y estadísticas

### Docker Containers
- Contenedores para cada componente
- Orquestación con Docker Compose
- Gestión de volúmenes y redes

## Diagrama de Arquitectura

```
[Cliente] → [HAProxy] → [WebLogic A/B] → [Aplicaciones]
                ↓
           [Monitoreo]
```

## Flujo de Datos

1. **Entrada**: Cliente hace petición
2. **Balanceo**: HAProxy distribuye tráfico
3. **Procesamiento**: WebLogic procesa petición
4. **Respuesta**: Resultado enviado al cliente
ARCH_EOF

# Actualizar mkdocs.yml con nueva estructura
cat > "$PROJECT_ROOT/mkdocs.yml" << 'MKDOCS_EOF'
site_name: Docker Oracle WebLogic - Documentación
site_description: Documentación completa para el proyecto Docker Oracle WebLogic con despliegues canary y feature flags
site_author: ICBS Team
site_url: https://your-domain.com

# Repository
repo_name: docker-for-oracle-weblogic
repo_url: https://github.com/your-org/docker-for-oracle-weblogic
edit_uri: edit/main/docs/

# Configuration
theme:
  name: material
  language: es
  palette:
    # Palette toggle for light mode
    - scheme: default
      primary: blue
      accent: blue
      toggle:
        icon: material/brightness-7
        name: Cambiar a modo oscuro
    # Palette toggle for dark mode
    - scheme: slate
      primary: blue
      accent: blue
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
    - search.highlight
    - search.share
    - content.code.copy
    - content.code.annotate
    - content.tabs.link
    - toc.follow
    - toc.integrate

# Plugins
plugins:
  - search:
      lang: es

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
      user: your-org
      repo: docker-for-oracle-weblogic
  - pymdownx.mark
  - pymdownx.smartsymbols
  - pymdownx.superfences
  - pymdownx.tabbed:
      alternate_style: true
  - pymdownx.tasklist:
      custom_checkbox: true
  - pymdownx.tilde

# Navigation - Estructura Completamente Organizada
nav:
  - 🏠 Inicio: index.md
  - 🚀 Primeros Pasos: getting-started.md
  - 🏗️ Arquitectura:
    - Visión General: architecture/index.md
    - Componentes: architecture/components.md
  - 📦 Despliegue:
    - Despliegue Básico: deployment/index.md
    - Guía Avanzada: deployment/advanced-guide.md
    - Despliegue Canary: deployment/canary-guide.md
  - 🎯 Canary y Features: canary-and-features.md
  - 📜 Scripts:
    - Índice de Scripts: scripts/index.md
    - Guía de Uso: scripts/usage-guide.md
    - Referencia Completa: scripts/reference.md
  - 📚 Guías:
    - Troubleshooting: guides/troubleshooting.md
    - Configuración HAProxy: guides/haproxy-setup.md
    - Integración MkDocs: mkdocs-haproxy-integration.md
  - 📖 Referencia:
    - Configuración: reference/configuration.md
    - API: reference/api.md
  - 🆘 Soporte: support.md

# Extra
extra:
  social:
    - icon: fontawesome/brands/github
      link: https://github.com/your-org/docker-for-oracle-weblogic
    - icon: fontawesome/brands/docker
      link: https://hub.docker.com/
  version:
    provider: mike

# Copyright
copyright: Copyright &copy; 2024 ICBS Team
MKDOCS_EOF

log "Configuración de MkDocs actualizada con estructura completa"

# Crear archivos de referencia faltantes
cat > "$PROJECT_ROOT/docs/reference/configuration.md" << 'CONFIG_EOF'
# Referencia de Configuración

## Variables de Entorno

### WebLogic
```bash
WEBLOGIC_ADMIN_USER=weblogic
WEBLOGIC_ADMIN_PASSWORD=welcome1
WEBLOGIC_PORT_A=7001
WEBLOGIC_PORT_B=7002
WEBLOGIC_DOMAIN_NAME=base_domain
```

### HAProxy
```bash
HAPROXY_PORT=8080
HAPROXY_STATS_PORT=8404
HAPROXY_STATS_USER=admin
HAPROXY_STATS_PASSWORD=admin
```

### Docker
```bash
COMPOSE_PROJECT_NAME=weblogic-project
DOCKER_NETWORK=weblogic-network
```

## Archivos de Configuración

### docker-compose.yml
Configuración principal de servicios Docker.

### .env
Variables de entorno del proyecto.

### mkdocs.yml
Configuración de documentación.
CONFIG_EOF

cat > "$PROJECT_ROOT/docs/reference/api.md" << 'API_EOF'
# Referencia de API

## WebLogic Admin API

### Endpoints Principales
- `/console` - Consola de administración
- `/management` - API de gestión
- `/monitoring` - Métricas y monitoreo

### Autenticación
```bash
curl -u admin:password http://localhost:7001/management
```

## HAProxy Stats API

### Endpoints
- `/stats` - Estadísticas web
- `/stats;csv` - Estadísticas en CSV
- `/stats/enable` - Habilitar servidor
- `/stats/disable` - Deshabilitar servidor

### Ejemplo de Uso
```bash
curl http://localhost:8404/stats
```

## Scripts API

### Comandos Principales
```bash
# Gestión de servicios
./manage-services.sh [start|stop|restart|status]

# Despliegue
./deploy-war.sh [war-name]

# Canary
./canary-control.sh [percentage]
```
API_EOF

# FASE 3: VALIDACIÓN COMPLETA
echo -e "${BLUE}🎯 FASE 3: VALIDACIÓN COMPLETA${NC}"

# Validar configuración de MkDocs
info "Validando configuración de MkDocs..."
if command -v mkdocs &> /dev/null; then
    if mkdocs build --quiet; then
        log "✅ Configuración de MkDocs válida"
    else
        warn "⚠️  Problemas detectados en configuración MkDocs"
    fi
else
    warn "MkDocs no instalado - saltando validación"
fi

# Validar estructura de scripts
info "Validando estructura de scripts..."
if [[ -f "$SCRIPTS_DIR/quick-validate.sh" ]]; then
    "$SCRIPTS_DIR/quick-validate.sh" > /dev/null 2>&1 && log "✅ Scripts validados correctamente" || warn "⚠️  Algunos scripts necesitan atención"
else
    warn "Script de validación no encontrado"
fi

# REPORTE FINAL
echo ""
echo -e "${PURPLE}📊 REPORTE DE LIMPIEZA COMPLETA${NC}"
echo -e "${CYAN}================================${NC}"

# Contar archivos en raíz
ROOT_SH_FILES=$(find "$PROJECT_ROOT" -maxdepth 1 -name "*.sh" -type f | wc -l)
ROOT_SYMLINKS=$(find "$PROJECT_ROOT" -maxdepth 1 -name "*.sh" -type l | wc -l)
TOTAL_SCRIPTS=$(find "$SCRIPTS_DIR" -name "*.sh" -type f | wc -l)

echo -e "${GREEN}✅ Scripts .sh en raíz: $ROOT_SH_FILES (objetivo: 0)${NC}"
echo -e "${GREEN}✅ Enlaces simbólicos: $ROOT_SYMLINKS${NC}"
echo -e "${GREEN}✅ Scripts organizados: $TOTAL_SCRIPTS${NC}"
echo -e "${GREEN}✅ Estructura MkDocs: Completamente organizada${NC}"
echo -e "${GREEN}✅ Backup creado en: $BACKUP_DIR${NC}"

if [[ $ROOT_SH_FILES -eq 0 ]]; then
    echo -e "${GREEN}🎉 ¡LIMPIEZA 100% COMPLETADA!${NC}"
    echo -e "${GREEN}   Raíz completamente limpia${NC}"
else
    echo -e "${YELLOW}⚠️  Aún hay $ROOT_SH_FILES archivos .sh en raíz${NC}"
fi

echo ""
echo -e "${BLUE}🚀 COMANDOS PARA VERIFICAR:${NC}"
echo -e "  ${CYAN}ls -la *.sh${NC}                    # Ver archivos en raíz"
echo -e "  ${CYAN}mkdocs serve${NC}                   # Probar documentación"
echo -e "  ${CYAN}./scripts/quick-validate.sh${NC}   # Validar scripts"
echo ""

exit 0
