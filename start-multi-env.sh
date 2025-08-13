#!/bin/bash

# Script para iniciar el entorno usando docker-compose-multi-env.yml
# Incluye el dashboard profesional integrado

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
    echo "  build [servicio]   Construir imágenes de todos los servicios o uno específico"
    echo "  status             Mostrar estado de los servicios"
    echo "  logs [servicio]    Mostrar logs (opcional: servicio específico)"
    echo "  dashboard          Iniciar solo el dashboard (equivale a start dashboard)"
    echo "  full               Iniciar todos los servicios + verificar dashboard"
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
    echo "  $0 build                    # Construir todas las imágenes"
    echo "  $0 logs dashboard           # Ver logs del dashboard"
    echo "  $0 status                   # Ver estado de todos los servicios"
    echo ""
}

# Mostrar estado de los servicios
show_status() {
    echo -e "${BLUE}=== Estado de los servicios ===${NC}"
    docker-compose -f config/docker-compose-multi-env.yml ps
    echo ""
    
    echo -e "${BLUE}=== URLs de acceso ===${NC}"
    echo -e "🌐 HAProxy Frontend:           ${YELLOW}http://localhost:8080${NC}"
    echo -e "📊 Dashboard Profesional:      ${YELLOW}http://localhost:8080/dashboard/${NC}"
    echo -e "🔧 Dashboard Directo:          ${YELLOW}http://localhost:8001/${NC}"
    echo -e "📈 HAProxy Stats:              ${YELLOW}http://localhost:8404/stats${NC}"
    echo -e "⚙️  HAProxy Admin UI:           ${YELLOW}http://localhost:8082${NC}"
    echo -e "🅰️  WebLogic A:                 ${YELLOW}http://localhost:7001/console${NC}"
    echo -e "🅱️  WebLogic B:                 ${YELLOW}http://localhost:7002/console${NC}"
    echo -e "🚩 WebLogic Feature Flags:     ${YELLOW}http://localhost:7003/console${NC}"
    echo -e "🗄️  Oracle Database:            ${YELLOW}localhost:1521${NC}"
    echo -e "🗄️  Oracle Enterprise Manager:  ${YELLOW}http://localhost:5500/em${NC}"
    echo ""
}

# Función para mostrar estado
show_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        return 1
    fi
}

