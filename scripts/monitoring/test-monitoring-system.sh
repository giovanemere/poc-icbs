#!/bin/bash

# =============================================================================
# Script de prueba para el sistema de monitoreo de URLs
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                  PRUEBA SISTEMA MONITOREO                   ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_status() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${PURPLE}ℹ️  $1${NC}"
}

# Directorio base del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

print_header

# Cargar variables de entorno
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
fi

URL_STATUS_SERVICE_PORT=${URL_STATUS_SERVICE_PORT:-8090}
HAPROXY_INTEGRATION_PORT=${HAPROXY_INTEGRATION_PORT:-8085}

print_status "Probando sistema de monitoreo..."
echo ""

# Test 1: Verificar que los servicios están corriendo
print_status "Test 1: Verificando servicios..."

if curl -s "http://localhost:$URL_STATUS_SERVICE_PORT/api/status" > /dev/null; then
    print_success "Servicio de monitoreo está corriendo"
else
    print_error "Servicio de monitoreo no responde"
    echo ""
    print_info "Para iniciar el sistema:"
    echo "  ./scripts/monitoring/setup-complete-monitoring.sh"
    exit 1
fi

if curl -s "http://localhost:$HAPROXY_INTEGRATION_PORT/api/status" > /dev/null; then
    print_success "Integración HAProxy está corriendo"
else
    print_error "Integración HAProxy no responde"
fi

echo ""

# Test 2: Probar endpoint de estado de URLs
print_status "Test 2: Probando endpoint de URLs..."

URL_RESPONSE=$(curl -s "http://localhost:$URL_STATUS_SERVICE_PORT/api/url-status" || echo "ERROR")

if echo "$URL_RESPONSE" | grep -q "urls"; then
    print_success "Endpoint de URLs responde correctamente"
    
    # Mostrar resumen
    SUCCESS_COUNT=$(echo "$URL_RESPONSE" | jq -r '.summary.success // 0' 2>/dev/null || echo "0")
    WARNING_COUNT=$(echo "$URL_RESPONSE" | jq -r '.summary.warnings // 0' 2>/dev/null || echo "0")
    ERROR_COUNT=$(echo "$URL_RESPONSE" | jq -r '.summary.errors // 0' 2>/dev/null || echo "0")
    
    print_info "Resumen de URLs:"
    echo "  • Exitosas: $SUCCESS_COUNT"
    echo "  • Advertencias: $WARNING_COUNT"
    echo "  • Errores: $ERROR_COUNT"
    
else
    print_error "Endpoint de URLs no responde correctamente"
    echo "Respuesta: $URL_RESPONSE"
fi

echo ""

# Test 3: Probar integración con HAProxy
print_status "Test 3: Probando integración HAProxy..."

HAPROXY_RESPONSE=$(curl -s "http://localhost:$HAPROXY_INTEGRATION_PORT/api/url-status" || echo "ERROR")

if echo "$HAPROXY_RESPONSE" | grep -q "urls"; then
    print_success "Integración HAProxy funciona correctamente"
else
    print_error "Integración HAProxy no funciona"
    echo "Respuesta: $HAPROXY_RESPONSE"
fi

echo ""

# Test 4: Probar actualización de IPs (si Docker está disponible)
if command -v docker &> /dev/null; then
    print_status "Test 4: Probando actualización de IPs..."
    
    UPDATE_RESPONSE=$(curl -s -X POST "http://localhost:$URL_STATUS_SERVICE_PORT/api/containers/update-ips" || echo "ERROR")
    
    if echo "$UPDATE_RESPONSE" | grep -q "success\|error"; then
        if echo "$UPDATE_RESPONSE" | grep -q "success.*true"; then
            print_success "Actualización de IPs exitosa"
        else
            print_warning "Actualización de IPs reportó problemas"
            echo "Respuesta: $UPDATE_RESPONSE"
        fi
    else
        print_error "Error en actualización de IPs"
        echo "Respuesta: $UPDATE_RESPONSE"
    fi
