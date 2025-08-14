#!/bin/bash
#
# Script para iniciar el entorno usando imágenes ya construidas
#

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función de ayuda
show_help() {
    echo "Uso: $0 [comando] [opciones] [servicio]"
    echo ""
    echo "Comandos disponibles:"
    echo "  start [servicio]   Iniciar todos los servicios o uno específico"
    echo "  stop [servicio]    Detener todos los servicios o uno específico"
    echo "  restart [servicio] Reiniciar todos los servicios o uno específico"
    echo "  full               Iniciar todos los servicios + verificar dashboard"
    echo "  status             Mostrar estado de los servicios"
    echo "  logs [servicio]    Mostrar logs (opcional: servicio específico)"
    echo "  build              Reconstruir imágenes faltantes"
    echo "  dashboard          Iniciar solo el dashboard (equivale a start dashboard)"
    echo "  help               Mostrar esta ayuda"
    echo ""
    echo "Servicios disponibles:"
    echo "  weblogic-a         WebLogic versión A (puerto 7001)"
    echo "  weblogic-b         WebLogic versión B (puerto 7002)"
    echo "  weblogic-ff        WebLogic Feature Flags (puerto 7003)"
    echo "  haproxy            HAProxy Load Balancer (puerto 8080)"
    echo "  dashboard          Dashboard Profesional (puerto 8001)"
    echo "  orcldb             Oracle Database (puerto 1521)"
    echo ""
    echo "Ejemplos:"
    echo "  $0 start                    # Iniciar todos los servicios"
    echo "  $0 full                     # Iniciar todo + verificar dashboard"
    echo "  $0 start dashboard          # Iniciar solo el dashboard"
    echo "  $0 start haproxy dashboard  # Iniciar HAProxy y dashboard"
    echo "  $0 dashboard                # Atajo para iniciar dashboard"
    echo "  $0 logs weblogic-a          # Ver logs de WebLogic A"
    echo "  $0 status                   # Ver estado de todos los servicios"
    echo ""
}