# Función principal
main() {
    local command="${1:-help}"
    shift || true  # Remover el primer argumento (comando)
    local services=("$@")  # Resto de argumentos son servicios
    
    case "$command" in
        start)
            if [ ${#services[@]} -eq 0 ]; then
                echo -e "${GREEN}=== Iniciando todos los servicios (Multi-Env) ===${NC}"
                docker-compose -f config/docker-compose-multi-env.yml up -d
                echo ""
                echo -e "${GREEN}✓ Todos los servicios iniciados correctamente${NC}"
                show_status
            else
                echo -e "${GREEN}=== Iniciando servicios específicos: ${services[*]} ===${NC}"
                for service in "${services[@]}"; do
                    echo -e "${BLUE}Iniciando $service...${NC}"
                    docker-compose -f config/docker-compose-multi-env.yml up -d "$service"
                done
                echo ""
                echo -e "${GREEN}✓ Servicios ${services[*]} iniciados correctamente${NC}"
                show_status
            fi
            ;;
        stop)
            if [ ${#services[@]} -eq 0 ]; then
                echo -e "${YELLOW}=== Deteniendo todos los servicios ===${NC}"
                docker-compose -f config/docker-compose-multi-env.yml down
                echo -e "${GREEN}✓ Todos los servicios detenidos${NC}"
            else
                echo -e "${YELLOW}=== Deteniendo servicios específicos: ${services[*]} ===${NC}"
                for service in "${services[@]}"; do
                    echo -e "${BLUE}Deteniendo $service...${NC}"
                    docker-compose -f config/docker-compose-multi-env.yml stop "$service"
                done
                echo -e "${GREEN}✓ Servicios ${services[*]} detenidos${NC}"
            fi
            ;;
        restart)
            if [ ${#services[@]} -eq 0 ]; then
                echo -e "${YELLOW}=== Reiniciando todos los servicios ===${NC}"
                docker-compose -f config/docker-compose-multi-env.yml restart
                echo -e "${GREEN}✓ Todos los servicios reiniciados${NC}"
                show_status
            else
                echo -e "${YELLOW}=== Reiniciando servicios específicos: ${services[*]} ===${NC}"
                for service in "${services[@]}"; do
                    echo -e "${BLUE}Reiniciando $service...${NC}"
                    docker-compose -f config/docker-compose-multi-env.yml restart "$service"
                done
                echo -e "${GREEN}✓ Servicios ${services[*]} reiniciados${NC}"
                show_status
            fi
            ;;
        build)
            if [ ${#services[@]} -eq 0 ]; then
                echo -e "${BLUE}=== Construyendo todas las imágenes ===${NC}"
                docker-compose -f config/docker-compose-multi-env.yml build
                echo -e "${GREEN}✓ Todas las imágenes construidas${NC}"
            else
                echo -e "${BLUE}=== Construyendo servicios específicos: ${services[*]} ===${NC}"
                for service in "${services[@]}"; do
                    echo -e "${BLUE}Construyendo $service...${NC}"
                    docker-compose -f config/docker-compose-multi-env.yml build "$service"
                done
                echo -e "${GREEN}✓ Servicios ${services[*]} construidos${NC}"
            fi
            ;;
        full)
            echo -e "${GREEN}=== Iniciando Entorno Completo con Dashboard (Multi-Env) ===${NC}"
            echo
            
            # Paso 1: Verificar y limpiar si es necesario
            echo -e "${BLUE}0. Verificando estado actual...${NC}"
            
            # Verificar si hay contenedores problemáticos
            if docker ps -a | grep -E "(weblogic|haproxy|dashboard|orcldb)" | grep -q "Exited\|Dead\|Restarting"; then
                echo -e "${YELLOW}⚠ Detectados contenedores en estado problemático${NC}"
                echo -e "${BLUE}Limpiando contenedores problemáticos...${NC}"
                docker-compose -f config/docker-compose-multi-env.yml down --remove-orphans 2>/dev/null || true
                sleep 2
            fi
            
            # Paso 1: Iniciar todos los servicios
            echo -e "${BLUE}1. Iniciando todos los servicios...${NC}"
            
            if docker-compose -f config/docker-compose-multi-env.yml up -d; then
                echo -e "${GREEN}✓ Todos los servicios iniciados${NC}"
            else
                echo -e "${RED}✗ Error al iniciar servicios${NC}"
                echo -e "${YELLOW}Intentando limpieza y reinicio...${NC}"
                
                # Limpieza en caso de error
                docker-compose -f config/docker-compose-multi-env.yml down --remove-orphans 2>/dev/null || true
                sleep 3
                
                # Segundo intento
                echo -e "${BLUE}Segundo intento de inicio...${NC}"
                if docker-compose -f config/docker-compose-multi-env.yml up -d; then
                    echo -e "${GREEN}✓ Servicios iniciados en segundo intento${NC}"
                else
                    echo -e "${RED}✗ Error persistente al iniciar servicios${NC}"
                    echo -e "${YELLOW}Mostrando logs de error...${NC}"
                    docker-compose -f config/docker-compose-multi-env.yml logs --tail=20
                    exit 1
                fi
            fi
            
            # Paso 2: Esperar y verificar dashboard
            echo
            echo -e "${BLUE}2. Verificando dashboard...${NC}"
            sleep 10
            
            if docker ps | grep -q "dashboard"; then
                show_result 0 "Dashboard está ejecutándose"
            else
                echo -e "${YELLOW}⚠ Dashboard no detectado, iniciando específicamente...${NC}"
                docker-compose -f config/docker-compose-multi-env.yml up -d dashboard
                sleep 5
                
                if docker ps | grep -q "dashboard"; then
                    show_result 0 "Dashboard iniciado específicamente"
                else
                    show_result 1 "Error al iniciar dashboard"
                    echo -e "${YELLOW}Logs del dashboard:${NC}"
                    docker-compose -f config/docker-compose-multi-env.yml logs dashboard
                fi
            fi
            
            # Paso 3: Verificar conectividad
            echo
            echo -e "${BLUE}3. Verificando conectividad...${NC}"
            
            # Dar tiempo adicional para que los servicios estén listos
            echo "Esperando que los servicios estén completamente listos..."
            sleep 15
            
            # Verificar acceso directo
            if curl -s --max-time 10 http://localhost:8001/api/health >/dev/null 2>&1; then
                show_result 0 "Dashboard accesible directamente (puerto 8001)"
            else
                show_result 1 "Dashboard no accesible directamente"
                echo -e "${YELLOW}Verificando si el contenedor está ejecutándose...${NC}"
                docker ps | grep dashboard || echo "Contenedor dashboard no encontrado"
            fi
            
            # Verificar acceso vía HAProxy
            if curl -s --max-time 10 http://localhost:8080/dashboard/api/health >/dev/null 2>&1; then
                show_result 0 "Dashboard accesible vía HAProxy (puerto 8080/dashboard)"
            else
                show_result 1 "Dashboard no accesible vía HAProxy"
                echo -e "${YELLOW}Verificando HAProxy...${NC}"
                if curl -s --max-time 5 http://localhost:8080 >/dev/null 2>&1; then
                    echo -e "${YELLOW}HAProxy está funcionando, pero no puede acceder al dashboard${NC}"
                else
                    echo -e "${YELLOW}HAProxy no está accesible${NC}"
                fi
            fi
            
            echo
            echo -e "${GREEN}=== Entorno Completo Iniciado ===${NC}"
            show_status
            ;;
        dashboard)
            echo -e "${GREEN}=== Iniciando Dashboard Profesional (Multi-Env) ===${NC}"
            
            # Asegurar que HAProxy esté ejecutándose (dependencia del dashboard)
            if ! docker ps | grep -q "haproxy"; then
                echo -e "${BLUE}Iniciando HAProxy (requerido para el dashboard)...${NC}"
                docker-compose -f config/docker-compose-multi-env.yml up -d haproxy
                sleep 5
            fi
            
            echo -e "${BLUE}Iniciando dashboard...${NC}"
            docker-compose -f config/docker-compose-multi-env.yml up -d dashboard
            
            echo ""
            echo -e "${GREEN}✓ Dashboard iniciado correctamente${NC}"
            echo ""
            echo -e "${BLUE}=== URLs del Dashboard ===${NC}"
            echo -e "Dashboard vía HAProxy:      ${YELLOW}http://localhost:8080/dashboard/${NC}"
            echo -e "Dashboard directo:          ${YELLOW}http://localhost:8001/${NC}"
            echo -e "API Health Check:           ${YELLOW}http://localhost:8080/dashboard/api/health${NC}"
            echo -e "API Estadísticas:           ${YELLOW}http://localhost:8080/dashboard/api/stats${NC}"
            ;;
        status)
            show_status
            ;;
        logs)
            if [ ${#services[@]} -gt 0 ]; then
                for service in "${services[@]}"; do
                    echo -e "${BLUE}=== Logs de $service ===${NC}"
                    docker-compose -f config/docker-compose-multi-env.yml logs -f "$service"
                done
            else
                echo -e "${BLUE}=== Logs de todos los servicios ===${NC}"
                docker-compose -f config/docker-compose-multi-env.yml logs -f
            fi
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
