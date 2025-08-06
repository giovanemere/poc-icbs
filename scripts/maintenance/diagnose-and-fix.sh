#!/bin/bash
# Script de diagnóstico y reparación completa del sistema

set -e

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Función para mostrar el banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Diagnóstico y Reparación del Sistema           ║"
    echo "║                    WebLogic + HAProxy + Docker               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para mostrar ayuda
show_help() {
    show_banner
    echo -e "${YELLOW}Uso: $0 [COMANDO]${NC}"
    echo ""
    echo -e "${BLUE}Comandos disponibles:${NC}"
    echo "  diagnose        Ejecutar diagnóstico completo"
    echo "  fix             Reparar problemas encontrados"
    echo "  fix-mkdocs      Reparar específicamente el servicio MkDocs"
    echo "  fix-scripts     Reparar permisos y enlaces de scripts"
    echo "  fix-env         Reparar configuración de variables de entorno"
    echo "  validate        Validar que todo funciona correctamente"
    echo "  clean-rebuild   Limpiar y reconstruir todo el sistema"
    echo ""
    echo -e "${BLUE}Ejemplos:${NC}"
    echo "  $0 diagnose     # Ejecutar diagnóstico completo"
    echo "  $0 fix          # Reparar todos los problemas"
    echo "  $0 fix-mkdocs   # Reparar solo MkDocs"
    echo "  $0 validate     # Validar el sistema"
}

# Función de diagnóstico
diagnose_system() {
    show_banner
    echo -e "${BLUE}=== DIAGNÓSTICO DEL SISTEMA ===${NC}"
    
    local issues_found=0
    
    echo ""
    echo -e "${YELLOW}1. Verificando estructura de archivos...${NC}"
    
    # Verificar archivos críticos
    critical_files=(
        ".env"
        "config/docker-compose.yml"
        "scripts/core/load-env.sh"
        "scripts/core/docker-compose-wrapper.sh"
        "manage-services.sh"
        "start-with-auto-update.sh"
        "requirements.txt"
        "Dockerfile.mkdocs-dev"
    )
    
    for file in "${critical_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            echo -e "  ${GREEN}✓${NC} $file existe"
        else
            echo -e "  ${RED}✗${NC} $file NO EXISTE"
            ((issues_found++))
        fi
    done
    
    echo ""
    echo -e "${YELLOW}2. Verificando permisos de scripts...${NC}"
    
    # Verificar permisos de scripts
    script_files=(
        "manage-services.sh"
        "start-with-auto-update.sh"
        "scripts/core/load-env.sh"
        "scripts/core/docker-compose-wrapper.sh"
        "scripts/maintenance/auto-update-haproxy.sh"
    )
    
    for script in "${script_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$script" ]]; then
            if [[ -x "$PROJECT_ROOT/$script" ]]; then
                echo -e "  ${GREEN}✓${NC} $script es ejecutable"
            else
                echo -e "  ${RED}✗${NC} $script NO es ejecutable"
                ((issues_found++))
            fi
        else
            echo -e "  ${RED}✗${NC} $script NO EXISTE"
            ((issues_found++))
        fi
    done
    
    echo ""
    echo -e "${YELLOW}3. Verificando variables de entorno...${NC}"
    
    if source "$PROJECT_ROOT/scripts/core/load-env.sh" && load_env > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Variables de entorno se cargan correctamente"
    else
        echo -e "  ${RED}✗${NC} Error al cargar variables de entorno"
        ((issues_found++))
    fi
    
    echo ""
    echo -e "${YELLOW}4. Verificando servicios Docker...${NC}"
    
    if docker --version > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Docker está instalado"
    else
        echo -e "  ${RED}✗${NC} Docker NO está instalado"
        ((issues_found++))
    fi
    
    if docker-compose --version > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Docker Compose está instalado"
    else
        echo -e "  ${RED}✗${NC} Docker Compose NO está instalado"
        ((issues_found++))
    fi
    
    echo ""
    echo -e "${YELLOW}5. Verificando estado de contenedores...${NC}"
    
    if "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" ps > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Docker Compose funciona correctamente"
        
        # Verificar contenedores específicos
        containers=("weblogic-a" "weblogic-b" "haproxy" "orcldb" "mkdocs-server")
        for container in "${containers[@]}"; do
            if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
                echo -e "  ${GREEN}✓${NC} $container está corriendo"
            elif docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
                status=$(docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep "$container" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}')
                if [[ "$status" == *"Restarting"* ]]; then
                    echo -e "  ${YELLOW}⚠${NC} $container está reiniciando continuamente"
                    ((issues_found++))
                else
                    echo -e "  ${RED}✗${NC} $container está detenido: $status"
                    ((issues_found++))
                fi
            else
                echo -e "  ${RED}✗${NC} $container no existe"
                ((issues_found++))
            fi
        done
    else
        echo -e "  ${RED}✗${NC} Error al ejecutar Docker Compose"
        ((issues_found++))
    fi
    
    echo ""
    echo -e "${YELLOW}6. Verificando conectividad de puertos...${NC}"
    
    # Verificar puertos críticos
    source "$PROJECT_ROOT/scripts/core/load-env.sh"
    load_env > /dev/null 2>&1
    
    ports=(
        "${WEBLOGIC_A_EXTERNAL_PORT:-7001}"
        "${WEBLOGIC_B_EXTERNAL_PORT:-7002}"
        "${HAPROXY_HTTP_EXTERNAL_PORT:-8083}"
        "${HAPROXY_STATS_EXTERNAL_PORT:-8404}"
        "${ORACLE_EXTERNAL_PORT:-1521}"
        "${MKDOCS_EXTERNAL_PORT:-8000}"
    )
    
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":${port} "; then
            echo -e "  ${GREEN}✓${NC} Puerto $port está en uso"
        else
            echo -e "  ${YELLOW}⚠${NC} Puerto $port no está en uso"
        fi
    done
    
    echo ""
    echo -e "${BLUE}=== RESUMEN DEL DIAGNÓSTICO ===${NC}"
    if [[ $issues_found -eq 0 ]]; then
        echo -e "${GREEN}✅ No se encontraron problemas críticos${NC}"
        return 0
    else
        echo -e "${RED}❌ Se encontraron $issues_found problemas${NC}"
        echo -e "${YELLOW}💡 Ejecuta '$0 fix' para reparar los problemas automáticamente${NC}"
        return 1
    fi
}

