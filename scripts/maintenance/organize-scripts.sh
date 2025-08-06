#!/bin/bash
# Script para organizar y mantener la estructura de scripts

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# Función para mostrar el banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 Organizador de Scripts                      ║"
    echo "║              Mantenimiento y Estructura                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para mostrar ayuda
show_help() {
    show_banner
    echo -e "${YELLOW}Uso: $0 [COMANDO]${NC}"
    echo ""
    echo -e "${BLUE}Comandos disponibles:${NC}"
    echo "  organize        Organizar scripts por categorías"
    echo "  permissions     Aplicar permisos correctos"
    echo "  validate        Validar estructura y funcionalidad"
    echo "  clean           Limpiar archivos de respaldo y temporales"
    echo "  index           Crear índice de scripts disponibles"
    echo "  links           Verificar y reparar enlaces simbólicos"
    echo "  all             Ejecutar todas las operaciones"
    echo ""
    echo -e "${BLUE}Ejemplos:${NC}"
    echo "  $0 organize     # Organizar scripts"
    echo "  $0 permissions  # Aplicar permisos"
    echo "  $0 all          # Ejecutar todo"
}

# Función para organizar scripts por categorías
organize_scripts() {
    echo -e "${BLUE}=== ORGANIZANDO SCRIPTS ===${NC}"
    
    # Crear estructura de directorios si no existe
    local dirs=(
        "build"
        "canary"
        "deploy"
        "monitoring"
        "utils"
        "validation"
        "maintenance"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$SCRIPTS_DIR/$dir" ]]; then
            echo -e "${YELLOW}Creando directorio: scripts/$dir${NC}"
            mkdir -p "$SCRIPTS_DIR/$dir"
        fi
    done
    
    # Mover scripts a sus categorías apropiadas si no están ya organizados
    echo -e "${YELLOW}Verificando organización de scripts...${NC}"
    
    # Scripts de validación
    validation_scripts=(
        "validate-*.sh"
        "check-*.sh"
        "test-*.sh"
        "run-all-tests.sh"
    )
    
    for pattern in "${validation_scripts[@]}"; do
        for script in $SCRIPTS_DIR/$pattern; do
            if [[ -f "$script" && ! "$script" =~ scripts/validation/ ]]; then
                script_name=$(basename "$script")
                if [[ ! -f "$SCRIPTS_DIR/validation/$script_name" ]]; then
                    echo -e "  ${YELLOW}Moviendo $script_name a validation/${NC}"
                    mv "$script" "$SCRIPTS_DIR/validation/"
                fi
            fi
        done
    done
    
    # Scripts de mantenimiento
    maintenance_scripts=(
        "cleanup-*.sh"
        "update-*.sh"
        "auto-update-*.sh"
        "manage-*.sh"
        "organize-*.sh"
        "diagnose-*.sh"
    )
    
    for pattern in "${maintenance_scripts[@]}"; do
        for script in $SCRIPTS_DIR/$pattern; do
            if [[ -f "$script" && ! "$script" =~ scripts/maintenance/ ]]; then
                script_name=$(basename "$script")
                if [[ ! -f "$SCRIPTS_DIR/maintenance/$script_name" ]]; then
                    echo -e "  ${YELLOW}Moviendo $script_name a maintenance/${NC}"
                    mv "$script" "$SCRIPTS_DIR/maintenance/"
                fi
            fi
        done
    done
    
    echo -e "${GREEN}✅ Scripts organizados${NC}"
}

# Función para aplicar permisos correctos
apply_permissions() {
    echo -e "${BLUE}=== APLICANDO PERMISOS ===${NC}"
    
    # Hacer ejecutables todos los scripts .sh
    echo -e "${YELLOW}Aplicando permisos de ejecución a scripts .sh...${NC}"
    find "$SCRIPTS_DIR" -name "*.sh" -type f -exec chmod +x {} \;
    
    # Aplicar permisos de lectura a archivos de configuración
    echo -e "${YELLOW}Aplicando permisos de lectura a archivos de configuración...${NC}"
    find "$SCRIPTS_DIR" -name "*.py" -type f -exec chmod +r {} \;
    find "$SCRIPTS_DIR" -name "*.md" -type f -exec chmod +r {} \;
    find "$SCRIPTS_DIR" -name "*.yml" -type f -exec chmod +r {} \;
    find "$SCRIPTS_DIR" -name "*.yaml" -type f -exec chmod +r {} \;
    
    # Scripts principales en el directorio raíz
    chmod +x "$PROJECT_ROOT/manage-services.sh" 2>/dev/null || true
    chmod +x "$PROJECT_ROOT/start-with-auto-update.sh" 2>/dev/null || true
    chmod +x "$PROJECT_ROOT/stop-all-services.sh" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Permisos aplicados${NC}"
}

# Función para validar estructura
validate_structure() {
    echo -e "${BLUE}=== VALIDANDO ESTRUCTURA ===${NC}"
    
    local issues=0
    
    # Verificar scripts críticos
    critical_scripts=(
        "load-env.sh"
        "docker-compose-wrapper.sh"
        "auto-update-haproxy.sh"
        "minikube-port-forwards.sh"
    )
    
    for script in "${critical_scripts[@]}"; do
        if [[ -f "$SCRIPTS_DIR/$script" ]]; then
            if [[ -x "$SCRIPTS_DIR/$script" ]]; then
                echo -e "  ${GREEN}✓${NC} $script (ejecutable)"
            else
                echo -e "  ${YELLOW}⚠${NC} $script (no ejecutable)"
                chmod +x "$SCRIPTS_DIR/$script"
            fi
        else
            echo -e "  ${RED}✗${NC} $script (no encontrado)"
            ((issues++))
        fi
    done
    
    # Verificar estructura de directorios
    required_dirs=(
        "build"
        "canary"
        "deploy"
        "monitoring"
        "utils"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$SCRIPTS_DIR/$dir" ]]; then
            echo -e "  ${GREEN}✓${NC} Directorio scripts/$dir existe"
        else
            echo -e "  ${YELLOW}⚠${NC} Directorio scripts/$dir no existe"
            mkdir -p "$SCRIPTS_DIR/$dir"
        fi
    done
    
    # Verificar sintaxis de scripts bash
    echo -e "${YELLOW}Verificando sintaxis de scripts...${NC}"
    local syntax_errors=0
    
    while IFS= read -r -d '' script; do
        if ! bash -n "$script" 2>/dev/null; then
            echo -e "  ${RED}✗${NC} Error de sintaxis en: $(basename "$script")"
            ((syntax_errors++))
        fi
    done < <(find "$SCRIPTS_DIR" -name "*.sh" -type f -print0)
    
    if [[ $syntax_errors -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} Todos los scripts tienen sintaxis válida"
    else
        echo -e "  ${RED}✗${NC} $syntax_errors scripts con errores de sintaxis"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        echo -e "${GREEN}✅ Estructura validada correctamente${NC}"
        return 0
    else
        echo -e "${RED}❌ Se encontraron $issues problemas${NC}"
        return 1
    fi
}

# Función para limpiar archivos temporales
clean_temp_files() {
    echo -e "${BLUE}=== LIMPIANDO ARCHIVOS TEMPORALES ===${NC}"
    
    # Limpiar archivos de respaldo
    echo -e "${YELLOW}Eliminando archivos de respaldo...${NC}"
    find "$SCRIPTS_DIR" -name "*.backup.*" -type f -delete
    find "$PROJECT_ROOT" -name "*.backup.*" -type f -delete
    
    # Limpiar archivos temporales
    echo -e "${YELLOW}Eliminando archivos temporales...${NC}"
    find "$SCRIPTS_DIR" -name "*.tmp" -type f -delete
    find "$SCRIPTS_DIR" -name "*.temp" -type f -delete
    find "$SCRIPTS_DIR" -name "*~" -type f -delete
    
    # Limpiar logs antiguos
    echo -e "${YELLOW}Limpiando logs antiguos...${NC}"
    find "$PROJECT_ROOT/logs" -name "*.log" -mtime +7 -type f -delete 2>/dev/null || true
    
    echo -e "${GREEN}✅ Archivos temporales limpiados${NC}"
}

# Función para crear índice de scripts
create_index() {
    echo -e "${BLUE}=== CREANDO ÍNDICE DE SCRIPTS ===${NC}"
    
    local index_file="$SCRIPTS_DIR/INDEX.md"
    
    cat > "$index_file" << 'EOF'
# Índice de Scripts

Este documento proporciona una descripción de todos los scripts disponibles en el proyecto.

## Scripts Principales

### Gestión de Servicios
- `load-env.sh` - Carga variables de entorno desde .env
- `docker-compose-wrapper.sh` - Wrapper para docker-compose con variables de entorno
- `auto-update-haproxy.sh` - Actualización automática de configuración HAProxy
- `minikube-port-forwards.sh` - Gestión de port-forwards de Minikube

### Utilidades
EOF
    
    # Agregar scripts por categoría
    for dir in "$SCRIPTS_DIR"/*; do
        if [[ -d "$dir" ]]; then
            dir_name=$(basename "$dir")
            echo "" >> "$index_file"
            echo "### $(echo "$dir_name" | sed 's/^./\U&/' | sed 's/-/ /g')" >> "$index_file"
            
            for script in "$dir"/*.sh; do
                if [[ -f "$script" ]]; then
                    script_name=$(basename "$script")
                    # Extraer descripción del script si existe
                    description=$(head -10 "$script" | grep -E "^#.*[Dd]escripción|^# .*" | head -1 | sed 's/^# *//' || echo "Sin descripción")
                    echo "- \`$script_name\` - $description" >> "$index_file"
                fi
            done
        fi
    done
    
    # Agregar scripts en el directorio raíz
    echo "" >> "$index_file"
    echo "### Scripts en Directorio Raíz" >> "$index_file"
    
    for script in "$SCRIPTS_DIR"/*.sh; do
        if [[ -f "$script" ]]; then
            script_name=$(basename "$script")
            description=$(head -10 "$script" | grep -E "^#.*[Dd]escripción|^# .*" | head -1 | sed 's/^# *//' || echo "Sin descripción")
            echo "- \`$script_name\` - $description" >> "$index_file"
        fi
    done
    
    echo -e "${GREEN}✅ Índice creado en: $index_file${NC}"
}

# Función para verificar enlaces simbólicos
check_symlinks() {
    echo -e "${BLUE}=== VERIFICANDO ENLACES SIMBÓLICOS ===${NC}"
    
    # Enlaces simbólicos esperados en el directorio raíz
    expected_links=(
        "build.sh:scripts/build/build.sh"
        "setup-canary.sh:scripts/canary/setup-canary.sh"
        "canary-control.sh:scripts/canary/canary-control.sh"
        "docker-compose.yml:config/docker-compose.yml"
        "deploy-war.sh:scripts/deploy/deploy-war.sh"
        "test-canary.sh:scripts/canary/test-canary.sh"
    )
    
    for link_def in "${expected_links[@]}"; do
        link_name="${link_def%%:*}"
        target="${link_def##*:}"
        link_path="$PROJECT_ROOT/$link_name"
        target_path="$PROJECT_ROOT/$target"
        
        if [[ -L "$link_path" ]]; then
            if [[ -e "$target_path" ]]; then
                echo -e "  ${GREEN}✓${NC} $link_name -> $target"
            else
                echo -e "  ${RED}✗${NC} $link_name -> $target (destino no existe)"
                rm "$link_path"
            fi
        elif [[ -e "$target_path" ]]; then
            echo -e "  ${YELLOW}⚠${NC} Creando enlace: $link_name -> $target"
            ln -s "$target" "$link_path"
        else
            echo -e "  ${YELLOW}⚠${NC} Enlace y destino no existen: $link_name -> $target"
        fi
    done
    
    echo -e "${GREEN}✅ Enlaces simbólicos verificados${NC}"
}

# Función para ejecutar todas las operaciones
run_all() {
    show_banner
    echo -e "${BLUE}=== EJECUTANDO TODAS LAS OPERACIONES ===${NC}"
    
    organize_scripts
    echo ""
    apply_permissions
    echo ""
    check_symlinks
    echo ""
    clean_temp_files
    echo ""
    create_index
    echo ""
    validate_structure
    
    echo ""
    echo -e "${GREEN}✅ Todas las operaciones completadas${NC}"
}

# Función principal
main() {
    case "${1:-}" in
        organize)
            organize_scripts
            ;;
        permissions)
            apply_permissions
            ;;
        validate)
            validate_structure
            ;;
        clean)
            clean_temp_files
            ;;
        index)
            create_index
            ;;
        links)
            check_symlinks
            ;;
        all)
            run_all
            ;;
        --help|-h|help|"")
            show_help
            ;;
        *)
            echo -e "${RED}Comando no reconocido: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
