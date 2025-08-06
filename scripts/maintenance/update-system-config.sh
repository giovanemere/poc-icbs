#!/bin/bash

# =============================================================================
# SCRIPT DE ACTUALIZACIÓN AUTOMÁTICA DEL SISTEMA
# =============================================================================
# Este script actualiza automáticamente todos los archivos del sistema
# para usar la configuración centralizada del archivo .env

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${PROJECT_ROOT}/backups/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/tmp/system-update-$(date +%Y%m%d_%H%M%S).log"

# Cargar variables de entorno
source "${PROJECT_ROOT}/scripts/core/load-env.sh"

# Función para logging
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Función para crear backup
create_backup() {
    local file="$1"
    local backup_file="${BACKUP_DIR}/$(basename "$file").backup"
    
    if [[ -f "$file" ]]; then
        mkdir -p "$(dirname "$backup_file")"
        cp "$file" "$backup_file"
        log "${GREEN}✅ Backup creado: $backup_file${NC}"
    fi
}

# Función para actualizar archivo Python
update_python_file() {
    local file="$1"
    local temp_file="${file}.tmp"
    
    log "${BLUE}🔧 Actualizando archivo Python: $file${NC}"
    create_backup "$file"
    
    # Actualizar admin_ui.py
    if [[ "$file" == *"admin_ui.py" ]]; then
        sed "s|API_BASE_URL = 'http://localhost:8081/api'|API_BASE_URL = os.getenv('HAPROXY_API_URL', 'http://localhost:8081/api')|g" "$file" > "$temp_file"
        
        # Añadir import os si no existe
        if ! grep -q "import os" "$file"; then
            sed '1i import os' "$temp_file" > "${temp_file}.2"
            mv "${temp_file}.2" "$temp_file"
        fi
        
        # Añadir carga de dotenv si no existe
        if ! grep -q "from dotenv import load_dotenv" "$file"; then
            sed '/import os/a from dotenv import load_dotenv\nload_dotenv()' "$temp_file" > "${temp_file}.2"
            mv "${temp_file}.2" "$temp_file"
        fi
        
        mv "$temp_file" "$file"
        log "${GREEN}✅ Actualizado: $file${NC}"
    fi
}

# Función para actualizar Docker Compose
update_docker_compose() {
    local file="$1"
    local temp_file="${file}.tmp"
    
    log "${BLUE}🔧 Actualizando Docker Compose: $file${NC}"
    create_backup "$file"
    
    # Reemplazar puertos hardcodeados con variables
    sed -e "s|\"8083:80\"|\"${HAPROXY_HTTP_PORT}:80\"|g" \
        -e "s|\"8444:443\"|\"${HAPROXY_HTTPS_PORT}:443\"|g" \
        -e "s|\"8404:8404\"|\"${HAPROXY_STATS_PORT}:8404\"|g" \
        -e "s|\"8081:8083\"|\"${HAPROXY_API_EXTERNAL_PORT}:${HAPROXY_API_INTERNAL_PORT}\"|g" \
        -e "s|\"8082:8082\"|\"${HAPROXY_UI_PORT}:8082\"|g" \
        "$file" > "$temp_file"
    
    mv "$temp_file" "$file"
    log "${GREEN}✅ Actualizado: $file${NC}"
}

# Función para actualizar scripts bash
update_bash_script() {
    local file="$1"
    local temp_file="${file}.tmp"
    
    log "${BLUE}🔧 Actualizando script Bash: $file${NC}"
    create_backup "$file"
    
    # Añadir carga de variables de entorno al inicio del script
    if ! grep -q "source.*load-env.sh" "$file"; then
        # Encontrar la línea después del shebang
        awk '
        NR==1 && /^#!/ { print; print ""; print "# Cargar configuración centralizada"; print "source \"$(dirname \"$0\")/load-env.sh\" 2>/dev/null || source \"$(dirname \"$0\")/scripts/core/load-env.sh\" 2>/dev/null || true"; print ""; next }
        { print }
        ' "$file" > "$temp_file"
        
        mv "$temp_file" "$file"
    fi
    
    # Reemplazar URLs hardcodeadas
    sed -i.bak \
        -e "s|http://localhost:8404/stats|${HAPROXY_STATS_URL}|g" \
        -e "s|http://localhost:8082|${HAPROXY_UI_URL}|g" \
        -e "s|http://localhost:8081|${HAPROXY_API_URL%/api}|g" \
        -e "s|http://localhost:7001|${WEBLOGIC_A_URL}|g" \
        -e "s|http://localhost:7002|${WEBLOGIC_B_URL}|g" \
        "$file"
    
    rm -f "${file}.bak"
    log "${GREEN}✅ Actualizado: $file${NC}"
}

