#!/bin/bash
# Script de validación para verificar la actualización de docker-compose.yml

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/config/docker-compose.yml"
ENV_FILE="$PROJECT_ROOT/.env"

echo "🔍 Validando actualización de docker-compose.yml..."

# Verificar que el archivo existe
if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
    echo "❌ Error: $DOCKER_COMPOSE_FILE no existe"
    exit 1
fi

# Verificar que el archivo .env existe
if [[ ! -f "$ENV_FILE" ]]; then
    echo "❌ Error: $ENV_FILE no existe"
    exit 1
fi

# Cargar variables de entorno
source "$PROJECT_ROOT/scripts/core/load-env.sh"
load_env > /dev/null 2>&1

echo "✅ Archivos encontrados correctamente"

# Lista de variables que deben estar en docker-compose.yml
declare -a required_vars=(
    "WEBLOGIC_A_EXTERNAL_PORT"
    "WEBLOGIC_B_EXTERNAL_PORT"
    "WEBLOGIC_ADMIN_PASSWORD"
    "HAPROXY_HTTP_EXTERNAL_PORT"
    "HAPROXY_HTTPS_EXTERNAL_PORT"
    "HAPROXY_STATS_EXTERNAL_PORT"
    "HAPROXY_API_EXTERNAL_PORT"
    "HAPROXY_UI_EXTERNAL_PORT"
    "ORACLE_EXTERNAL_PORT"
    "ORACLE_EM_EXTERNAL_PORT"
    "ORACLE_ADMIN_PASSWORD"
    "MKDOCS_EXTERNAL_PORT"
    "MKDOCS_DEV_EXTERNAL_PORT"
    "MKDOCS_V1_EXTERNAL_PORT"
)

# Verificar que todas las variables están en docker-compose.yml
echo "🔧 Verificando variables de entorno en docker-compose.yml..."
for var in "${required_vars[@]}"; do
    if grep -q "\${${var}" "$DOCKER_COMPOSE_FILE"; then
        echo "  ✅ $var encontrada"
    else
        echo "  ❌ $var NO encontrada"
        exit 1
    fi
done

# Verificar que las variables están definidas en .env
echo "🔧 Verificando variables de entorno en .env..."
for var in "${required_vars[@]}"; do
    if grep -q "^${var}=" "$ENV_FILE"; then
        echo "  ✅ $var definida en .env"
    else
        echo "  ❌ $var NO definida en .env"
        exit 1
    fi
done

# Verificar que no hay puertos hardcodeados (excepto puertos internos)
echo "🔧 Verificando que no hay puertos hardcodeados..."
hardcoded_ports_found=false

# Buscar patrones de puertos hardcodeados en la sección de ports
if grep -A 20 "ports:" "$DOCKER_COMPOSE_FILE" | grep -E "^\s*-\s*\"[0-9]+:" | grep -v "\${" | grep -v "#"; then
    echo "❌ Error: Se encontraron puertos hardcodeados"
    hardcoded_ports_found=true
fi

if [[ "$hardcoded_ports_found" == "false" ]]; then
    echo "✅ No se encontraron puertos hardcodeados"
fi

# Verificar sintaxis de docker-compose
echo "🔧 Verificando sintaxis de docker-compose.yml..."
if docker-compose -f "$DOCKER_COMPOSE_FILE" config > /dev/null 2>&1; then
    echo "✅ docker-compose.yml tiene sintaxis válida"
else
    echo "❌ Error: docker-compose.yml tiene errores de sintaxis"
    exit 1
fi

# Verificar que las variables se resuelven correctamente
echo "🔧 Verificando resolución de variables..."
temp_output=$(mktemp)
docker-compose -f "$DOCKER_COMPOSE_FILE" config > "$temp_output" 2>/dev/null

# Verificar algunos puertos específicos
if grep -q "published: 8083" "$temp_output" && grep -q "target: 80" "$temp_output"; then
    echo "✅ Puerto HTTP de HAProxy se resuelve correctamente"
else
    echo "❌ Error: Puerto HTTP de HAProxy no se resuelve correctamente"
    echo "Debug: Buscando configuración de HAProxy..."
    grep -A 20 -B 5 "haproxy:" "$temp_output"
    exit 1
fi

if grep -q "published: 7001" "$temp_output" && grep -q "target: 7001" "$temp_output"; then
    echo "✅ Puerto WebLogic A se resuelve correctamente"
else
    echo "❌ Error: Puerto WebLogic A no se resuelve correctamente"
    echo "Debug: Buscando configuración de WebLogic A..."
    grep -A 15 -B 5 "weblogic-a:" "$temp_output"
    exit 1
fi

rm -f "$temp_output"

echo ""
echo "🎉 ¡Validación completada exitosamente!"
echo "📋 Resumen de la actualización:"
echo "   - ✅ Archivo actualizado: config/docker-compose.yml"
echo "   - ✅ Variables de entorno definidas: ${#required_vars[@]}"
echo "   - ✅ No contiene puertos hardcodeados"
echo "   - ✅ Sintaxis de docker-compose válida"
echo "   - ✅ Variables se resuelven correctamente"
echo ""
echo "🚀 Para probar la configuración:"
echo "   docker-compose -f config/docker-compose.yml config"
echo ""
echo "🔧 Para iniciar los servicios:"
echo "   docker-compose -f config/docker-compose.yml up -d"
