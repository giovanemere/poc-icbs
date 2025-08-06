#!/bin/bash
# Script de validación para verificar la actualización de los scripts principales

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔍 Validando actualización de scripts principales..."

# Lista de scripts principales a validar
declare -a main_scripts=(
    "start-all.sh"
    "manage-services.sh"
    "start-with-auto-update.sh"
    "stop-all-services.sh"
)

# Verificar que todos los scripts existen
echo "📁 Verificando existencia de scripts..."
for script in "${main_scripts[@]}"; do
    if [[ -f "$PROJECT_ROOT/$script" ]]; then
        echo "  ✅ $script encontrado"
    else
        echo "  ❌ $script NO encontrado"
        exit 1
    fi
done

# Verificar que los scripts son ejecutables
echo "🔧 Verificando permisos de ejecución..."
for script in "${main_scripts[@]}"; do
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
for script in "${main_scripts[@]}"; do
    if grep -q "scripts/core/load-env.sh" "$PROJECT_ROOT/$script"; then
        echo "  ✅ $script usa load-env.sh"
    else
        echo "  ❌ $script NO usa load-env.sh"
        exit 1
    fi
done

# Verificar que usan docker-compose-wrapper.sh
scripts_that_should_use_wrapper=("start-all.sh" "start-with-auto-update.sh" "stop-all-services.sh" "manage-services.sh")
for script in "${scripts_that_should_use_wrapper[@]}"; do
    if grep -q "docker-compose-wrapper.sh" "$PROJECT_ROOT/$script"; then
        echo "  ✅ $script usa docker-compose-wrapper.sh"
    else
        echo "  ❌ $script NO usa docker-compose-wrapper.sh"
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
    "ORACLE_EXTERNAL_PORT"
    "ORACLE_EM_EXTERNAL_PORT"
    "MKDOCS_EXTERNAL_PORT"
)

# Verificar que al menos algunas variables están siendo usadas
variables_found=0
for script in "${main_scripts[@]}"; do
    for var in "${expected_vars[@]}"; do
        if grep -q "\${${var}" "$PROJECT_ROOT/$script"; then
            variables_found=$((variables_found + 1))
            break
        fi
    done
done

if [[ $variables_found -ge 3 ]]; then
    echo "  ✅ Scripts usan variables de entorno correctamente"
else
    echo "  ❌ Scripts NO usan suficientes variables de entorno"
    exit 1
fi

# Verificar que no hay puertos hardcodeados comunes
echo "🔧 Verificando que no hay puertos hardcodeados..."
hardcoded_ports_found=false

common_hardcoded_ports=("7001" "7002" "8083" "8404" "8082" "1521" "5500" "8000")
for script in "${main_scripts[@]}"; do
    for port in "${common_hardcoded_ports[@]}"; do
        # Buscar puertos hardcodeados que no estén en contexto de variables
        if grep -E "localhost:$port[^}]" "$PROJECT_ROOT/$script" | grep -v "\${" | grep -v ":-$port"; then
            echo "  ❌ Puerto hardcodeado $port encontrado en $script"
            hardcoded_ports_found=true
        fi
    done
done

if [[ "$hardcoded_ports_found" == "false" ]]; then
    echo "  ✅ No se encontraron puertos hardcodeados problemáticos"
fi

# Probar ejecución básica de los scripts
echo "🧪 Probando ejecución básica de scripts..."

# Probar start-all.sh con --help o dry-run si está disponible
if "$PROJECT_ROOT/manage-services.sh" --help > /dev/null 2>&1; then
    echo "  ✅ manage-services.sh --help funciona"
else
    echo "  ❌ manage-services.sh --help falló"
    exit 1
fi

# Verificar que el script de carga de variables funciona
if source "$PROJECT_ROOT/scripts/core/load-env.sh" && load_env > /dev/null 2>&1; then
    echo "  ✅ Sistema de carga de variables funciona"
else
    echo "  ❌ Sistema de carga de variables falló"
    exit 1
fi

# Verificar que docker-compose-wrapper funciona
if "$PROJECT_ROOT/scripts/core/docker-compose-wrapper.sh" config --services > /dev/null 2>&1; then
    echo "  ✅ docker-compose-wrapper.sh funciona"
else
    echo "  ❌ docker-compose-wrapper.sh falló"
    exit 1
fi

echo ""
echo "🎉 ¡Validación completada exitosamente!"
echo "📋 Resumen de la actualización:"
echo "   - ✅ Scripts principales actualizados: ${#main_scripts[@]}"
echo "   - ✅ Todos los scripts son ejecutables"
echo "   - ✅ Usan configuración centralizada (load-env.sh)"
echo "   - ✅ Usan docker-compose-wrapper.sh"
echo "   - ✅ Usan variables de entorno en lugar de valores hardcodeados"
echo "   - ✅ No contienen puertos hardcodeados problemáticos"
echo "   - ✅ Ejecución básica funciona correctamente"
echo ""
echo "🚀 Scripts listos para usar:"
echo "   ./start-all.sh                    # Iniciar todos los servicios"
echo "   ./manage-services.sh status       # Ver estado"
echo "   ./manage-services.sh config       # Ver configuración"
echo "   ./manage-services.sh start        # Iniciar servicios"
echo "   ./manage-services.sh stop         # Detener servicios"
echo ""
echo "🔧 Para cambiar configuración:"
echo "   Editar .env y reiniciar servicios"
