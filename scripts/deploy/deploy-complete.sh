#!/bin/bash
# Script para desplegar todos los archivos WAR necesarios
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

echo -e "${GREEN}=== Desplegando archivos WAR para estrategias completas ===${NC}"
echo ""

# Cargar variables de entorno
echo -e "${BLUE}Cargando configuración...${NC}"
source "$PROJECT_ROOT/scripts/core/load-env.sh"
load_env

# Verificar si los contenedores están en ejecución
check_containers() {
    echo -e "${BLUE}=== Verificando contenedores ===${NC}"
    
    if ! docker ps | grep -q weblogic-a; then
        echo -e "${RED}Error: El contenedor weblogic-a no está en ejecución${NC}"
        echo "Por favor, inicie los contenedores con:"
        echo -e "${YELLOW}  ./manage-services.sh start${NC}"
        exit 1
    fi

    if ! docker ps | grep -q weblogic-b; then
        echo -e "${RED}Error: El contenedor weblogic-b no está en ejecución${NC}"
        echo "Por favor, inicie los contenedores con:"
        echo -e "${YELLOW}  ./manage-services.sh start${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Contenedores verificados correctamente${NC}"
    echo ""
}

# Función para desplegar un archivo WAR
deploy_war() {
    local war_file="$1"
    local war_name=$(basename "$war_file" .war)
    
    echo -e "${BLUE}=== Desplegando $war_name ===${NC}"
    
    if [ ! -f "$war_file" ]; then
        echo -e "${RED}Error: Archivo WAR no encontrado: $war_file${NC}"
        return 1
    fi
    
    # Usar el script de despliegue actualizado
    if [ -f "$PROJECT_ROOT/scripts/deploy/deploy-war.sh" ]; then
        "$PROJECT_ROOT/scripts/deploy/deploy-war.sh" "$war_file" "$war_name"
    else
        echo -e "${RED}Error: Script de despliegue no encontrado${NC}"
        return 1
    fi
    
    echo -e "${GREEN}$war_name desplegado correctamente${NC}"
    echo ""
}

