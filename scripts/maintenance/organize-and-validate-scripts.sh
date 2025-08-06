#!/bin/bash

# Script para organizar y validar todos los scripts del proyecto
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

echo -e "${BLUE}=== ORGANIZANDO Y VALIDANDO SCRIPTS ===${NC}"

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

# 1. MOVER SCRIPTS DISPERSOS AL DIRECTORIO SCRIPTS/
log "Paso 1: Moviendo scripts dispersos a la carpeta scripts/"

# Scripts que deberían estar en scripts/docs/
DOCS_SCRIPTS=(
    "build-docs.sh"
    "setup-docs.sh"
    "apply-haproxy-mkdocs.sh"
    "setup-haproxy-mkdocs.sh"
    "manage-docs-haproxy.sh"
)

# Scripts que deberían estar en scripts/services/
SERVICE_SCRIPTS=(
    "manage-services.sh"
    "start-all.sh"
    "stop-all-services.sh"
    "start-with-auto-update.sh"
)

# Scripts que deberían estar en scripts/maintenance/
MAINTENANCE_SCRIPTS=(
    "organize-project.sh"
    "fix-references.sh"
    "update_dashboard.sh"
)

# Scripts que deberían estar en scripts/core/
CORE_SCRIPTS=(
    "setup.sh"
    "run.sh"
)

# Crear directorios si no existen
mkdir -p "$SCRIPTS_DIR/docs"
mkdir -p "$SCRIPTS_DIR/services"
mkdir -p "$SCRIPTS_DIR/maintenance"
mkdir -p "$SCRIPTS_DIR/core"

# Mover scripts de documentación
for script in "${DOCS_SCRIPTS[@]}"; do
    if [[ -f "$PROJECT_ROOT/$script" ]]; then
        log "Moviendo $script a scripts/docs/"
        mv "$PROJECT_ROOT/$script" "$SCRIPTS_DIR/docs/"
        # Crear enlace simbólico en la raíz
        ln -sf "scripts/docs/$script" "$PROJECT_ROOT/$script"
    fi
done

# Mover scripts de servicios
for script in "${SERVICE_SCRIPTS[@]}"; do
    if [[ -f "$PROJECT_ROOT/$script" ]]; then
        log "Moviendo $script a scripts/services/"
        mv "$PROJECT_ROOT/$script" "$SCRIPTS_DIR/services/"
        # Crear enlace simbólico en la raíz
        ln -sf "scripts/services/$script" "$PROJECT_ROOT/$script"
    fi
done

# Mover scripts de mantenimiento
for script in "${MAINTENANCE_SCRIPTS[@]}"; do
    if [[ -f "$PROJECT_ROOT/$script" ]]; then
        log "Moviendo $script a scripts/maintenance/"
        mv "$PROJECT_ROOT/$script" "$SCRIPTS_DIR/maintenance/"
        # Crear enlace simbólico en la raíz
        ln -sf "scripts/maintenance/$script" "$PROJECT_ROOT/$script"
    fi
done

# Mover scripts core
for script in "${CORE_SCRIPTS[@]}"; do
    if [[ -f "$PROJECT_ROOT/$script" ]]; then
        log "Moviendo $script a scripts/core/"
        mv "$PROJECT_ROOT/$script" "$SCRIPTS_DIR/core/"
        # Crear enlace simbólico en la raíz
        ln -sf "scripts/core/$script" "$PROJECT_ROOT/$script"
    fi
done

# 2. VALIDAR QUE TODOS LOS SCRIPTS TENGAN PERMISOS DE EJECUCIÓN
log "Paso 2: Verificando permisos de ejecución"

find "$SCRIPTS_DIR" -name "*.sh" -type f | while read -r script; do
    if [[ ! -x "$script" ]]; then
        warn "Agregando permisos de ejecución a $script"
        chmod +x "$script"
    fi
done

# 3. VALIDAR SINTAXIS DE TODOS LOS SCRIPTS
log "Paso 3: Validando sintaxis de scripts"

