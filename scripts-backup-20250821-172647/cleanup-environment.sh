#!/bin/bash

# Script de limpieza para el entorno Docker
# Útil cuando hay problemas con contenedores o configuraciones

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Script de Limpieza del Entorno Docker ===${NC}"
echo

# Función para mostrar estado
show_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        return 1
    fi
}

# Función de ayuda
show_help() {
    echo "Uso: $0 [opción]"
    echo ""
    echo "Opciones disponibles:"
    echo "  light      Limpieza ligera (solo contenedores del proyecto)"
    echo "  full       Limpieza completa (contenedores + redes + imágenes no utilizadas)"
    echo "  deep       Limpieza profunda (todo + volúmenes - ⚠️ ELIMINA DATOS)"
    echo "  status     Mostrar estado actual sin limpiar"
    echo "  help       Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 light     # Limpieza recomendada para problemas comunes"
    echo "  $0 full      # Limpieza más agresiva"
    echo "  $0 status    # Solo ver el estado actual"
    echo ""
}

# Función para mostrar estado actual
show_current_status() {
    echo -e "${BLUE}=== Estado Actual del Sistema ===${NC}"
    echo
    
    echo -e "${BLUE}Contenedores relacionados con el proyecto:${NC}"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(weblogic|haproxy|dashboard|orcldb|NAME)" || echo "No se encontraron contenedores del proyecto"
    
    echo
    echo -e "${BLUE}Redes Docker:${NC}"
    docker network ls | grep -E "(weblogic|bridge|NAME)" || echo "No se encontraron redes relacionadas"
    
    echo
    echo -e "${BLUE}Volúmenes del proyecto:${NC}"
    docker volume ls | grep -E "(weblogic|oracle|haproxy|dashboard|NAME)" || echo "No se encontraron volúmenes del proyecto"
    
    echo
    echo -e "${BLUE}Uso de espacio en disco:${NC}"
    docker system df 2>/dev/null || echo "No se pudo obtener información de espacio"
}

# Función de limpieza ligera
cleanup_light() {
    echo -e "${YELLOW}🧹 Iniciando limpieza ligera...${NC}"
    echo
    
    # Detener servicios del proyecto
    echo -e "${BLUE}1. Deteniendo servicios del proyecto...${NC}"
    docker-compose -f config/docker-compose-multi-env.yml down --remove-orphans 2>/dev/null && show_status 0 "Servicios detenidos" || show_status 1 "Error al detener servicios"
    
    # Limpiar procesos Python del HAProxy Deployment Manager
    echo -e "${BLUE}2. Limpiando procesos del HAProxy Deployment Manager...${NC}"
    docker exec haproxy pkill -f "admin_api.py" 2>/dev/null || true
    docker exec haproxy pkill -f "admin_ui.py" 2>/dev/null || true
    show_status 0 "Procesos del HAProxy Manager limpiados"
    
    # Limpiar contenedores detenidos
    echo -e "${BLUE}3. Limpiando contenedores detenidos...${NC}"
    docker container prune -f >/dev/null 2>&1 && show_status 0 "Contenedores detenidos limpiados" || show_status 1 "Error al limpiar contenedores"
    
    # Limpiar redes no utilizadas
    echo -e "${BLUE}4. Limpiando redes no utilizadas...${NC}"
    docker network prune -f >/dev/null 2>&1 && show_status 0 "Redes no utilizadas limpiadas" || show_status 1 "Error al limpiar redes"
    
    echo
    echo -e "${GREEN}✅ Limpieza ligera completada${NC}"
}

# Función de limpieza completa
cleanup_full() {
    echo -e "${YELLOW}🧹 Iniciando limpieza completa...${NC}"
    echo
    
    # Ejecutar limpieza ligera primero
    cleanup_light
    
    # Limpiar imágenes no utilizadas
    echo -e "${BLUE}4. Limpiando imágenes no utilizadas...${NC}"
    docker image prune -f >/dev/null 2>&1 && show_status 0 "Imágenes no utilizadas limpiadas" || show_status 1 "Error al limpiar imágenes"
    
    # Limpiar caché de build
    echo -e "${BLUE}5. Limpiando caché de build...${NC}"
    docker builder prune -f >/dev/null 2>&1 && show_status 0 "Caché de build limpiado" || show_status 1 "Error al limpiar caché de build"
    
    echo
    echo -e "${GREEN}✅ Limpieza completa terminada${NC}"
}

# Función de limpieza profunda
cleanup_deep() {
    echo -e "${RED}⚠️  ADVERTENCIA: Limpieza profunda eliminará TODOS los volúmenes${NC}"
    echo -e "${RED}⚠️  Esto incluye datos de la base de datos Oracle y logs${NC}"
    echo
    read -p "¿Estás seguro de que quieres continuar? (escribe 'SI' para confirmar): " confirm
    
    if [ "$confirm" != "SI" ]; then
        echo -e "${YELLOW}Limpieza profunda cancelada${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}🧹 Iniciando limpieza profunda...${NC}"
    echo
    
    # Ejecutar limpieza completa primero
    cleanup_full
    
    # Limpiar volúmenes
    echo -e "${BLUE}6. Limpiando volúmenes no utilizados...${NC}"
    docker volume prune -f >/dev/null 2>&1 && show_status 0 "Volúmenes no utilizados limpiados" || show_status 1 "Error al limpiar volúmenes"
    
    # Limpieza completa del sistema
    echo -e "${BLUE}7. Limpieza completa del sistema Docker...${NC}"
    docker system prune -a -f >/dev/null 2>&1 && show_status 0 "Sistema Docker limpiado completamente" || show_status 1 "Error en limpieza del sistema"
    
    echo
    echo -e "${GREEN}✅ Limpieza profunda completada${NC}"
    echo -e "${YELLOW}⚠️  Nota: Será necesario reconstruir todas las imágenes${NC}"
}

# Función principal
main() {
    local command="${1:-help}"
    
    case "$command" in
        light)
            cleanup_light
            echo
            show_current_status
            ;;
        full)
            cleanup_full
            echo
            show_current_status
            ;;
        deep)
            cleanup_deep
            echo
            show_current_status
            ;;
        status)
            show_current_status
            ;;
        help)
            show_help
            ;;
        *)
            echo -e "${RED}Error: Opción desconocida '$command'${NC}"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Cambiar al directorio del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic 2>/dev/null || {
    echo -e "${RED}Error: No se pudo cambiar al directorio del proyecto${NC}"
    exit 1
}

# Ejecutar función principal
main "$@"
