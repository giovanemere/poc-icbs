#!/bin/bash
# Script para migrar configuraciones existentes al nuevo sistema de variables centralizadas

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              Migración de Configuraciones                   ║"
echo "║                Sistema Variables Centralizadas              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}Uso: $0 [OPCIONES]${NC}"
    echo ""
    echo -e "${YELLOW}Opciones:${NC}"
    echo "  --backup        Crear backup de configuraciones actuales"
    echo "  --migrate       Migrar configuraciones al nuevo sistema"
    echo "  --validate      Validar migración"
    echo "  --rollback      Revertir a configuración anterior"
    echo "  --clean         Limpiar archivos temporales"
    echo "  --help          Mostrar esta ayuda"
    echo ""
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo "  $0 --backup --migrate    # Backup y migración completa"
    echo "  $0 --validate            # Solo validar migración"
    echo "  $0 --rollback            # Revertir cambios"
}

# Función para crear backup
create_backup() {
    local backup_dir="$PROJECT_ROOT/backup-config-$(date +%Y%m%d-%H%M%S)"
    
    echo -e "${BLUE}=== Creando Backup de Configuraciones ===${NC}"
    
    mkdir -p "$backup_dir"
    
    # Archivos a respaldar
    local files_to_backup=(
        "scripts/.env"
        "docker-compose.yml"
        "scripts/core/load-env.sh"
        "scripts/services/manage-services.sh"
    )
    
    for file in "${files_to_backup[@]}"; do
        local source_file="$PROJECT_ROOT/$file"
        if [ -f "$source_file" ]; then
            local dest_dir="$backup_dir/$(dirname "$file")"
            mkdir -p "$dest_dir"
            cp "$source_file" "$backup_dir/$file"
            echo -e "${GREEN}✓ Backup: $file${NC}"
        else
            echo -e "${YELLOW}⚠ Archivo no encontrado: $file${NC}"
        fi
    done
    
    # Crear archivo de información del backup
    {
        echo "# Backup de configuraciones"
        echo "# Fecha: $(date)"
        echo "# Directorio original: $PROJECT_ROOT"
        echo "# Versión: Pre-migración variables centralizadas"
        echo ""
        echo "# Archivos respaldados:"
        for file in "${files_to_backup[@]}"; do
            if [ -f "$PROJECT_ROOT/$file" ]; then
                echo "# - $file"
            fi
        done
    } > "$backup_dir/backup-info.txt"
    
    echo -e "${GREEN}✅ Backup creado en: $backup_dir${NC}"
    echo "$backup_dir" > "$PROJECT_ROOT/.last-backup"
    
    return 0
}

