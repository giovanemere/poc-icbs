#!/bin/bash
#
# Script para gestionar configuraciones de HAProxy
#

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HAPROXY_CONFIG_DIR="$PROJECT_DIR/haproxy/config"

# Función de ayuda
show_help() {
    echo "Uso: $0 [comando] [opciones]"
    echo ""
    echo "Comandos disponibles:"
    echo "  list                    Listar configuraciones disponibles"
    echo "  current                 Mostrar configuración actual"
    echo "  use <config>            Cambiar a una configuración específica"
    echo "  validate <config>       Validar una configuración"
    echo "  backup                  Crear backup de la configuración actual"
    echo "  restore <backup>        Restaurar desde un backup"
    echo "  diff <config1> <config2> Comparar dos configuraciones"
    echo "  help                    Mostrar esta ayuda"
    echo ""
    echo "Configuraciones disponibles:"
    echo "  basic                   Configuración básica"
    echo "  advanced                Configuración avanzada (recomendada)"
    echo "  fixed                   Configuración corregida"
    echo ""
    echo "Ejemplos:"
    echo "  $0 list                 # Listar todas las configuraciones"
    echo "  $0 use advanced         # Cambiar a configuración avanzada"
    echo "  $0 validate advanced    # Validar configuración avanzada"
    echo "  $0 backup               # Crear backup de configuración actual"
    echo ""
}

# Función para listar configuraciones
list_configs() {
    echo -e "${BLUE}=== Configuraciones de HAProxy Disponibles ===${NC}"
    echo ""
    
    if [ -f "$HAPROXY_CONFIG_DIR/haproxy.cfg" ]; then
        echo -e "${GREEN}✓ current${NC}               - Configuración actualmente en uso"
    fi
    
    if [ -f "$HAPROXY_CONFIG_DIR/haproxy-advanced.cfg" ]; then
        echo -e "${GREEN}✓ advanced${NC}              - Configuración avanzada con A/B testing y dashboard"
    fi
    
    if [ -f "$HAPROXY_CONFIG_DIR/haproxy-fixed.cfg" ]; then
        echo -e "${GREEN}✓ fixed${NC}                 - Configuración corregida"
    fi
    
    echo ""
    echo "Backups disponibles:"
    if ls "$HAPROXY_CONFIG_DIR"/haproxy-backup-*.cfg 1> /dev/null 2>&1; then
        for backup in "$HAPROXY_CONFIG_DIR"/haproxy-backup-*.cfg; do
            backup_name=$(basename "$backup" .cfg)
            backup_date=$(echo "$backup_name" | sed 's/haproxy-backup-//')
            echo -e "${YELLOW}📦 $backup_name${NC}    - Backup del $backup_date"
        done
    else
        echo -e "${YELLOW}No hay backups disponibles${NC}"
    fi
    echo ""
}

# Función para mostrar configuración actual
show_current() {
    echo -e "${BLUE}=== Configuración Actual de HAProxy ===${NC}"
    echo ""
    
    if [ -f "$HAPROXY_CONFIG_DIR/haproxy.cfg" ]; then
        echo -e "${GREEN}Archivo activo:${NC} haproxy.cfg"
        echo ""
        
        # Mostrar información básica de la configuración
        echo "Información de la configuración:"
        echo "- Líneas totales: $(wc -l < "$HAPROXY_CONFIG_DIR/haproxy.cfg")"
        echo "- Frontends: $(grep -c "^frontend" "$HAPROXY_CONFIG_DIR/haproxy.cfg" || echo "0")"
        echo "- Backends: $(grep -c "^backend" "$HAPROXY_CONFIG_DIR/haproxy.cfg" || echo "0")"
        echo "- Listen sections: $(grep -c "^listen" "$HAPROXY_CONFIG_DIR/haproxy.cfg" || echo "0")"
        
        # Verificar si tiene características avanzadas
        if grep -q "dashboard" "$HAPROXY_CONFIG_DIR/haproxy.cfg"; then
            echo -e "- Dashboard: ${GREEN}✓ Habilitado${NC}"
        else
            echo -e "- Dashboard: ${RED}✗ No configurado${NC}"
        fi
        
        if grep -q "canary_percent" "$HAPROXY_CONFIG_DIR/haproxy.cfg"; then
            echo -e "- Canary Deployment: ${GREEN}✓ Habilitado${NC}"
        else
            echo -e "- Canary Deployment: ${RED}✗ No configurado${NC}"
        fi
        
        if grep -q "ab_test_cookie" "$HAPROXY_CONFIG_DIR/haproxy.cfg"; then
            echo -e "- A/B Testing: ${GREEN}✓ Habilitado${NC}"
        else
            echo -e "- A/B Testing: ${RED}✗ No configurado${NC}"
        fi
        
    else
        echo -e "${RED}No se encontró configuración activa (haproxy.cfg)${NC}"
    fi
    echo ""
}

