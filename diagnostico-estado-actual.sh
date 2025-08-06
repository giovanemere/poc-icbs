#!/bin/bash

# =============================================================================
# Diagnóstico Estado Actual - Docker WebLogic Oracle
# Verifica el estado real de todos los servicios y configuraciones
# =============================================================================

echo "🔍 DIAGNÓSTICO COMPLETO DEL SISTEMA"
echo "Fecha: $(date)"
echo "========================================"
echo ""

# Función para verificar HTTP response
check_http() {
    local url=$1
    local name=$2
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    if [ "$response" = "200" ] || [ "$response" = "302" ] || [ "$response" = "401" ]; then
        echo "✅ $name: HTTP $response (FUNCIONAL)"
    elif [ "$response" = "000" ]; then
        echo "❌ $name: NO RESPONDE (INACTIVO)"
    else
        echo "⚠️ $name: HTTP $response (VERIFICAR)"
    fi
}

# =============================================================================
# 1. VERIFICAR SERVICIOS BÁSICOS CONFIRMADOS
# =============================================================================
echo "=== 1. SERVICIOS BÁSICOS ==="
check_http "http://localhost:8000/" "MkDocs Documentation (8000)"
check_http "http://localhost:8404/stats" "HAProxy Stats (8404)"
check_http "http://localhost:8082/" "HAProxy API (8082)"
echo ""

# =============================================================================
# 2. VERIFICAR WEBLOGIC (ESTADO INCIERTO)
# =============================================================================
echo "=== 2. WEBLOGIC SERVERS (CRÍTICO) ==="
check_http "http://localhost:7001/console" "WebLogic A Console (7001)"
check_http "http://localhost:7002/console" "WebLogic B Console (7002)"
echo ""

# =============================================================================
# 3. VERIFICAR HAPROXY LOAD BALANCER
# =============================================================================
echo "=== 3. HAPROXY LOAD BALANCER ==="
check_http "http://localhost:8083/" "HAProxy Load Balancer (8083)"
check_http "http://localhost:80/" "HAProxy Frontend (80)"
echo ""

# =============================================================================
# 4. VERIFICAR ORACLE DATABASE
# =============================================================================
echo "=== 4. ORACLE DATABASE ==="
if command -v sqlplus >/dev/null 2>&1; then
    echo "⚠️ Oracle Database: sqlplus disponible (requiere prueba de conexión)"
else
    echo "⚠️ Oracle Database: sqlplus no disponible (verificar manualmente puerto 1521)"
fi
echo ""

# =============================================================================
# 5. VERIFICAR DOCKER CONTAINERS
# =============================================================================
echo "=== 5. DOCKER CONTAINERS ==="
if command -v docker >/dev/null 2>&1; then
    echo "Containers activos:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "❌ Error accediendo a Docker"
    echo ""
    echo "Containers totales (incluyendo detenidos):"
    docker ps -a --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | head -10
else
    echo "❌ Docker no disponible"
fi
echo ""

# =============================================================================
# 6. VERIFICAR CONFIGURACIONES DISPONIBLES
# =============================================================================
echo "=== 6. CONFIGURACIONES Y BACKUPS ==="
echo "HAProxy backups disponibles:"
ls -la backups/haproxy/ 2>/dev/null | wc -l | xargs echo "  Archivos:"
echo ""

echo "Docker compose backups:"
ls -la backups/docker-compose-*.yml 2>/dev/null | wc -l | xargs echo "  Archivos:"
echo ""

echo "Configuración HAProxy actual:"
if [ -f "haproxy/config/haproxy.cfg" ]; then
    echo "  ✅ Archivo existe"
    echo "  Líneas: $(wc -l < haproxy/config/haproxy.cfg)"
    echo "  Backends configurados: $(grep -c "server " haproxy/config/haproxy.cfg)"
else
    echo "  ❌ Archivo no encontrado"
fi
echo ""

echo "Configuración MkDocs:"
if [ -f "mkdocs.yml" ]; then
    echo "  ✅ mkdocs.yml existe"
    echo "  Contenido: $(wc -l < mkdocs.yml) líneas"
else
    echo "  ❌ mkdocs.yml no encontrado"
fi
echo ""