# Función para migrar docker-compose.yml
migrate_docker_compose() {
    echo -e "${BLUE}=== Migrando docker-compose.yml ===${NC}"
    
    local compose_file="$PROJECT_ROOT/docker-compose.yml"
    local temp_file="$compose_file.tmp"
    
    if [ ! -f "$compose_file" ]; then
        echo -e "${YELLOW}⚠ docker-compose.yml no encontrado${NC}"
        return 0
    fi
    
    # Crear versión migrada
    cat > "$temp_file" << 'EOF'
version: '3.8'

# Docker Compose con Variables Centralizadas
# Utiliza el nuevo sistema de variables de entorno centralizadas
# Para cargar variables: source scripts/core/load-env-enhanced.sh [environment]

services:
  weblogic-a:
    image: ${WEBLOGIC_FULL_IMAGE:-edissonz8809/weblogic-feature-flags:v1.0.0}
    container_name: ${WEBLOGIC_A_CONTAINER_NAME:-weblogic-a}
    ports:
      - "${WEBLOGIC_A_EXTERNAL_PORT:-7001}:7001"
    environment:
      - ADMIN_PASSWORD=${WEBLOGIC_ADMIN_PASSWORD:-welcome1}
      - FEATURE_FLAGS_ENABLED=${FEATURE_FLAGS_ENABLED:-true}
    networks:
      - ${DOCKER_NETWORK_NAME:-weblogic-network}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7001/console"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 120s

  weblogic-b:
    image: ${WEBLOGIC_FULL_IMAGE:-edissonz8809/weblogic-feature-flags:v1.0.0}
    container_name: ${WEBLOGIC_B_CONTAINER_NAME:-weblogic-b}
    ports:
      - "${WEBLOGIC_B_EXTERNAL_PORT:-7002}:7001"
    environment:
      - ADMIN_PASSWORD=${WEBLOGIC_ADMIN_PASSWORD:-welcome1}
      - FEATURE_FLAGS_ENABLED=${FEATURE_FLAGS_ENABLED:-true}
    networks:
      - ${DOCKER_NETWORK_NAME:-weblogic-network}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7001/console"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 120s

  haproxy:
    image: ${HAPROXY_FULL_IMAGE:-edissonz8809/haproxy-advanced:v1.1.0}
    container_name: ${HAPROXY_CONTAINER_NAME:-haproxy}
    ports:
      - "${HAPROXY_HTTP_EXTERNAL_PORT:-8083}:80"
      - "${HAPROXY_HTTPS_EXTERNAL_PORT:-8444}:443"
      - "${HAPROXY_STATS_EXTERNAL_PORT:-8404}:8404"
      - "${HAPROXY_UI_EXTERNAL_PORT:-8082}:8082"
      - "${HAPROXY_API_EXTERNAL_PORT:-8081}:8081"
    volumes:
      - haproxy_config:/usr/local/etc/haproxy
      - haproxy_ssl:/etc/ssl
    networks:
      - ${DOCKER_NETWORK_NAME:-weblogic-network}
    depends_on:
      - weblogic-a
      - weblogic-b
    environment:
      - STATS_USER=${HAPROXY_STATS_USER:-admin}
      - STATS_PASSWORD=${HAPROXY_STATS_PASSWORD:-admin123}
      - ENABLE_DYNAMIC_IP_UPDATE=${ENABLE_DYNAMIC_IP_UPDATE:-true}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8404/stats"]
      interval: 30s
      timeout: 10s
      retries: 3

  orcldb:
    image: ${ORACLE_FULL_IMAGE:-edissonz8809/oracle-setup:v1.0.0}
    container_name: ${ORACLE_CONTAINER_NAME:-orcldb}
    ports:
      - "${ORACLE_EXTERNAL_PORT:-1521}:1521"
      - "${ORACLE_EM_EXTERNAL_PORT:-5500}:5500"
    environment:
      - ORACLE_PWD=${ORACLE_ADMIN_PASSWORD:-welcome1}
      - ORACLE_SID=${ORACLE_SID:-XE}
      - ORACLE_PDB=${ORACLE_PDB:-XEPDB1}
      - ORACLE_CHARSET=${ORACLE_CHARSET:-AL32UTF8}
    volumes:
      - oracle_data:/opt/oracle/oradata
    networks:
      - ${DOCKER_NETWORK_NAME:-weblogic-network}
    healthcheck:
      test: ["CMD", "sqlplus", "-L", "sys/${ORACLE_ADMIN_PASSWORD:-welcome1}@localhost:1521/XE", "as", "sysdba", "<<<", "SELECT 1 FROM DUAL;"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 180s

  mkdocs:
    image: ${MKDOCS_FULL_IMAGE:-edissonz8809/mkdocs-server:v1.0.0}
    container_name: mkdocs-server
    ports:
      - "${MKDOCS_EXTERNAL_PORT:-8000}:8000"
    volumes:
      - ./docs:/docs
      - mkdocs_site:/site
    networks:
      - ${DOCKER_NETWORK_NAME:-weblogic-network}
    environment:
      - SITE_NAME=${MKDOCS_SITE_NAME:-Docker WebLogic Oracle Documentation}
      - SITE_DESCRIPTION=${MKDOCS_SITE_DESCRIPTION:-Comprehensive documentation}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  oracle_data:
    name: ${ORACLE_VOLUME_PREFIX:-oracle_data}_${COMPOSE_PROJECT_NAME:-weblogic-haproxy}
  haproxy_config:
    name: ${HAPROXY_VOLUME_PREFIX:-haproxy_data}_config_${COMPOSE_PROJECT_NAME:-weblogic-haproxy}
  haproxy_ssl:
    name: ${HAPROXY_VOLUME_PREFIX:-haproxy_data}_ssl_${COMPOSE_PROJECT_NAME:-weblogic-haproxy}
  mkdocs_site:
    name: ${MKDOCS_VOLUME_PREFIX:-mkdocs_data}_site_${COMPOSE_PROJECT_NAME:-weblogic-haproxy}

networks:
  weblogic-network:
    name: ${DOCKER_NETWORK_NAME:-weblogic-network}
    driver: ${DOCKER_NETWORK_DRIVER:-bridge}
    ipam:
      config:
        - subnet: ${DOCKER_NETWORK_SUBNET:-172.20.0.0/16}
          gateway: ${DOCKER_NETWORK_GATEWAY:-172.20.0.1}
EOF
    
    # Reemplazar archivo original
    mv "$temp_file" "$compose_file"
    echo -e "${GREEN}✓ docker-compose.yml migrado${NC}"
    
    return 0
}

# Función para migrar scripts existentes
migrate_scripts() {
    echo -e "${BLUE}=== Migrando Scripts Existentes ===${NC}"
    
    # Lista de scripts a actualizar
    local scripts_to_update=(
        "scripts/services/manage-services.sh"
        "scripts/maintenance/auto-update-haproxy.sh"
        "scripts/build/build-all-images.sh"
    )
    
    for script in "${scripts_to_update[@]}"; do
        local script_path="$PROJECT_ROOT/$script"
        
        if [ -f "$script_path" ]; then
            echo -e "${BLUE}Actualizando: $script${NC}"
            
            # Crear backup del script
            cp "$script_path" "$script_path.pre-migration"
            
            # Actualizar referencia al load-env
            sed -i 's|scripts/core/load-env.sh|scripts/core/load-env-enhanced.sh|g' "$script_path"
            
            # Actualizar llamadas a load_env
            sed -i 's|load_env > /dev/null 2>&1|load_env_enhanced "${ENVIRONMENT:-development}" 2>/dev/null|g' "$script_path"
            
            echo -e "${GREEN}✓ Script actualizado: $script${NC}"
        else
            echo -e "${YELLOW}⚠ Script no encontrado: $script${NC}"
        fi
    done
    
    return 0
}

# Función para validar migración
validate_migration() {
    echo -e "${BLUE}=== Validando Migración ===${NC}"
    
    local errors=0
    
    # Verificar que los nuevos archivos existen
    local required_files=(
        "scripts/.env"
        "scripts/.env.development"
        "scripts/.env.staging"
        "scripts/.env.production"
        "scripts/core/load-env-enhanced.sh"
        "scripts/validation/validate-env-variables.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            echo -e "${GREEN}✓ Archivo presente: $file${NC}"
        else
            echo -e "${RED}✗ Archivo faltante: $file${NC}"
            ((errors++))
        fi
    done
    
    # Probar carga de variables
    echo -e "${BLUE}Probando carga de variables...${NC}"
    
    if source "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" development 2>/dev/null; then
        echo -e "${GREEN}✓ Carga de variables development: OK${NC}"
    else
        echo -e "${RED}✗ Error cargando variables development${NC}"
        ((errors++))
    fi
    
    # Verificar variables críticas
    local critical_vars=(
        "WEBLOGIC_A_EXTERNAL_PORT"
        "HAPROXY_HTTP_EXTERNAL_PORT"
        "DOCKER_NAMESPACE"
    )
    
    for var in "${critical_vars[@]}"; do
        if [ -n "${!var}" ]; then
            echo -e "${GREEN}✓ Variable crítica $var: ${!var}${NC}"
        else
            echo -e "${RED}✗ Variable crítica $var no definida${NC}"
            ((errors++))
        fi
    done
    
    # Ejecutar validación completa
    if [ -x "$PROJECT_ROOT/scripts/validation/validate-env-variables.sh" ]; then
        echo -e "${BLUE}Ejecutando validación completa...${NC}"
        if "$PROJECT_ROOT/scripts/validation/validate-env-variables.sh" development >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Validación completa: EXITOSA${NC}"
        else
            echo -e "${YELLOW}⚠ Validación completa: CON ADVERTENCIAS${NC}"
        fi
    fi
    
    # Resultado final
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✅ MIGRACIÓN VÁLIDA${NC}"
        return 0
    else
        echo -e "${RED}❌ $errors ERRORES EN MIGRACIÓN${NC}"
        return 1
    fi
}

# Función para rollback
rollback_migration() {
    echo -e "${BLUE}=== Rollback de Migración ===${NC}"
    
    local backup_dir
    if [ -f "$PROJECT_ROOT/.last-backup" ]; then
        backup_dir=$(cat "$PROJECT_ROOT/.last-backup")
    else
        echo -e "${RED}Error: No se encontró información del último backup${NC}"
        return 1
    fi
    
    if [ ! -d "$backup_dir" ]; then
        echo -e "${RED}Error: Directorio de backup no encontrado: $backup_dir${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Restaurando desde: $backup_dir${NC}"
    
    # Restaurar archivos
    local files_to_restore=(
        "scripts/.env"
        "docker-compose.yml"
        "scripts/core/load-env.sh"
        "scripts/services/manage-services.sh"
    )
    
    for file in "${files_to_restore[@]}"; do
        local backup_file="$backup_dir/$file"
        local target_file="$PROJECT_ROOT/$file"
        
        if [ -f "$backup_file" ]; then
            cp "$backup_file" "$target_file"
            echo -e "${GREEN}✓ Restaurado: $file${NC}"
        else
            echo -e "${YELLOW}⚠ Backup no encontrado: $file${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Rollback completado${NC}"
    return 0
}

# Función para limpiar archivos temporales
clean_temp_files() {
    echo -e "${BLUE}=== Limpiando Archivos Temporales ===${NC}"
    
    # Archivos temporales a limpiar
    find "$PROJECT_ROOT" -name "*.pre-migration" -type f | while read -r file; do
        echo -e "${YELLOW}Eliminando: $file${NC}"
        rm -f "$file"
    done
    
    # Limpiar archivos .tmp
    find "$PROJECT_ROOT" -name "*.tmp" -type f | while read -r file; do
        echo -e "${YELLOW}Eliminando: $file${NC}"
        rm -f "$file"
    done
    
    echo -e "${GREEN}✓ Limpieza completada${NC}"
}

# Función principal
main() {
    local do_backup=false
    local do_migrate=false
    local do_validate=false
    local do_rollback=false
    local do_clean=false
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --backup)
                do_backup=true
                shift
                ;;
            --migrate)
                do_migrate=true
                shift
                ;;
            --validate)
                do_validate=true
                shift
                ;;
            --rollback)
                do_rollback=true
                shift
                ;;
            --clean)
                do_clean=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Opción desconocida: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Si no se especifica ninguna acción, mostrar ayuda
    if [ "$do_backup" = false ] && [ "$do_migrate" = false ] && [ "$do_validate" = false ] && [ "$do_rollback" = false ] && [ "$do_clean" = false ]; then
        echo -e "${YELLOW}No se especificó ninguna acción${NC}"
        show_help
        exit 1
    fi
    
    # Ejecutar acciones en orden
    local exit_code=0
    
    if [ "$do_rollback" = true ]; then
        rollback_migration || exit_code=1
    fi
    
    if [ "$do_backup" = true ]; then
        create_backup || exit_code=1
    fi
    
    if [ "$do_migrate" = true ]; then
        migrate_docker_compose || exit_code=1
        migrate_scripts || exit_code=1
    fi
    
    if [ "$do_validate" = true ]; then
        validate_migration || exit_code=1
    fi
    
    if [ "$do_clean" = true ]; then
        clean_temp_files || exit_code=1
    fi
    
    # Mensaje final
    if [ $exit_code -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 MIGRACIÓN COMPLETADA EXITOSAMENTE${NC}"
        echo -e "${BLUE}Próximos pasos:${NC}"
        echo -e "  1. Probar carga de variables: source scripts/core/load-env-enhanced.sh development"
        echo -e "  2. Validar configuración: ./scripts/validation/validate-env-variables.sh"
        echo -e "  3. Probar servicios: ./scripts/services/manage-services.sh status"
    else
        echo ""
        echo -e "${RED}❌ ERRORES EN LA MIGRACIÓN${NC}"
        echo -e "${YELLOW}Revise los errores y ejecute rollback si es necesario${NC}"
    fi
    
    exit $exit_code
}

# Ejecutar función principal
main "$@"