# Función para cambiar configuración
use_config() {
    local config_name="$1"
    local source_file=""
    
    case "$config_name" in
        "advanced")
            source_file="$HAPROXY_CONFIG_DIR/haproxy-advanced.cfg"
            ;;
        "fixed")
            source_file="$HAPROXY_CONFIG_DIR/haproxy-fixed.cfg"
            ;;
        "basic")
            source_file="$HAPROXY_CONFIG_DIR/haproxy-basic.cfg"
            ;;
        *)
            echo -e "${RED}Error: Configuración '$config_name' no reconocida${NC}"
            echo "Configuraciones disponibles: advanced, fixed, basic"
            return 1
            ;;
    esac
    
    if [ ! -f "$source_file" ]; then
        echo -e "${RED}Error: No se encontró el archivo $source_file${NC}"
        return 1
    fi
    
    # Crear backup de la configuración actual
    if [ -f "$HAPROXY_CONFIG_DIR/haproxy.cfg" ]; then
        local backup_name="haproxy-backup-$(date +%Y%m%d_%H%M%S).cfg"
        cp "$HAPROXY_CONFIG_DIR/haproxy.cfg" "$HAPROXY_CONFIG_DIR/$backup_name"
        echo -e "${YELLOW}✓ Backup creado: $backup_name${NC}"
    fi
    
    # Copiar nueva configuración
    cp "$source_file" "$HAPROXY_CONFIG_DIR/haproxy.cfg"
    echo -e "${GREEN}✓ Configuración cambiada a: $config_name${NC}"
    
    # Validar la nueva configuración
    echo "Validando nueva configuración..."
    if validate_config "current"; then
        echo -e "${GREEN}✓ Configuración válida${NC}"
        
        # Preguntar si reiniciar HAProxy
        read -p "¿Deseas reiniciar HAProxy para aplicar los cambios? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Reiniciando HAProxy..."
            cd "$PROJECT_DIR"
            if [ -f "start-with-images.sh" ]; then
                ./start-with-images.sh restart
                echo -e "${GREEN}✓ HAProxy reiniciado correctamente${NC}"
            else
                echo -e "${YELLOW}Advertencia: No se encontró start-with-images.sh${NC}"
                echo "Reinicia HAProxy manualmente para aplicar los cambios"
            fi
        fi
    else
        echo -e "${RED}✗ Error en la configuración. Restaurando backup...${NC}"
        if [ -f "$HAPROXY_CONFIG_DIR/$backup_name" ]; then
            cp "$HAPROXY_CONFIG_DIR/$backup_name" "$HAPROXY_CONFIG_DIR/haproxy.cfg"
            echo -e "${GREEN}✓ Configuración restaurada${NC}"
        fi
        return 1
    fi
}

# Función para validar configuración
validate_config() {
    local config_name="$1"
    local config_file=""
    
    case "$config_name" in
        "current")
            config_file="$HAPROXY_CONFIG_DIR/haproxy.cfg"
            ;;
        "advanced")
            config_file="$HAPROXY_CONFIG_DIR/haproxy-advanced.cfg"
            ;;
        "fixed")
            config_file="$HAPROXY_CONFIG_DIR/haproxy-fixed.cfg"
            ;;
        "basic")
            config_file="$HAPROXY_CONFIG_DIR/haproxy-basic.cfg"
            ;;
        *)
            echo -e "${RED}Error: Configuración '$config_name' no reconocida${NC}"
            return 1
            ;;
    esac
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: No se encontró el archivo $config_file${NC}"
        return 1
    fi
    
    echo "Validando configuración: $config_name"
    
    # Verificar si HAProxy está corriendo para usar docker exec
    if docker ps | grep -q haproxy; then
        # Copiar archivo temporalmente al contenedor y validar
        docker cp "$config_file" haproxy:/tmp/haproxy-test.cfg
        if docker exec haproxy haproxy -f /tmp/haproxy-test.cfg -c; then
            docker exec haproxy rm /tmp/haproxy-test.cfg
            echo -e "${GREEN}✓ Configuración válida${NC}"
            return 0
        else
            docker exec haproxy rm /tmp/haproxy-test.cfg 2>/dev/null || true
            echo -e "${RED}✗ Configuración inválida${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Advertencia: HAProxy no está corriendo. No se puede validar la configuración.${NC}"
        echo "Verificando sintaxis básica..."
        
        # Verificaciones básicas de sintaxis
        if grep -q "^global" "$config_file" && grep -q "^defaults" "$config_file"; then
            echo -e "${GREEN}✓ Estructura básica correcta${NC}"
            return 0
        else
            echo -e "${RED}✗ Estructura básica incorrecta${NC}"
            return 1
        fi
    fi
}

