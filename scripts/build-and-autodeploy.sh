#!/bin/bash
#
# Script completo para compilar WAR y copiar a autodeploy
#

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=============================================="
echo "  Build y AutoDeploy de Archivos WAR"
echo "  Oracle WebLogic Server"
echo -e "===============================================${NC}"
echo ""

# Función para mostrar ayuda
show_help() {
    echo -e "${GREEN}=== Script de Build y AutoDeploy ===${NC}"
    echo ""
    echo -e "Uso: $0 [opciones]"
    echo ""
    echo -e "Opciones:"
    echo -e "  ${YELLOW}--all${NC}         Compilar todos los WAR y copiar a autodeploy"
    echo -e "  ${YELLOW}--clean${NC}       Limpiar directorios antes de compilar"
    echo -e "  ${YELLOW}--help${NC}        Mostrar esta ayuda"
    echo ""
    echo -e "Ejemplos:"
    echo -e "  $0 --all                # Compilar y autodeplegar todos los WAR"
    echo -e "  $0 --clean --all        # Limpiar, compilar y autodeplegar"
    echo ""
}

# Función para limpiar directorios
clean_directories() {
    echo -e "${YELLOW}=== Limpiando directorios ===${NC}"
    
    # Limpiar deploy (mantener .gitkeep)
    find deploy/ -name "*.war" -delete 2>/dev/null || true
    echo "✓ Directorio deploy/ limpiado"
    
    # Limpiar autodeploy
    rm -f autodeploy/*.war 2>/dev/null || true
    echo "✓ Directorio autodeploy/ limpiado"
    
    echo ""
}

# Función para compilar WAR
build_wars() {
    echo -e "${BLUE}=== Compilando archivos WAR ===${NC}"
    
    # Ejecutar script de build
    ./scripts/build/build-wars.sh
    
    echo -e "${GREEN}✓ Compilación completada${NC}"
    echo ""
}

# Función para copiar a autodeploy
copy_to_autodeploy() {
    echo -e "${BLUE}=== Copiando WAR a autodeploy/ ===${NC}"
    
    # Verificar que existen archivos WAR
    if [ ! -f deploy/*.war ]; then
        echo -e "${RED}Error: No se encontraron archivos WAR en deploy/${NC}"
        exit 1
    fi
    
    # Copiar archivos WAR
    cp deploy/*.war autodeploy/
    
    echo "✓ Archivos WAR copiados a autodeploy/"
    echo ""
    
    # Mostrar archivos copiados
    echo -e "${YELLOW}Archivos en autodeploy/:${NC}"
    ls -lh autodeploy/*.war
    echo ""
}

# Función para mostrar resumen
show_summary() {
    echo -e "${GREEN}=== Resumen del Proceso ===${NC}"
    echo ""
    
    echo -e "${YELLOW}Archivos WAR generados:${NC}"
    ls -lh deploy/*.war | while read -r line; do
        echo "  ✓ $line"
    done
    echo ""
    
    echo -e "${YELLOW}Archivos en autodeploy:${NC}"
    ls -lh autodeploy/*.war | while read -r line; do
        echo "  ✓ $line"
    done
    echo ""
    
    echo -e "${GREEN}=== Proceso Completado ===${NC}"
    echo ""
    echo -e "Los archivos WAR están listos para despliegue automático en WebLogic."
    echo ""
    echo -e "${YELLOW}Próximos pasos:${NC}"
    echo "1. Iniciar los contenedores: ./start-all.sh"
    echo "2. WebLogic detectará automáticamente los WAR en autodeploy/"
    echo "3. Verificar despliegue en: http://localhost:7001/console"
    echo ""
}

# Función principal
main() {
    local clean_flag=false
    local build_all=false
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                clean_flag=true
                shift
                ;;
            --all)
                build_all=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Error: Opción desconocida $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Verificar que se especificó --all
    if [ "$build_all" = false ]; then
        show_help
        exit 1
    fi
    
    # Ejecutar limpieza si se solicitó
    if [ "$clean_flag" = true ]; then
        clean_directories
    fi
    
    # Compilar WAR
    build_wars
    
    # Copiar a autodeploy
    copy_to_autodeploy
    
    # Mostrar resumen
    show_summary
}

# Ejecutar función principal con todos los argumentos
main "$@"