# Función para actualizar configuración HAProxy
update_haproxy_config() {
    local file="$1"
    
    log "${BLUE}🔧 Actualizando configuración HAProxy: $file${NC}"
    create_backup "$file"
    
    # Crear nueva configuración con variables
    cat > "$file" << EOF
# HAProxy Configuration - Generated from .env
global
    daemon
    maxconn ${MAX_CONNECTIONS:-1000}
    
defaults
    mode http
    timeout connect ${CONNECTION_TIMEOUT:-30}s
    timeout client ${REQUEST_TIMEOUT:-60}s
    timeout server ${REQUEST_TIMEOUT:-60}s
    timeout http-keep-alive ${KEEPALIVE_TIMEOUT:-5}s

# Frontend HTTP
frontend weblogic_frontend
    bind *:80
    default_backend weblogic_main

# Frontend HTTPS
frontend weblogic_https_frontend
    bind *:443 ssl crt /etc/ssl/certs/haproxy.pem
    default_backend weblogic_main

# Backend WebLogic
backend weblogic_main
    balance roundrobin
    option httpchk GET /console
    server weblogic-a ${WEBLOGIC_A_HOST}:${WEBLOGIC_A_PORT} check
    server weblogic-b ${WEBLOGIC_B_HOST}:${WEBLOGIC_B_PORT} check

# Stats
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 5s
    stats admin if TRUE
    stats auth ${HAPROXY_STATS_USER}:${HAPROXY_STATS_PASSWORD}

# API de administración
listen api
    bind *:${HAPROXY_API_INTERNAL_PORT}
    stats enable
    stats uri /
    stats refresh 5s
    stats admin if TRUE
    stats show-desc "HAProxy API Interface"
EOF
    
    log "${GREEN}✅ Actualizado: $file${NC}"
}

# Función principal de actualización
main() {
    log "${BLUE}🚀 Iniciando actualización del sistema...${NC}"
    log "${BLUE}📁 Directorio del proyecto: $PROJECT_ROOT${NC}"
    log "${BLUE}📝 Log file: $LOG_FILE${NC}"
    
    # Crear directorio de backup
    mkdir -p "$BACKUP_DIR"
    log "${GREEN}📦 Directorio de backup creado: $BACKUP_DIR${NC}"
    
    # Fase 1: Archivos críticos
    log "${YELLOW}📋 FASE 1: Actualizando archivos críticos...${NC}"
    
    # HAProxy Scripts
    if [[ -f "${PROJECT_ROOT}/haproxy/scripts/admin_ui.py" ]]; then
        update_python_file "${PROJECT_ROOT}/haproxy/scripts/admin_ui.py"
    fi
    
    # Docker Compose
    if [[ -f "${PROJECT_ROOT}/config/docker-compose.yml" ]]; then
        update_docker_compose "${PROJECT_ROOT}/config/docker-compose.yml"
    fi
    
    # HAProxy Config
    if [[ -f "${PROJECT_ROOT}/haproxy/config/haproxy.cfg" ]]; then
        update_haproxy_config "${PROJECT_ROOT}/haproxy/config/haproxy.cfg"
    fi
    
    # Fase 2: Scripts principales
    log "${YELLOW}📋 FASE 2: Actualizando scripts principales...${NC}"
    
    local main_scripts=(
        "start-all.sh"
        "manage-services.sh"
        "update_dashboard.sh"
    )
    
    for script in "${main_scripts[@]}"; do
        if [[ -f "${PROJECT_ROOT}/$script" ]]; then
            update_bash_script "${PROJECT_ROOT}/$script"
        fi
    done
    
    # Fase 3: Scripts de utilidades
    log "${YELLOW}📋 FASE 3: Actualizando scripts de utilidades...${NC}"
    
    find "${PROJECT_ROOT}/scripts" -name "*.sh" -type f | while read -r script; do
        if [[ "$script" != *"load-env.sh"* ]] && [[ "$script" != *"update-system-config.sh"* ]]; then
            update_bash_script "$script"
        fi
    done
    
    # Validación final
    log "${YELLOW}📋 FASE 4: Validación final...${NC}"
    
    if "${PROJECT_ROOT}/scripts/core/load-env.sh" validate; then
        log "${GREEN}✅ Validación exitosa${NC}"
    else
        log "${RED}❌ Error en validación${NC}"
        return 1
    fi
    
    # Resumen
    log "${GREEN}🎉 ACTUALIZACIÓN COMPLETADA${NC}"
    log "${GREEN}📦 Backups guardados en: $BACKUP_DIR${NC}"
    log "${GREEN}📝 Log completo en: $LOG_FILE${NC}"
    log "${BLUE}💡 Ejecuta './scripts/core/load-env.sh show' para ver la configuración${NC}"
    
    return 0
}

# Función de ayuda
show_help() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --dry-run    Mostrar qué archivos se actualizarían sin hacer cambios"
    echo "  --backup     Solo crear backups sin actualizar"
    echo "  --help       Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0                    # Actualización completa"
    echo "  $0 --dry-run         # Ver qué se actualizaría"
    echo "  $0 --backup          # Solo crear backups"
}

# Procesar argumentos
case "${1:-}" in
    "--dry-run")
        log "${YELLOW}🔍 Modo DRY-RUN: Mostrando archivos que se actualizarían...${NC}"
        # Implementar lógica de dry-run aquí
        ;;
    "--backup")
        log "${BLUE}📦 Creando solo backups...${NC}"
        # Implementar solo backup aquí
        ;;
    "--help"|"-h")
        show_help
        exit 0
        ;;
    "")
        main
        ;;
    *)
        echo "❌ Opción desconocida: $1"
        show_help
        exit 1
        ;;
esac
