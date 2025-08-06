#!/bin/bash
# Script completo de reorganización y reparación del sistema

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# Función para mostrar el banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           REORGANIZACIÓN COMPLETA DEL SISTEMA               ║"
    echo "║         Scripts + MkDocs + Funcionalidades                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para crear estructura de directorios
create_directory_structure() {
    echo -e "${BLUE}=== CREANDO ESTRUCTURA DE DIRECTORIOS ===${NC}"
    
    local dirs=(
        "core"           # Scripts fundamentales del sistema
        "services"       # Scripts de gestión de servicios
        "deployment"     # Scripts de despliegue
        "testing"        # Scripts de testing y validación
        "maintenance"    # Scripts de mantenimiento
        "monitoring"     # Scripts de monitoreo
        "utilities"      # Scripts de utilidades
        "canary"         # Scripts de despliegue canary
        "build"          # Scripts de construcción
        "docs"           # Scripts relacionados con documentación
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$SCRIPTS_DIR/$dir" ]]; then
            echo -e "${YELLOW}Creando: scripts/$dir${NC}"
            mkdir -p "$SCRIPTS_DIR/$dir"
        else
            echo -e "${GREEN}✓${NC} scripts/$dir ya existe"
        fi
    done
}

# Función para mover scripts a sus categorías correctas
organize_scripts_by_category() {
    echo -e "${BLUE}=== ORGANIZANDO SCRIPTS POR CATEGORÍA ===${NC}"
    
    # Scripts core (fundamentales)
    local core_scripts=(
        "load-env.sh"
        "docker-compose-wrapper.sh"
    )
    
    for script in "${core_scripts[@]}"; do
        if [[ -f "$SCRIPTS_DIR/$script" && ! -f "$SCRIPTS_DIR/core/$script" ]]; then
            echo -e "${YELLOW}Moviendo $script a core/${NC}"
            mv "$SCRIPTS_DIR/$script" "$SCRIPTS_DIR/core/"
        fi
    done
    
    # Scripts de servicios
    local service_scripts=(
        "minikube-port-forwards.sh"
        "start-haproxy-dynamic.sh"
        "find-free-port.sh"
    )
    
    for script in "${service_scripts[@]}"; do
        if [[ -f "$SCRIPTS_DIR/$script" && ! -f "$SCRIPTS_DIR/services/$script" ]]; then
            echo -e "${YELLOW}Moviendo $script a services/${NC}"
            mv "$SCRIPTS_DIR/$script" "$SCRIPTS_DIR/services/"
        fi
    done
    
    # Scripts de utilidades
    local utility_scripts=(
        "debug-haproxy.sh"
        "verify-feature-flags-urls.sh"
        "copy-check-urls-to-haproxy.sh"
        "verify-icbs-ports.sh"
        "rebuild-feature-flags.sh"
        "haproxy-ip-updater.py"
    )
    
    for script in "${utility_scripts[@]}"; do
        if [[ -f "$SCRIPTS_DIR/$script" && ! -f "$SCRIPTS_DIR/utilities/$script" ]]; then
            echo -e "${YELLOW}Moviendo $script a utilities/${NC}"
            mv "$SCRIPTS_DIR/$script" "$SCRIPTS_DIR/utilities/"
        fi
    done
    
    echo -e "${GREEN}✅ Scripts organizados por categoría${NC}"
}

# Función para crear enlaces simbólicos para compatibilidad
create_compatibility_links() {
    echo -e "${BLUE}=== CREANDO ENLACES DE COMPATIBILIDAD ===${NC}"
    
    # Enlaces para scripts core
    local core_links=(
        "load-env.sh:core/load-env.sh"
        "docker-compose-wrapper.sh:core/docker-compose-wrapper.sh"
    )
    
    for link_def in "${core_links[@]}"; do
        link_name="${link_def%%:*}"
        target="${link_def##*:}"
        
        if [[ -f "$SCRIPTS_DIR/$target" && ! -e "$SCRIPTS_DIR/$link_name" ]]; then
            echo -e "${YELLOW}Creando enlace: $link_name -> $target${NC}"
            ln -sf "$target" "$SCRIPTS_DIR/$link_name"
        fi
    done
    
    # Enlaces para scripts de servicios
    local service_links=(
        "minikube-port-forwards.sh:services/minikube-port-forwards.sh"
        "start-haproxy-dynamic.sh:services/start-haproxy-dynamic.sh"
        "find-free-port.sh:services/find-free-port.sh"
    )
    
    for link_def in "${service_links[@]}"; do
        link_name="${link_def%%:*}"
        target="${link_def##*:}"
        
        if [[ -f "$SCRIPTS_DIR/$target" && ! -e "$SCRIPTS_DIR/$link_name" ]]; then
            echo -e "${YELLOW}Creando enlace: $link_name -> $target${NC}"
            ln -sf "$target" "$SCRIPTS_DIR/$link_name"
        fi
    done
    
    echo -e "${GREEN}✅ Enlaces de compatibilidad creados${NC}"
}

# Función para reparar MkDocs completamente
fix_mkdocs_completely() {
    echo -e "${BLUE}=== REPARANDO MKDOCS COMPLETAMENTE ===${NC}"
    
    # 1. Detener y eliminar contenedor problemático
    echo -e "${YELLOW}1. Deteniendo contenedor mkdocs-server...${NC}"
    docker stop mkdocs-server 2>/dev/null || true
    docker rm mkdocs-server 2>/dev/null || true
    
    # 2. Verificar y crear directorio docs si no existe
    echo -e "${YELLOW}2. Verificando directorio docs...${NC}"
    if [[ ! -d "$PROJECT_ROOT/docs" ]]; then
        mkdir -p "$PROJECT_ROOT/docs"
        echo -e "${GREEN}✓${NC} Directorio docs creado"
    fi
    
    # 3. Crear archivo index.md básico si no existe
    if [[ ! -f "$PROJECT_ROOT/docs/index.md" ]]; then
        cat > "$PROJECT_ROOT/docs/index.md" << 'EOF'
# Documentación del Proyecto WebLogic + HAProxy

Bienvenido a la documentación del sistema WebLogic con HAProxy.

## Servicios Disponibles

### WebLogic Servers
- **WebLogic A**: http://localhost:7001/console
- **WebLogic B**: http://localhost:7002/console

### HAProxy Load Balancer
- **Load Balancer**: http://localhost:8083
- **HAProxy Stats**: http://localhost:8404/stats
- **HAProxy Admin**: http://localhost:8082

### Base de Datos
- **Oracle Database**: localhost:1521 (XE)
- **Oracle EM Express**: https://localhost:5500/em

## Gestión del Sistema

Para gestionar los servicios, utiliza:

```bash
# Ver estado
./manage-services.sh status

# Iniciar servicios
./manage-services.sh start

# Detener servicios
./manage-services.sh stop

# Ver logs
./manage-services.sh logs --follow
```

## Documentación Adicional

- [Scripts Disponibles](scripts/INDEX.md)
- [Configuración del Sistema](../README.md)
EOF
        echo -e "${GREEN}✓${NC} Archivo docs/index.md creado"
    fi
    
    # 4. Verificar mkdocs.yml
    echo -e "${YELLOW}3. Verificando configuración mkdocs.yml...${NC}"
    if [[ ! -f "$PROJECT_ROOT/mkdocs.yml" ]]; then
        cat > "$PROJECT_ROOT/mkdocs.yml" << 'EOF'
site_name: WebLogic + HAProxy Documentation
site_description: Documentación del sistema WebLogic con HAProxy
site_author: Sistema de Documentación

theme:
  name: material
  palette:
    - scheme: default
      primary: blue
      accent: blue
  features:
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - navigation.top
    - search.highlight
    - search.share

nav:
  - Inicio: index.md
  - Scripts: scripts/INDEX.md

markdown_extensions:
  - admonition
  - codehilite
  - toc:
      permalink: true

plugins:
  - search
  - minify:
      minify_html: true

extra:
  social:
    - icon: fontawesome/brands/docker
      link: http://localhost:8083
EOF
        echo -e "${GREEN}✓${NC} Archivo mkdocs.yml creado"
    fi
    
    # 5. Reconstruir imagen de MkDocs
    echo -e "${YELLOW}4. Reconstruyendo imagen de MkDocs...${NC}"
    docker build -f "$PROJECT_ROOT/Dockerfile.mkdocs-dev" -t mkdocs-dev:latest "$PROJECT_ROOT" --no-cache
    
    # 6. Reiniciar servicio
    echo -e "${YELLOW}5. Reiniciando servicio MkDocs...${NC}"
    "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" up -d mkdocs-server
    
    # 7. Esperar y verificar
    echo -e "${YELLOW}6. Esperando que el servicio se estabilice...${NC}"
    sleep 10
    
    if docker ps | grep -q "mkdocs-server.*Up"; then
        echo -e "${GREEN}✅ MkDocs reparado y funcionando${NC}"
        return 0
    else
        echo -e "${RED}❌ MkDocs aún tiene problemas${NC}"
        return 1
    fi
}

# Función para crear scripts de documentación
create_docs_scripts() {
    echo -e "${BLUE}=== CREANDO SCRIPTS DE DOCUMENTACIÓN ===${NC}"
    
    # Script para generar documentación
    cat > "$SCRIPTS_DIR/docs/generate-docs.sh" << 'EOF'
#!/bin/bash
# Script para generar documentación automáticamente

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "🔧 Generando documentación..."

# Crear índice de scripts actualizado
"$PROJECT_ROOT/scripts/docs/update-scripts-index.sh"

# Generar documentación de configuración
"$PROJECT_ROOT/scripts/docs/generate-config-docs.sh"

echo "✅ Documentación generada"
EOF

    # Script para actualizar índice de scripts
    cat > "$SCRIPTS_DIR/docs/update-scripts-index.sh" << 'EOF'
#!/bin/bash
# Script para actualizar el índice de scripts

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
INDEX_FILE="$SCRIPTS_DIR/INDEX.md"

echo "🔧 Actualizando índice de scripts..."

cat > "$INDEX_FILE" << 'EOINDEX'
# Índice de Scripts del Sistema

Este documento proporciona una descripción completa de todos los scripts disponibles.

## 📁 Estructura Organizada

### 🔧 Core (Fundamentales)
Scripts esenciales para el funcionamiento del sistema.

EOINDEX

# Agregar scripts por categoría
for category_dir in "$SCRIPTS_DIR"/*; do
    if [[ -d "$category_dir" ]]; then
        category_name=$(basename "$category_dir")
        
        # Saltar directorios especiales
        [[ "$category_name" == "." || "$category_name" == ".." ]] && continue
        
        echo "" >> "$INDEX_FILE"
        
        # Crear título de categoría
        case "$category_name" in
            "core") echo "### 🔧 Core (Fundamentales)" >> "$INDEX_FILE" ;;
            "services") echo "### 🚀 Services (Servicios)" >> "$INDEX_FILE" ;;
            "deployment") echo "### 📦 Deployment (Despliegue)" >> "$INDEX_FILE" ;;
            "testing") echo "### ✅ Testing (Pruebas)" >> "$INDEX_FILE" ;;
            "maintenance") echo "### 🔧 Maintenance (Mantenimiento)" >> "$INDEX_FILE" ;;
            "monitoring") echo "### 📊 Monitoring (Monitoreo)" >> "$INDEX_FILE" ;;
            "utilities") echo "### 🛠️ Utilities (Utilidades)" >> "$INDEX_FILE" ;;
            "canary") echo "### 🔄 Canary (Despliegue Canary)" >> "$INDEX_FILE" ;;
            "build") echo "### 🏗️ Build (Construcción)" >> "$INDEX_FILE" ;;
            "docs") echo "### 📚 Docs (Documentación)" >> "$INDEX_FILE" ;;
            *) echo "### 📁 $(echo "$category_name" | sed 's/^./\U&/')" >> "$INDEX_FILE" ;;
        esac
        
        # Agregar scripts de la categoría
        for script in "$category_dir"/*.sh; do
            if [[ -f "$script" ]]; then
                script_name=$(basename "$script")
                # Extraer descripción del script
                description=$(head -10 "$script" 2>/dev/null | grep -E "^#.*[Dd]escripción|^# .*" | head -1 | sed 's/^# *//' 2>/dev/null || echo "Script de $category_name")
                echo "- \`$script_name\` - $description" >> "$INDEX_FILE"
            fi
        done
    fi
done

echo "✅ Índice actualizado: $INDEX_FILE"
EOF

    # Script para generar documentación de configuración
    cat > "$SCRIPTS_DIR/docs/generate-config-docs.sh" << 'EOF'
#!/bin/bash
# Script para generar documentación de configuración

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS_DIR="$PROJECT_ROOT/docs"

echo "🔧 Generando documentación de configuración..."

# Crear documentación de configuración
cat > "$DOCS_DIR/configuration.md" << 'EOCONFIG'
# Configuración del Sistema

## Variables de Entorno

El sistema utiliza un archivo `.env` para centralizar toda la configuración.

### WebLogic Servers
```bash
WEBLOGIC_A_PORT=7001
WEBLOGIC_B_PORT=7002
WEBLOGIC_ADMIN_PASSWORD=welcome1
```

### HAProxy Configuration
```bash
HAPROXY_HTTP_PORT=8083
HAPROXY_HTTPS_PORT=8444
HAPROXY_STATS_PORT=8404
HAPROXY_UI_PORT=8082
```

### Oracle Database
```bash
ORACLE_EXTERNAL_PORT=1521
ORACLE_EM_EXTERNAL_PORT=5500
ORACLE_ADMIN_PASSWORD=welcome1
```

### Documentation
```bash
MKDOCS_EXTERNAL_PORT=8000
```

## Archivos de Configuración

### docker-compose.yml
Ubicado en `config/docker-compose.yml`, define todos los servicios Docker.

### haproxy.cfg
Ubicado en `haproxy/config/haproxy.cfg`, configuración del load balancer.

### mkdocs.yml
Configuración de la documentación con MkDocs Material.

## Scripts de Gestión

### Comando Principal
```bash
./manage-services.sh [comando]
```

Comandos disponibles:
- `start` - Iniciar servicios
- `stop` - Detener servicios
- `status` - Ver estado
- `logs` - Ver logs
- `config` - Mostrar configuración

EOCONFIG

echo "✅ Documentación de configuración generada"
EOF

    # Hacer ejecutables los scripts
    chmod +x "$SCRIPTS_DIR/docs"/*.sh
    
    echo -e "${GREEN}✅ Scripts de documentación creados${NC}"
}

# Función para aplicar permisos correctos
apply_correct_permissions() {
    echo -e "${BLUE}=== APLICANDO PERMISOS CORRECTOS ===${NC}"
    
    # Hacer ejecutables todos los scripts .sh
    find "$SCRIPTS_DIR" -name "*.sh" -type f -exec chmod +x {} \;
    
    # Permisos especiales para scripts principales
    chmod +x "$PROJECT_ROOT/manage-services.sh" 2>/dev/null || true
    chmod +x "$PROJECT_ROOT/start-with-auto-update.sh" 2>/dev/null || true
    chmod +x "$PROJECT_ROOT/stop-all-services.sh" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Permisos aplicados correctamente${NC}"
}

# Función para validar que todo funciona
validate_system_functionality() {
    echo -e "${BLUE}=== VALIDANDO FUNCIONALIDAD DEL SISTEMA ===${NC}"
    
    local issues=0
    
    # Verificar scripts core
    echo -e "${YELLOW}Verificando scripts core...${NC}"
    if [[ -f "$SCRIPTS_DIR/core/load-env.sh" && -x "$SCRIPTS_DIR/core/load-env.sh" ]]; then
        if source "$SCRIPTS_DIR/core/load-env.sh" && load_env > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} load-env.sh funciona correctamente"
        else
            echo -e "  ${RED}✗${NC} load-env.sh tiene problemas"
            ((issues++))
        fi
    else
        echo -e "  ${RED}✗${NC} load-env.sh no encontrado o no ejecutable"
        ((issues++))
    fi
    
    # Verificar docker-compose-wrapper
    if [[ -f "$SCRIPTS_DIR/core/docker-compose-wrapper.sh" && -x "$SCRIPTS_DIR/core/docker-compose-wrapper.sh" ]]; then
        echo -e "  ${GREEN}✓${NC} docker-compose-wrapper.sh disponible"
    else
        echo -e "  ${RED}✗${NC} docker-compose-wrapper.sh no encontrado"
        ((issues++))
    fi
    
    # Verificar manage-services.sh
    echo -e "${YELLOW}Verificando script principal...${NC}"
    if [[ -f "$PROJECT_ROOT/manage-services.sh" && -x "$PROJECT_ROOT/manage-services.sh" ]]; then
        echo -e "  ${GREEN}✓${NC} manage-services.sh disponible"
    else
        echo -e "  ${RED}✗${NC} manage-services.sh no encontrado"
        ((issues++))
    fi
    
    # Verificar MkDocs
    echo -e "${YELLOW}Verificando MkDocs...${NC}"
    if docker ps | grep -q "mkdocs-server.*Up"; then
        echo -e "  ${GREEN}✓${NC} MkDocs funcionando"
    else
        echo -e "  ${YELLOW}⚠${NC} MkDocs no está corriendo (puede ser normal)"
    fi
    
    # Verificar estructura de directorios
    echo -e "${YELLOW}Verificando estructura...${NC}"
    local required_dirs=("core" "services" "deployment" "testing" "maintenance" "utilities" "docs")
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$SCRIPTS_DIR/$dir" ]]; then
            echo -e "  ${GREEN}✓${NC} Directorio $dir existe"
        else
            echo -e "  ${RED}✗${NC} Directorio $dir faltante"
            ((issues++))
        fi
    done
    
    if [[ $issues -eq 0 ]]; then
        echo -e "${GREEN}✅ Sistema validado correctamente${NC}"
        return 0
    else
        echo -e "${RED}❌ Se encontraron $issues problemas${NC}"
        return 1
    fi
}

# Función para crear resumen final
create_final_summary() {
    echo -e "${BLUE}=== CREANDO RESUMEN FINAL ===${NC}"
    
    cat > "$PROJECT_ROOT/REORGANIZATION_COMPLETE.md" << 'EOF'
# ✅ REORGANIZACIÓN COMPLETA FINALIZADA

## 📊 Estado del Sistema

**✅ SISTEMA COMPLETAMENTE REORGANIZADO Y FUNCIONAL**

## 🗂️ Nueva Estructura de Scripts

```
scripts/
├── core/                    # 🔧 Scripts fundamentales
│   ├── load-env.sh         # Carga de variables de entorno
│   └── docker-compose-wrapper.sh  # Wrapper para docker-compose
├── services/               # 🚀 Gestión de servicios
│   ├── minikube-port-forwards.sh
│   ├── start-haproxy-dynamic.sh
│   └── find-free-port.sh
├── deployment/             # 📦 Scripts de despliegue
├── testing/                # ✅ Scripts de testing
├── maintenance/            # 🔧 Scripts de mantenimiento
├── monitoring/             # 📊 Scripts de monitoreo
├── utilities/              # 🛠️ Scripts de utilidades
├── canary/                 # 🔄 Despliegue canary
├── build/                  # 🏗️ Scripts de construcción
├── docs/                   # 📚 Scripts de documentación
│   ├── generate-docs.sh
│   ├── update-scripts-index.sh
│   └── generate-config-docs.sh
└── INDEX.md               # 📋 Índice completo actualizado
```

## 🔗 Enlaces de Compatibilidad

Se mantienen enlaces simbólicos en el directorio raíz para compatibilidad:
- `scripts/core/load-env.sh` -> `core/load-env.sh`
- `scripts/core/docker-compose-wrapper.sh` -> `core/docker-compose-wrapper.sh`
- Y otros scripts críticos

## 📚 MkDocs Reparado

- ✅ Contenedor funcionando correctamente
- ✅ Documentación básica creada
- ✅ Configuración mkdocs.yml optimizada
- ✅ Scripts de generación automática de docs

## 🚀 Comandos Principales

### Gestión de Servicios
```bash
./manage-services.sh start    # Iniciar servicios
./manage-services.sh status   # Ver estado
./manage-services.sh stop     # Detener servicios
./manage-services.sh logs     # Ver logs
```

### Documentación
```bash
./scripts/docs/generate-docs.sh        # Generar documentación
./scripts/docs/update-scripts-index.sh # Actualizar índice
```

### Diagnóstico
```bash
./scripts/maintenance/diagnose-and-fix.sh diagnose  # Diagnosticar
./scripts/maintenance/diagnose-and-fix.sh fix       # Reparar
```

## 🎯 URLs de Acceso

- **Load Balancer**: http://localhost:8083
- **HAProxy Stats**: http://localhost:8404/stats
- **HAProxy Admin**: http://localhost:8082
- **WebLogic A**: http://localhost:7001/console
- **WebLogic B**: http://localhost:7002/console
- **Documentación**: http://localhost:8000
- **Oracle EM**: https://localhost:5500/em

## ✅ Verificaciones Completadas

- [x] Scripts organizados por categoría
- [x] Permisos correctos aplicados
- [x] Enlaces de compatibilidad creados
- [x] MkDocs reparado y funcionando
- [x] Documentación automática configurada
- [x] Sistema validado completamente

---
**Reorganización completada el:** $(date)
**Estado:** ✅ COMPLETADO Y FUNCIONAL
EOF

    echo -e "${GREEN}✅ Resumen final creado: REORGANIZATION_COMPLETE.md${NC}"
}

# Función principal
main() {
    show_banner
    
    echo -e "${MAGENTA}Iniciando reorganización completa del sistema...${NC}"
    echo ""
    
    # Ejecutar todas las operaciones
    create_directory_structure
    echo ""
    
    organize_scripts_by_category
    echo ""
    
    create_compatibility_links
    echo ""
    
    create_docs_scripts
    echo ""
    
    fix_mkdocs_completely
    echo ""
    
    apply_correct_permissions
    echo ""
    
    validate_system_functionality
    echo ""
    
    create_final_summary
    echo ""
    
    echo -e "${GREEN}🎉 ¡REORGANIZACIÓN COMPLETA FINALIZADA! 🎉${NC}"
    echo ""
    echo -e "${CYAN}El sistema está ahora completamente organizado y funcional.${NC}"
    echo -e "${YELLOW}Revisa el archivo REORGANIZATION_COMPLETE.md para más detalles.${NC}"
    echo ""
    echo -e "${BLUE}Para probar el sistema:${NC}"
    echo -e "  ${GREEN}./manage-services.sh status${NC}"
    echo -e "  ${GREEN}./manage-services.sh start${NC}"
}

# Ejecutar función principal
main "$@"
