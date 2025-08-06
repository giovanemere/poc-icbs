#!/bin/bash

# =============================================================================
# VALIDATE PHASE 3 - DOCKER HUB INTEGRATION
# =============================================================================
# Script para validar que la Fase 3 esté 100% completada

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔍 VALIDANDO FASE 3 - DOCKER HUB INTEGRATION"
echo "=============================================="

ERRORS=0
WARNINGS=0

# Función para reportar errores
report_error() {
    echo "❌ ERROR: $1"
    ((ERRORS++))
}

# Función para reportar warnings
report_warning() {
    echo "⚠️  WARNING: $1"
    ((WARNINGS++))
}

# Función para reportar éxito
report_success() {
    echo "✅ $1"
}

echo ""
echo "📋 1. VALIDANDO VARIABLES CENTRALIZADAS"
echo "----------------------------------------"

# Verificar .env.registry existe
if [[ -f "$PROJECT_ROOT/.env.registry" ]]; then
    report_success "Archivo .env.registry existe"
else
    report_error "Archivo .env.registry no encontrado"
fi

# Verificar variables en .env principal
REQUIRED_VARS=("MKDOCS_IMAGE" "HAPROXY_IMAGE" "WEBLOGIC_IMAGE" "ORACLE_IMAGE")
for var in "${REQUIRED_VARS[@]}"; do
    if grep -q "^${var}=" "$PROJECT_ROOT/.env" 2>/dev/null; then
        VALUE=$(grep "^${var}=" "$PROJECT_ROOT/.env" | cut -d= -f2)
        if [[ "$VALUE" == *"edissonz8809"* ]]; then
            report_success "Variable $var correctamente configurada: $VALUE"
        else
            report_error "Variable $var no apunta a Docker Hub: $VALUE"
        fi
    else
        report_error "Variable $var no encontrada en .env"
    fi
done

echo ""
echo "📋 2. VALIDANDO HAPROXY API PORT"
echo "---------------------------------"

# Verificar puerto 8081 en docker-compose.yml
if grep -q "HAPROXY_API_EXTERNAL_PORT.*8081.*:8084" "$PROJECT_ROOT/config/docker-compose.yml" 2>/dev/null; then
    report_success "Puerto HAProxy API 8081 correctamente mapeado"
else
    report_error "Puerto HAProxy API 8081 no está mapeado correctamente"
fi

# Verificar variable en .env
if grep -q "HAPROXY_API_EXTERNAL_PORT=8081" "$PROJECT_ROOT/.env" 2>/dev/null; then
    report_success "Variable HAPROXY_API_EXTERNAL_PORT configurada correctamente"
else
    report_error "Variable HAPROXY_API_EXTERNAL_PORT no está en 8081"
fi

echo ""
echo "📋 3. VALIDANDO ESTRUCTURA APPLICATIONS"
echo "---------------------------------------"

REQUIRED_APPS=("weblogic-feature-flags" "mkdocs-server" "haproxy-advanced" "oracle-express-db")
for app in "${REQUIRED_APPS[@]}"; do
    if [[ -d "$PROJECT_ROOT/applications/$app" ]]; then
        report_success "Directorio applications/$app existe"
        
        # Verificar Dockerfile
        if [[ -f "$PROJECT_ROOT/applications/$app/Dockerfile" ]]; then
            report_success "  └─ Dockerfile encontrado"
        else
            report_warning "  └─ Dockerfile no encontrado en $app"
        fi
    else
        if [[ "$app" == "oracle-express-db" ]]; then
            report_warning "Directorio applications/$app no existe (opcional)"
        else
            report_error "Directorio applications/$app no existe"
        fi
    fi
done

# Verificar README actualizado
if [[ -f "$PROJECT_ROOT/applications/README.md" ]]; then
    if grep -q "Fase.*3.*Docker Hub Integration" "$PROJECT_ROOT/applications/README.md" 2>/dev/null; then
        report_success "README.md de applications actualizado"
    else
        report_warning "README.md de applications necesita actualización"
    fi
else
    report_error "README.md de applications no encontrado"
fi

echo ""
echo "📋 4. VALIDANDO DOCKER HUB IMAGES"
echo "----------------------------------"

# Verificar que las imágenes existen en Docker Hub (simulado)
DOCKER_IMAGES=("edissonz8809/mkdocs-server:v1.1.0" "edissonz8809/haproxy-advanced:v1.1.0" "edissonz8809/weblogic-feature-flags:v1.1.0")
for image in "${DOCKER_IMAGES[@]}"; do
    # Verificar que la imagen está referenciada en .env.registry
    IMAGE_NAME=$(echo "$image" | cut -d: -f1)
    if grep -q "$IMAGE_NAME" "$PROJECT_ROOT/.env.registry" 2>/dev/null; then
        report_success "Imagen $image referenciada en .env.registry"
    else
        report_error "Imagen $image no referenciada en .env.registry"
    fi
done

echo ""
echo "📋 5. VALIDANDO DOCKER-COMPOSE INTEGRATION"
echo "-------------------------------------------"

# Verificar que docker-compose.yml usa variables
COMPOSE_FILE="$PROJECT_ROOT/config/docker-compose.yml"
if grep -q "\${MKDOCS_IMAGE" "$COMPOSE_FILE" 2>/dev/null; then
    report_success "docker-compose.yml usa variables de imagen MkDocs"
else
    report_error "docker-compose.yml no usa variables de imagen MkDocs"
fi

if grep -q "\${HAPROXY_IMAGE" "$COMPOSE_FILE" 2>/dev/null; then
    report_success "docker-compose.yml usa variables de imagen HAProxy"
else
    report_error "docker-compose.yml no usa variables de imagen HAProxy"
fi

if grep -q "\${WEBLOGIC_IMAGE" "$COMPOSE_FILE" 2>/dev/null; then
    report_success "docker-compose.yml usa variables de imagen WebLogic"
else
    report_error "docker-compose.yml no usa variables de imagen WebLogic"
fi

echo ""
echo "📊 RESUMEN DE VALIDACIÓN"
echo "========================"

if [[ $ERRORS -eq 0 ]]; then
    echo "🎉 ¡FASE 3 COMPLETADA AL 100%!"
    echo ""
    echo "✅ Variables centralizadas: INTEGRADAS"
    echo "✅ HAProxy API Port: CONFIGURADO"
    echo "✅ Estructura applications: ORGANIZADA"
    echo "✅ Docker Hub integration: COMPLETA"
    echo ""
    echo "🚀 Listo para continuar con Fase 4 - CI/CD Pipeline"
    
    if [[ $WARNINGS -gt 0 ]]; then
        echo ""
        echo "⚠️  Se encontraron $WARNINGS warnings (no críticos)"
    fi
    
    exit 0
else
    echo "❌ FASE 3 INCOMPLETA"
    echo ""
    echo "📊 Errores encontrados: $ERRORS"
    echo "📊 Warnings encontrados: $WARNINGS"
    echo ""
    echo "🔧 Por favor, corrige los errores antes de continuar"
    exit 1
fi