else
    print_warning "Docker no disponible, saltando test de IPs"
fi

echo ""

# Test 5: Probar refresh forzado
print_status "Test 5: Probando refresh forzado..."

REFRESH_RESPONSE=$(curl -s -X POST "http://localhost:$URL_STATUS_SERVICE_PORT/api/url-status/refresh" || echo "ERROR")

if echo "$REFRESH_RESPONSE" | grep -q "success"; then
    print_success "Refresh forzado funciona"
else
    print_error "Error en refresh forzado"
    echo "Respuesta: $REFRESH_RESPONSE"
fi

echo ""

# Test 6: Verificar logs
print_status "Test 6: Verificando logs..."

LOG_DIR="$PROJECT_ROOT/logs/monitoring"
if [ -d "$LOG_DIR" ]; then
    LOG_FILES=$(find "$LOG_DIR" -name "*.log" -mtime -1 | wc -l)
    if [ "$LOG_FILES" -gt 0 ]; then
        print_success "Logs están siendo generados ($LOG_FILES archivos recientes)"
        
        # Mostrar últimas líneas del log principal
        MAIN_LOG=$(find "$LOG_DIR" -name "url-monitoring-*.log" -mtime -1 | head -1)
        if [ -n "$MAIN_LOG" ] && [ -f "$MAIN_LOG" ]; then
            print_info "Últimas líneas del log principal:"
            tail -3 "$MAIN_LOG" | sed 's/^/    /'
        fi
    else
        print_warning "No se encontraron logs recientes"
    fi
else
    print_error "Directorio de logs no existe"
fi

echo ""

# Test 7: Verificar configuración
print_status "Test 7: Verificando configuración..."

CONFIG_FILE="$PROJECT_ROOT/config/monitoring/url-monitoring.json"
if [ -f "$CONFIG_FILE" ]; then
    print_success "Archivo de configuración existe"
    
    # Verificar que es JSON válido
    if jq . "$CONFIG_FILE" > /dev/null 2>&1; then
        print_success "Configuración JSON es válida"
        
        URL_COUNT=$(jq '.urls | length' "$CONFIG_FILE" 2>/dev/null || echo "0")
        print_info "URLs configuradas: $URL_COUNT"
    else
        print_error "Configuración JSON no es válida"
    fi
else
    print_error "Archivo de configuración no existe"
fi

echo ""

# Resumen final
print_info "═══════════════════════════════════════════════════════════════"
print_info "                        RESUMEN DE PRUEBAS"
print_info "═══════════════════════════════════════════════════════════════"
echo ""

print_info "🌐 ENDPOINTS PROBADOS:"
echo "  • Servicio principal:     http://localhost:$URL_STATUS_SERVICE_PORT/api/url-status"
echo "  • Integración HAProxy:    http://localhost:$HAPROXY_INTEGRATION_PORT/api/url-status"
echo "  • Estado del sistema:     http://localhost:$URL_STATUS_SERVICE_PORT/api/status"
echo ""

print_info "🔧 COMANDOS ÚTILES:"
echo "  • Ver estado completo:    curl -s http://localhost:$URL_STATUS_SERVICE_PORT/api/url-status | jq"
echo "  • Forzar actualización:   curl -X POST http://localhost:$URL_STATUS_SERVICE_PORT/api/url-status/refresh"
echo "  • Actualizar IPs:         curl -X POST http://localhost:$URL_STATUS_SERVICE_PORT/api/containers/update-ips"
echo "  • Ver logs:               tail -f $PROJECT_ROOT/logs/monitoring/url-monitoring-$(date +%Y%m%d).log"
echo ""

print_success "🎉 Pruebas del sistema de monitoreo completadas!"
echo ""

print_info "Si hay errores, revisa:"
echo "  1. Que todos los contenedores estén corriendo: docker ps"
echo "  2. Los logs del sistema: tail -f $PROJECT_ROOT/logs/monitoring/*.log"
echo "  3. La configuración: cat $PROJECT_ROOT/config/monitoring/url-monitoring.json"
echo ""