# Función para reparar MkDocs específicamente
fix_mkdocs() {
    echo -e "${BLUE}=== REPARANDO MKDOCS ===${NC}"
    
    # Detener el contenedor problemático
    echo -e "${YELLOW}Deteniendo contenedor mkdocs-server...${NC}"
    docker stop mkdocs-server 2>/dev/null || true
    docker rm mkdocs-server 2>/dev/null || true
    
    # Reconstruir la imagen
    echo -e "${YELLOW}Reconstruyendo imagen de MkDocs...${NC}"
    docker build -f "$PROJECT_ROOT/Dockerfile.mkdocs-dev" -t mkdocs-dev:latest "$PROJECT_ROOT"
    
    # Reiniciar el servicio
    echo -e "${YELLOW}Reiniciando servicio MkDocs...${NC}"
    "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" up -d mkdocs-server
    
    echo -e "${GREEN}✅ MkDocs reparado${NC}"
}

# Función para reparar permisos de scripts
fix_scripts() {
    echo -e "${BLUE}=== REPARANDO SCRIPTS ===${NC}"
    
    # Hacer ejecutables todos los scripts
    echo -e "${YELLOW}Aplicando permisos de ejecución...${NC}"
    find "$PROJECT_ROOT/scripts" -name "*.sh" -exec chmod +x {} \;
    chmod +x "$PROJECT_ROOT/manage-services.sh"
    chmod +x "$PROJECT_ROOT/start-with-auto-update.sh"
    chmod +x "$PROJECT_ROOT/stop-all-services.sh"
    
    # Verificar y reparar enlaces simbólicos
    echo -e "${YELLOW}Verificando enlaces simbólicos...${NC}"
    
    symlinks=(
        "build.sh:scripts/build/build.sh"
        "setup-canary.sh:scripts/canary/setup-canary.sh"
        "canary-control.sh:scripts/canary/canary-control.sh"
        "docker-compose.yml:config/docker-compose.yml"
        "deploy-war.sh:scripts/deploy/deploy-war.sh"
        "test-canary.sh:scripts/canary/test-canary.sh"
    )
    
    for symlink in "${symlinks[@]}"; do
        link_name="${symlink%%:*}"
        target="${symlink##*:}"
        
        if [[ -L "$PROJECT_ROOT/$link_name" ]]; then
            if [[ -e "$PROJECT_ROOT/$target" ]]; then
                echo -e "  ${GREEN}✓${NC} $link_name -> $target (OK)"
            else
                echo -e "  ${YELLOW}⚠${NC} $link_name -> $target (destino no existe)"
                rm "$PROJECT_ROOT/$link_name"
                if [[ -f "$PROJECT_ROOT/$target" ]]; then
                    ln -s "$target" "$PROJECT_ROOT/$link_name"
                    echo -e "  ${GREEN}✓${NC} Enlace reparado: $link_name"
                fi
            fi
        elif [[ -f "$PROJECT_ROOT/$target" ]]; then
            echo -e "  ${YELLOW}⚠${NC} Creando enlace faltante: $link_name"
            ln -s "$target" "$PROJECT_ROOT/$link_name"
        fi
    done
    
    echo -e "${GREEN}✅ Scripts reparados${NC}"
}

