#!/bin/bash

# =============================================================================
# Setup de Documentación MkDocs
# =============================================================================
# Este script configura el entorno completo de documentación MkDocs
# Solo necesita ejecutarse una vez por proyecto
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Verificar si ya está configurado
check_existing_setup() {
    if [ -d "mkdocs-env" ] && [ -f "mkdocs.yml" ]; then
        print_warning "La documentación ya parece estar configurada."
        read -p "¿Deseas reconfigurar? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Configuración cancelada."
            exit 0
        fi
    fi
}

# Verificar dependencias del sistema
check_system_dependencies() {
    print_header "Verificando Dependencias del Sistema"
    
    # Verificar Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 no está instalado"
        print_info "Instala Python 3: sudo apt-get install python3 python3-pip python3-venv"
        exit 1
    fi
    
    python_version=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1-2)
    print_success "Python $python_version encontrado"
    
    # Verificar pip
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 no está instalado"
        print_info "Instala pip3: sudo apt-get install python3-pip"
        exit 1
    fi
    
    print_success "pip3 encontrado"
    
    # Verificar git (opcional pero recomendado)
    if command -v git &> /dev/null; then
        print_success "Git encontrado"
    else
        print_warning "Git no encontrado (recomendado para versionado)"
    fi
}

# Crear entorno virtual
create_virtual_environment() {
    print_header "Creando Entorno Virtual"
    
    if [ -d "mkdocs-env" ]; then
        print_warning "Eliminando entorno virtual existente..."
        rm -rf mkdocs-env
    fi
    
    print_info "Creando entorno virtual en mkdocs-env/"
    python3 -m venv mkdocs-env
    
    print_success "Entorno virtual creado"
}

# Activar entorno virtual
activate_virtual_environment() {
    print_info "Activando entorno virtual..."
    source mkdocs-env/bin/activate
    
    # Actualizar pip
    print_info "Actualizando pip..."
    pip install --upgrade pip
    
    print_success "Entorno virtual activado"
}

# Instalar dependencias de MkDocs
install_mkdocs_dependencies() {
    print_header "Instalando Dependencias de MkDocs"
    
    print_info "Instalando MkDocs y plugins..."
    
    # Lista de dependencias
    dependencies=(
        "mkdocs>=1.5.0"
        "mkdocs-material>=9.0.0"
        "mkdocs-mermaid2-plugin>=1.1.0"
        "pymdown-extensions>=10.0.0"
        "mkdocs-awesome-pages-plugin>=2.9.0"
        "mkdocs-git-revision-date-localized-plugin>=1.2.0"
        "mkdocs-minify-plugin>=0.7.0"
        "mkdocs-redirects>=1.2.0"
    )
    
    for dep in "${dependencies[@]}"; do
        print_info "Instalando $dep..."
        pip install "$dep"
    done
    
    print_success "Todas las dependencias instaladas"
}

# Crear archivo requirements.txt
create_requirements_file() {
    print_header "Creando Archivo de Requisitos"
    
    print_info "Generando requirements.txt..."
    pip freeze > requirements.txt
    
    print_success "requirements.txt creado"
}

# Verificar configuración de MkDocs
verify_mkdocs_config() {
    print_header "Verificando Configuración de MkDocs"
    
    if [ ! -f "mkdocs.yml" ]; then
        print_error "mkdocs.yml no encontrado"
        exit 1
    fi
    
    print_info "Validando configuración..."
    mkdocs config
    
    print_success "Configuración válida"
}