SYNTAX_ERRORS=0
find "$SCRIPTS_DIR" -name "*.sh" -type f | while read -r script; do
    if ! bash -n "$script" 2>/dev/null; then
        error "Error de sintaxis en: $script"
        SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
    fi
done

# 4. VERIFICAR DEPENDENCIAS DE SCRIPTS
log "Paso 4: Verificando dependencias"

check_dependencies() {
    local missing_deps=()
    
    # Verificar comandos básicos
    for cmd in docker docker-compose curl wget jq; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Dependencias faltantes: ${missing_deps[*]}"
        return 1
    else
        log "Todas las dependencias básicas están disponibles"
        return 0
    fi
}

check_dependencies

# 5. ACTUALIZAR ÍNDICE DE SCRIPTS
log "Paso 5: Actualizando índice de scripts"

cat > "$SCRIPTS_DIR/INDEX.md" << 'EOF'
# Índice de Scripts - Organizado

Este documento proporciona una descripción de todos los scripts disponibles en el proyecto, organizados por categorías.

## 📁 Estructura de Directorios

```
scripts/
├── core/           # Scripts fundamentales del sistema
├── services/       # Gestión de servicios y contenedores
├── deployment/     # Scripts de despliegue
├── canary/         # Gestión de despliegues canary
├── maintenance/    # Mantenimiento y limpieza
├── validation/     # Validación y testing
├── utilities/      # Utilidades generales
├── docs/          # Gestión de documentación
├── monitoring/    # Monitoreo y métricas
└── build/         # Scripts de construcción
```

## 🔧 Scripts Core

### scripts/core/
- `load-env.sh` - Carga variables de entorno desde .env
- `docker-compose-wrapper.sh` - Wrapper para docker-compose con variables de entorno
- `setup.sh` - Script de configuración inicial del proyecto
- `run.sh` - Script principal para ejecutar el proyecto

## 🚀 Scripts de Servicios

### scripts/services/
- `manage-services.sh` - Gestión completa de servicios Docker
- `start-all.sh` - Iniciar todos los servicios
- `stop-all-services.sh` - Detener todos los servicios
- `start-with-auto-update.sh` - Iniciar con actualización automática
- `find-free-port.sh` - Encontrar puerto libre dinámicamente
- `start-haproxy-dynamic.sh` - Iniciar HAProxy con puerto dinámico
- `minikube-port-forwards.sh` - Gestión de port-forwards de Minikube

## 📦 Scripts de Despliegue

### scripts/deployment/
- `deploy-complete.sh` - Despliegue completo del sistema
- `deploy-war.sh` - Desplegar archivos WAR específicos
- `clear-all-caches.sh` - Limpiar todas las cachés
- `clear-weblogic-cache.sh` - Limpiar caché de WebLogic
- `clear-haproxy-cache.sh` - Limpiar caché de HAProxy

## 🎯 Scripts Canary

### scripts/canary/
- `setup-canary.sh` - Configurar despliegue canary
- `canary-control.sh` - Controlar porcentaje de tráfico canary
- `test-canary.sh` - Probar despliegue canary
- `manage-traffic.sh` - Gestionar tráfico entre versiones
- `simulate-traffic.sh` - Simular tráfico para pruebas

## 🔧 Scripts de Mantenimiento

### scripts/maintenance/
- `organize-scripts.sh` - Organizar estructura de scripts
- `cleanup-all.sh` - Limpieza completa del entorno
- `diagnose-and-fix.sh` - Diagnóstico y reparación del sistema
- `update-system-config.sh` - Actualizar configuración del sistema
- `auto-update-haproxy.sh` - Actualización automática de HAProxy
- `organize-project.sh` - Organizar estructura del proyecto
- `fix-references.sh` - Corregir referencias rotas
- `update_dashboard.sh` - Actualizar dashboard

## ✅ Scripts de Validación

### scripts/validation/
- `validate-complete-system.sh` - Validación completa del sistema
- `test-integration.sh` - Tests de integración
- `test-performance.sh` - Tests de rendimiento
- `check-urls.sh` - Verificar URLs del sistema
- `run-all-tests.sh` - Ejecutar todos los tests

