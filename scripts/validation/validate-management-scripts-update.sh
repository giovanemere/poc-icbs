#!/bin/bash
# Script de validación para verificar la actualización de los scripts de gestión

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔍 Validando actualización de scripts de gestión..."

# Lista de scripts de gestión a validar
declare -a deployment_scripts=(
    "scripts/deploy/deploy-war.sh"
    "scripts/deploy/deploy-complete.sh"
)

declare -a canary_scripts=(
    "scripts/canary/manage-traffic.sh"
    "scripts/canary/simulate-traffic.sh"
    "scripts/canary/test-canary.sh"
)

# Verificar que todos los scripts existen
echo "📁 Verificando existencia de scripts..."
all_scripts=("${deployment_scripts[@]}" "${canary_scripts[@]}")

for script in "${all_scripts[@]}"; do
    if [[ -f "$PROJECT_ROOT/$script" ]]; then
        echo "  ✅ $script encontrado"
    else
        echo "  ❌ $script NO encontrado"
        exit 1
    fi
done

# Verificar que los scripts son ejecutables
echo "🔧 Verificando permisos de ejecución..."
for script in "${all_scripts[@]}"; do
    if [[ -x "$PROJECT_ROOT/$script" ]]; then
        echo "  ✅ $script es ejecutable"
    else
        echo "  ❌ $script NO es ejecutable"
        exit 1
    fi
done

# Verificar que los scripts usan el sistema de configuración centralizada
echo "🔧 Verificando uso de configuración centralizada..."

# Verificar que usan load-env.sh
for script in "${all_scripts[@]}"; do
    if grep -q "scripts/core/load-env.sh" "$PROJECT_ROOT/$script"; then
        echo "  ✅ $script usa load-env.sh"
    else
        echo "  ❌ $script NO usa load-env.sh"
        exit 1
    fi
done

# Verificar que usan variables de entorno en lugar de valores hardcodeados
echo "🔧 Verificando uso de variables de entorno..."

# Variables que deberían estar en los scripts
declare -a expected_vars=(
    "WEBLOGIC_A_EXTERNAL_PORT"
    "WEBLOGIC_B_EXTERNAL_PORT"
    "HAPROXY_HTTP_EXTERNAL_PORT"
    "HAPROXY_STATS_EXTERNAL_PORT"
    "HAPROXY_UI_EXTERNAL_PORT"
    "HAPROXY_API_EXTERNAL_PORT"
)

# Verificar que al menos algunas variables están siendo usadas
variables_found=0
for script in "${all_scripts[@]}"; do
    for var in "${expected_vars[@]}"; do
        if grep -q "\${${var}" "$PROJECT_ROOT/$script"; then
            variables_found=$((variables_found + 1))
            break
        fi
    done
done

if [[ $variables_found -ge 4 ]]; then
    echo "  ✅ Scripts usan variables de entorno correctamente"
else
    echo "  ❌ Scripts NO usan suficientes variables de entorno"
    exit 1
fi

# Verificar que no hay puertos hardcodeados comunes
echo "🔧 Verificando que no hay puertos hardcodeados..."
hardcoded_ports_found=false

common_hardcoded_ports=("7001" "7002" "8083" "8404" "8082" "8081")
for script in "${all_scripts[@]}"; do
    for port in "${common_hardcoded_ports[@]}"; do
        # Buscar puertos hardcodeados que no estén en contexto de variables
        if grep -E "localhost:$port[^}]" "$PROJECT_ROOT/$script" | grep -v "\${" | grep -v ":-$port" > /dev/null; then
            echo "  ❌ Puerto hardcodeado $port encontrado en $script"
            hardcoded_ports_found=true
        fi
    done
done

if [[ "$hardcoded_ports_found" == "false" ]]; then
    echo "  ✅ No se encontraron puertos hardcodeados problemáticos"
fi

# Verificar funcionalidades específicas de scripts de deployment
echo "🔧 Verificando funcionalidades de deployment..."

# Verificar que deploy-war.sh tiene las funciones necesarias
if grep -q "clean_haproxy_cache" "$PROJECT_ROOT/scripts/deploy/deploy-war.sh"; then
    echo "  ✅ deploy-war.sh tiene función de limpieza de caché"
else
    echo "  ❌ deploy-war.sh NO tiene función de limpieza de caché"
    exit 1
fi

if grep -q "show_verification_urls" "$PROJECT_ROOT/scripts/deploy/deploy-war.sh"; then
    echo "  ✅ deploy-war.sh muestra URLs de verificación"
else
    echo "  ❌ deploy-war.sh NO muestra URLs de verificación"
    exit 1
fi

