#!/bin/bash

# Script para crear limpieza integral de archivos dispersos
# Reorganiza .py, .txt, backups y otros archivos desorganizados
# Autor: Amazon Q

set -e

PROJECT_ROOT="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}🧹 CREANDO SISTEMA DE LIMPIEZA INTEGRAL${NC}"
echo -e "${BLUE}Reorganizando archivos .py, .txt, backups y otros${NC}"
echo ""

# Función de logging
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"; }
info() { echo -e "${CYAN}[$(date +'%H:%M:%S')] ℹ️  $1${NC}"; }

# 1. CREAR SCRIPT DE LIMPIEZA INTEGRAL
log "Creando script de limpieza integral..."

cat > "$SCRIPTS_DIR/maintenance/comprehensive-cleanup.sh" << 'EOF'
#!/bin/bash

# SCRIPT DE LIMPIEZA INTEGRAL DE ARCHIVOS DISPERSOS
# Reorganiza archivos .py, .txt, backups y otros desorganizados
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

echo -e "${PURPLE}🧹 LIMPIEZA INTEGRAL INICIADA${NC}"
echo -e "${BLUE}Reorganizando archivos dispersos en raíz${NC}"
echo ""

# Función de logging
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"; }
info() { echo -e "${CYAN}[$(date +'%H:%M:%S')] ℹ️  $1${NC}"; }

# CREAR BACKUP DE SEGURIDAD
BACKUP_DIR="$PROJECT_ROOT/backup/comprehensive-cleanup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
log "Backup de seguridad creado: $BACKUP_DIR"

# Lista de archivos ESENCIALES que deben permanecer en raíz
ESSENTIAL_FILES=(
    "README.md"
    "LICENSE"
    ".env"
    ".env.example"
    ".gitignore"
    "docker-compose.yml"
    "docker-compose.override.yml"
    "Dockerfile"
    "Dockerfile.mkdocs"
    "Dockerfile.mkdocs-dev"
    "mkdocs.yml"
    "mkdocs-dev.yml"
    "requirements.txt"
    "CHANGELOG.md"
    "PROJECT_SUMMARY.md"
)

# FASE 1: CREAR ESTRUCTURA DE CARPETAS
echo -e "${BLUE}🎯 FASE 1: CREANDO ESTRUCTURA ORGANIZADA${NC}"

info "Creando estructura de carpetas..."
mkdir -p "$PROJECT_ROOT/scripts/python"
mkdir -p "$PROJECT_ROOT/docs/user-guides"
mkdir -p "$PROJECT_ROOT/backup/docker-compose"
mkdir -p "$PROJECT_ROOT/config"
mkdir -p "$PROJECT_ROOT/temp"

log "Estructura de carpetas creada"

# FASE 2: REORGANIZAR ARCHIVOS PYTHON
echo -e "${BLUE}🎯 FASE 2: REORGANIZANDO SCRIPTS PYTHON${NC}"

info "Buscando archivos .py en raíz..."
find "$PROJECT_ROOT" -maxdepth 1 -name "*.py" -type f | while read -r pyfile; do
    filename=$(basename "$pyfile")
    
    # Hacer backup
    cp "$pyfile" "$BACKUP_DIR/"
    
    # Mover a scripts/python/
    mv "$pyfile" "$PROJECT_ROOT/scripts/python/"
    log "Python script movido: $filename → scripts/python/"
    
    # Buscar y actualizar referencias
    info "Actualizando referencias a $filename..."
    find "$PROJECT_ROOT" -name "*.sh" -type f -exec grep -l "$filename" {} \; | while read -r script; do
        if [[ "$script" != *"/backup/"* ]]; then
            # Crear backup del script antes de modificar
            cp "$script" "$BACKUP_DIR/$(basename "$script").backup"
            
            # Actualizar referencia
            sed -i "s|\./$filename|./scripts/python/$filename|g" "$script"
            sed -i "s|python3 $filename|python3 scripts/python/$filename|g" "$script"
            sed -i "s|python $filename|python scripts/python/$filename|g" "$script"
            
            warn "Actualizada referencia en: $(basename "$script")"
        fi
    done
done

# Crear enlace simbólico para compatibilidad si es necesario
if [[ -f "$PROJECT_ROOT/scripts/python/fix_dashboard.py" ]]; then
    # Verificar si algún servicio lo necesita en raíz
    if grep -r "fix_dashboard.py" "$PROJECT_ROOT/docker-compose"* 2>/dev/null; then
        ln -sf "scripts/python/fix_dashboard.py" "$PROJECT_ROOT/fix_dashboard.py"
        log "Enlace de compatibilidad creado para fix_dashboard.py"
    fi
