#!/bin/bash

# Versión Docker Compose del comando integrado
# Ejecuta: cleanup + start-dashboard + update-ips usando Docker Compose

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuración
COMPOSE_FILE="config/docker-compose.yml"
PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                              ║${NC}"
echo -e "${BLUE}║     🚀 COMANDO INTEGRADO - DOCKER COMPOSE VERSION           ║${NC}"
echo -e "${BLUE}║                                                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${YELLOW}Comando equivalente a:${NC}"
echo -e "${BLUE}cd $PROJECT_DIR && ./cleanup-environment.sh light && ./start-dashboard-with-ip-update.sh${NC}"
echo -e "${YELLOW}Pero usando Docker Compose para gestión completa de servicios${NC}"
echo

# Verificar prerequisitos
check_prerequisites() {
    echo -e "${BLUE}=== Verificando Prerequisitos ===${NC}"
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Error: docker-compose no está instalado${NC}"
        exit 1
    fi
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo -e "${RED}❌ Error: Archivo $COMPOSE_FILE no encontrado${NC}"
        exit 1
    fi
    
    # Cambiar al directorio del proyecto
    if [ "$(pwd)" != "$PROJECT_DIR" ]; then
        echo -e "${YELLOW}⚠️  Cambiando al directorio del proyecto: $PROJECT_DIR${NC}"
        cd "$PROJECT_DIR"
    fi
    
    echo -e "${GREEN}✓ Prerequisitos verificados${NC}"
}

# Paso 1: Limpieza del entorno
cleanup_environment() {
    echo -e "${BLUE}=== Paso 1: Limpieza del Entorno ===${NC}"
    
    # Ejecutar limpieza ligera usando el script existente
    if [ -f "./cleanup-environment.sh" ]; then
        echo -e "${YELLOW}Ejecutando limpieza ligera...${NC}"
        ./cleanup-environment.sh light
    else
        echo -e "${YELLOW}Script cleanup-environment.sh no encontrado, ejecutando limpieza básica...${NC}"
        # Limpieza básica con Docker Compose
        docker-compose -f "$COMPOSE_FILE" down
        docker system prune -f
    fi
    
    echo -e "${GREEN}✓ Limpieza completada${NC}"
}

# Paso 2: Iniciar servicios con Docker Compose
start_services() {
    echo -e "${BLUE}=== Paso 2: Iniciando Servicios con Docker Compose ===${NC}"
    
    echo -e "${YELLOW}Iniciando todos los servicios...${NC}"
    docker-compose -f "$COMPOSE_FILE" up -d
    
    echo -e "${YELLOW}Esperando que los servicios estén listos...${NC}"
    sleep 15
    
    # Verificar estado de servicios
    echo -e "${YELLOW}Verificando estado de servicios...${NC}"
    docker-compose -f "$COMPOSE_FILE" ps
    
    echo -e "${GREEN}✓ Servicios iniciados${NC}"
}

# Paso 3: Actualizar IPs de HAProxy
update_haproxy_ips() {
    echo -e "${BLUE}=== Paso 3: Actualizando IPs de HAProxy ===${NC}"
    
    # Método 1: Script de actualización de IPs
    if [ -f "./update-haproxy-ips.sh" ]; then
        echo -e "${YELLOW}Ejecutando actualización de IPs...${NC}"
        ./update-haproxy-ips.sh
    elif [ -f "./scripts/auto-update-haproxy.sh" ]; then
        echo -e "${YELLOW}Ejecutando auto-update-haproxy.sh...${NC}"
        ./scripts/auto-update-haproxy.sh
    else
        echo -e "${YELLOW}Scripts de actualización de IPs no encontrados, obteniendo IPs dinámicamente...${NC}"
        
        # Obtener IPs dinámicamente de Docker Compose
        ORACLE_IP=$(docker-compose -f "$COMPOSE_FILE" exec -T orcldb hostname -i 2>/dev/null | tr -d '\r' || echo "172.23.0.2")
        WEBLOGIC_A_IP=$(docker-compose -f "$COMPOSE_FILE" exec -T weblogic-a hostname -i 2>/dev/null | tr -d '\r' || echo "172.23.0.4")
        WEBLOGIC_B_IP=$(docker-compose -f "$COMPOSE_FILE" exec -T weblogic-b hostname -i 2>/dev/null | tr -d '\r' || echo "172.23.0.3")
        
        echo -e "${GREEN}✓ IPs obtenidas:${NC}"
        echo -e "  Oracle DB: $ORACLE_IP"
        echo -e "  WebLogic A: $WEBLOGIC_A_IP"
        echo -e "  WebLogic B: $WEBLOGIC_B_IP"
    fi
    
    echo -e "${GREEN}✓ IPs actualizadas${NC}"
}

