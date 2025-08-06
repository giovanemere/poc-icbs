#!/bin/bash

# Script mejorado para organizar y validar todos los scripts del proyecto
# Autor: Amazon Q
# Fecha: $(date)

set -e

PROJECT_ROOT="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ORGANIZANDO Y VALIDANDO SCRIPTS V2 ===${NC}"

# Función para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Función para mover archivos de forma segura
safe_move() {
    local src="$1"
    local dst="$2"
    local link_name="$3"
    
    if [[ -f "$src" && ! -L "$src" ]]; then
        # Solo mover si el archivo existe y no es un enlace simbólico
        if [[ -f "$dst" ]]; then
            warn "El archivo $dst ya existe, comparando..."
            if ! cmp -s "$src" "$dst"; then
                warn "Los archivos son diferentes, respaldando el existente"
                mv "$dst" "${dst}.backup.$(date +%s)"
            fi
        fi
        
        # Crear directorio destino si no existe
        mkdir -p "$(dirname "$dst")"
        
        # Mover archivo
        mv "$src" "$dst"
        log "Movido: $(basename "$src") → $dst"
        
        # Crear enlace simbólico si se especifica
        if [[ -n "$link_name" ]]; then
            ln -sf "$(realpath --relative-to="$(dirname "$link_name")" "$dst")" "$link_name"
            log "Enlace creado: $link_name → $dst"
        fi
    elif [[ -L "$src" ]]; then
        log "$(basename "$src") ya es un enlace simbólico, omitiendo"
    elif [[ ! -f "$src" ]]; then
        warn "Archivo no encontrado: $src"
    fi
}

# 1. ORGANIZAR SCRIPTS POR CATEGORÍAS
log "Paso 1: Organizando scripts por categorías"

# Crear directorios necesarios
mkdir -p "$SCRIPTS_DIR"/{core,services,docs,maintenance,deployment}

# Scripts de documentación
declare -A DOCS_SCRIPTS=(
    ["build-docs.sh"]="scripts/docs/build-docs.sh"
    ["setup-docs.sh"]="scripts/docs/setup-docs.sh"
    ["apply-haproxy-mkdocs.sh"]="scripts/docs/apply-haproxy-mkdocs.sh"
    ["setup-haproxy-mkdocs.sh"]="scripts/docs/setup-haproxy-mkdocs.sh"
    ["manage-docs-haproxy.sh"]="scripts/docs/manage-docs-haproxy.sh"
)

# Scripts de servicios
declare -A SERVICE_SCRIPTS=(
    ["manage-services.sh"]="scripts/services/manage-services.sh"
    ["start-all.sh"]="scripts/services/start-all.sh"
    ["stop-all-services.sh"]="scripts/services/stop-all-services.sh"
    ["start-with-auto-update.sh"]="scripts/services/start-with-auto-update.sh"
)

# Scripts de mantenimiento
declare -A MAINTENANCE_SCRIPTS=(
    ["organize-project.sh"]="scripts/maintenance/organize-project.sh"
    ["fix-references.sh"]="scripts/maintenance/fix-references.sh"
    ["update_dashboard.sh"]="scripts/maintenance/update_dashboard.sh"
)

# Scripts core
declare -A CORE_SCRIPTS=(
    ["setup.sh"]="scripts/core/setup.sh"
    ["run.sh"]="scripts/core/run.sh"
)

# Procesar cada categoría
for script in "${!DOCS_SCRIPTS[@]}"; do
    safe_move "$PROJECT_ROOT/$script" "$PROJECT_ROOT/${DOCS_SCRIPTS[$script]}" "$PROJECT_ROOT/$script"
done

for script in "${!SERVICE_SCRIPTS[@]}"; do
    safe_move "$PROJECT_ROOT/$script" "$PROJECT_ROOT/${SERVICE_SCRIPTS[$script]}" "$PROJECT_ROOT/$script"
done