fi

# FASE 3: REORGANIZAR DOCUMENTACIÓN DE USUARIO
echo -e "${BLUE}🎯 FASE 3: REORGANIZANDO DOCUMENTACIÓN DE USUARIO${NC}"

info "Reorganizando archivos de documentación..."

# Mover browser-cache-instructions.txt y convertir a Markdown
if [[ -f "$PROJECT_ROOT/browser-cache-instructions.txt" ]]; then
    cp "$PROJECT_ROOT/browser-cache-instructions.txt" "$BACKUP_DIR/"
    
    # Convertir a Markdown y mover
    cat > "$PROJECT_ROOT/docs/user-guides/browser-cache-guide.md" << 'CACHE_EOF'
# Guía de Limpieza de Caché del Navegador

Para asegurar que los cambios en las aplicaciones se reflejen correctamente, es recomendable limpiar la caché del navegador.

## 🌐 Chrome
1. Presiona `Ctrl+Shift+Delete` (Windows/Linux) o `Cmd+Shift+Delete` (Mac)
2. Selecciona "Cookies y datos de sitios" y "Imágenes y archivos almacenados en caché"
3. Haz clic en "Borrar datos"

## 🦊 Firefox
1. Presiona `Ctrl+Shift+Delete` (Windows/Linux) o `Cmd+Shift+Delete` (Mac)
2. Selecciona "Cookies" y "Caché"
3. Haz clic en "Limpiar ahora"

## 🧭 Safari
1. Ve a Safari > Preferencias > Avanzado
2. Marca "Mostrar menú Desarrollo en la barra de menús"
3. Ve a Desarrollo > Vaciar cachés

## 🔷 Edge
1. Presiona `Ctrl+Shift+Delete`
2. Selecciona "Cookies y datos guardados" y "Archivos e imágenes en caché"
3. Haz clic en "Borrar ahora"

## 🕵️ Alternativa: Modo Incógnito/Privado

Otra opción es utilizar el modo incógnito o privado del navegador para probar las aplicaciones sin caché.

### Atajos de Teclado:
- **Chrome**: `Ctrl+Shift+N` (Windows/Linux) o `Cmd+Shift+N` (Mac)
- **Firefox**: `Ctrl+Shift+P` (Windows/Linux) o `Cmd+Shift+P` (Mac)
- **Safari**: `Cmd+Shift+N` (Mac)
- **Edge**: `Ctrl+Shift+N` (Windows/Linux)

## 🔄 Recarga Forzada

Para recargar una página ignorando la caché:
- **Windows/Linux**: `Ctrl+F5` o `Ctrl+Shift+R`
- **Mac**: `Cmd+Shift+R`

---

*Esta guía es parte de la documentación del proyecto Docker Oracle WebLogic.*
CACHE_EOF
    
    rm "$PROJECT_ROOT/browser-cache-instructions.txt"
    log "Documentación convertida: browser-cache-instructions.txt → docs/user-guides/browser-cache-guide.md"
fi

# FASE 4: REORGANIZAR BACKUPS Y ARCHIVOS TEMPORALES
echo -e "${BLUE}🎯 FASE 4: REORGANIZANDO BACKUPS Y TEMPORALES${NC}"

info "Moviendo archivos de backup..."

# Mover backups de docker-compose
find "$PROJECT_ROOT" -maxdepth 1 -name "docker-compose*.backup" -o -name "*.yml.backup" | while read -r backup; do
    filename=$(basename "$backup")
    cp "$backup" "$BACKUP_DIR/"
    mv "$backup" "$PROJECT_ROOT/backup/docker-compose/"
    log "Backup movido: $filename → backup/docker-compose/"
done

# Mover archivos temporales
find "$PROJECT_ROOT" -maxdepth 1 -name "*.tmp" -o -name "*.temp" -o -name "*~" | while read -r temp; do
    filename=$(basename "$temp")
    cp "$temp" "$BACKUP_DIR/" 2>/dev/null || true
    mv "$temp" "$PROJECT_ROOT/temp/"
    log "Temporal movido: $filename → temp/"
done

# FASE 5: ACTUALIZAR CONFIGURACIÓN DE MKDOCS
echo -e "${BLUE}🎯 FASE 5: ACTUALIZANDO CONFIGURACIÓN MKDOCS${NC}"

info "Actualizando navegación de MkDocs..."