# Función para reparar variables de entorno
fix_env() {
    echo -e "${BLUE}=== REPARANDO CONFIGURACIÓN DE ENTORNO ===${NC}"
    
    if [[ ! -f "$PROJECT_ROOT/.env" ]]; then
        if [[ -f "$PROJECT_ROOT/.env.example" ]]; then
            echo -e "${YELLOW}Copiando .env.example a .env...${NC}"
            cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
        else
            echo -e "${RED}Error: No se encontró .env.example${NC}"
            return 1
        fi
    fi
    
    # Verificar que las variables críticas estén definidas
    source "$PROJECT_ROOT/scripts/core/load-env.sh"
    if load_env > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Variables de entorno configuradas correctamente${NC}"
    else
        echo -e "${RED}❌ Error en la configuración de variables de entorno${NC}"
        return 1
    fi
}

# Función para reparar todos los problemas
fix_all() {
    show_banner
    echo -e "${BLUE}=== REPARANDO TODOS LOS PROBLEMAS ===${NC}"
    
    fix_env
    fix_scripts
    fix_mkdocs
    
    echo ""
    echo -e "${GREEN}✅ Reparación completada${NC}"
    echo -e "${YELLOW}💡 Ejecuta '$0 validate' para verificar que todo funciona${NC}"
}

# Función para validar el sistema
validate_system() {
    echo -e "${BLUE}=== VALIDANDO SISTEMA ===${NC}"
    
    # Ejecutar diagnóstico
    if diagnose_system; then
        echo ""
        echo -e "${YELLOW}Probando funcionalidades básicas...${NC}"
        
        # Probar carga de variables de entorno
        if source "$PROJECT_ROOT/scripts/core/load-env.sh" && load_env > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} Carga de variables de entorno"
        else
            echo -e "  ${RED}✗${NC} Carga de variables de entorno"
            return 1
        fi
        
        # Probar docker-compose
        if "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" ps > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} Docker Compose wrapper"
        else
            echo -e "  ${RED}✗${NC} Docker Compose wrapper"
            return 1
        fi
        
        # Probar manage-services.sh
        if "$PROJECT_ROOT/manage-services.sh" status > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} Script de gestión de servicios"
        else
            echo -e "  ${RED}✗${NC} Script de gestión de servicios"
            return 1
        fi
        
        echo ""
        echo -e "${GREEN}✅ Sistema validado correctamente${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Validación fallida${NC}"
        return 1
    fi
}

# Función para limpiar y reconstruir
clean_rebuild() {
    echo -e "${BLUE}=== LIMPIEZA Y RECONSTRUCCIÓN COMPLETA ===${NC}"
    
    echo -e "${YELLOW}⚠ ADVERTENCIA: Esto detendrá todos los servicios y eliminará datos temporales${NC}"
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operación cancelada${NC}"
        return 0
    fi
    
    # Detener todos los servicios
    echo -e "${YELLOW}Deteniendo servicios...${NC}"
    "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" down --volumes --remove-orphans 2>/dev/null || true
    
    # Limpiar imágenes y contenedores
    echo -e "${YELLOW}Limpiando contenedores e imágenes...${NC}"
    docker system prune -f
    
    # Reconstruir imágenes
    echo -e "${YELLOW}Reconstruyendo imágenes...${NC}"
    "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" build --no-cache
    
    # Reparar scripts
    fix_scripts
    
    # Iniciar servicios
    echo -e "${YELLOW}Iniciando servicios...${NC}"
    "$PROJECT_ROOT/manage-services.sh" start
    
    echo -e "${GREEN}✅ Reconstrucción completada${NC}"
}

# Función principal
main() {
    case "${1:-}" in
        diagnose)
            diagnose_system
            ;;
        fix)
            fix_all
            ;;
        fix-mkdocs)
            fix_mkdocs
            ;;
        fix-scripts)
            fix_scripts
            ;;
        fix-env)
            fix_env
            ;;
        validate)
            validate_system
            ;;
        clean-rebuild)
            clean_rebuild
            ;;
        --help|-h|help|"")
            show_help
            ;;
        *)
            echo -e "${RED}Comando no reconocido: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
