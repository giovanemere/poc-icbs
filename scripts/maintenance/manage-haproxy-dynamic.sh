#!/bin/bash

# Script maestro para gestionar HAProxy con puerto dinámico
# Uso: ./manage-haproxy-dynamic.sh [start|stop|restart|status|change-port]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Función para mostrar ayuda
show_help() {
    echo "🔧 Gestor HAProxy Load Balancer Dinámico"
    echo ""
    echo "Uso:"
    echo "  $0 start              # Iniciar HAProxy con puerto dinámico"
    echo "  $0 stop               # Detener HAProxy"
    echo "  $0 restart            # Reiniciar HAProxy con puerto dinámico"
    echo "  $0 status             # Mostrar estado de HAProxy"
    echo "  $0 change-port [auto|puerto]  # Cambiar puerto (auto=automático)"
    echo "  $0 --help             # Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 start              # Iniciar con puerto libre automático"
    echo "  $0 change-port auto   # Cambiar a puerto libre automático"
    echo "  $0 change-port 8085   # Cambiar a puerto específico"
}

# Función para obtener el puerto actual
get_current_port() {
    grep -E '^\s*-\s*"[0-9]+:80"' "$PROJECT_DIR/config/docker-compose.yml" | sed 's/.*"\([0-9]*\):80".*/\1/' | head -1
}

# Función para verificar si HAProxy está corriendo
is_haproxy_running() {
    docker ps --filter "name=haproxy" --format "{{.Names}}" | grep -q "haproxy"
}

# Función para mostrar estado
show_status() {
    local puerto=$(get_current_port)
    
    echo "📊 Estado de HAProxy Load Balancer"
    echo ""
    
    if is_haproxy_running; then
        echo "✅ Estado: CORRIENDO"
        echo "🔌 Puerto configurado: $puerto"
        echo "🔗 URL de acceso: http://localhost:$puerto"
        echo ""
        echo "📋 Información del contenedor:"
        docker ps --filter "name=haproxy" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        echo "🌐 URLs disponibles:"
        echo "   • Load Balancer:    http://localhost:$puerto"
        echo "   • HAProxy Stats:    http://localhost:8404/stats"
        echo "   • HAProxy Admin UI: http://localhost:8082"
        echo "   • HAProxy Admin API: http://localhost:8081"
        echo ""
        
        # Verificar conectividad
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:$puerto | grep -q "404\|200\|503"; then
            echo "✅ Load Balancer responde correctamente"
        else
            echo "⚠️  Load Balancer no responde en el puerto $puerto"
        fi
    else
        echo "❌ Estado: DETENIDO"
        echo "🔌 Puerto configurado: $puerto"
        echo "🔗 URL cuando esté activo: http://localhost:$puerto"
    fi
}

# Función para iniciar HAProxy
start_haproxy() {
    echo "🚀 Iniciando HAProxy Load Balancer..."
    echo ""
    
    if is_haproxy_running; then
        echo "⚠️  HAProxy ya está corriendo"
        show_status
        return 0
    fi
    
    # Ejecutar el script de inicio dinámico
    "$SCRIPT_DIR/start-haproxy-dynamic.sh"
}

# Función para detener HAProxy
stop_haproxy() {
    echo "🛑 Deteniendo HAProxy Load Balancer..."
    echo ""
    
    if ! is_haproxy_running; then
        echo "ℹ️  HAProxy ya está detenido"
        return 0
    fi
    
    cd "$PROJECT_DIR"
    docker-compose -f config/docker-compose.yml stop haproxy
    echo "✅ HAProxy detenido exitosamente"
}

# Función para reiniciar HAProxy
restart_haproxy() {
    echo "🔄 Reiniciando HAProxy Load Balancer..."
    echo ""
    
    stop_haproxy
    echo ""
    start_haproxy
}

# Función para cambiar puerto
change_port() {
    local nuevo_puerto="$1"
    
    if [[ -z "$nuevo_puerto" ]]; then
        echo "❌ Error: Debe especificar un puerto o 'auto'"
        echo "   Uso: $0 change-port [auto|puerto]"
        exit 1
    fi
    
    echo "🔧 Cambiando puerto de HAProxy..."
    echo ""
    
    # Actualizar puerto
    "$SCRIPT_DIR/update-haproxy-port.sh" "$nuevo_puerto"
    
    # Si HAProxy está corriendo, reiniciarlo
    if is_haproxy_running; then
        echo ""
        echo "🔄 Reiniciando HAProxy para aplicar cambios..."
        cd "$PROJECT_DIR"
        docker-compose -f config/docker-compose.yml stop haproxy
        docker-compose -f config/docker-compose.yml up -d haproxy
        
        echo ""
        echo "⏳ Esperando que HAProxy esté listo..."
        sleep 3
        
        show_status
    else
        echo ""
        echo "ℹ️  HAProxy no está corriendo. Use '$0 start' para iniciarlo."
    fi
}

# Función principal
main() {
    case "${1:-}" in
        "start")
            start_haproxy
            ;;
        "stop")
            stop_haproxy
            ;;
        "restart")
            restart_haproxy
            ;;
        "status")
            show_status
            ;;
        "change-port")
            change_port "$2"
            ;;
        "--help"|"-h"|"help"|"")
            show_help
            ;;
        *)
            echo "❌ Error: Comando desconocido '$1'"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