# Verificar que las imágenes existan
check_images() {
    echo -e "${BLUE}Verificando imágenes requeridas...${NC}"
    
    local required_images=(
        "weblogic-version-a:latest"
        "weblogic-version-b:latest"
        "weblogic-feature-flags:latest"
        "haproxy-advanced:latest"
        "edissonz8809/oracle-express-db:latest"
    )
    
    local missing_images=()
    
    for image in "${required_images[@]}"; do
        if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$image$"; then
            missing_images+=("$image")
        fi
    done
    
    if [ ${#missing_images[@]} -gt 0 ]; then
        echo -e "${RED}Error: Faltan las siguientes imágenes:${NC}"
        for image in "${missing_images[@]}"; do
            echo -e "${RED}- $image${NC}"
        done
        echo ""
        echo -e "${YELLOW}Para construir las imágenes faltantes, ejecuta:${NC}"
        echo -e "${YELLOW}  ./build.sh${NC}"
        echo ""
        return 1
    fi
    
    echo -e "${GREEN}✓ Todas las imágenes requeridas están disponibles${NC}"
    return 0
}

# Mostrar estado de los servicios
show_status() {
    echo -e "${BLUE}=== Estado de los servicios ===${NC}"
    docker-compose -f config/docker-compose-images.yml ps
    echo ""
    
    echo -e "${BLUE}=== URLs de acceso ===${NC}"
    echo -e "WebLogic A (version-a):     ${YELLOW}http://localhost:7001/console${NC}"
    echo -e "WebLogic B (version-b):     ${YELLOW}http://localhost:7002/console${NC}"
    echo -e "WebLogic FF (feature-flags): ${YELLOW}http://localhost:7003/console${NC}"
    echo -e "HAProxy Frontend:           ${YELLOW}http://localhost:8080${NC}"
    echo -e "HAProxy Stats:              ${YELLOW}http://localhost:8404/stats${NC}"
    echo -e "HAProxy Admin UI:           ${YELLOW}http://localhost:8082${NC}"
    echo -e "Dashboard Profesional:      ${YELLOW}http://localhost:8080/dashboard/${NC}"
    echo -e "Dashboard Directo:          ${YELLOW}http://localhost:8001/${NC}"
    echo -e "Oracle Database:            ${YELLOW}localhost:1521${NC}"
    echo -e "Oracle Enterprise Manager:  ${YELLOW}http://localhost:5500/em${NC}"
    echo ""
}

# Función principal
main() {
    local command="${1:-help}"
    shift || true  # Remover el primer argumento (comando)
    local services=("$@")  # Resto de argumentos son servicios
    
    case "$command" in
        start)
            if [ ${#services[@]} -eq 0 ]; then
                echo -e "${GREEN}=== Iniciando todos los servicios con imágenes construidas ===${NC}"
                if check_images; then
                    docker-compose -f config/docker-compose-images.yml up -d
                    echo ""
                    echo -e "${GREEN}✓ Todos los servicios iniciados correctamente${NC}"
                    show_status
                fi
            else
                echo -e "${GREEN}=== Iniciando servicios específicos: ${services[*]} ===${NC}"
                if check_images; then
                    for service in "${services[@]}"; do
                        echo -e "${BLUE}Iniciando $service...${NC}"
                        docker-compose -f config/docker-compose-images.yml up -d "$service"
                    done
                    echo ""
                    echo -e "${GREEN}✓ Servicios ${services[*]} iniciados correctamente${NC}"
                    show_status
                fi
            fi
            ;;
        stop)
            if [ ${#services[@]} -eq 0 ]; then
                echo -e "${YELLOW}=== Deteniendo todos los servicios ===${NC}"
                docker-compose -f config/docker-compose-images.yml down
                echo -e "${GREEN}✓ Todos los servicios detenidos${NC}"
            else
                echo -e "${YELLOW}=== Deteniendo servicios específicos: ${services[*]} ===${NC}"
                for service in "${services[@]}"; do
                    echo -e "${BLUE}Deteniendo $service...${NC}"
                    docker-compose -f config/docker-compose-images.yml stop "$service"
                done
                echo -e "${GREEN}✓ Servicios ${services[*]} detenidos${NC}"
            fi
            ;;
        restart)
            if [ ${#services[@]} -eq 0 ]; then
                echo -e "${YELLOW}=== Reiniciando todos los servicios ===${NC}"
                docker-compose -f config/docker-compose-images.yml restart
                echo -e "${GREEN}✓ Todos los servicios reiniciados${NC}"
                show_status
            else
                echo -e "${YELLOW}=== Reiniciando servicios específicos: ${services[*]} ===${NC}"
                for service in "${services[@]}"; do
                    echo -e "${BLUE}Reiniciando $service...${NC}"
                    docker-compose -f config/docker-compose-images.yml restart "$service"
                done
                echo -e "${GREEN}✓ Servicios ${services[*]} reiniciados${NC}"
                show_status
            fi
            ;;
        full)
            echo -e "${GREEN}=== Iniciando Entorno Completo con Dashboard ===${NC}"
            echo
            
            # Paso 1: Iniciar todos los servicios
            echo -e "${BLUE}1. Iniciando todos los servicios...${NC}"
            if check_images; then
                docker-compose -f config/docker-compose-images.yml up -d
                echo -e "${GREEN}✓ Todos los servicios iniciados${NC}"
            else
                echo -e "${RED}✗ Error al verificar imágenes${NC}"
                exit 1
            fi
            
            # Paso 2: Esperar y verificar dashboard
            echo
            echo -e "${BLUE}2. Verificando dashboard...${NC}"
            sleep 10
            
            if docker ps | grep -q "dashboard"; then
                echo -e "${GREEN}✓ Dashboard está ejecutándose${NC}"
            else
                echo -e "${YELLOW}⚠ Dashboard no detectado, iniciando específicamente...${NC}"
                docker-compose -f config/docker-compose-images.yml up -d dashboard
                sleep 5
            fi
            
            # Paso 3: Verificar conectividad
            echo
            echo -e "${BLUE}3. Verificando conectividad...${NC}"
            
            # Verificar acceso directo
            if curl -s --max-time 10 http://localhost:8001/api/health >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Dashboard accesible directamente (puerto 8001)${NC}"
            else
                echo -e "${YELLOW}⚠ Dashboard no accesible directamente${NC}"
            fi
            
            # Verificar acceso vía HAProxy
            if curl -s --max-time 10 http://localhost:8080/dashboard/api/health >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Dashboard accesible vía HAProxy (puerto 8080/dashboard)${NC}"
            else
                echo -e "${YELLOW}⚠ Dashboard no accesible vía HAProxy${NC}"
            fi
            
            echo
            echo -e "${GREEN}=== Entorno Completo Iniciado ===${NC}"
            echo
            echo -e "${BLUE}URLs Principales:${NC}"
            echo -e "🌐 HAProxy Frontend:           ${YELLOW}http://localhost:8080${NC}"
            echo -e "📊 Dashboard Profesional:      ${YELLOW}http://localhost:8080/dashboard/${NC}"
            echo -e "🔧 Dashboard Directo:          ${YELLOW}http://localhost:8001/${NC}"
            echo -e "📈 HAProxy Stats:              ${YELLOW}http://localhost:8404/stats${NC}"
            echo
            show_status
            ;;
        dashboard)
            echo -e "${GREEN}=== Iniciando Dashboard Profesional ===${NC}"
            if check_images; then
                # Asegurar que HAProxy esté ejecutándose (dependencia del dashboard)
                if ! docker ps | grep -q "haproxy"; then
                    echo -e "${BLUE}Iniciando HAProxy (requerido para el dashboard)...${NC}"
                    docker-compose -f config/docker-compose-images.yml up -d haproxy
                    sleep 5
                fi
                
                echo -e "${BLUE}Iniciando dashboard...${NC}"
                docker-compose -f config/docker-compose-images.yml up -d dashboard
                
                echo ""
                echo -e "${GREEN}✓ Dashboard iniciado correctamente${NC}"
                echo ""
                echo -e "${BLUE}=== URLs del Dashboard ===${NC}"
                echo -e "Dashboard vía HAProxy:      ${YELLOW}http://localhost:8080/dashboard/${NC}"
                echo -e "Dashboard directo:          ${YELLOW}http://localhost:8001/${NC}"
                echo -e "API Health Check:           ${YELLOW}http://localhost:8080/dashboard/api/health${NC}"
                echo -e "API Estadísticas:           ${YELLOW}http://localhost:8080/dashboard/api/stats${NC}"
                echo ""
                echo -e "${BLUE}Para probar el dashboard completo, ejecuta:${NC}"
                echo -e "${YELLOW}  ./scripts/test-dashboard.sh${NC}"
            fi
            ;;
        status)
            show_status
            ;;
        logs)
            if [ ${#services[@]} -gt 0 ]; then
                for service in "${services[@]}"; do
                    echo -e "${BLUE}=== Logs de $service ===${NC}"
                    docker-compose -f config/docker-compose-images.yml logs -f "$service"
                done
            else
                echo -e "${BLUE}=== Logs de todos los servicios ===${NC}"
                docker-compose -f config/docker-compose-images.yml logs -f
            fi
            ;;
        build)
            echo -e "${YELLOW}=== Construyendo imágenes faltantes ===${NC}"
            ./build.sh
            ;;
        help)
            show_help
            ;;
        *)
            echo -e "${RED}Error: Comando desconocido '$command'${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