# =============================================================================
# 7. ANÁLISIS DE CONTENIDO MKDOCS
# =============================================================================
echo "=== 7. ANÁLISIS CONTENIDO MKDOCS ==="
if curl -s http://localhost:8000/ | grep -q "WebLogic Oracle Documentation"; then
    echo "✅ MkDocs cargando correctamente"
    
    # Verificar contenido específico
    if curl -s http://localhost:8000/ | grep -q "Arquitectura del Sistema"; then
        echo "✅ Contenido avanzado presente"
    else
        echo "⚠️ Contenido básico solamente"
    fi
    
    # Verificar navegación
    nav_items=$(curl -s http://localhost:8000/ | grep -o '<a[^>]*href[^>]*>' | wc -l)
    echo "  Enlaces de navegación: $nav_items"
else
    echo "❌ MkDocs no responde correctamente"
fi
echo ""

# =============================================================================
# 8. ANÁLISIS HAPROXY STATS
# =============================================================================
echo "=== 8. ANÁLISIS HAPROXY STATS ==="
if curl -s http://localhost:8404/stats | grep -q "Statistics Report"; then
    echo "✅ HAProxy Stats funcionando"
    
    # Verificar backends
    backends=$(curl -s http://localhost:8404/stats | grep -c "weblogic-[ab]" || echo "0")
    echo "  Backends WebLogic detectados: $backends"
    
    # Verificar estado backends
    if [ "$backends" -gt 0 ]; then
        echo "  Estado backends:"
        curl -s http://localhost:8404/stats | grep "weblogic-[ab]" | head -2 || echo "    No se pudo obtener estado"
    fi
else
    echo "❌ HAProxy Stats no responde correctamente"
fi
echo ""

# =============================================================================
# 9. RESUMEN Y RECOMENDACIONES
# =============================================================================
echo "=== 9. RESUMEN Y PRÓXIMOS PASOS ==="
echo ""

# Contar servicios funcionando
services_ok=0
services_total=7

# MkDocs
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ | grep -q "200"; then
    ((services_ok++))
fi

# HAProxy Stats
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8404/stats | grep -q "200"; then
    ((services_ok++))
fi

# HAProxy API
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/ | grep -q "200"; then
    ((services_ok++))
fi

# WebLogic A
if curl -s -o /dev/null -w "%{http_code}" http://localhost:7001/console 2>/dev/null | grep -qE "200|302|401"; then
    ((services_ok++))
fi

# WebLogic B
if curl -s -o /dev/null -w "%{http_code}" http://localhost:7002/console 2>/dev/null | grep -qE "200|302|401"; then
    ((services_ok++))
fi

# HAProxy Load Balancer
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8083/ 2>/dev/null | grep -qE "200|302"; then
    ((services_ok++))
fi

# HAProxy Frontend
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80/ 2>/dev/null | grep -qE "200|302"; then
    ((services_ok++))
fi

percentage=$((services_ok * 100 / services_total))

echo "📊 ESTADO GENERAL DEL SISTEMA:"
echo "  Servicios funcionando: $services_ok/$services_total ($percentage%)"
echo ""

if [ $services_ok -ge 5 ]; then
    echo "✅ ESTADO: SISTEMA MAYORMENTE FUNCIONAL"
    echo "🎯 PRÓXIMO PASO: Restaurar configuraciones avanzadas"
    echo ""
    echo "📋 ACCIONES RECOMENDADAS:"
    echo "  1. Restaurar configuración HAProxy avanzada desde backup"
    echo "  2. Completar contenido MkDocs"
    echo "  3. Verificar y optimizar WebLogic si no está funcionando"
    echo "  4. Validar sistema completo"
elif [ $services_ok -ge 3 ]; then
    echo "⚠️ ESTADO: SERVICIOS BÁSICOS FUNCIONANDO"
    echo "🎯 PRÓXIMO PASO: Verificar y restaurar servicios faltantes"
    echo ""
    echo "📋 ACCIONES RECOMENDADAS:"
    echo "  1. Verificar por qué WebLogic no responde"
    echo "  2. Restaurar configuraciones perdidas"
    echo "  3. Validar conectividad entre servicios"
else
    echo "❌ ESTADO: SISTEMA CON PROBLEMAS CRÍTICOS"
    echo "🎯 PRÓXIMO PASO: Diagnóstico profundo y corrección arquitectural"
    echo ""
    echo "📋 ACCIONES CRÍTICAS:"
    echo "  1. Verificar docker-compose y containers"
    echo "  2. Revisar logs de servicios"
    echo "  3. Posible rediseño arquitectural necesario"
fi

echo ""
echo "🔗 ENLACES PARA VERIFICACIÓN MANUAL:"
echo "  - MkDocs: http://localhost:8000/"
echo "  - HAProxy Stats: http://localhost:8404/stats"
echo "  - HAProxy API: http://localhost:8082/"
echo "  - WebLogic A: http://localhost:7001/console"
echo "  - WebLogic B: http://localhost:7002/console"
echo "  - HAProxy LB: http://localhost:8083/"
echo ""
echo "📅 Diagnóstico completado: $(date)"
echo "========================================"
