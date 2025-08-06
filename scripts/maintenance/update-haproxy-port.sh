#!/bin/bash

# Script para actualizar dinámicamente el puerto del Load Balancer HAProxy
# Uso: ./update-haproxy-port.sh [nuevo_puerto]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_COMPOSE_FILE="$PROJECT_DIR/config/docker-compose.yml"
PUERTOS_CONFIG_FILE="$PROJECT_DIR/PUERTOS_CONFIGURACION.md"

# Función para mostrar ayuda
show_help() {
    echo "🔧 Actualizador de Puerto HAProxy Load Balancer"
    echo ""
    echo "Uso:"
    echo "  $0 [nuevo_puerto]     # Usar puerto específico"
    echo "  $0 auto              # Encontrar puerto libre automáticamente"
    echo "  $0 --help            # Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 8085              # Cambiar a puerto 8085"
    echo "  $0 auto              # Encontrar puerto libre automáticamente"
}

# Función para obtener el puerto actual
get_current_port() {
    grep -E '^\s*-\s*"[0-9]+:80"' "$DOCKER_COMPOSE_FILE" | sed 's/.*"\([0-9]*\):80".*/\1/' | head -1
}

# Función para actualizar el puerto en docker-compose.yml
update_docker_compose() {
    local nuevo_puerto=$1
    local puerto_actual=$(get_current_port)
    
    echo "🔄 Actualizando docker-compose.yml..."
    echo "   Puerto actual: $puerto_actual"
    echo "   Puerto nuevo:  $nuevo_puerto"
    
    # Crear backup
    cp "$DOCKER_COMPOSE_FILE" "$DOCKER_COMPOSE_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Actualizar el puerto en docker-compose.yml
    sed -i "s/\"$puerto_actual:80\"/\"$nuevo_puerto:80\"/" "$DOCKER_COMPOSE_FILE"
    
    echo "✅ docker-compose.yml actualizado"
}

# Función para actualizar la documentación
update_documentation() {
    local nuevo_puerto=$1
    local puerto_actual=$(get_current_port)
    
    echo "📝 Actualizando documentación..."
    
    # Actualizar PUERTOS_CONFIGURACION.md
    if [[ -f "$PUERTOS_CONFIG_FILE" ]]; then
        cp "$PUERTOS_CONFIG_FILE" "$PUERTOS_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        sed -i "s/| HAProxy Load Balancer.*| http:\/\/localhost:$puerto_actual/| HAProxy Load Balancer      | http:\/\/localhost:$nuevo_puerto/" "$PUERTOS_CONFIG_FILE"
        sed -i "s/http:\/\/localhost:$puerto_actual/http:\/\/localhost:$nuevo_puerto/g" "$PUERTOS_CONFIG_FILE"
        echo "✅ PUERTOS_CONFIGURACION.md actualizado"
    fi
}

# Función para verificar si el puerto está libre
check_port_available() {
    local puerto=$1
    if netstat -tlnp 2>/dev/null | grep -q ":$puerto "; then
        echo "❌ Error: El puerto $puerto ya está en uso"
        echo "   Procesos usando el puerto:"
        netstat -tlnp 2>/dev/null | grep ":$puerto " || echo "   (No se puede determinar el proceso)"
        return 1
    fi
    return 0
}

# Función principal
main() {
    local nuevo_puerto=""
    
    # Verificar argumentos
    if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    # Verificar que existe docker-compose.yml
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        echo "❌ Error: No se encontró $DOCKER_COMPOSE_FILE"
        exit 1
    fi
    
    # Obtener puerto actual
    local puerto_actual=$(get_current_port)
    if [[ -z "$puerto_actual" ]]; then
        echo "❌ Error: No se pudo determinar el puerto actual de HAProxy"
        exit 1
    fi
    
    echo "🔍 Puerto actual del Load Balancer: $puerto_actual"
    
    # Determinar nuevo puerto
    if [[ "$1" == "auto" ]]; then
        echo "🤖 Buscando puerto libre automáticamente..."
        nuevo_puerto=$("$SCRIPT_DIR/find-free-port.sh" 8083 8099 --quiet)
        if [[ $? -ne 0 ]] || [[ -z "$nuevo_puerto" ]]; then
            echo "❌ Error: No se pudo encontrar un puerto libre"
            exit 1
        fi
        echo "✅ Puerto libre encontrado: $nuevo_puerto"
    else
        nuevo_puerto="$1"
        # Validar que es un número
        if ! [[ "$nuevo_puerto" =~ ^[0-9]+$ ]]; then
            echo "❌ Error: '$nuevo_puerto' no es un puerto válido"
            exit 1
        fi
        
        # Verificar rango válido
        if [[ $nuevo_puerto -lt 1024 ]] || [[ $nuevo_puerto -gt 65535 ]]; then
            echo "❌ Error: El puerto debe estar entre 1024 y 65535"
            exit 1
        fi
    fi
    
    # Verificar si el puerto está disponible
    if ! check_port_available "$nuevo_puerto"; then
        exit 1
    fi
    
    # Verificar si es el mismo puerto
    if [[ "$nuevo_puerto" == "$puerto_actual" ]]; then
        echo "ℹ️  El puerto $nuevo_puerto ya está configurado"
        exit 0
    fi
    
    echo ""
    echo "🚀 Configurando Load Balancer en puerto $nuevo_puerto..."
    echo ""
    
    # Actualizar configuraciones
    update_docker_compose "$nuevo_puerto"
    update_documentation "$nuevo_puerto"
    
    echo ""
    echo "✅ ¡Configuración actualizada exitosamente!"
    echo ""
    echo "📋 Resumen de cambios:"
    echo "   • Puerto anterior: $puerto_actual"
    echo "   • Puerto nuevo:    $nuevo_puerto"
    echo "   • URL de acceso:   http://localhost:$nuevo_puerto"
    echo ""
    echo "🔄 Para aplicar los cambios:"
    echo "   docker-compose down && docker-compose up -d haproxy"
    echo ""
    echo "🔗 Acceso al Load Balancer:"
    echo "   http://localhost:$nuevo_puerto"
    echo ""
}

# Ejecutar función principal
main "$@"
