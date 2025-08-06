#!/bin/bash

# Análisis y Limpieza de Archivos Obsoletos
# Docker WebLogic Oracle Project

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🔍 ANÁLISIS DE ARCHIVOS OBSOLETOS - Docker WebLogic Oracle${NC}"
echo -e "${BLUE}Fecha: $(date)${NC}"
echo ""

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Crear directorio de backup para archivos obsoletos
CLEANUP_DIR="backups/cleanup-obsolete-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$CLEANUP_DIR"

echo -e "${BLUE}📋 IDENTIFICANDO ARCHIVOS OBSOLETOS...${NC}"

# Arrays para clasificar archivos
declare -a OBSOLETE_FILES=()
declare -a OBSOLETE_DIRS=()
declare -a KEEP_FILES=()
declare -a SYMLINKS_BROKEN=()

# Función para verificar si un symlink está roto
check_broken_symlink() {
    local file="$1"
    if [[ -L "$file" ]] && [[ ! -e "$file" ]]; then
        return 0  # Es un symlink roto
    fi
    return 1  # No es un symlink roto
}

# Función para verificar si un archivo es obsoleto
is_obsolete() {
    local file="$1"
    local basename=$(basename "$file")
    
    # Archivos claramente obsoletos
    case "$basename" in
        "CLEANUP-REPORT-"*) return 0 ;;
        "ESTADO-PROYECTO-ACTUALIZADO.md") return 0 ;;
        "DOCKER-WEBLOGIC-BUILD-LOCAL.md") return 0 ;;
        "fix-haproxy-ui.py") return 0 ;;
        "patch-admin-ui.py") return 0 ;;
        "admin_ui_fixed.py") return 0 ;;
        "complete-reorganization.sh") return 0 ;;
        ".env.current") return 0 ;;
        ".env.development") return 0 ;;
        ".env.staging") return 0 ;;
        ".env.production") return 0 ;;
        *) return 1 ;;
    esac
}

# Función para verificar directorios obsoletos
is_obsolete_dir() {
    local dir="$1"
    local basename=$(basename "$dir")
    
    case "$basename" in
        "war-projects") return 0 ;;
        "nginx") return 0 ;;
        "monitoring-env") return 0 ;;
        "python") return 0 ;;
        "users") return 0 ;;
        *) return 1 ;;
    esac
}

echo -e "${YELLOW}🔍 Analizando archivos en directorio raíz...${NC}"

# Analizar archivos en directorio raíz
for file in *; do
    if [[ -f "$file" ]]; then
        if check_broken_symlink "$file"; then
            SYMLINKS_BROKEN+=("$file")
        elif is_obsolete "$file"; then
            OBSOLETE_FILES+=("$file")
        else
            KEEP_FILES+=("$file")
        fi
    elif [[ -d "$file" ]]; then
        if is_obsolete_dir "$file"; then
            OBSOLETE_DIRS+=("$file")
        fi
    elif [[ -L "$file" ]]; then
        if check_broken_symlink "$file"; then
            SYMLINKS_BROKEN+=("$file")
        fi
    fi
done

echo -e "${YELLOW}🔍 Analizando scripts obsoletos...${NC}"

# Analizar scripts específicos
if [[ -d "scripts" ]]; then
    # Scripts obsoletos específicos
    OBSOLETE_SCRIPT_FILES=(
        "scripts/fix-haproxy-ui.py"
        "scripts/patch-admin-ui.py"
        "scripts/admin_ui_fixed.py"
        "scripts/complete-reorganization.sh"
        "scripts/.env.current"
        "scripts/.env.development"
        "scripts/.env.staging"
        "scripts/.env.production"
    )
    
    for script in "${OBSOLETE_SCRIPT_FILES[@]}"; do
        if [[ -f "$script" ]]; then
            OBSOLETE_FILES+=("$script")
        fi
    done
    
    # Directorios de scripts obsoletos
    OBSOLETE_SCRIPT_DIRS=(
        "scripts/python"
        "scripts/users"
    )
    
    for script_dir in "${OBSOLETE_SCRIPT_DIRS[@]}"; do
        if [[ -d "$script_dir" ]]; then
            OBSOLETE_DIRS+=("$script_dir")
        fi
    done
fi

# Mostrar resultados del análisis
echo ""
echo -e "${BLUE}📊 RESULTADOS DEL ANÁLISIS:${NC}"
echo ""

echo -e "${RED}🗑️  ARCHIVOS OBSOLETOS IDENTIFICADOS (${#OBSOLETE_FILES[@]}):${NC}"
for file in "${OBSOLETE_FILES[@]}"; do
    echo "  ❌ $file"
done

echo ""
echo -e "${RED}📁 DIRECTORIOS OBSOLETOS IDENTIFICADOS (${#OBSOLETE_DIRS[@]}):${NC}"
for dir in "${OBSOLETE_DIRS[@]}"; do
    echo "  ❌ $dir/"
done

echo ""
echo -e "${YELLOW}🔗 SYMLINKS ROTOS IDENTIFICADOS (${#SYMLINKS_BROKEN[@]}):${NC}"
for link in "${SYMLINKS_BROKEN[@]}"; do
    echo "  ⚠️  $link -> $(readlink "$link" 2>/dev/null || echo "BROKEN")"