# Crear estructura de directorios
create_directory_structure() {
    print_header "Creando Estructura de Directorios"
    
    # Directorios necesarios
    directories=(
        "docs/assets/images"
        "docs/assets/css"
        "docs/assets/js"
        "site"
        "logs"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Directorio creado: $dir"
        else
            print_info "Directorio ya existe: $dir"
        fi
    done
}

# Crear archivos de configuración adicionales
create_additional_configs() {
    print_header "Creando Archivos de Configuración Adicionales"
    
    # .gitignore para documentación
    if [ ! -f ".gitignore" ]; then
        cat > .gitignore << 'EOF'
# MkDocs
site/
mkdocs-env/
*.pyc
__pycache__/

# Logs
logs/*.log

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Temporary files
*.tmp
*.bak
*~
EOF
        print_success "Archivo .gitignore creado"
    else
        print_info "Archivo .gitignore ya existe"
    fi
    
    # Archivo de configuración para desarrollo
    if [ ! -f "mkdocs-dev.yml" ]; then
        cat > mkdocs-dev.yml << 'EOF'
# Configuración de desarrollo para MkDocs
# Hereda de mkdocs.yml pero con configuraciones específicas para desarrollo

INHERIT: mkdocs.yml

# Configuraciones de desarrollo
dev_addr: '127.0.0.1:8000'
use_directory_urls: false

# Plugins adicionales para desarrollo
plugins:
  - search:
      lang: es
  - mermaid2
  - git-revision-date-localized:
      enable_creation_date: true
      type: datetime
  - minify:
      minify_html: false
      minify_js: false
      minify_css: false

# Configuración de logging para desarrollo
extra:
  analytics:
    provider: google
    property: !ENV GA_TRACKING_ID
EOF
        print_success "Archivo mkdocs-dev.yml creado"
    else
        print_info "Archivo mkdocs-dev.yml ya existe"
    fi
}

# Crear scripts de utilidad
create_utility_scripts() {
    print_header "Creando Scripts de Utilidad"
    
    # Script para activar entorno
    cat > activate-docs-env.sh << 'EOF'
#!/bin/bash
# Script para activar el entorno de documentación

if [ ! -d "mkdocs-env" ]; then
    echo "❌ Entorno virtual no encontrado. Ejecuta ./setup-docs.sh primero."
    exit 1
fi

echo "🚀 Activando entorno de documentación..."
source mkdocs-env/bin/activate

echo "✅ Entorno activado. Comandos disponibles:"
echo "   - mkdocs serve    # Servir documentación"
echo "   - mkdocs build    # Construir sitio"
echo "   - deactivate      # Desactivar entorno"

# Mantener shell activo
exec bash
EOF
    chmod +x activate-docs-env.sh
    print_success "Script activate-docs-env.sh creado"
    
    # Script de limpieza
    cat > clean-docs.sh << 'EOF'
#!/bin/bash
# Script para limpiar archivos generados

echo "🧹 Limpiando archivos generados..."

# Limpiar sitio construido
if [ -d "site" ]; then
    rm -rf site/
    echo "✅ Directorio site/ eliminado"
fi

# Limpiar cache de Python
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
echo "✅ Cache de Python limpiado"

# Limpiar logs
if [ -d "logs" ]; then
    rm -f logs/*.log
    echo "✅ Logs limpiados"
fi

echo "✅ Limpieza completada"
EOF
    chmod +x clean-docs.sh
    print_success "Script clean-docs.sh creado"
}

# Verificar instalación
verify_installation() {
    print_header "Verificando Instalación"
    
    # Verificar que MkDocs funciona
    print_info "Verificando MkDocs..."
    mkdocs --version
    
    # Intentar construir documentación
    print_info "Probando construcción de documentación..."
    mkdocs build --quiet
    
    if [ -d "site" ]; then
        print_success "Documentación construida exitosamente"
    else
        print_error "Error al construir documentación"
        exit 1
    fi
    
    print_success "Instalación verificada correctamente"
}

# Mostrar información final
show_final_info() {
    print_header "Configuración Completada"
    
    echo -e "${GREEN}"
    cat << 'EOF'
🎉 ¡Configuración de documentación completada exitosamente!

📁 Estructura creada:
   ├── mkdocs-env/          # Entorno virtual Python
   ├── docs/                # Archivos de documentación
   ├── site/                # Sitio generado
   ├── mkdocs.yml           # Configuración principal
   ├── mkdocs-dev.yml       # Configuración de desarrollo
   ├── requirements.txt     # Dependencias Python
   └── scripts de utilidad

🚀 Comandos disponibles:
EOF
    echo -e "${NC}"
    
    echo -e "${BLUE}   # Activar entorno y trabajar${NC}"
    echo -e "   ./activate-docs-env.sh"
    echo
    echo -e "${BLUE}   # O manualmente:${NC}"
    echo -e "   source mkdocs-env/bin/activate"
    echo -e "   mkdocs serve                    # Servir en http://localhost:8000"
    echo -e "   mkdocs build                    # Construir sitio estático"
    echo
    echo -e "${BLUE}   # Scripts de utilidad:${NC}"
    echo -e "   ./build-docs.sh serve           # Servir con auto-reload"
    echo -e "   ./build-docs.sh build           # Construir para producción"
    echo -e "   ./clean-docs.sh                 # Limpiar archivos generados"
    echo
    echo -e "${YELLOW}💡 Próximos pasos:${NC}"
    echo -e "   1. Activa el entorno: ${BLUE}./activate-docs-env.sh${NC}"
    echo -e "   2. Sirve la documentación: ${BLUE}mkdocs serve${NC}"
    echo -e "   3. Abre http://localhost:8000 en tu navegador"
    echo -e "   4. Edita archivos en docs/ y ve los cambios en tiempo real"
    echo
    print_success "¡Listo para trabajar con la documentación!"
}

# Función principal
main() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    SETUP DOCUMENTACIÓN MKDOCS               ║
║                                                              ║
║  Este script configurará el entorno completo de             ║
║  documentación MkDocs con todas las dependencias            ║
║  y configuraciones necesarias.                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Verificar si ya está configurado
    check_existing_setup
    
    # Ejecutar pasos de configuración
    check_system_dependencies
    create_virtual_environment
    activate_virtual_environment
    install_mkdocs_dependencies
    create_requirements_file
    verify_mkdocs_config
    create_directory_structure
    create_additional_configs
    create_utility_scripts
    verify_installation
    show_final_info
}

# Manejo de errores
trap 'print_error "Error en línea $LINENO. Configuración interrumpida."; exit 1' ERR

# Verificar que estamos en el directorio correcto
if [ ! -f "mkdocs.yml" ]; then
    print_error "mkdocs.yml no encontrado. Ejecuta este script desde el directorio raíz del proyecto."
    exit 1
fi

# Ejecutar función principal
main "$@"