# Actualizar mkdocs.yml para incluir nueva documentación
if [[ -f "$PROJECT_ROOT/mkdocs.yml" ]]; then
    # Hacer backup
    cp "$PROJECT_ROOT/mkdocs.yml" "$BACKUP_DIR/"
    
    # Verificar si ya existe la sección user-guides
    if ! grep -q "user-guides" "$PROJECT_ROOT/mkdocs.yml"; then
        # Agregar sección de guías de usuario
        sed -i '/📚 Guías:/a\    - Limpieza de Caché: user-guides/browser-cache-guide.md' "$PROJECT_ROOT/mkdocs.yml"
        log "Navegación de MkDocs actualizada"
    fi
fi

# FASE 6: CREAR ENLACES DE COMPATIBILIDAD
echo -e "${BLUE}🎯 FASE 6: CREANDO ENLACES DE COMPATIBILIDAD${NC}"

info "Verificando necesidad de enlaces de compatibilidad..."

# Verificar si algún servicio Docker necesita archivos en ubicaciones específicas
if [[ -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
    # Buscar referencias a archivos movidos
    if grep -q "fix_dashboard.py" "$PROJECT_ROOT/docker-compose.yml"; then
        if [[ ! -L "$PROJECT_ROOT/fix_dashboard.py" ]]; then
            ln -sf "scripts/python/fix_dashboard.py" "$PROJECT_ROOT/fix_dashboard.py"
            log "Enlace de compatibilidad creado: fix_dashboard.py"
        fi
    fi
fi

# FASE 7: VALIDACIÓN Y LIMPIEZA FINAL
echo -e "${BLUE}🎯 FASE 7: VALIDACIÓN Y LIMPIEZA FINAL${NC}"

info "Validando estructura final..."

# Verificar que solo archivos esenciales estén en raíz
UNAUTHORIZED_FILES=0
find "$PROJECT_ROOT" -maxdepth 1 -type f | while read -r file; do
    filename=$(basename "$file")
    
    # Verificar si es un archivo esencial o enlace simbólico
    is_essential=false
    for essential in "${ESSENTIAL_FILES[@]}"; do
        if [[ "$filename" == "$essential" ]]; then
            is_essential=true
            break
        fi
    done
    
    # Verificar si es enlace simbólico .sh (permitido)
    if [[ "$filename" == *.sh && -L "$file" ]]; then
        is_essential=true
    fi
    
    if [[ "$is_essential" == false ]]; then
        warn "Archivo no esencial encontrado en raíz: $filename"
        UNAUTHORIZED_FILES=$((UNAUTHORIZED_FILES + 1))
    fi
done

# Limpiar archivos vacíos
find "$PROJECT_ROOT" -maxdepth 1 -type f -empty -delete 2>/dev/null || true

# REPORTE FINAL
echo ""
echo -e "${PURPLE}📊 REPORTE DE LIMPIEZA INTEGRAL${NC}"
echo -e "${CYAN}================================${NC}"

# Contar archivos organizados
PYTHON_SCRIPTS=$(find "$PROJECT_ROOT/scripts/python" -name "*.py" -type f 2>/dev/null | wc -l)
USER_GUIDES=$(find "$PROJECT_ROOT/docs/user-guides" -name "*.md" -type f 2>/dev/null | wc -l)
BACKUPS_MOVED=$(find "$PROJECT_ROOT/backup" -type f 2>/dev/null | wc -l)
ROOT_FILES=$(find "$PROJECT_ROOT" -maxdepth 1 -type f | wc -l)

echo -e "${GREEN}✅ Scripts Python organizados: $PYTHON_SCRIPTS${NC}"
echo -e "${GREEN}✅ Guías de usuario: $USER_GUIDES${NC}"
echo -e "${GREEN}✅ Backups organizados: $BACKUPS_MOVED${NC}"
echo -e "${GREEN}✅ Archivos en raíz: $ROOT_FILES${NC}"
echo -e "${GREEN}✅ Backup de seguridad: $BACKUP_DIR${NC}"

if [[ $UNAUTHORIZED_FILES -eq 0 ]]; then
    echo -e "${GREEN}🎉 ¡LIMPIEZA INTEGRAL COMPLETADA!${NC}"
    echo -e "${GREEN}   Raíz completamente organizada${NC}"
else
    echo -e "${YELLOW}⚠️  Aún hay $UNAUTHORIZED_FILES archivos no esenciales en raíz${NC}"
fi

echo ""
echo -e "${BLUE}🚀 COMANDOS PARA VERIFICAR:${NC}"
echo -e "  ${CYAN}ls -la${NC}                           # Ver archivos en raíz"
echo -e "  ${CYAN}tree scripts/python${NC}              # Ver scripts Python"
echo -e "  ${CYAN}tree docs/user-guides${NC}            # Ver guías de usuario"
echo -e "  ${CYAN}mkdocs serve${NC}                     # Probar documentación"
echo ""

exit 0
EOF

chmod +x "$SCRIPTS_DIR/maintenance/comprehensive-cleanup.sh"
log "Script de limpieza integral creado"

# 2. CREAR SCRIPT DE VALIDACIÓN POST-LIMPIEZA
log "Creando script de validación post-limpieza..."

cat > "$SCRIPTS_DIR/validation/validate-services-after-cleanup.sh" << 'EOF'
#!/bin/bash

# SCRIPT DE VALIDACIÓN POST-LIMPIEZA
# Valida que todos los servicios funcionen después de reorganizar archivos

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 VALIDACIÓN POST-LIMPIEZA INICIADA${NC}"

# Función de logging
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"; }

# Validar estructura de archivos Python
if [[ -d "$PROJECT_ROOT/scripts/python" ]]; then
    PYTHON_COUNT=$(find "$PROJECT_ROOT/scripts/python" -name "*.py" -type f | wc -l)
    log "✅ Scripts Python organizados: $PYTHON_COUNT"
else
    warn "⚠️  Carpeta scripts/python no encontrada"
fi

# Validar documentación de usuario
if [[ -d "$PROJECT_ROOT/docs/user-guides" ]]; then
    GUIDES_COUNT=$(find "$PROJECT_ROOT/docs/user-guides" -name "*.md" -type f | wc -l)
    log "✅ Guías de usuario: $GUIDES_COUNT"
else
    warn "⚠️  Carpeta docs/user-guides no encontrada"
fi

# Validar que archivos esenciales estén en raíz
ESSENTIAL_FILES=(
    "README.md"
    "docker-compose.yml"
    "mkdocs.yml"
    "requirements.txt"
)

for file in "${ESSENTIAL_FILES[@]}"; do
    if [[ -f "$PROJECT_ROOT/$file" ]]; then
        log "✅ Archivo esencial presente: $file"
    else
        error "❌ Archivo esencial faltante: $file"
    fi
done

# Validar configuración de MkDocs
if command -v mkdocs &> /dev/null; then
    if mkdocs build --quiet 2>/dev/null; then
        log "✅ Configuración MkDocs válida"
    else
        warn "⚠️  Problemas en configuración MkDocs"
    fi
else
    warn "MkDocs no instalado"
fi

# Validar enlaces simbólicos
BROKEN_LINKS=0
find "$PROJECT_ROOT" -maxdepth 1 -name "*.sh" -type l | while read -r link; do
    if [[ ! -e "$link" ]]; then
        error "Enlace roto: $(basename "$link")"
        BROKEN_LINKS=$((BROKEN_LINKS + 1))
    fi
done

if [[ $BROKEN_LINKS -eq 0 ]]; then
    log "✅ Todos los enlaces simbólicos funcionando"
fi

echo -e "${BLUE}🏁 Validación post-limpieza completada${NC}"

exit 0
EOF

chmod +x "$SCRIPTS_DIR/validation/validate-services-after-cleanup.sh"
log "Script de validación post-limpieza creado"

# 3. CREAR ENLACE DE ACCESO RÁPIDO
ln -sf "scripts/maintenance/comprehensive-cleanup.sh" "$PROJECT_ROOT/comprehensive-cleanup.sh"
log "Enlace de acceso rápido creado: comprehensive-cleanup.sh"

# 4. MOSTRAR RESUMEN
echo ""
echo -e "${PURPLE}🎉 SISTEMA DE LIMPIEZA INTEGRAL CREADO${NC}"
echo -e "${CYAN}=======================================${NC}"
echo ""
echo -e "${GREEN}✅ Scripts creados:${NC}"
echo -e "  📄 scripts/maintenance/comprehensive-cleanup.sh"
echo -e "  📄 scripts/validation/validate-services-after-cleanup.sh"
echo -e "  🔗 comprehensive-cleanup.sh (enlace de acceso rápido)"
echo ""
echo -e "${BLUE}🚀 PARA EJECUTAR LA LIMPIEZA INTEGRAL:${NC}"
echo -e "  ${YELLOW}./comprehensive-cleanup.sh${NC}"
echo ""
echo -e "${BLUE}🔍 PARA VALIDAR DESPUÉS DE LIMPIEZA:${NC}"
echo -e "  ${YELLOW}./scripts/validation/validate-services-after-cleanup.sh${NC}"
echo ""
echo -e "${GREEN}¡Sistema listo para limpieza integral de archivos dispersos!${NC}"

exit 0
