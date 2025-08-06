#!/bin/bash

# =============================================================================
# Script de Construcción de Documentación MkDocs
# =============================================================================
# Este script maneja la construcción y servicio de la documentación MkDocs
# con todas las configuraciones y validaciones necesarias.
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
DOCS_DIR="docs"
SITE_DIR="site"
VENV_DIR="mkdocs-env"
CONFIG_FILE="mkdocs.yml"
DEV_CONFIG_FILE="mkdocs-dev.yml"
SERVE_PORT=8000

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

# Verificar si necesita configuración inicial
check_initial_setup() {
    if [ ! -d "$VENV_DIR" ] || [ ! -f "requirements.txt" ]; then
        print_warning "Configuración inicial no encontrada"
        print_info "Ejecutando configuración inicial..."
        
        if [ -f "setup-docs.sh" ]; then
            ./setup-docs.sh
        else
            print_error "setup-docs.sh no encontrado"
            print_info "Crea el entorno manualmente o ejecuta la configuración inicial"
            exit 1
        fi
    fi
}

# Verificar entorno virtual
check_virtual_environment() {
    if [ ! -d "$VENV_DIR" ]; then
        print_error "Entorno virtual no encontrado en $VENV_DIR"
        print_info "Ejecuta primero: ./setup-docs.sh"
        exit 1
    fi
    
    if [ -z "$VIRTUAL_ENV" ]; then
        print_info "Activando entorno virtual..."
        source "$VENV_DIR/bin/activate"
    fi
}

# Verificar dependencias
check_dependencies() {
    if ! command -v mkdocs &> /dev/null; then
        print_error "MkDocs no está instalado"
        print_info "Ejecuta primero: ./setup-docs.sh"
        exit 1
    fi
}

# Verificar configuración
check_configuration() {
    print_info "🔍 Verificando configuración..."
    
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Archivo de configuración $CONFIG_FILE no encontrado"
        exit 1
    fi
    
    # Verificar archivos de documentación requeridos
    required_files=("index.md")
    for file in "${required_files[@]}"; do
        if [ ! -f "$DOCS_DIR/$file" ]; then
            print_warning "Archivo faltante: $DOCS_DIR/$file"
        fi
    done
    
    print_success "Configuración verificada"
}

# Limpiar archivos anteriores
clean_build() {
    if [ -d "$SITE_DIR" ]; then
        print_info "🧹 Limpiando construcción anterior..."
        rm -rf "$SITE_DIR"
    fi
}

# Construir documentación
build_docs() {
    print_header "Construyendo Documentación"
    
    check_initial_setup
    check_virtual_environment
    check_dependencies
    check_configuration
    clean_build
    
    print_info "🔨 Construyendo sitio estático..."
    
    if mkdocs build --config-file "$CONFIG_FILE" --site-dir "$SITE_DIR"; then
        print_success "Sitio construido en: $SITE_DIR/"
        print_info "   Puedes servir con: python -m http.server -d $SITE_DIR/ 8000"
    else
        print_error "Error al construir la documentación"
        exit 1
    fi
}

# Servir documentación
serve_docs() {
    print_header "Sirviendo Documentación"
    
    check_initial_setup
    check_virtual_environment
    check_dependencies
    check_configuration
    
    print_info "🚀 Iniciando servidor de desarrollo..."
    print_info "   URL: http://localhost:$SERVE_PORT"
    print_info "   Presiona Ctrl+C para detener"
    
    # Usar configuración de desarrollo si existe
    config_file="$CONFIG_FILE"
    if [ -f "$DEV_CONFIG_FILE" ]; then
        config_file="$DEV_CONFIG_FILE"
        print_info "   Usando configuración de desarrollo: $DEV_CONFIG_FILE"
    fi
    
    mkdocs serve --config-file "$config_file" --dev-addr "127.0.0.1:$SERVE_PORT"
}

# Validar documentación
validate_docs() {
    print_header "Validando Documentación"
    
    check_initial_setup
    check_virtual_environment
    check_dependencies
    
    print_info "🔍 Validando configuración..."
    mkdocs config --config-file "$CONFIG_FILE"
    
    print_info "🔍 Verificando enlaces internos..."
    # Construir temporalmente para verificar enlaces
    temp_site="temp_site"
    if mkdocs build --config-file "$CONFIG_FILE" --site-dir "$temp_site" --quiet; then
        print_success "Documentación válida"
        rm -rf "$temp_site"
    else
        print_error "Errores encontrados en la documentación"
        rm -rf "$temp_site"
        exit 1
    fi
}