# Función para desplegar aplicaciones de feature flags
deploy_feature_flags() {
    echo -e "${BLUE}=== Desplegando Feature Flags ===${NC}"
    
    # Buscar archivos WAR de feature flags
    local feature_flags_dir="$PROJECT_ROOT/war-projects/feature-flags"
    
    if [ -d "$feature_flags_dir" ]; then
        for war_file in "$feature_flags_dir"/*.war; do
            if [ -f "$war_file" ]; then
                deploy_war "$war_file"
            fi
        done
    else
        echo -e "${YELLOW}Directorio de feature flags no encontrado: $feature_flags_dir${NC}"
    fi
}

# Función para desplegar aplicaciones de ejemplo
deploy_sample_apps() {
    echo -e "${BLUE}=== Desplegando Aplicaciones de Ejemplo ===${NC}"
    
    # Buscar archivos WAR de ejemplo
    local samples_dir="$PROJECT_ROOT/war-projects/samples"
    
    if [ -d "$samples_dir" ]; then
        for war_file in "$samples_dir"/*.war; do
            if [ -f "$war_file" ]; then
                deploy_war "$war_file"
            fi
        done
    else
        echo -e "${YELLOW}Directorio de ejemplos no encontrado: $samples_dir${NC}"
    fi
}

# Función para desplegar aplicaciones personalizadas
deploy_custom_apps() {
    echo -e "${BLUE}=== Desplegando Aplicaciones Personalizadas ===${NC}"
    
    # Buscar archivos WAR personalizados
    local custom_dir="$PROJECT_ROOT/war-projects/custom"
    
    if [ -d "$custom_dir" ]; then
        for war_file in "$custom_dir"/*.war; do
            if [ -f "$war_file" ]; then
                deploy_war "$war_file"
            fi
        done
    else
        echo -e "${YELLOW}Directorio de aplicaciones personalizadas no encontrado: $custom_dir${NC}"
    fi
}

# Función para verificar despliegues
verify_deployments() {
    echo -e "${BLUE}=== Verificando Despliegues ===${NC}"
    
    # Verificar aplicaciones en WebLogic A
    echo -e "${YELLOW}Verificando aplicaciones en WebLogic A...${NC}"
    if command -v curl >/dev/null 2>&1; then
        curl -s "http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/console" > /dev/null && \
            echo -e "${GREEN}✓ WebLogic A accesible${NC}" || \
            echo -e "${RED}✗ WebLogic A no accesible${NC}"
    fi
    
    # Verificar aplicaciones en WebLogic B
    echo -e "${YELLOW}Verificando aplicaciones en WebLogic B...${NC}"
    if command -v curl >/dev/null 2>&1; then
        curl -s "http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/console" > /dev/null && \
            echo -e "${GREEN}✓ WebLogic B accesible${NC}" || \
            echo -e "${RED}✗ WebLogic B no accesible${NC}"
    fi
    
    # Verificar HAProxy
    echo -e "${YELLOW}Verificando HAProxy...${NC}"
    if command -v curl >/dev/null 2>&1; then
        curl -s "http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/" > /dev/null && \
            echo -e "${GREEN}✓ HAProxy accesible${NC}" || \
            echo -e "${RED}✗ HAProxy no accesible${NC}"
    fi
    
    echo ""
}

# Función para mostrar resumen final
show_final_summary() {
    echo -e "${GREEN}=== Despliegue Completo Finalizado ===${NC}"
    echo ""
    echo -e "${BLUE}URLs de Acceso:${NC}"
    echo -e "  WebLogic A Console: http://localhost:${WEBLOGIC_A_EXTERNAL_PORT:-7001}/console"
    echo -e "  WebLogic B Console: http://localhost:${WEBLOGIC_B_EXTERNAL_PORT:-7002}/console"
    echo -e "  HAProxy Load Balancer: http://localhost:${HAPROXY_HTTP_EXTERNAL_PORT:-8083}/"
    echo -e "  HAProxy Stats: http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
    echo -e "  HAProxy Admin UI: http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}/"
    echo ""
    echo -e "${YELLOW}Comandos útiles post-despliegue:${NC}"
    echo -e "  ./manage-services.sh status     # Ver estado de servicios"
    echo -e "  ./manage-services.sh logs       # Ver logs"
    echo -e "  ./scripts/canary/manage-traffic.sh canary 20  # Configurar canary deployment"
    echo -e "  ./scripts/canary/simulate-traffic.sh 100 0.5  # Simular tráfico"
    echo ""
}

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Script de Despliegue Completo ===${NC}"
    echo ""
    echo -e "${YELLOW}Uso: $0 [OPCIÓN]${NC}"
    echo ""
    echo -e "${BLUE}Opciones:${NC}"
    echo "  --help, -h              Mostrar esta ayuda"
    echo "  --feature-flags-only    Solo desplegar feature flags"
    echo "  --samples-only          Solo desplegar aplicaciones de ejemplo"
    echo "  --custom-only           Solo desplegar aplicaciones personalizadas"
    echo "  --verify-only           Solo verificar despliegues existentes"
    echo ""
    echo -e "${BLUE}Descripción:${NC}"
    echo "  Este script despliega todos los archivos WAR disponibles en:"
    echo "  - war-projects/feature-flags/"
    echo "  - war-projects/samples/"
    echo "  - war-projects/custom/"
    echo ""
    echo "  Sin opciones, despliega todo automáticamente."
    echo ""
}

# Función principal
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --feature-flags-only)
            check_containers
            deploy_feature_flags
            verify_deployments
            show_final_summary
            ;;
        --samples-only)
            check_containers
            deploy_sample_apps
            verify_deployments
            show_final_summary
            ;;
        --custom-only)
            check_containers
            deploy_custom_apps
            verify_deployments
            show_final_summary
            ;;
        --verify-only)
            verify_deployments
            ;;
        "")
            # Despliegue completo
            check_containers
            
            echo -e "${BLUE}=== Iniciando Despliegue Completo ===${NC}"
            echo ""
            
            # Desplegar en orden
            deploy_feature_flags
            deploy_sample_apps
            deploy_custom_apps
            
            # Verificar todo
            verify_deployments
            
            # Mostrar resumen
            show_final_summary
            ;;
        *)
            echo -e "${RED}Opción no reconocida: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
