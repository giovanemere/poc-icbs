#!/bin/bash
# Script para gestionar la configuración de Docker Hub

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
echo "║              Configuración Docker Hub                       ║"
echo "║                  edissonz8809 Registry                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}Uso: $0 [COMANDO] [OPCIONES]${NC}"
    echo ""
    echo -e "${YELLOW}Comandos disponibles:${NC}"
    echo "  setup           Configurar credenciales Docker Hub"
    echo "  login           Hacer login en Docker Hub"
    echo "  logout          Hacer logout de Docker Hub"
    echo "  status          Mostrar estado de autenticación"
    echo "  test            Probar conectividad con Docker Hub"
    echo "  list-repos      Listar repositorios del namespace"
    echo "  create-repos    Crear repositorios necesarios"
    echo "  validate        Validar configuración completa"
    echo ""
    echo -e "${YELLOW}Opciones:${NC}"
    echo "  --username USER Especificar usuario Docker Hub"
    echo "  --namespace NS  Especificar namespace (default: edissonz8809)"
    echo "  --token TOKEN   Especificar token de acceso"
    echo "  --help          Mostrar esta ayuda"
    echo ""
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo "  $0 setup                    # Configuración interactiva"
    echo "  $0 login --username user    # Login con usuario específico"
    echo "  $0 create-repos             # Crear todos los repositorios"
    echo "  $0 validate                 # Validar configuración completa"
}

# Función para cargar variables de entorno
load_environment() {
    if [ -f "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" ]; then
        source "$PROJECT_ROOT/scripts/core/load-env-enhanced.sh" development 2>/dev/null || true
    fi
}

# Función para configurar credenciales
setup_credentials() {
    local username="$1"
    local namespace="$2"
    local token="$3"
    
    echo -e "${BLUE}=== Configuración de Credenciales Docker Hub ===${NC}"
    
    # Solicitar username si no se proporcionó
    if [ -z "$username" ]; then
        read -p "Usuario Docker Hub: " username
    fi
    
    # Solicitar namespace si no se proporcionó
    if [ -z "$namespace" ]; then
        read -p "Namespace Docker Hub [$username]: " namespace
        namespace="${namespace:-$username}"
    fi
    
    # Solicitar token si no se proporcionó
    if [ -z "$token" ]; then
        echo -e "${YELLOW}Para mayor seguridad, use un Personal Access Token en lugar de la contraseña${NC}"
        echo -e "${BLUE}Puede crear uno en: https://hub.docker.com/settings/security${NC}"
        read -s -p "Token/Contraseña Docker Hub: " token
        echo
    fi
    
    # Validar que se proporcionaron todos los datos
    if [ -z "$username" ] || [ -z "$namespace" ] || [ -z "$token" ]; then
        echo -e "${RED}Error: Todos los campos son obligatorios${NC}"
        return 1
    fi
    
    # Guardar configuración en archivo temporal
    local config_file="$PROJECT_ROOT/scripts/.docker-hub-config"
    {
        echo "DOCKER_USERNAME=$username"
        echo "DOCKER_NAMESPACE=$namespace"
        echo "DOCKER_PASSWORD=$token"
        echo "DOCKER_REGISTRY=docker.io"
    } > "$config_file"
    
    # Hacer el archivo solo legible por el propietario
    chmod 600 "$config_file"
    
    echo -e "${GREEN}✓ Configuración guardada en: $config_file${NC}"
    echo -e "${YELLOW}⚠ Recuerde agregar este archivo a .gitignore${NC}"
    
    # Actualizar .gitignore si existe
    if [ -f "$PROJECT_ROOT/.gitignore" ]; then
        if ! grep -q ".docker-hub-config" "$PROJECT_ROOT/.gitignore"; then
            echo "scripts/.docker-hub-config" >> "$PROJECT_ROOT/.gitignore"
            echo -e "${GREEN}✓ Archivo agregado a .gitignore${NC}"
        fi
    fi
    
    return 0
}

