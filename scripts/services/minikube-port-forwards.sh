#!/bin/bash
#
# Script para manejar port-forwards de Minikube
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Archivo para almacenar PIDs de port-forwards
PID_FILE="/tmp/minikube-port-forwards.pid"

# Función para mostrar ayuda
show_help() {
    echo -e "${CYAN}=== Gestor de Port-Forwards Minikube ===${NC}"
    echo ""
    echo -e "${YELLOW}Uso: $0 [COMANDO]${NC}"
    echo ""
    echo -e "${BLUE}Comandos disponibles:${NC}"
    echo "  start     Iniciar todos los port-forwards"
    echo "  stop      Detener todos los port-forwards"
    echo "  status    Mostrar estado de los port-forwards"
    echo "  list      Listar servicios disponibles"
    echo ""
}

# Función para verificar si Minikube está corriendo
check_minikube() {
    if ! minikube status >/dev/null 2>&1; then
        echo -e "${RED}Error: Minikube no está corriendo${NC}"
        echo -e "${YELLOW}Inicia Minikube con: minikube start${NC}"
        exit 1
    fi
}

# Función para listar servicios
list_services() {
    echo -e "${BLUE}=== Servicios disponibles en Minikube ===${NC}"
    kubectl get services --all-namespaces
}

# Función para iniciar port-forwards
start_port_forwards() {
    check_minikube
    
    echo -e "${BLUE}=== Iniciando Port-Forwards de Minikube ===${NC}"
    
    # Limpiar archivo de PIDs anterior
    > "$PID_FILE"
    
    # Array de port-forwards a configurar
    # Formato: "namespace:service:local_port:remote_port:description"
    declare -a port_forwards=(
        "backstage-demo:backstage:3000:7007:Backstage"
        "jenkins:jenkins:8090:8083:Jenkins"
        "kubernetes-dashboard:kubernetes-dashboard:8443:80:Kubernetes Dashboard"
        "backstage-demo:backstage-simple:3001:7007:Backstage Simple"
    )
    
    # Iniciar cada port-forward
    for pf in "${port_forwards[@]}"; do
        IFS=':' read -r namespace service local_port remote_port description <<< "$pf"
        
        # Verificar si el servicio existe
        if kubectl get service "$service" -n "$namespace" >/dev/null 2>&1; then
            echo -e "${YELLOW}Iniciando port-forward para $description...${NC}"
            
            # Iniciar port-forward en background
            kubectl port-forward -n "$namespace" "service/$service" "$local_port:$remote_port" >/dev/null 2>&1 &
            
            # Guardar PID
            echo "$! $description $local_port" >> "$PID_FILE"
            
            # Verificar que se inició correctamente
            sleep 2
            if kill -0 $! 2>/dev/null; then
                echo -e "${GREEN}✓ $description disponible en http://localhost:$local_port${NC}"
            else
                echo -e "${RED}✗ Error iniciando port-forward para $description${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ Servicio $service no encontrado en namespace $namespace${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}=== Port-forwards iniciados ===${NC}"
    echo -e "${YELLOW}Para detener: $0 stop${NC}"
    echo -e "${YELLOW}Para ver estado: $0 status${NC}"
}

# Función para detener port-forwards
stop_port_forwards() {
    echo -e "${BLUE}=== Deteniendo Port-Forwards ===${NC}"
    
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}No hay port-forwards activos${NC}"
        return
    fi
    
    while IFS=' ' read -r pid description port; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo -e "${YELLOW}Deteniendo $description (puerto $port)...${NC}"
            kill "$pid" 2>/dev/null
            echo -e "${GREEN}✓ $description detenido${NC}"
        else
            echo -e "${YELLOW}⚠ $description ya no está corriendo${NC}"
        fi
    done < "$PID_FILE"
    
    # Limpiar archivo de PIDs
    rm -f "$PID_FILE"
    
    echo -e "${GREEN}=== Todos los port-forwards detenidos ===${NC}"
}

# Función para mostrar estado
show_status() {
    echo -e "${BLUE}=== Estado de Port-Forwards ===${NC}"
    
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}No hay port-forwards configurados${NC}"
        return
    fi
    
    echo ""
    while IFS=' ' read -r pid description port; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}✓ ACTIVO${NC}   $description - http://localhost:$port (PID: $pid)"
        else
            echo -e "${RED}✗ INACTIVO${NC} $description - puerto $port"
        fi
    done < "$PID_FILE"
    
    echo ""
    echo -e "${BLUE}=== Puertos en uso ===${NC}"
    netstat -tlnp 2>/dev/null | grep -E ':(3000|3001|8090|8443)' | while read line; do
        echo "  $line"
    done
}

# Función principal
main() {
    case "${1:-}" in
        start)
            start_port_forwards
            ;;
        stop)
            stop_port_forwards
            ;;
        status)
            show_status
            ;;
        list)
            list_services
            ;;
        --help|-h|help|"")
            show_help
            ;;
        *)
            echo -e "${RED}Comando no reconocido: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
