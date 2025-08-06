#!/bin/bash
# Script para desplegar archivos WAR en WebLogic con limpieza de caché
# Actualizado para usar configuración centralizada

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo -e "${GREEN}=== Desplegando archivos WAR en WebLogic ===${NC}"
echo ""

# Cargar variables de entorno
echo -e "${BLUE}Cargando configuración...${NC}"
source "$PROJECT_ROOT/scripts/core/load-env.sh"
load_env

# Verificar si los contenedores están en ejecución
check_containers() {
    echo -e "${BLUE}=== Verificando estado de contenedores ===${NC}"
    
    if ! docker ps | grep -q weblogic-a; then
        echo -e "${RED}Error: El contenedor weblogic-a no está en ejecución${NC}"
        echo "Por favor, inicie el contenedor con:"
        echo -e "${YELLOW}  ./manage-services.sh start${NC}"
        exit 1
    fi
    
    if ! docker ps | grep -q weblogic-b; then
        echo -e "${YELLOW}Advertencia: El contenedor weblogic-b no está en ejecución${NC}"
        echo "Solo se desplegará en weblogic-a"
    fi
    
    echo -e "${GREEN}Contenedores verificados correctamente${NC}"
    echo ""
}

# Función para limpiar caché en HAProxy
clean_haproxy_cache() {
    echo -e "${BLUE}=== Limpiando caché en HAProxy ===${NC}"
    
    if ! docker ps | grep -q haproxy; then
        echo -e "${YELLOW}HAProxy no está en ejecución, omitiendo limpieza de caché${NC}"
        return
    fi
    
    # Limpiar caché de HAProxy usando la API configurada
    echo -e "${YELLOW}Limpiando caché de HAProxy...${NC}"
    
    # 1. Reiniciar estadísticas
    echo -e "${YELLOW}Reiniciando estadísticas de HAProxy...${NC}"
    docker exec haproxy bash -c "echo 'clear counters all' | socat stdio /var/run/haproxy.sock" || true
    
    # 2. Limpiar caché de cookies
    echo -e "${YELLOW}Limpiando caché de cookies en HAProxy...${NC}"
    docker exec haproxy bash -c "echo 'clear table http-in ab_test' | socat stdio /var/run/haproxy.sock" 2>/dev/null || true
    docker exec haproxy bash -c "echo 'clear table http-in canary' | socat stdio /var/run/haproxy.sock" 2>/dev/null || true
    
    # 3. Recargar configuración sin reiniciar (soft reload)
    echo -e "${YELLOW}Recargando configuración de HAProxy...${NC}"
    docker exec haproxy bash -c "haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg && haproxy -sf \$(pidof haproxy) -f /usr/local/etc/haproxy/haproxy.cfg" || true
    
    # 4. Verificar estado usando la API configurada
    echo -e "${YELLOW}Verificando estado de HAProxy...${NC}"
    if command -v curl >/dev/null 2>&1; then
        curl -s "http://localhost:${HAPROXY_API_EXTERNAL_PORT:-8081}/api/stats" > /dev/null || echo -e "${YELLOW}API de HAProxy no disponible${NC}"
    fi
    
    echo -e "${GREEN}Caché de HAProxy limpiada correctamente${NC}"
    echo ""
}