# Función para hacer login
docker_login() {
    local username="$1"
    local token="$2"
    
    echo -e "${BLUE}=== Login Docker Hub ===${NC}"
    
    # Cargar configuración si existe
    local config_file="$PROJECT_ROOT/scripts/.docker-hub-config"
    if [ -f "$config_file" ]; then
        source "$config_file"
        username="${username:-$DOCKER_USERNAME}"
        token="${token:-$DOCKER_PASSWORD}"
    fi
    
    # Solicitar credenciales si no están disponibles
    if [ -z "$username" ]; then
        read -p "Usuario Docker Hub: " username
    fi
    
    if [ -z "$token" ]; then
        read -s -p "Token/Contraseña Docker Hub: " token
        echo
    fi
    
    # Hacer login
    echo -e "${YELLOW}Haciendo login en Docker Hub...${NC}"
    if echo "$token" | docker login --username "$username" --password-stdin; then
        echo -e "${GREEN}✓ Login exitoso en Docker Hub${NC}"
        return 0
    else
        echo -e "${RED}✗ Error en login Docker Hub${NC}"
        return 1
    fi
}

# Función para hacer logout
docker_logout() {
    echo -e "${BLUE}=== Logout Docker Hub ===${NC}"
    
    if docker logout; then
        echo -e "${GREEN}✓ Logout exitoso de Docker Hub${NC}"
    else
        echo -e "${RED}✗ Error en logout Docker Hub${NC}"
    fi
}

# Función para mostrar estado
show_status() {
    echo -e "${BLUE}=== Estado Docker Hub ===${NC}"
    
    # Verificar si Docker está instalado
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}✗ Docker no está instalado${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Docker CLI disponible${NC}"
    
    # Verificar estado de autenticación
    if docker info 2>/dev/null | grep -q "Username:"; then
        local current_user=$(docker info 2>/dev/null | grep "Username:" | awk '{print $2}')
        echo -e "${GREEN}✓ Autenticado como: $current_user${NC}"
    else
        echo -e "${YELLOW}⚠ No autenticado en Docker Hub${NC}"
    fi
    
    # Mostrar configuración cargada
    load_environment
    if [ -n "$DOCKER_NAMESPACE" ]; then
        echo -e "${BLUE}Namespace configurado: $DOCKER_NAMESPACE${NC}"
    fi
    
    # Verificar archivo de configuración local
    local config_file="$PROJECT_ROOT/scripts/.docker-hub-config"
    if [ -f "$config_file" ]; then
        echo -e "${GREEN}✓ Archivo de configuración local encontrado${NC}"
    else
        echo -e "${YELLOW}⚠ No hay archivo de configuración local${NC}"
    fi
}

# Función para probar conectividad
test_connectivity() {
    echo -e "${BLUE}=== Test de Conectividad Docker Hub ===${NC}"
    
    # Test básico de conectividad
    if curl -s --connect-timeout 10 https://hub.docker.com >/dev/null; then
        echo -e "${GREEN}✓ Conectividad a Docker Hub: OK${NC}"
    else
        echo -e "${RED}✗ No hay conectividad a Docker Hub${NC}"
        return 1
    fi
    
    # Test de autenticación
    if docker info 2>/dev/null | grep -q "Username:"; then
        echo -e "${GREEN}✓ Autenticación: OK${NC}"
        
        # Test de push (usando imagen hello-world)
        echo -e "${YELLOW}Probando capacidad de push...${NC}"
        local test_image="hello-world:latest"
        local namespace="${DOCKER_NAMESPACE:-edissonz8809}"
        local test_tag="$namespace/test-connectivity:latest"
        
        if docker pull "$test_image" >/dev/null 2>&1 && \
           docker tag "$test_image" "$test_tag" && \
           docker push "$test_tag" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Capacidad de push: OK${NC}"
            
            # Limpiar imagen de test
            docker rmi "$test_tag" >/dev/null 2>&1 || true
        else
            echo -e "${RED}✗ Error en capacidad de push${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠ No autenticado - no se puede probar push${NC}"
    fi
    
    return 0
}

# Función para listar repositorios
list_repositories() {
    local namespace="${DOCKER_NAMESPACE:-edissonz8809}"
    
    echo -e "${BLUE}=== Repositorios en namespace: $namespace ===${NC}"
    
    # Usar API de Docker Hub para listar repositorios
    local api_url="https://hub.docker.com/v2/repositories/$namespace/"
    
    if curl -s "$api_url" | grep -q '"name"'; then
        echo -e "${GREEN}Repositorios encontrados:${NC}"
        curl -s "$api_url" | grep -o '"name":"[^"]*"' | sed 's/"name":"//g' | sed 's/"//g' | while read -r repo; do
            echo -e "  • $namespace/$repo"
        done
    else
        echo -e "${YELLOW}No se encontraron repositorios o error en la consulta${NC}"
    fi
}