# Mostrar estadísticas
show_stats() {
    print_header "Estadísticas de Documentación"
    
    if [ -d "$DOCS_DIR" ]; then
        total_files=$(find "$DOCS_DIR" -name "*.md" | wc -l)
        total_lines=$(find "$DOCS_DIR" -name "*.md" -exec wc -l {} + | tail -1 | awk '{print $1}')
        
        print_info "📊 Archivos Markdown: $total_files"
        print_info "📊 Total de líneas: $total_lines"
        
        echo -e "\n${BLUE}📁 Estructura de archivos:${NC}"
        find "$DOCS_DIR" -name "*.md" | sort | sed 's/^/   /'
    fi
    
    if [ -d "$SITE_DIR" ]; then
        site_size=$(du -sh "$SITE_DIR" | cut -f1)
        print_info "📊 Tamaño del sitio: $site_size"
    fi
}

# Configuración inicial rápida
quick_setup() {
    print_header "Configuración Inicial Rápida"
    
    if [ -f "setup-docs.sh" ]; then
        print_info "Ejecutando configuración completa..."
        ./setup-docs.sh
    else
        print_error "setup-docs.sh no encontrado"
        exit 1
    fi
}

# Mostrar ayuda
show_help() {
    echo -e "${BLUE}Uso: $0 {build|serve|validate|stats|clean|setup|help}${NC}"
    echo
    echo -e "${YELLOW}Comandos disponibles:${NC}"
    echo -e "  ${GREEN}build${NC}     - Construir documentación estática"
    echo -e "  ${GREEN}serve${NC}     - Servir documentación con auto-reload"
    echo -e "  ${GREEN}validate${NC}  - Validar configuración y enlaces"
    echo -e "  ${GREEN}stats${NC}     - Mostrar estadísticas de documentación"
    echo -e "  ${GREEN}clean${NC}     - Limpiar archivos generados"
    echo -e "  ${GREEN}setup${NC}     - Ejecutar configuración inicial"
    echo -e "  ${GREEN}help${NC}      - Mostrar esta ayuda"
    echo
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo -e "  $0 setup          # Configuración inicial (solo una vez)"
    echo -e "  $0 serve          # Servir en modo desarrollo"
    echo -e "  $0 build          # Construir para producción"
    echo -e "  $0 validate       # Verificar antes de commit"
    echo
    echo -e "${YELLOW}Configuración:${NC}"
    echo -e "  Puerto de desarrollo: $SERVE_PORT"
    echo -e "  Directorio de docs: $DOCS_DIR"
    echo -e "  Directorio de salida: $SITE_DIR"
    echo -e "  Entorno virtual: $VENV_DIR"
    echo
    echo -e "${YELLOW}Flujo de trabajo típico:${NC}"
    echo -e "  1. $0 setup       # Solo la primera vez"
    echo -e "  2. $0 serve       # Para desarrollo"
    echo -e "  3. $0 build       # Para producción"
}

# Limpiar archivos generados
clean_docs() {
    print_header "Limpiando Archivos Generados"
    
    if [ -d "$SITE_DIR" ]; then
        rm -rf "$SITE_DIR"
        print_success "Directorio $SITE_DIR eliminado"
    fi
    
    # Limpiar archivos temporales
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    
    print_success "Limpieza completada"
}

# Función principal
main() {
    case "${1:-help}" in
        "build")
            build_docs
            ;;
        "serve")
            serve_docs
            ;;
        "validate")
            validate_docs
            ;;
        "stats")
            show_stats
            ;;
        "clean")
            clean_docs
            ;;
        "setup")
            quick_setup
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            print_error "Comando desconocido: $1"
            show_help
            exit 1
            ;;
    esac
}

# Manejo de errores
trap 'print_error "Error en línea $LINENO. Ejecución interrumpida."; exit 1' ERR

# Verificar que estamos en el directorio correcto
if [ ! -f "$CONFIG_FILE" ]; then
    print_error "Archivo $CONFIG_FILE no encontrado. Ejecuta desde el directorio raíz del proyecto."
    exit 1
fi

# Ejecutar función principal
main "$@"