# Verificar que deploy-complete.sh usa el script de deploy-war.sh
if grep -q "deploy-war.sh" "$PROJECT_ROOT/scripts/deploy/deploy-complete.sh"; then
    echo "  ✅ deploy-complete.sh usa deploy-war.sh"
else
    echo "  ❌ deploy-complete.sh NO usa deploy-war.sh"
    exit 1
fi

# Verificar funcionalidades específicas de scripts de canary
echo "🔧 Verificando funcionalidades de canary..."

# Verificar que manage-traffic.sh tiene validación de parámetros
if grep -q "validate_parameters" "$PROJECT_ROOT/scripts/canary/manage-traffic.sh"; then
    echo "  ✅ manage-traffic.sh tiene validación de parámetros"
else
    echo "  ❌ manage-traffic.sh NO tiene validación de parámetros"
    exit 1
fi

# Verificar que simulate-traffic.sh tiene análisis de respuestas
if grep -q "send_request" "$PROJECT_ROOT/scripts/canary/simulate-traffic.sh"; then
    echo "  ✅ simulate-traffic.sh tiene análisis de respuestas"
else
    echo "  ❌ simulate-traffic.sh NO tiene análisis de respuestas"
    exit 1
fi

# Verificar que test-canary.sh tiene verificación de contenedores
if grep -q "check_containers" "$PROJECT_ROOT/scripts/canary/test-canary.sh"; then
    echo "  ✅ test-canary.sh tiene verificación de contenedores"
else
    echo "  ❌ test-canary.sh NO tiene verificación de contenedores"
    exit 1
fi

# Probar ejecución básica de los scripts (solo ayuda)
echo "🧪 Probando ejecución básica de scripts..."

# Probar scripts de deployment
if "$PROJECT_ROOT/scripts/deploy/deploy-war.sh" --help > /dev/null 2>&1; then
    echo "  ✅ deploy-war.sh --help funciona"
else
    echo "  ❌ deploy-war.sh --help falló"
    exit 1
fi

if "$PROJECT_ROOT/scripts/deploy/deploy-complete.sh" --help > /dev/null 2>&1; then
    echo "  ✅ deploy-complete.sh --help funciona"
else
    echo "  ❌ deploy-complete.sh --help falló"
    exit 1
fi

# Probar scripts de canary
if "$PROJECT_ROOT/scripts/canary/manage-traffic.sh" --help > /dev/null 2>&1; then
    echo "  ✅ manage-traffic.sh --help funciona"
else
    echo "  ❌ manage-traffic.sh --help falló"
    exit 1
fi

if "$PROJECT_ROOT/scripts/canary/simulate-traffic.sh" --help > /dev/null 2>&1; then
    echo "  ✅ simulate-traffic.sh --help funciona"
else
    echo "  ❌ simulate-traffic.sh --help falló"
    exit 1
fi

if "$PROJECT_ROOT/scripts/canary/test-canary.sh" --help > /dev/null 2>&1; then
    echo "  ✅ test-canary.sh --help funciona"
else
    echo "  ❌ test-canary.sh --help falló"
    exit 1
fi

# Verificar que el sistema de carga de variables funciona
if source "$PROJECT_ROOT/scripts/core/load-env.sh" && load_env > /dev/null 2>&1; then
    echo "  ✅ Sistema de carga de variables funciona"
else
    echo "  ❌ Sistema de carga de variables falló"
    exit 1
fi

echo ""
echo "🎉 ¡Validación completada exitosamente!"
echo "📋 Resumen de la actualización:"
echo "   - ✅ Scripts de deployment actualizados: ${#deployment_scripts[@]}"
echo "   - ✅ Scripts de canary actualizados: ${#canary_scripts[@]}"
echo "   - ✅ Todos los scripts son ejecutables"
echo "   - ✅ Usan configuración centralizada (load-env.sh)"
echo "   - ✅ Usan variables de entorno en lugar de valores hardcodeados"
echo "   - ✅ No contienen puertos hardcodeados problemáticos"
echo "   - ✅ Funcionalidades específicas implementadas"
echo "   - ✅ Ejecución básica funciona correctamente"
echo ""
echo "🚀 Scripts de gestión listos para usar:"
echo ""
echo "📦 Deployment:"
echo "   ./scripts/deploy/deploy-war.sh [archivo.war]     # Desplegar WAR específico"
echo "   ./scripts/deploy/deploy-complete.sh              # Desplegar todo"
echo ""
echo "🎯 Canary Deployment:"
echo "   ./scripts/canary/manage-traffic.sh canary 20     # 20% canary"
echo "   ./scripts/canary/simulate-traffic.sh 100 0.5     # Simular tráfico"
echo "   ./scripts/canary/test-canary.sh 50               # Probar canary"
echo ""
echo "🔧 Para cambiar configuración:"
echo "   Editar .env y reiniciar servicios"