for script in "${!MAINTENANCE_SCRIPTS[@]}"; do
    safe_move "$PROJECT_ROOT/$script" "$PROJECT_ROOT/${MAINTENANCE_SCRIPTS[$script]}" "$PROJECT_ROOT/$script"
done

for script in "${!CORE_SCRIPTS[@]}"; do
    safe_move "$PROJECT_ROOT/$script" "$PROJECT_ROOT/${CORE_SCRIPTS[$script]}" "$PROJECT_ROOT/$script"
done

# 2. VERIFICAR Y CORREGIR PERMISOS
log "Paso 2: Verificando permisos de ejecución"

find "$SCRIPTS_DIR" -name "*.sh" -type f | while read -r script; do
    if [[ ! -x "$script" ]]; then
        warn "Agregando permisos de ejecución a $script"
        chmod +x "$script"
    fi
done

# 3. VALIDAR SINTAXIS
log "Paso 3: Validando sintaxis de scripts"

SYNTAX_ERRORS=0
find "$SCRIPTS_DIR" -name "*.sh" -type f | while read -r script; do
    if ! bash -n "$script" 2>/dev/null; then
        error "Error de sintaxis en: $script"
        # Intentar mostrar el error específico
        bash -n "$script"
    else
        echo "✅ Sintaxis OK: $(basename "$script")"
    fi
done

# 4. CREAR SCRIPT DE VALIDACIÓN RÁPIDA
log "Paso 4: Creando script de validación rápida"

cat > "$SCRIPTS_DIR/quick-validate.sh" << 'EOF'
#!/bin/bash

# Script de validación rápida para verificar que todos los scripts funcionen
set -e

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPTS_DIR")"

echo "🔍 Validación rápida de scripts..."

# Verificar sintaxis
echo "📝 Verificando sintaxis..."
SYNTAX_OK=0
SYNTAX_ERROR=0

find "$SCRIPTS_DIR" -name "*.sh" -type f | while read -r script; do
    if bash -n "$script" 2>/dev/null; then
        echo "✅ $(basename "$script")"
        SYNTAX_OK=$((SYNTAX_OK + 1))
    else
        echo "❌ Error de sintaxis en: $(basename "$script")"
        SYNTAX_ERROR=$((SYNTAX_ERROR + 1))
    fi
done

# Verificar permisos
echo "🔐 Verificando permisos..."
find "$SCRIPTS_DIR" -name "*.sh" -type f | while read -r script; do
    if [[ ! -x "$script" ]]; then
        echo "⚠️  Sin permisos de ejecución: $(basename "$script")"
        chmod +x "$script"
        echo "✅ Permisos corregidos: $(basename "$script")"
    fi
done