# Función para crear repositorios necesarios
create_repositories() {
    local namespace="${DOCKER_NAMESPACE:-edissonz8809}"
    
    echo -e "${BLUE}=== Creando Repositorios Necesarios ===${NC}"
    
    # Repositorios que necesita el proyecto
    local repositories=(
        "weblogic-feature-flags:WebLogic con Feature Flags"
        "haproxy-advanced:HAProxy con configuración avanzada"
        "oracle-setup:Oracle Database con configuración personalizada"
        "mkdocs-server:Servidor de documentación MkDocs"
    )
    
    echo -e "${YELLOW}Los repositorios se crearán automáticamente al hacer el primer push${NC}"
    echo -e "${BLUE}Repositorios que se crearán:${NC}"
    
    for repo_desc in "${repositories[@]}"; do
        local repo_name="${repo_desc%%:*}"
        local repo_description="${repo_desc##*:}"
        echo -e "  • $namespace/$repo_name - $repo_description"
    done
    
    echo ""
    echo -e "${YELLOW}Para crear los repositorios, ejecute:${NC}"
    echo -e "${BLUE}  ./scripts/build/build-all-images.sh --push${NC}"
    
    return 0
}

# Función para validar configuración completa
validate_configuration() {
    echo -e "${BLUE}=== Validación Completa Docker Hub ===${NC}"
    
    local errors=0
    
    # Verificar Docker CLI
    if command -v docker >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Docker CLI instalado${NC}"
    else
        echo -e "${RED}✗ Docker CLI no encontrado${NC}"
        ((errors++))
    fi
    
    # Verificar variables de entorno
    load_environment
    
    local required_vars=(
        "DOCKER_NAMESPACE"
        "DOCKER_REGISTRY"
        "WEBLOGIC_FULL_IMAGE"
        "HAPROXY_FULL_IMAGE"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -n "${!var}" ]; then
            echo -e "${GREEN}✓ Variable $var: ${!var}${NC}"
        else
            echo -e "${RED}✗ Variable $var no definida${NC}"
            ((errors++))
        fi
    done
    
    # Verificar autenticación
    if docker info 2>/dev/null | grep -q "Username:"; then
        local current_user=$(docker info 2>/dev/null | grep "Username:" | awk '{print $2}')
        echo -e "${GREEN}✓ Autenticado como: $current_user${NC}"
        
        # Verificar que el usuario coincida con el namespace
        if [ "$current_user" = "$DOCKER_NAMESPACE" ]; then
            echo -e "${GREEN}✓ Usuario coincide con namespace${NC}"
        else
            echo -e "${YELLOW}⚠ Usuario ($current_user) no coincide con namespace ($DOCKER_NAMESPACE)${NC}"
        fi
    else
        echo -e "${RED}✗ No autenticado en Docker Hub${NC}"
        ((errors++))
    fi
    
    # Test de conectividad
    if curl -s --connect-timeout 5 https://hub.docker.com >/dev/null; then
        echo -e "${GREEN}✓ Conectividad a Docker Hub${NC}"
    else
        echo -e "${RED}✗ Sin conectividad a Docker Hub${NC}"
        ((errors++))
    fi
    
    # Resultado final
    echo ""
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✅ CONFIGURACIÓN DOCKER HUB VÁLIDA${NC}"
        echo -e "${BLUE}Listo para build y push de imágenes${NC}"
        return 0
    else
        echo -e "${RED}❌ $errors ERRORES EN CONFIGURACIÓN${NC}"
        echo -e "${YELLOW}Corrija los errores antes de continuar${NC}"
        return 1
    fi
}

# Función principal
main() {
    local command=""
    local username=""
    local namespace=""
    local token=""
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            setup|login|logout|status|test|list-repos|create-repos|validate)
                command="$1"
                shift
                ;;
            --username)
                username="$2"
                shift 2
                ;;
            --namespace)
                namespace="$2"
                shift 2
                ;;
            --token)
                token="$2"
                shift 2
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
    
    # Ejecutar comando
    case "$command" in
        setup)
            setup_credentials "$username" "$namespace" "$token"
            ;;
        login)
            docker_login "$username" "$token"
            ;;
        logout)
            docker_logout
            ;;
        status)
            show_status
            ;;
        test)
            test_connectivity
            ;;
        list-repos)
            list_repositories
            ;;
        create-repos)
            create_repositories
            ;;
        validate)
            validate_configuration
            ;;
        "")
            echo -e "${YELLOW}No se especificó comando${NC}"
            show_help
            exit 1
            ;;
        *)
            echo -e "${RED}Comando desconocido: $command${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