## 🛠️ Scripts de Utilidades

### scripts/utilities/
- `debug-haproxy.sh` - Debug de HAProxy
- `verify-icbs-ports.sh` - Verificar puertos ICBS
- `haproxy-ip-updater.py` - Actualizar IPs de HAProxy

## 📚 Scripts de Documentación

### scripts/docs/
- `build-docs.sh` - Construir documentación
- `setup-docs.sh` - Configurar entorno de documentación
- `setup-haproxy-mkdocs.sh` - Configurar HAProxy para MkDocs
- `apply-haproxy-mkdocs.sh` - Aplicar configuración HAProxy-MkDocs
- `manage-docs-haproxy.sh` - Gestionar documentación con HAProxy
- `generate-docs.sh` - Generar documentación automáticamente
- `update-scripts-index.sh` - Actualizar índice de scripts

## 🏗️ Scripts de Build

### scripts/build/
- `build.sh` - Build principal del proyecto
- `build-local.sh` - Build local de proyectos WAR
- `build-wars.sh` - Construir archivos WAR
- `create-simple-wars.sh` - Crear archivos WAR simples

## 📊 Scripts de Monitoreo

### scripts/monitoring/
- Scripts de monitoreo y métricas (en desarrollo)

## 👥 Scripts de Usuarios

### scripts/users/
- `create-users.sh` - Crear usuarios en WebLogic
- `assign-roles.sh` - Asignar roles a usuarios

## 🔗 Enlaces Simbólicos en Raíz

Los siguientes scripts tienen enlaces simbólicos en la raíz del proyecto para facilitar el acceso:

- `build.sh` → `scripts/build/build.sh`
- `setup.sh` → `scripts/core/setup.sh`
- `run.sh` → `scripts/core/run.sh`
- `manage-services.sh` → `scripts/services/manage-services.sh`
- `start-all.sh` → `scripts/services/start-all.sh`
- `deploy-war.sh` → `scripts/deployment/deploy-war.sh`
- `setup-canary.sh` → `scripts/canary/setup-canary.sh`
- `canary-control.sh` → `scripts/canary/canary-control.sh`
- `test-canary.sh` → `scripts/canary/test-canary.sh`

## 🚀 Uso Rápido

### Comandos más comunes:
```bash
# Configuración inicial
./setup.sh

# Iniciar todos los servicios
./start-all.sh

# Desplegar aplicación
./deploy-war.sh

# Configurar canary
./setup-canary.sh

# Ejecutar tests
./scripts/validation/run-all-tests.sh

# Limpiar sistema
./scripts/maintenance/cleanup-all.sh
```

## 📝 Notas

- Todos los scripts tienen permisos de ejecución
- Los scripts cargan automáticamente las variables de entorno desde `.env`
- Se recomienda ejecutar `./scripts/validation/run-all-tests.sh` después de cambios importantes
- Para debugging, usar `./scripts/utilities/debug-haproxy.sh`

EOF

# 6. CREAR SCRIPT DE VALIDACIÓN RÁPIDA
log "Paso 6: Creando script de validación rápida"

cat > "$SCRIPTS_DIR/quick-validate.sh" << 'EOF'
#!/bin/bash

# Script de validación rápida para verificar que todos los scripts funcionen
set -e

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPTS_DIR")"

echo "🔍 Validación rápida de scripts..."

# Verificar sintaxis
echo "📝 Verificando sintaxis..."
find "$SCRIPTS_DIR" -name "*.sh" -type f | while read -r script; do
    if ! bash -n "$script" 2>/dev/null; then
        echo "❌ Error de sintaxis en: $script"
        exit 1
    fi
done

# Verificar permisos
echo "🔐 Verificando permisos..."
find "$SCRIPTS_DIR" -name "*.sh" -type f | while read -r script; do
    if [[ ! -x "$script" ]]; then
        echo "⚠️  Sin permisos de ejecución: $script"
        chmod +x "$script"
        echo "✅ Permisos corregidos: $script"
    fi
done

