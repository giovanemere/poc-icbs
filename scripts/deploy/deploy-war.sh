#!/bin/bash
#
# Script para desplegar archivos WAR en WebLogic con limpieza de caché
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Desplegando archivos WAR en WebLogic ===${NC}"
echo ""

# Verificar si el contenedor está en ejecución
if ! docker ps | grep -q weblogic-a; then
    echo -e "${RED}Error: El contenedor weblogic-a no está en ejecución${NC}"
    echo "Por favor, inicie el contenedor con:"
    echo -e "${YELLOW}  docker-compose -f config/docker-compose.yml up -d${NC}"
    exit 1
fi

# Función para limpiar caché en HAProxy
clean_haproxy_cache() {
    echo -e "${BLUE}=== Limpiando caché en HAProxy ===${NC}"
    
    if ! docker ps | grep -q haproxy; then
        echo -e "${YELLOW}HAProxy no está en ejecución, omitiendo limpieza de caché${NC}"
        return
    fi
    
    # Limpiar caché de HAProxy
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
    
    echo -e "${GREEN}Caché de HAProxy limpiada correctamente${NC}"
    echo ""
}

# Función para limpiar caché en WebLogic
clean_weblogic_cache() {
    echo -e "${BLUE}=== Limpiando caché en WebLogic ===${NC}"
    
    # Limpiar caché en weblogic-a
    if docker ps | grep -q weblogic-a; then
        echo -e "${YELLOW}Limpiando caché en weblogic-a...${NC}"
        
        # 1. Limpiar archivos temporales
        docker exec weblogic-a bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/tmp/*" || true
        docker exec weblogic-a bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/cache/*" || true
        
        # 2. Limpiar archivos de trabajo de aplicaciones específicas
        if [ -n "$1" ]; then
            app_name=$(basename $1 .war)
            echo -e "${YELLOW}Limpiando archivos de trabajo para $app_name...${NC}"
            docker exec weblogic-a bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/tmp/$app_name*" || true
            docker exec weblogic-a bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/stage/$app_name*" || true
        fi
        
        echo -e "${GREEN}Caché de weblogic-a limpiada correctamente${NC}"
    else
        echo -e "${YELLOW}weblogic-a no está en ejecución, omitiendo limpieza de caché${NC}"
    fi
    
    # Limpiar caché en weblogic-b
    if docker ps | grep -q weblogic-b; then
        echo -e "${YELLOW}Limpiando caché en weblogic-b...${NC}"
        
        # 1. Limpiar archivos temporales
        docker exec weblogic-b bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/tmp/*" || true
        docker exec weblogic-b bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/cache/*" || true
        
        # 2. Limpiar archivos de trabajo de aplicaciones específicas
        if [ -n "$1" ]; then
            app_name=$(basename $1 .war)
            echo -e "${YELLOW}Limpiando archivos de trabajo para $app_name...${NC}"
            docker exec weblogic-b bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/tmp/$app_name*" || true
            docker exec weblogic-b bash -c "rm -rf /u01/oracle/user_projects/domains/base_domain/servers/AdminServer/stage/$app_name*" || true
        fi
        
        echo -e "${GREEN}Caché de weblogic-b limpiada correctamente${NC}"
    else
        echo -e "${YELLOW}weblogic-b no está en ejecución, omitiendo limpieza de caché${NC}"
    fi
    
    echo ""
}

# Función para limpiar caché en navegadores (generando un archivo de instrucciones)
generate_browser_cache_instructions() {
    echo -e "${BLUE}=== Generando instrucciones para limpiar caché en navegadores ===${NC}"
    
    # Crear archivo de instrucciones
    cat > browser-cache-instructions.txt << EOF
# Instrucciones para limpiar caché en navegadores

Para asegurar que los cambios en las aplicaciones se reflejen correctamente, es recomendable limpiar la caché del navegador:

## Chrome
1. Presiona Ctrl+Shift+Delete (Windows/Linux) o Cmd+Shift+Delete (Mac)
2. Selecciona "Cookies y datos de sitios" y "Imágenes y archivos almacenados en caché"
3. Haz clic en "Borrar datos"

## Firefox
1. Presiona Ctrl+Shift+Delete (Windows/Linux) o Cmd+Shift+Delete (Mac)
2. Selecciona "Cookies" y "Caché"
3. Haz clic en "Limpiar ahora"

## Safari
1. Ve a Safari > Preferencias > Avanzado
2. Marca "Mostrar menú Desarrollo en la barra de menús"
3. Ve a Desarrollo > Vaciar cachés

## Edge
1. Presiona Ctrl+Shift+Delete
2. Selecciona "Cookies y datos guardados" y "Archivos e imágenes en caché"
3. Haz clic en "Borrar ahora"

## Alternativa: Modo incógnito/privado
Otra opción es utilizar el modo incógnito o privado del navegador para probar las aplicaciones sin caché.
EOF
    
    echo -e "${GREEN}Instrucciones generadas en browser-cache-instructions.txt${NC}"
    echo ""
}

# Función para limpiar todas las cachés
clean_all_caches() {
    local app_name=$1
    
    clean_haproxy_cache
    clean_weblogic_cache "$app_name"
    generate_browser_cache_instructions
    
    echo -e "${GREEN}=== Todas las cachés han sido limpiadas ===${NC}"
    echo ""
}

# Función para verificar una URL
check_url() {
    local url=$1
    local max_attempts=$2
    local attempt=1
    local wait_time=5
    local success=false
    
    echo -e "${YELLOW}Verificando disponibilidad de $url...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        status=$(curl -s -o /dev/null -w "%{http_code}" $url)
        if [[ "$status" == "200" || "$status" == "302" ]]; then
            echo -e "${GREEN}  ✅ $url - OK ($status) - Intento $attempt${NC}"
            success=true
            break
        else
            echo -e "${YELLOW}  ⏳ $url - ($status) - Intento $attempt de $max_attempts${NC}"
            attempt=$((attempt+1))
            sleep $wait_time
        fi
    done
    
    if [ "$success" = false ]; then
        echo -e "${RED}  ❌ $url - No disponible después de $max_attempts intentos${NC}"
        return 1
    fi
    
    return 0
}

# Función para desplegar un archivo WAR
deploy_war() {
    local war_file=$1
    local war_name=$(basename $war_file .war)
    local clean_cache=$2
    
    echo -e "${YELLOW}Desplegando $war_file...${NC}"
    
    # Limpiar caché si se solicita
    if [ "$clean_cache" = true ]; then
        clean_all_caches "$war_file"
    fi
    
    # Eliminar aplicación existente si está presente
    echo -e "${YELLOW}Eliminando versión anterior de $war_name si existe...${NC}"
    docker exec weblogic-a bash -c "rm -f /u01/oracle/user_projects/domains/base_domain/autodeploy/$war_name.war" || true
    if docker ps | grep -q weblogic-b; then
        docker exec weblogic-b bash -c "rm -f /u01/oracle/user_projects/domains/base_domain/autodeploy/$war_name.war" || true
    fi
    
    # Esperar a que la aplicación se desinstale
    echo -e "${YELLOW}Esperando a que la aplicación anterior se desinstale...${NC}"
    sleep 5
    
    # Copiar el archivo WAR al directorio autodeploy de ambos contenedores
    docker cp $war_file weblogic-a:/u01/oracle/user_projects/domains/base_domain/autodeploy/
    
    # Si weblogic-b está en ejecución, también desplegar allí
    if docker ps | grep -q weblogic-b; then
        docker cp $war_file weblogic-b:/u01/oracle/user_projects/domains/base_domain/autodeploy/
        echo -e "${GREEN}Archivo $war_file desplegado en ambos servidores WebLogic${NC}"
    else
        echo -e "${YELLOW}Archivo $war_file desplegado solo en weblogic-a (weblogic-b no está en ejecución)${NC}"
    fi
    
    echo -e "${YELLOW}Esperando a que WebLogic despliegue la aplicación...${NC}"
    sleep 15
    
    # Verificar que la aplicación esté disponible
    local success=true
    
    # Verificar en weblogic-a
    if ! check_url "http://localhost:7001/$war_name/" 6; then
        success=false
    fi
    
    # Verificar en weblogic-b si está en ejecución
    if docker ps | grep -q weblogic-b; then
        if ! check_url "http://localhost:7002/$war_name/" 6; then
            success=false
        fi
    fi
    
    # Verificar en HAProxy si está en ejecución
    if docker ps | grep -q haproxy; then
        if ! check_url "http://localhost:8080/$war_name/" 6; then
            success=false
        fi
    fi
    
    if [ "$success" = true ]; then
        echo -e "${GREEN}Despliegue de $war_name completado exitosamente${NC}"
    else
        echo -e "${YELLOW}Despliegue de $war_name completado con advertencias${NC}"
        echo -e "${YELLOW}Algunas URLs pueden no estar disponibles. Ejecute ./scripts/check-urls.sh para verificar todas las URLs${NC}"
    fi
    
    echo ""
}

# Desplegar todos los archivos WAR
deploy_all() {
    local clean_cache=$1
    
    echo -e "${YELLOW}Desplegando todos los archivos WAR...${NC}"
    
    # Limpiar caché si se solicita
    if [ "$clean_cache" = true ]; then
        clean_all_caches
    fi
    
    for war_file in deploy/*.war; do
        if [ -f "$war_file" ]; then
            deploy_war $war_file false
        fi
    done
    
    echo -e "${GREEN}Todos los archivos WAR han sido desplegados${NC}"
}

# Desplegar solo FF4J
deploy_ff4j() {
    local clean_cache=$1
    
    echo -e "${YELLOW}Desplegando FF4J...${NC}"
    
    # Limpiar caché si se solicita
    if [ "$clean_cache" = true ]; then
        clean_all_caches
    fi
    
    if [ -f "deploy/feature-flags.war" ]; then
        deploy_war deploy/feature-flags.war false
    else
        echo -e "${RED}Error: No se encontró el archivo deploy/feature-flags.war${NC}"
        echo "Por favor, construya el archivo WAR con:"
        echo -e "${YELLOW}  ./scripts/deploy/create-simple-feature-flags.sh${NC}"
        exit 1
    fi
    
    if [ -f "deploy/ff4j-simple.war" ]; then
        deploy_war deploy/ff4j-simple.war false
    else
        echo -e "${RED}Error: No se encontró el archivo deploy/ff4j-simple.war${NC}"
        echo "Por favor, construya el archivo WAR con:"
        echo -e "${YELLOW}  ./scripts/build/create-simple-wars.sh ff4j-simple${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}FF4J ha sido desplegado${NC}"
}

# Desplegar versiones A y B para pruebas A/B
deploy_ab() {
    local clean_cache=$1
    
    echo -e "${YELLOW}Desplegando versiones A y B para pruebas A/B...${NC}"
    
    # Limpiar caché si se solicita
    if [ "$clean_cache" = true ]; then
        clean_all_caches
    fi
    
    if [ -f "deploy/version-a.war" ]; then
        deploy_war deploy/version-a.war false
    else
        echo -e "${RED}Error: No se encontró el archivo deploy/version-a.war${NC}"
        echo "Por favor, construya el archivo WAR con:"
        echo -e "${YELLOW}  ./scripts/build/create-simple-wars.sh version-a${NC}"
        exit 1
    fi
    
    if [ -f "deploy/version-b.war" ]; then
        deploy_war deploy/version-b.war false
    else
        echo -e "${RED}Error: No se encontró el archivo deploy/version-b.war${NC}"
        echo "Por favor, construya el archivo WAR con:"
        echo -e "${YELLOW}  ./scripts/build/create-simple-wars.sh version-b${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Versiones A y B para pruebas A/B han sido desplegadas${NC}"
}

# Desplegar versiones A y B para Canary
deploy_canary() {
    local clean_cache=$1
    
    echo -e "${YELLOW}Desplegando versiones A y B para Canary...${NC}"
    
    # Limpiar caché si se solicita
    if [ "$clean_cache" = true ]; then
        clean_all_caches
    fi
    
    if [ -f "deploy/weblogic-features-a.war" ]; then
        deploy_war deploy/weblogic-features-a.war false
    else
        echo -e "${RED}Error: No se encontró el archivo deploy/weblogic-features-a.war${NC}"
        echo "Por favor, construya el archivo WAR con:"
        echo -e "${YELLOW}  ./scripts/build/create-simple-wars.sh weblogic-features-a${NC}"
        exit 1
    fi
    
    if [ -f "deploy/weblogic-features-b.war" ]; then
        deploy_war deploy/weblogic-features-b.war false
    else
        echo -e "${RED}Error: No se encontró el archivo deploy/weblogic-features-b.war${NC}"
        echo "Por favor, construya el archivo WAR con:"
        echo -e "${YELLOW}  ./scripts/build/create-simple-wars.sh weblogic-features-b${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Versiones A y B para Canary han sido desplegadas${NC}"
}

# Verificar todas las URLs
check_all_urls() {
    echo -e "${YELLOW}Verificando todas las URLs...${NC}"
    ./scripts/check-urls.sh
}

# Solo limpiar caché
only_clean_cache() {
    echo -e "${YELLOW}Limpiando todas las cachés...${NC}"
    clean_all_caches
}

# Mostrar ayuda
show_help() {
    echo -e "${GREEN}=== Script de despliegue para WebLogic ===${NC}"
    echo ""
    echo -e "Uso: $0 [opciones] [archivo.war]"
    echo ""
    echo -e "Opciones:"
    echo -e "  ${YELLOW}--all${NC}         Desplegar todos los archivos WAR"
    echo -e "  ${YELLOW}--ff4j${NC}        Desplegar FF4J y Feature Flags"
    echo -e "  ${YELLOW}--ab${NC}          Desplegar versiones A y B para pruebas A/B"
    echo -e "  ${YELLOW}--canary${NC}      Desplegar versiones A y B para Canary"
    echo -e "  ${YELLOW}--check${NC}       Verificar todas las URLs"
    echo -e "  ${YELLOW}--clean${NC}       Solo limpiar caché sin desplegar"
    echo -e "  ${YELLOW}--clean-all${NC}   Limpiar caché y desplegar todos los archivos WAR"
    echo -e "  ${YELLOW}--clean-ff4j${NC}  Limpiar caché y desplegar FF4J"
    echo -e "  ${YELLOW}--clean-ab${NC}    Limpiar caché y desplegar versiones A/B"
    echo -e "  ${YELLOW}--clean-canary${NC} Limpiar caché y desplegar versiones Canary"
    echo -e "  ${YELLOW}--help${NC}        Mostrar esta ayuda"
    echo ""
    echo -e "Ejemplos:"
    echo -e "  $0 --all                # Desplegar todos los archivos WAR"
    echo -e "  $0 --clean              # Solo limpiar caché"
    echo -e "  $0 --clean-all          # Limpiar caché y desplegar todos los archivos WAR"
    echo -e "  $0 deploy/version-a.war # Desplegar un archivo WAR específico"
    echo -e "  $0 --clean deploy/version-a.war # Limpiar caché y desplegar un archivo WAR específico"
    echo ""
}

# Procesar argumentos
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Verificar si se debe limpiar la caché
clean_cache=false

case "$1" in
    --all)
        deploy_all false
        ;;
    --ff4j)
        deploy_ff4j false
        ;;
    --ab)
        deploy_ab false
        ;;
    --canary)
        deploy_canary false
        ;;
    --check)
        check_all_urls
        ;;
    --clean)
        if [ $# -eq 1 ]; then
            only_clean_cache
        else
            clean_cache=true
            shift
            if [ -f "$1" ]; then
                deploy_war $1 $clean_cache
            else
                echo -e "${RED}Error: No se encontró el archivo $1${NC}"
                exit 1
            fi
        fi
        ;;
    --clean-all)
        deploy_all true
        ;;
    --clean-ff4j)
        deploy_ff4j true
        ;;
    --clean-ab)
        deploy_ab true
        ;;
    --clean-canary)
        deploy_canary true
        ;;
    --help)
        show_help
        exit 0
        ;;
    *)
        if [ -f "$1" ]; then
            deploy_war $1 false
        else
            echo -e "${RED}Error: No se encontró el archivo o la opción $1${NC}"
            show_help
            exit 1
        fi
        ;;
esac

echo ""
echo -e "${GREEN}=== Despliegue completado ===${NC}"
echo ""
echo -e "Para acceder a las aplicaciones desplegadas:"
echo -e "  - Feature Flags: ${YELLOW}http://localhost:8080/feature-flags/${NC}"
echo -e "  - FF4J Simple: ${YELLOW}http://localhost:8080/ff4j-simple/${NC}"
echo -e "  - Versión A: ${YELLOW}http://localhost:8080/version-a/${NC}"
echo -e "  - Versión B: ${YELLOW}http://localhost:8080/version-b/${NC}"
echo -e "  - WebLogic Features A: ${YELLOW}http://localhost:8080/weblogic-features-a/${NC}"
echo -e "  - WebLogic Features B: ${YELLOW}http://localhost:8080/weblogic-features-b/${NC}"
echo ""
echo -e "Para verificar todas las URLs:"
echo -e "${YELLOW}  ./scripts/deploy/deploy-war.sh --check${NC}"
echo ""
echo -e "Para limpiar todas las cachés:"
echo -e "${YELLOW}  ./scripts/deploy/deploy-war.sh --clean${NC}"
echo ""
if [ -f "browser-cache-instructions.txt" ]; then
    echo -e "Se han generado instrucciones para limpiar caché en navegadores:"
    echo -e "${YELLOW}  cat browser-cache-instructions.txt${NC}"
    echo ""
fi