# Función para limpiar caché de WebLogic
clean_weblogic_cache() {
    local container_name="$1"
    echo -e "${BLUE}=== Limpiando caché en $container_name ===${NC}"
    
    if ! docker ps | grep -q "$container_name"; then
        echo -e "${YELLOW}$container_name no está en ejecución, omitiendo limpieza${NC}"
        return
    fi
    
    # Limpiar caché de trabajo temporal
    echo -e "${YELLOW}Limpiando archivos temporales...${NC}"
    docker exec "$container_name" bash -c "rm -rf /tmp/weblogic_temp/* 2>/dev/null || true"
    docker exec "$container_name" bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/tmp/* 2>/dev/null || true"
    
    # Limpiar caché de aplicaciones
    echo -e "${YELLOW}Limpiando caché de aplicaciones...${NC}"
    docker exec "$container_name" bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/cache/* 2>/dev/null || true"
    
    echo -e "${GREEN}Caché de $container_name limpiada correctamente${NC}"
    echo ""
}

# Función para desplegar WAR en un contenedor específico
deploy_to_container() {
    local container_name="$1"
    local war_file="$2"
    local app_name="$3"
    
    echo -e "${BLUE}=== Desplegando en $container_name ===${NC}"
    
    if ! docker ps | grep -q "$container_name"; then
        echo -e "${YELLOW}$container_name no está en ejecución, omitiendo despliegue${NC}"
        return
    fi
    
    # Verificar que el archivo WAR existe
    if [ ! -f "$war_file" ]; then
        echo -e "${RED}Error: Archivo WAR no encontrado: $war_file${NC}"
        return 1
    fi
    
    # Copiar archivo WAR al contenedor
    echo -e "${YELLOW}Copiando $war_file a $container_name...${NC}"
    docker cp "$war_file" "$container_name:/u01/oracle/user_projects/domains/base_domain/autodeploy/"
    
    # Esperar un momento para que WebLogic procese el archivo
    echo -e "${YELLOW}Esperando a que WebLogic procese el despliegue...${NC}"
    sleep 10
    
    # Verificar el despliegue
    echo -e "${YELLOW}Verificando despliegue en $container_name...${NC}"
    if docker exec "$container_name" bash -c "ls -la /u01/oracle/user_projects/domains/base_domain/autodeploy/ | grep -q '$app_name'"; then
        echo -e "${GREEN}Despliegue exitoso en $container_name${NC}"
    else
        echo -e "${YELLOW}Verificación de despliegue no concluyente en $container_name${NC}"
    fi
    
    echo ""
}

# Función para mostrar URLs de verificación
show_verification_urls() {
    echo -e "${BLUE}=== URLs de Verificación ===${NC}"
    echo ""
    echo -e "${YELLOW}Consolas de WebLogic:${NC}"
    echo -e "  WebLogic A: http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/console"
    echo -e "  WebLogic B: http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/console"
    echo ""
    echo -e "${YELLOW}Load Balancer:${NC}"
    echo -e "  HAProxy: http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    echo -e "  HAProxy Stats: http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
    echo ""
    echo -e "${YELLOW}Para verificar aplicaciones desplegadas:${NC}"
    echo -e "  Directo WebLogic A: http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/[app-name]"
    echo -e "  Directo WebLogic B: http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/[app-name]"
    echo -e "  A través de HAProxy: http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/[app-name]"
    echo ""
}

# Función principal de despliegue
main_deploy() {
    local war_file="$1"
    local app_name="$2"
    
    if [ -z "$war_file" ]; then
        echo -e "${RED}Error: Debe especificar un archivo WAR${NC}"
        echo ""
        echo -e "${YELLOW}Uso: $0 <archivo.war> [nombre-app]${NC}"
        echo ""
        echo -e "${YELLOW}Ejemplos:${NC}"
        echo -e "  $0 /path/to/app.war"
        echo -e "  $0 /path/to/app.war mi-aplicacion"
        echo ""
        exit 1
    fi
    
    # Extraer nombre de la aplicación si no se proporciona
    if [ -z "$app_name" ]; then
        app_name=$(basename "$war_file" .war)
    fi
    
    echo -e "${BLUE}Archivo WAR: $war_file${NC}"
    echo -e "${BLUE}Nombre de aplicación: $app_name${NC}"
    echo ""
    
    # Verificar contenedores
    check_containers
    
    # Limpiar cachés antes del despliegue
    clean_haproxy_cache
    clean_weblogic_cache "weblogic-a"
    clean_weblogic_cache "weblogic-b"
    
    # Desplegar en ambos contenedores
    deploy_to_container "weblogic-a" "$war_file" "$app_name"
    deploy_to_container "weblogic-b" "$war_file" "$app_name"
    
    # Limpiar cachés después del despliegue
    echo -e "${BLUE}=== Limpieza final de cachés ===${NC}"
    clean_haproxy_cache
    
    # Mostrar URLs de verificación
    show_verification_urls
    
    echo -e "${GREEN}=== Despliegue completado ===${NC}"
    echo ""
    echo -e "${YELLOW}Recomendaciones post-despliegue:${NC}"
    echo -e "  1. Verificar logs: ./manage-services.sh logs"
    echo -e "  2. Verificar estado: ./manage-services.sh status"
    echo -e "  3. Probar aplicación en las URLs mostradas arriba"
    echo -e "  4. Verificar balanceador de carga con tráfico de prueba"
    echo ""
}

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Script de Despliegue WAR ===${NC}"
    echo ""
    echo -e "${YELLOW}Uso: $0 [OPCIÓN] <archivo.war> [nombre-app]${NC}"
    echo ""
    echo -e "${BLUE}Opciones:${NC}"
    echo "  --help, -h          Mostrar esta ayuda"
    echo "  --clean-only        Solo limpiar cachés sin desplegar"
    echo "  --verify-only       Solo mostrar URLs de verificación"
    echo ""
    echo -e "${BLUE}Ejemplos:${NC}"
    echo "  $0 /path/to/app.war"
    echo "  $0 /path/to/app.war mi-aplicacion"
    echo "  $0 --clean-only"
    echo "  $0 --verify-only"
    echo ""
    echo -e "${BLUE}Descripción:${NC}"
    echo "  Este script despliega archivos WAR en ambos contenedores WebLogic"
    echo "  (weblogic-a y weblogic-b) y limpia los cachés de HAProxy y WebLogic"
    echo "  para asegurar que los cambios se reflejen inmediatamente."
    echo ""
}

# Función principal
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --clean-only)
            echo -e "${BLUE}=== Solo limpieza de cachés ===${NC}"
            check_containers
            clean_haproxy_cache
            clean_weblogic_cache "weblogic-a"
            clean_weblogic_cache "weblogic-b"
            echo -e "${GREEN}Limpieza completada${NC}"
            ;;
        --verify-only)
            show_verification_urls
            ;;
        "")
            echo -e "${RED}Error: Debe especificar un archivo WAR o una opción${NC}"
            echo ""
            show_help
            exit 1
            ;;
        *)
            main_deploy "$@"
            ;;
    esac
}

# Ejecutar función principal
main "$@"