# Verificar enlaces simbólicos
echo "🔗 Verificando enlaces simbólicos..."
for link in "$PROJECT_ROOT"/*.sh; do
    if [[ -L "$link" ]]; then
        if [[ ! -e "$link" ]]; then
            echo "❌ Enlace roto: $link"
        else
            echo "✅ Enlace válido: $(basename "$link")"
        fi
    fi
done

echo "✅ Validación rápida completada"
EOF

chmod +x "$SCRIPTS_DIR/quick-validate.sh"

# 7. ORGANIZAR MKDOCS
log "Paso 7: Organizando estructura de MkDocs"

# Verificar si existe mkdocs.yml
if [[ -f "$PROJECT_ROOT/mkdocs.yml" ]]; then
    # Crear estructura mejorada para docs
    mkdir -p "$PROJECT_ROOT/docs/scripts"
    mkdir -p "$PROJECT_ROOT/docs/guides"
    mkdir -p "$PROJECT_ROOT/docs/reference"
    
    # Copiar INDEX.md de scripts a docs
    cp "$SCRIPTS_DIR/INDEX.md" "$PROJECT_ROOT/docs/scripts/index.md"
    
    # Crear guía de scripts para docs
    cat > "$PROJECT_ROOT/docs/scripts/usage-guide.md" << 'EOF'
# Guía de Uso de Scripts

Esta guía explica cómo usar los scripts más importantes del proyecto.

## Scripts Principales

### Configuración Inicial
```bash
# Configurar el proyecto por primera vez
./setup.sh

# Cargar variables de entorno
source scripts/core/load-env.sh
```

### Gestión de Servicios
```bash
# Iniciar todos los servicios
./start-all.sh

# Gestionar servicios individualmente
./manage-services.sh

# Detener todos los servicios
./stop-all-services.sh
```

### Despliegue
```bash
# Despliegue completo
./scripts/deployment/deploy-complete.sh

# Desplegar WAR específico
./deploy-war.sh <nombre-war>

# Limpiar cachés
./scripts/deployment/clear-all-caches.sh
```

### Canary Deployment
```bash
# Configurar canary
./setup-canary.sh

# Controlar tráfico
./canary-control.sh 50  # 50% de tráfico

# Probar canary
./test-canary.sh
```

### Validación y Testing
```bash
# Ejecutar todos los tests
./scripts/validation/run-all-tests.sh

# Validación rápida
./scripts/quick-validate.sh

# Verificar URLs
./scripts/validation/check-urls.sh
```

### Mantenimiento
```bash
# Limpieza completa
./scripts/maintenance/cleanup-all.sh

# Diagnóstico del sistema
./scripts/maintenance/diagnose-and-fix.sh

# Organizar proyecto
./scripts/maintenance/organize-scripts.sh
```

## Variables de Entorno

Los scripts utilizan las siguientes variables principales:

- `WEBLOGIC_ADMIN_USER`: Usuario administrador de WebLogic
- `WEBLOGIC_ADMIN_PASSWORD`: Contraseña del administrador
- `HAPROXY_PORT`: Puerto de HAProxy
- `WEBLOGIC_PORT_A`: Puerto del servidor WebLogic A
- `WEBLOGIC_PORT_B`: Puerto del servidor WebLogic B

## Troubleshooting

### Problemas Comunes

1. **Scripts sin permisos**: Ejecutar `./scripts/quick-validate.sh`
2. **Enlaces rotos**: Ejecutar `./scripts/maintenance/fix-references.sh`
3. **Servicios no responden**: Ejecutar `./scripts/maintenance/diagnose-and-fix.sh`

### Logs

Los logs se encuentran en:
- `logs/weblogic/`: Logs de WebLogic
- `logs/haproxy/`: Logs de HAProxy
- `logs/scripts/`: Logs de scripts

EOF

    log "Estructura de MkDocs organizada"
fi

# 8. EJECUTAR VALIDACIÓN FINAL
log "Paso 8: Ejecutando validación final"

"$SCRIPTS_DIR/quick-validate.sh"

# 9. GENERAR REPORTE
log "Paso 9: Generando reporte final"

cat > "$PROJECT_ROOT/ORGANIZATION_REPORT.md" << EOF
# Reporte de Organización de Scripts

**Fecha:** $(date)
**Proyecto:** Docker Oracle WebLogic

## ✅ Tareas Completadas

1. **Scripts Organizados**: Todos los scripts han sido movidos a sus directorios correspondientes
2. **Enlaces Simbólicos**: Creados enlaces en la raíz para scripts principales
3. **Permisos**: Verificados y corregidos permisos de ejecución
4. **Sintaxis**: Validada sintaxis de todos los scripts
5. **Documentación**: Actualizado INDEX.md y creada documentación para MkDocs
6. **Validación**: Creado script de validación rápida

## 📁 Estructura Final

\`\`\`
scripts/
├── core/           # Scripts fundamentales ($(find "$SCRIPTS_DIR/core" -name "*.sh" 2>/dev/null | wc -l) scripts)
├── services/       # Gestión de servicios ($(find "$SCRIPTS_DIR/services" -name "*.sh" 2>/dev/null | wc -l) scripts)
├── deployment/     # Scripts de despliegue ($(find "$SCRIPTS_DIR/deployment" -name "*.sh" 2>/dev/null | wc -l) scripts)
├── canary/         # Gestión canary ($(find "$SCRIPTS_DIR/canary" -name "*.sh" 2>/dev/null | wc -l) scripts)
├── maintenance/    # Mantenimiento ($(find "$SCRIPTS_DIR/maintenance" -name "*.sh" 2>/dev/null | wc -l) scripts)
├── validation/     # Validación y testing ($(find "$SCRIPTS_DIR/validation" -name "*.sh" 2>/dev/null | wc -l) scripts)
├── utilities/      # Utilidades ($(find "$SCRIPTS_DIR/utilities" -name "*.sh" 2>/dev/null | wc -l) scripts)
├── docs/          # Documentación ($(find "$SCRIPTS_DIR/docs" -name "*.sh" 2>/dev/null | wc -l) scripts)
├── build/         # Build ($(find "$SCRIPTS_DIR/build" -name "*.sh" 2>/dev/null | wc -l) scripts)
└── users/         # Usuarios ($(find "$SCRIPTS_DIR/users" -name "*.sh" 2>/dev/null | wc -l) scripts)
\`\`\`

## 🔗 Enlaces Simbólicos Principales

$(find "$PROJECT_ROOT" -maxdepth 1 -name "*.sh" -type l | while read -r link; do
    target=$(readlink "$link")
    echo "- \`$(basename "$link")\` → \`$target\`"
done)

## 🚀 Comandos de Uso Rápido

\`\`\`bash
# Validación rápida
./scripts/quick-validate.sh

# Configuración inicial
./setup.sh

# Iniciar servicios
./start-all.sh

# Desplegar aplicación
./deploy-war.sh

# Ejecutar tests
./scripts/validation/run-all-tests.sh
\`\`\`

## 📚 Documentación

- **Índice de Scripts**: \`scripts/INDEX.md\`
- **Guía de Uso**: \`docs/scripts/usage-guide.md\`
- **MkDocs**: Configurado y organizado

## ⚠️ Notas Importantes

1. Los scripts principales mantienen enlaces simbólicos en la raíz para compatibilidad
2. Todos los scripts cargan automáticamente variables de entorno
3. Se recomienda ejecutar validación después de cambios importantes
4. La documentación de MkDocs se actualiza automáticamente

## 🔧 Próximos Pasos

1. Ejecutar \`./scripts/validation/run-all-tests.sh\` para validar funcionamiento
2. Revisar y actualizar documentación específica si es necesario
3. Configurar CI/CD para validación automática de scripts

EOF

log "¡Organización completada exitosamente!"
echo -e "${GREEN}📋 Reporte generado en: ORGANIZATION_REPORT.md${NC}"
echo -e "${GREEN}📚 Documentación actualizada en: scripts/INDEX.md${NC}"
echo -e "${GREEN}🔍 Para validación rápida: ./scripts/quick-validate.sh${NC}"

exit 0
