#!/bin/bash
#
# Script de ayuda para ejecutar comandos en el proyecto
#

set -e

# Función de ayuda
show_help() {
    echo "Uso: ./run.sh [comando] [opciones]"
    echo ""
    echo "Comandos disponibles:"
    echo "  build              Construye la imagen Docker"
    echo "  build-wars         Compila los archivos WAR"
    echo "  build-ff           Compila la aplicación de Feature Flags"
    echo "  create-war         Crea un archivo WAR simple"
    echo "  deploy             Despliega archivos WAR"
    echo "  setup-canary       Configura el despliegue canary"
    echo "  canary-control     Controla el porcentaje de tráfico"
    echo "  test-canary        Prueba el despliegue canary"
    echo "  help               Muestra esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  ./run.sh build                     # Construye la imagen Docker"
    echo "  ./run.sh deploy --all              # Despliega todos los archivos WAR"
    echo "  ./run.sh deploy --ff4j             # Despliega solo la consola FF4J"
    echo "  ./run.sh deploy mi-aplicacion.war  # Despliega un archivo WAR específico"
    echo "  ./run.sh setup-canary 20           # Configura el despliegue canary (20% a la versión B)"
    echo "  ./run.sh canary-control 50         # Cambia el porcentaje de tráfico (50% a la versión B)"
    echo "  ./run.sh test-canary 100           # Realiza 100 peticiones para probar la distribución"
    echo "  ./run.sh create-war mi-app         # Crea un archivo WAR simple llamado mi-app.war"
    echo ""
}

# Verificar si se proporcionó un comando
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Procesar el comando
case "$1" in
    build)
        shift
        ./scripts/build/build.sh "$@"
        ;;
    build-wars)
        shift
        ./scripts/build/build-wars.sh "$@"
        ;;
    build-ff)
        shift
        ./scripts/build/build-feature-flags.sh "$@"
        ;;
    create-war)
        shift
        ./scripts/build/create-simple-wars.sh "$@"
        ;;
    deploy)
        shift
        ./scripts/deploy/deploy-war.sh "$@"
        ;;
    setup-canary)
        shift
        ./scripts/canary/setup-canary.sh "$@"
        ;;
    canary-control)
        shift
        ./scripts/canary/canary-control.sh "$@"
        ;;
    test-canary)
        shift
        ./scripts/canary/test-canary.sh "$@"
        ;;
    help)
        show_help
        ;;
    *)
        echo "Error: Comando desconocido '$1'"
        show_help
        exit 1
        ;;
esac