done

echo ""
echo -e "${GREEN}✅ ARCHIVOS A MANTENER (${#KEEP_FILES[@]}):${NC}"
for file in "${KEEP_FILES[@]}"; do
    echo "  ✅ $file"
done

# Preguntar si proceder con la limpieza
echo ""
echo -e "${CYAN}🤔 ¿Proceder con la limpieza de archivos obsoletos?${NC}"
echo -e "${YELLOW}Los archivos se moverán a: $CLEANUP_DIR${NC}"
read -p "Continuar? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🧹 INICIANDO LIMPIEZA...${NC}"
    
    # Crear estructura en backup
    mkdir -p "$CLEANUP_DIR/files"
    mkdir -p "$CLEANUP_DIR/directories"
    mkdir -p "$CLEANUP_DIR/symlinks"
    
    # Mover archivos obsoletos
    if [[ ${#OBSOLETE_FILES[@]} -gt 0 ]]; then
        echo -e "${YELLOW}📦 Moviendo archivos obsoletos...${NC}"
        for file in "${OBSOLETE_FILES[@]}"; do
            if [[ -f "$file" ]]; then
                echo "  📦 $file"
                mv "$file" "$CLEANUP_DIR/files/"
            fi
        done
    fi
    
    # Mover directorios obsoletos
    if [[ ${#OBSOLETE_DIRS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}📁 Moviendo directorios obsoletos...${NC}"
        for dir in "${OBSOLETE_DIRS[@]}"; do
            if [[ -d "$dir" ]]; then
                echo "  📁 $dir/"
                mv "$dir" "$CLEANUP_DIR/directories/"
            fi
        done
    fi
    
    # Remover symlinks rotos
    if [[ ${#SYMLINKS_BROKEN[@]} -gt 0 ]]; then
        echo -e "${YELLOW}🔗 Removiendo symlinks rotos...${NC}"
        for link in "${SYMLINKS_BROKEN[@]}"; do
            if [[ -L "$link" ]]; then
                echo "  🔗 $link"
                # Guardar información del symlink
                echo "$link -> $(readlink "$link" 2>/dev/null || echo "BROKEN")" >> "$CLEANUP_DIR/symlinks/broken_symlinks.txt"
                rm "$link"
            fi
        done
    fi
    
    # Crear reporte de limpieza
    cat > "$CLEANUP_DIR/CLEANUP_REPORT.md" << EOF
# Reporte de Limpieza - $(date)

## Archivos Obsoletos Removidos
$(printf '%s\n' "${OBSOLETE_FILES[@]}")

## Directorios Obsoletos Removidos
$(printf '%s\n' "${OBSOLETE_DIRS[@]}")

## Symlinks Rotos Removidos
$(printf '%s\n' "${SYMLINKS_BROKEN[@]}")

## Estadísticas
- Archivos removidos: ${#OBSOLETE_FILES[@]}
- Directorios removidos: ${#OBSOLETE_DIRS[@]}
- Symlinks rotos removidos: ${#SYMLINKS_BROKEN[@]}
- Total items limpiados: $((${#OBSOLETE_FILES[@]} + ${#OBSOLETE_DIRS[@]} + ${#SYMLINKS_BROKEN[@]}))

## Backup Location
$CLEANUP_DIR

## Archivos Mantenidos
$(printf '%s\n' "${KEEP_FILES[@]}")
EOF
    
    echo ""
    echo -e "${GREEN}✅ LIMPIEZA COMPLETADA${NC}"
    echo -e "${BLUE}📊 Estadísticas:${NC}"
    echo "  • Archivos removidos: ${#OBSOLETE_FILES[@]}"
    echo "  • Directorios removidos: ${#OBSOLETE_DIRS[@]}"
    echo "  • Symlinks rotos removidos: ${#SYMLINKS_BROKEN[@]}"
    echo "  • Total items limpiados: $((${#OBSOLETE_FILES[@]} + ${#OBSOLETE_DIRS[@]} + ${#SYMLINKS_BROKEN[@]}))"
    echo ""
    echo -e "${CYAN}📁 Backup creado en: $CLEANUP_DIR${NC}"
    echo -e "${CYAN}📄 Reporte: $CLEANUP_DIR/CLEANUP_REPORT.md${NC}"
    
else
    echo -e "${YELLOW}❌ Limpieza cancelada por el usuario${NC}"
    rm -rf "$CLEANUP_DIR"
fi

echo ""
echo -e "${GREEN}🎯 PRÓXIMOS PASOS RECOMENDADOS:${NC}"
echo "1. Revisar documentación actualizada"
echo "2. Verificar scripts principales funcionando"
echo "3. Actualizar guías de uso"
echo "4. Continuar con Fase 4 (CI/CD Pipeline)"

echo ""
echo -e "${BLUE}📋 SCRIPTS PRINCIPALES MANTENIDOS:${NC}"
echo "  ✅ ./manage-services.sh - Gestión de servicios"
echo "  ✅ ./scripts/docker-hub/ - Build de imágenes"
echo "  ✅ ./scripts/maintenance/ - Mantenimiento"
echo "  ✅ ./start-monitoring-integrated.sh - Monitoreo"

echo ""
echo -e "${CYAN}🔍 Análisis completado - $(date)${NC}"