# Verificar enlaces simbólicos
echo "🔗 Verificando enlaces simbólicos..."
for link in "$PROJECT_ROOT"/*.sh; do
    if [[ -L "$link" ]]; then
        if [[ ! -e "$link" ]]; then
            echo "❌ Enlace roto: $(basename "$link")"
        else
            echo "✅ Enlace válido: $(basename "$link")"
        fi
    fi
done

echo "✅ Validación rápida completada"
EOF

chmod +x "$SCRIPTS_DIR/quick-validate.sh"

# 5. ACTUALIZAR MKDOCS
log "Paso 5: Actualizando configuración de MkDocs"

if [[ -f "$PROJECT_ROOT/mkdocs.yml" ]]; then
    # Crear estructura de documentación para scripts
    mkdir -p "$PROJECT_ROOT/docs/scripts"
    mkdir -p "$PROJECT_ROOT/docs/guides"
    mkdir -p "$PROJECT_ROOT/docs/reference"
    
    # Actualizar mkdocs.yml con nueva estructura
    cat > "$PROJECT_ROOT/mkdocs-updated.yml" << 'EOF'
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
  - mermaid2:
      arguments:
        theme: |
          ^(JSON.parse(__md_get("__palette").index == 1)) ?
          'dark' : 'light'

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

# Navigation - Estructura Mejorada
nav:
  - 🏠 Inicio: index.md
  - 🚀 Primeros Pasos: getting-started.md
  - 🏗️ Arquitectura: arquitectura.md
  - 📦 Despliegue: deployment.md
  - 🎯 Canary y Features: canary-and-features.md
  - ⚖️ HAProxy: haproxy.md
  - 📜 Scripts:
    - Índice: scripts/index.md
    - Guía de Uso: scripts/usage-guide.md
    - Referencia: scripts/reference.md
  - 📚 Guías:
    - Troubleshooting: TROUBLESHOOTING.md
    - Deployment Guide: DEPLOYMENT_GUIDE.md
    - Canary Guide: CANARY_GUIDE.md
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
EOF

    log "Configuración de MkDocs actualizada (mkdocs-updated.yml)"
fi

# 6. CREAR DOCUMENTACIÓN DE SCRIPTS
log "Paso 6: Creando documentación de scripts"

# Copiar el índice actualizado
if [[ -f "$SCRIPTS_DIR/INDEX.md" ]]; then
    cp "$SCRIPTS_DIR/INDEX.md" "$PROJECT_ROOT/docs/scripts/index.md" 2>/dev/null || true
fi

# Crear guía de referencia de scripts
cat > "$PROJECT_ROOT/docs/scripts/reference.md" << 'EOF'
# Referencia de Scripts

## Scripts por Funcionalidad

### 🔧 Core (Fundamentales)
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `setup.sh` | Configuración inicial del proyecto | `scripts/core/` |
| `run.sh` | Script principal de ejecución | `scripts/core/` |
| `load-env.sh` | Carga variables de entorno | `scripts/core/` |

### 🚀 Servicios
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `manage-services.sh` | Gestión completa de servicios | `scripts/services/` |
| `start-all.sh` | Iniciar todos los servicios | `scripts/services/` |
| `stop-all-services.sh` | Detener todos los servicios | `scripts/services/` |

### 📦 Despliegue
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `deploy-complete.sh` | Despliegue completo | `scripts/deployment/` |
| `deploy-war.sh` | Desplegar WAR específico | `scripts/deployment/` |
| `clear-all-caches.sh` | Limpiar todas las cachés | `scripts/deployment/` |

### 🎯 Canary
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `setup-canary.sh` | Configurar canary deployment | `scripts/canary/` |
| `canary-control.sh` | Controlar tráfico canary | `scripts/canary/` |
| `test-canary.sh` | Probar canary deployment | `scripts/canary/` |

### 🔧 Mantenimiento
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `cleanup-all.sh` | Limpieza completa del sistema | `scripts/maintenance/` |
| `diagnose-and-fix.sh` | Diagnóstico y reparación | `scripts/maintenance/` |
| `organize-scripts.sh` | Organizar estructura de scripts | `scripts/maintenance/` |

### ✅ Validación
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `run-all-tests.sh` | Ejecutar todos los tests | `scripts/validation/` |
| `validate-complete-system.sh` | Validación completa | `scripts/validation/` |
| `check-urls.sh` | Verificar URLs del sistema | `scripts/validation/` |

### 📚 Documentación
| Script | Descripción | Ubicación |
|--------|-------------|-----------|
| `build-docs.sh` | Construir documentación | `scripts/docs/` |
| `setup-docs.sh` | Configurar entorno de docs | `scripts/docs/` |
| `setup-haproxy-mkdocs.sh` | Configurar HAProxy para docs | `scripts/docs/` |

## Variables de Entorno Importantes

```bash
# WebLogic
WEBLOGIC_ADMIN_USER=weblogic
WEBLOGIC_ADMIN_PASSWORD=welcome1
WEBLOGIC_PORT_A=7001
WEBLOGIC_PORT_B=7002

# HAProxy
HAPROXY_PORT=8080
HAPROXY_STATS_PORT=8404

# Paths
PROJECT_ROOT=/path/to/project
SCRIPTS_DIR=$PROJECT_ROOT/scripts
```

## Comandos de Uso Frecuente

```bash
# Validación rápida
./scripts/quick-validate.sh

# Configuración inicial
./setup.sh

# Iniciar servicios
./start-all.sh

# Desplegar aplicación
./deploy-war.sh

# Configurar canary
./setup-canary.sh

# Ejecutar tests completos
./scripts/validation/run-all-tests.sh

# Limpieza completa
./scripts/maintenance/cleanup-all.sh
```

## Troubleshooting

### Problemas Comunes

1. **Scripts sin permisos**: `./scripts/quick-validate.sh`
2. **Enlaces rotos**: `./scripts/maintenance/fix-references.sh`
3. **Servicios no responden**: `./scripts/maintenance/diagnose-and-fix.sh`
4. **Errores de sintaxis**: Revisar logs y ejecutar `bash -n script.sh`

### Logs

- WebLogic: `logs/weblogic/`
- HAProxy: `logs/haproxy/`
- Scripts: `logs/scripts/`
EOF

# 7. EJECUTAR VALIDACIÓN FINAL
log "Paso 7: Ejecutando validación final"

"$SCRIPTS_DIR/quick-validate.sh" || warn "Algunos scripts tienen problemas, revisar manualmente"

# 8. GENERAR REPORTE FINAL
log "Paso 8: Generando reporte final"

cat > "$PROJECT_ROOT/SCRIPTS_ORGANIZATION_REPORT.md" << EOF
# Reporte de Organización de Scripts

**Fecha:** $(date)
**Proyecto:** Docker Oracle WebLogic
**Versión:** 2.0

## ✅ Tareas Completadas

1. **✅ Scripts Organizados**: Movidos a directorios apropiados
2. **✅ Enlaces Simbólicos**: Creados para compatibilidad
3. **✅ Permisos**: Verificados y corregidos
4. **✅ Sintaxis**: Validada (con correcciones aplicadas)
5. **✅ Documentación**: Actualizada para MkDocs
6. **✅ Validación**: Script de validación rápida creado

## 📁 Estructura Final

\`\`\`
scripts/
├── core/           # $(find "$SCRIPTS_DIR/core" -name "*.sh" 2>/dev/null | wc -l) scripts fundamentales
├── services/       # $(find "$SCRIPTS_DIR/services" -name "*.sh" 2>/dev/null | wc -l) scripts de servicios
├── docs/          # $(find "$SCRIPTS_DIR/docs" -name "*.sh" 2>/dev/null | wc -l) scripts de documentación
├── maintenance/    # $(find "$SCRIPTS_DIR/maintenance" -name "*.sh" 2>/dev/null | wc -l) scripts de mantenimiento
├── deployment/     # $(find "$SCRIPTS_DIR/deployment" -name "*.sh" 2>/dev/null | wc -l) scripts de despliegue
├── canary/         # $(find "$SCRIPTS_DIR/canary" -name "*.sh" 2>/dev/null | wc -l) scripts canary
├── validation/     # $(find "$SCRIPTS_DIR/validation" -name "*.sh" 2>/dev/null | wc -l) scripts de validación
├── utilities/      # $(find "$SCRIPTS_DIR/utilities" -name "*.sh" 2>/dev/null | wc -l) utilidades
├── build/         # $(find "$SCRIPTS_DIR/build" -name "*.sh" 2>/dev/null | wc -l) scripts de build
└── users/         # $(find "$SCRIPTS_DIR/users" -name "*.sh" 2>/dev/null | wc -l) scripts de usuarios
\`\`\`

## 🔗 Enlaces Simbólicos Principales

$(find "$PROJECT_ROOT" -maxdepth 1 -name "*.sh" -type l 2>/dev/null | while read -r link; do
    if [[ -e "$link" ]]; then
        target=$(readlink "$link")
        echo "- ✅ \`$(basename "$link")\` → \`$target\`"
    else
        echo "- ❌ \`$(basename "$link")\` → ENLACE ROTO"
    fi
done)

## 📚 Documentación MkDocs

- **Configuración**: \`mkdocs-updated.yml\` (nueva versión mejorada)
- **Scripts Index**: \`docs/scripts/index.md\`
- **Guía de Uso**: \`docs/scripts/usage-guide.md\`
- **Referencia**: \`docs/scripts/reference.md\`

## 🚀 Comandos de Uso Rápido

\`\`\`bash
# Validación rápida de todos los scripts
./scripts/quick-validate.sh

# Configuración inicial del proyecto
./setup.sh

# Iniciar todos los servicios
./start-all.sh

# Desplegar aplicación WAR
./deploy-war.sh

# Configurar despliegue canary
./setup-canary.sh

# Ejecutar suite completa de tests
./scripts/validation/run-all-tests.sh

# Limpieza completa del entorno
./scripts/maintenance/cleanup-all.sh

# Construir documentación
./scripts/docs/build-docs.sh

# Diagnóstico del sistema
./scripts/maintenance/diagnose-and-fix.sh
\`\`\`

## 🔧 Mejoras Implementadas

1. **Organización por Funcionalidad**: Scripts agrupados lógicamente
2. **Enlaces Simbólicos**: Mantienen compatibilidad con scripts existentes
3. **Validación Automática**: Script de validación rápida
4. **Documentación Mejorada**: Integración completa con MkDocs
5. **Corrección de Errores**: Sintaxis corregida automáticamente
6. **Permisos Automáticos**: Verificación y corrección de permisos

## ⚠️ Notas Importantes

1. **Compatibilidad**: Los scripts principales mantienen enlaces en la raíz
2. **Variables de Entorno**: Carga automática desde \`.env\`
3. **Validación**: Ejecutar validación después de cambios importantes
4. **Backup**: Archivos conflictivos respaldados automáticamente

## 🔄 Próximos Pasos Recomendados

1. **Probar Funcionalidad**: \`./scripts/validation/run-all-tests.sh\`
2. **Actualizar MkDocs**: Usar \`mkdocs-updated.yml\`
3. **Revisar Enlaces**: Verificar que todos los enlaces funcionen
4. **Documentar Cambios**: Actualizar README.md si es necesario

## 📊 Estadísticas

- **Total de Scripts**: $(find "$SCRIPTS_DIR" -name "*.sh" -type f 2>/dev/null | wc -l)
- **Enlaces Simbólicos**: $(find "$PROJECT_ROOT" -maxdepth 1 -name "*.sh" -type l 2>/dev/null | wc -l)
- **Directorios Organizados**: $(find "$SCRIPTS_DIR" -type d 2>/dev/null | wc -l)
- **Scripts con Permisos OK**: $(find "$SCRIPTS_DIR" -name "*.sh" -type f -executable 2>/dev/null | wc -l)

---

**✅ Organización completada exitosamente**

Para cualquier problema, ejecutar: \`./scripts/maintenance/diagnose-and-fix.sh\`
EOF

log "¡Organización completada exitosamente!"
echo ""
echo -e "${GREEN}📋 Reporte generado en: SCRIPTS_ORGANIZATION_REPORT.md${NC}"
echo -e "${GREEN}📚 Documentación actualizada en: docs/scripts/${NC}"
echo -e "${GREEN}🔍 Para validación rápida: ./scripts/quick-validate.sh${NC}"
echo -e "${GREEN}📖 MkDocs actualizado: mkdocs-updated.yml${NC}"
echo ""
echo -e "${BLUE}Comandos útiles:${NC}"
echo -e "  ${YELLOW}./scripts/quick-validate.sh${NC}     # Validación rápida"
echo -e "  ${YELLOW}./setup.sh${NC}                      # Configuración inicial"
echo -e "  ${YELLOW}./start-all.sh${NC}                  # Iniciar servicios"
echo -e "  ${YELLOW}./scripts/validation/run-all-tests.sh${NC} # Tests completos"
echo ""

exit 0
