#!/bin/bash

# =============================================================================
# SCRIPT DE CARGA DE VARIABLES DE ENTORNO
# =============================================================================
# Este script carga las variables de entorno desde el archivo .env
# y las hace disponibles para otros scripts del sistema.

set -e

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

# Función para cargar variables de entorno
load_env() {
    if [[ -f "$ENV_FILE" ]]; then
        echo "🔧 Cargando configuración desde: $ENV_FILE"
        
        # Exportar variables de entorno
        set -a  # Automatically export all variables
        source "$ENV_FILE"
        set +a  # Stop automatically exporting
        
        echo "✅ Variables de entorno cargadas correctamente"
        return 0
    else
        echo "❌ Error: Archivo .env no encontrado en: $ENV_FILE"
        echo "💡 Ejecuta: cp .env.example .env y configura las variables"
        return 1
    fi
}

# Función para validar variables críticas
validate_env() {
    local required_vars=(
        "WEBLOGIC_A_PORT"
        "WEBLOGIC_B_PORT"
        "HAPROXY_HTTP_PORT"
        "HAPROXY_STATS_PORT"
        "HAPROXY_UI_PORT"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo "❌ Error: Variables de entorno faltantes:"
        printf "   - %s\n" "${missing_vars[@]}"
        return 1
    fi
    
    echo "✅ Todas las variables críticas están configuradas"
    return 0
}

# Función para mostrar configuración actual
show_config() {
    echo ""
    echo "📋 CONFIGURACIÓN ACTUAL:"
    echo "========================"
    echo "WebLogic A:     ${WEBLOGIC_A_URL}"
    echo "WebLogic B:     ${WEBLOGIC_B_URL}"
    echo "HAProxy HTTP:   ${HAPROXY_HTTP_URL}"
    echo "HAProxy HTTPS:  ${HAPROXY_HTTPS_URL}"
    echo "HAProxy Stats:  ${HAPROXY_STATS_URL}"
    echo "HAProxy UI:     ${HAPROXY_UI_URL}"
    echo "HAProxy API:    ${HAPROXY_API_URL}"
    echo "MkDocs Main:    ${MKDOCS_MAIN_URL}"
    echo "MkDocs Dev:     ${MKDOCS_DEV_URL}"
    echo "Feature Flags:  ${FEATURE_FLAGS_URL}"
    echo ""
}

# Función para generar archivo de ejemplo
generate_example() {
    local example_file="${PROJECT_ROOT}/.env.example"
    
    if [[ -f "$ENV_FILE" ]]; then
        echo "🔧 Generando archivo de ejemplo..."
        cp "$ENV_FILE" "$example_file"
        echo "✅ Archivo .env.example generado"
    else
        echo "❌ Error: No se puede generar ejemplo, .env no existe"
        return 1
    fi
}

# Función principal
main() {
    case "${1:-load}" in
        "load")
            load_env && validate_env
            ;;
        "show")
            load_env && show_config
            ;;
        "validate")
            load_env && validate_env
            ;;
        "example")
            generate_example
            ;;
        "help"|"-h"|"--help")
            echo "Uso: $0 [comando]"
            echo ""
            echo "Comandos:"
            echo "  load      Cargar variables de entorno (por defecto)"
            echo "  show      Mostrar configuración actual"
            echo "  validate  Validar variables críticas"
            echo "  example   Generar archivo .env.example"
            echo "  help      Mostrar esta ayuda"
            ;;
        *)
            echo "❌ Comando desconocido: $1"
            echo "💡 Usa '$0 help' para ver los comandos disponibles"
            return 1
            ;;
    esac
}

# Ejecutar función principal si el script se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