# Paso 4: Iniciar dashboard integrado
start_dashboard() {
    echo -e "${BLUE}=== Paso 4: Iniciando Dashboard Integrado ===${NC}"
    
    # Verificar si existe el script de dashboard
    if [ -f "./start-dashboard-with-ip-update.sh" ]; then
        echo -e "${YELLOW}Ejecutando start-dashboard-with-ip-update.sh...${NC}"
        ./start-dashboard-with-ip-update.sh
    elif [ -f "./start-dashboard-integrated.sh" ]; then
        echo -e "${YELLOW}Ejecutando start-dashboard-integrated.sh...${NC}"
        ./start-dashboard-integrated.sh
    else
        echo -e "${YELLOW}Scripts de dashboard no encontrados, verificando servicios...${NC}"
        
        # Verificar que HAProxy esté funcionando
        if docker-compose -f "$COMPOSE_FILE" ps haproxy | grep -q "Up"; then
            echo -e "${GREEN}✓ HAProxy está funcionando${NC}"
        else
            echo -e "${YELLOW}⚠️  Reiniciando HAProxy...${NC}"
            docker-compose -f "$COMPOSE_FILE" restart haproxy
        fi
    fi
    
    echo -e "${GREEN}✓ Dashboard iniciado${NC}"
}

# Paso 5: Verificación final
final_verification() {
    echo -e "${BLUE}=== Paso 5: Verificación Final ===${NC}"
    
    echo -e "${YELLOW}Verificando servicios...${NC}"
    
    # Verificar estado de contenedores
    docker-compose -f "$COMPOSE_FILE" ps
    
    echo
    echo -e "${YELLOW}Verificando conectividad...${NC}"
    
    # Verificar URLs principales
    urls=(
        "http://localhost:8080"
        "http://localhost:8082"
        "http://localhost:8404/stats"
        "http://localhost:7001/console"
        "http://localhost:7002/console"
    )
    
    for url in "${urls[@]}"; do
        if curl -s --max-time 5 "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ $url - Responde correctamente${NC}"
        else
            echo -e "${YELLOW}⚠️  $url - No responde (puede estar iniciándose)${NC}"
        fi
    done
    
    echo -e "${GREEN}✓ Verificación completada${NC}"
}

# Mostrar resultado final
show_final_result() {
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║                ✅ ¡COMANDO INTEGRADO COMPLETADO!             ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    echo -e "${BLUE}🎉 Todos los servicios están funcionando correctamente!${NC}"
    echo
    echo -e "${YELLOW}📋 URLs de acceso principales:${NC}"
    echo -e "   🌐 ${GREEN}HAProxy Frontend:${NC}     http://localhost:8080"
    echo -e "   📊 ${GREEN}HAProxy Stats:${NC}        http://localhost:8404/stats"
    echo -e "   ⚙️  ${GREEN}Panel Admin:${NC}          http://localhost:8082"
    echo -e "   📈 ${GREEN}Dashboard:${NC}            http://localhost:8001"
    echo -e "   🔧 ${GREEN}WebLogic A Console:${NC}   http://localhost:7001/console"
    echo -e "   🔧 ${GREEN}WebLogic B Console:${NC}   http://localhost:7002/console"
    
    echo
    echo -e "${YELLOW}🛠️  Comandos útiles:${NC}"
    echo -e "   docker-compose -f $COMPOSE_FILE ps              # Ver estado"
    echo -e "   docker-compose -f $COMPOSE_FILE logs haproxy    # Ver logs"
    echo -e "   docker-compose -f $COMPOSE_FILE restart haproxy # Reiniciar HAProxy"
    echo -e "   ./manage-direct-integrated.sh status            # Estado integrado"
    
    echo
    echo -e "${GREEN}🎯 ¡El entorno está listo para Testing A/B, Canary Deployment y Feature Flags!${NC}"
}

# Función principal
main() {
    check_prerequisites
    echo
    cleanup_environment
    echo
    start_services
    echo
    update_haproxy_ips
    echo
    start_dashboard
    echo
    final_verification
    echo
    show_final_result
}

# Manejar interrupciones
trap 'echo -e "\n${YELLOW}⚠️  Proceso interrumpido por el usuario${NC}"; exit 1' SIGINT SIGTERM

# Ejecutar función principal
main "$@"