# Función para crear backup
create_backup() {
    if [ ! -f "$HAPROXY_CONFIG_DIR/haproxy.cfg" ]; then
        echo -e "${RED}Error: No se encontró configuración actual para hacer backup${NC}"
        return 1
    fi
    
    local backup_name="haproxy-backup-$(date +%Y%m%d_%H%M%S).cfg"
    cp "$HAPROXY_CONFIG_DIR/haproxy.cfg" "$HAPROXY_CONFIG_DIR/$backup_name"
    echo -e "${GREEN}✓ Backup creado: $backup_name${NC}"
    echo "Ubicación: $HAPROXY_CONFIG_DIR/$backup_name"
}

# Función para restaurar backup
restore_backup() {
    local backup_name="$1"
    local backup_file="$HAPROXY_CONFIG_DIR/haproxy-backup-$backup_name.cfg"
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Error: No se encontró el backup $backup_name${NC}"
        echo "Backups disponibles:"
        ls "$HAPROXY_CONFIG_DIR"/haproxy-backup-*.cfg 2>/dev/null | sed 's/.*haproxy-backup-/  - /' | sed 's/.cfg$//' || echo "  Ninguno"
        return 1
    fi
    
    # Crear backup de la configuración actual antes de restaurar
    create_backup
    
    # Restaurar backup
    cp "$backup_file" "$HAPROXY_CONFIG_DIR/haproxy.cfg"
    echo -e "${GREEN}✓ Configuración restaurada desde backup: $backup_name${NC}"
    
    # Validar configuración restaurada
    if validate_config "current"; then
        echo -e "${GREEN}✓ Configuración restaurada es válida${NC}"
    else
        echo -e "${RED}✗ Advertencia: La configuración restaurada puede tener problemas${NC}"
    fi
}

# Función para comparar configuraciones
diff_configs() {
    local config1="$1"
    local config2="$2"
    local file1=""
    local file2=""
    
    # Resolver nombres de archivos
    case "$config1" in
        "current") file1="$HAPROXY_CONFIG_DIR/haproxy.cfg" ;;
        "advanced") file1="$HAPROXY_CONFIG_DIR/haproxy-advanced.cfg" ;;
        "fixed") file1="$HAPROXY_CONFIG_DIR/haproxy-fixed.cfg" ;;
        "basic") file1="$HAPROXY_CONFIG_DIR/haproxy-basic.cfg" ;;
        *) file1="$HAPROXY_CONFIG_DIR/haproxy-backup-$config1.cfg" ;;
    esac
    
    case "$config2" in
        "current") file2="$HAPROXY_CONFIG_DIR/haproxy.cfg" ;;
        "advanced") file2="$HAPROXY_CONFIG_DIR/haproxy-advanced.cfg" ;;
        "fixed") file2="$HAPROXY_CONFIG_DIR/haproxy-fixed.cfg" ;;
        "basic") file2="$HAPROXY_CONFIG_DIR/haproxy-basic.cfg" ;;
        *) file2="$HAPROXY_CONFIG_DIR/haproxy-backup-$config2.cfg" ;;
    esac
    
    if [ ! -f "$file1" ]; then
        echo -e "${RED}Error: No se encontró $config1${NC}"
        return 1
    fi
    
    if [ ! -f "$file2" ]; then
        echo -e "${RED}Error: No se encontró $config2${NC}"
        return 1
    fi
    
    echo -e "${BLUE}=== Diferencias entre $config1 y $config2 ===${NC}"
    echo ""
    
    if diff -u "$file1" "$file2"; then
        echo -e "${GREEN}✓ Las configuraciones son idénticas${NC}"
    else
        echo ""
        echo -e "${YELLOW}Las configuraciones son diferentes (mostrado arriba)${NC}"
    fi
}

# Función principal
main() {
    case "${1:-help}" in
        list)
            list_configs
            ;;
        current)
            show_current
            ;;
        use)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Especifica una configuración${NC}"
                echo "Uso: $0 use <config>"
                exit 1
            fi
            use_config "$2"
            ;;
        validate)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Especifica una configuración${NC}"
                echo "Uso: $0 validate <config>"
                exit 1
            fi
            validate_config "$2"
            ;;
        backup)
            create_backup
            ;;
        restore)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Especifica un backup${NC}"
                echo "Uso: $0 restore <backup>"
                exit 1
            fi
            restore_backup "$2"
            ;;
        diff)
            if [ -z "$2" ] || [ -z "$3" ]; then
                echo -e "${RED}Error: Especifica dos configuraciones${NC}"
                echo "Uso: $0 diff <config1> <config2>"
                exit 1
            fi
            diff_configs "$2" "$3"
            ;;
        help)
            show_help
            ;;
        *)
            echo -e "${RED}Error: Comando desconocido '$1'${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
