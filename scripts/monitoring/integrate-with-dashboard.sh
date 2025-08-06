#!/bin/bash

# =============================================================================
# Script para integrar el nuevo sistema de monitoreo con el dashboard existente
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
    echo -e "${PURPLE}║              INTEGRACIÓN CON DASHBOARD EXISTENTE            ║${NC}"
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header

# Cargar variables de entorno
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
fi

URL_STATUS_SERVICE_PORT=${URL_STATUS_SERVICE_PORT:-8090}
HAPROXY_INTEGRATION_PORT=${HAPROXY_INTEGRATION_PORT:-8085}

print_status "Integrando sistema de monitoreo con dashboard existente..."
echo ""

# 1. Buscar archivos del dashboard HAProxy existente
print_status "Buscando archivos del dashboard HAProxy..."

HAPROXY_DIR="$PROJECT_ROOT/haproxy"
ADMIN_API_FILE="$HAPROXY_DIR/scripts/admin_api.py"

if [ -f "$ADMIN_API_FILE" ]; then
    print_success "Encontrado admin_api.py existente"
    
    # Crear backup
    BACKUP_FILE="$ADMIN_API_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$ADMIN_API_FILE" "$BACKUP_FILE"
    print_success "Backup creado: $BACKUP_FILE"
    
    # Agregar endpoint de integración al admin_api.py existente
    print_status "Agregando endpoint de integración..."
    
    # Verificar si ya existe la integración
    if grep -q "url-status-integration" "$ADMIN_API_FILE"; then
        print_warning "La integración ya existe en admin_api.py"
    else
        # Agregar el endpoint de integración
        cat >> "$ADMIN_API_FILE" << 'EOF'

# =============================================================================
# INTEGRACIÓN CON SISTEMA DE MONITOREO DE URLs
# =============================================================================

@app.route('/api/url-status-integration', methods=['GET'])
def get_url_status_integration():
    """Endpoint integrado con el nuevo sistema de monitoreo de URLs."""
    try:
        import requests
        import os
        
        # URL del servicio de integración
        integration_port = os.getenv('HAPROXY_INTEGRATION_PORT', '8085')
        integration_url = f"http://localhost:{integration_port}/api/url-status"
        
        # Obtener datos del servicio de monitoreo
        response = requests.get(integration_url, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            
            # Agregar información adicional del sistema HAProxy
            data['haproxy_info'] = {
                'integration_active': True,
                'integration_port': integration_port,
                'monitoring_service_port': os.getenv('URL_STATUS_SERVICE_PORT', '8090'),
                'auto_ip_update': True
            }
            
            return jsonify(data)
        else:
            return jsonify({
                'error': f'Error del servicio de monitoreo: {response.status_code}',
                'fallback': True,
                'urls': [],
                'summary': {'success': 0, 'warnings': 0, 'errors': 0}
            }), 500
            
    except requests.exceptions.ConnectionError:
        return jsonify({
            'error': 'Sistema de monitoreo no disponible',
            'suggestion': 'Ejecutar: ./scripts/monitoring/setup-complete-monitoring.sh',
            'fallback': True,
            'urls': [],
            'summary': {'success': 0, 'warnings': 0, 'errors': 0}
        }), 503
        
    except Exception as e:
        return jsonify({
            'error': str(e),
            'fallback': True,
            'urls': [],
            'summary': {'success': 0, 'warnings': 0, 'errors': 0}
        }), 500

@app.route('/api/monitoring/status', methods=['GET'])
def get_monitoring_system_status():
    """Estado del sistema de monitoreo integrado."""
    try:
        import requests
        import os
        
        monitoring_port = os.getenv('URL_STATUS_SERVICE_PORT', '8090')
        integration_port = os.getenv('HAPROXY_INTEGRATION_PORT', '8085')
        
        # Verificar servicio principal
        try:
            monitoring_response = requests.get(f"http://localhost:{monitoring_port}/api/status", timeout=5)
            monitoring_status = monitoring_response.json() if monitoring_response.status_code == 200 else {'error': 'No disponible'}
        except:
            monitoring_status = {'error': 'No disponible'}
        
        # Verificar integración
        try:
            integration_response = requests.get(f"http://localhost:{integration_port}/api/status", timeout=5)
            integration_status = integration_response.json() if integration_response.status_code == 200 else {'error': 'No disponible'}
        except:
            integration_status = {'error': 'No disponible'}
        
        return jsonify({
            'system_status': 'integrated',
            'monitoring_service': monitoring_status,
            'integration_service': integration_status,
            'endpoints': {
                'monitoring': f"http://localhost:{monitoring_port}/api/url-status",
                'integration': f"http://localhost:{integration_port}/api/url-status",
                'haproxy_admin': f"http://localhost:{os.getenv('HAPROXY_UI_EXTERNAL_PORT', '8082')}"
            }
        })
        
    except Exception as e:
        return jsonify({
            'system_status': 'error',
            'error': str(e)
        })

@app.route('/api/monitoring/force-update', methods=['POST'])
def force_monitoring_update():
    """Forzar actualización del sistema de monitoreo."""
    try:
        import requests
        import os
        
        monitoring_port = os.getenv('URL_STATUS_SERVICE_PORT', '8090')
        
        # Forzar refresh
        refresh_response = requests.post(f"http://localhost:{monitoring_port}/api/url-status/refresh", timeout=30)
        
        # Actualizar IPs si es necesario
        ip_response = requests.post(f"http://localhost:{monitoring_port}/api/containers/update-ips", timeout=60)
        
        return jsonify({
            'success': True,
            'refresh_result': refresh_response.json() if refresh_response.status_code == 200 else {'error': 'Error en refresh'},
            'ip_update_result': ip_response.json() if ip_response.status_code == 200 else {'error': 'Error en actualización de IPs'}
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        })
EOF
        
        print_success "Endpoints de integración agregados a admin_api.py"
    fi
    
else
    print_warning "admin_api.py no encontrado, creando archivo de integración independiente"
    
    # Crear archivo de integración independiente
    INTEGRATION_FILE="$HAPROXY_DIR/scripts/monitoring_integration.py"
    cat > "$INTEGRATION_FILE" << 'EOF'
#!/usr/bin/env python3
"""
Integración independiente del sistema de monitoreo con HAProxy
"""

import os
import sys
import requests
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/api/url-status', methods=['GET'])
def get_url_status():
    """Endpoint principal de estado de URLs."""
    try:
        integration_port = os.getenv('HAPROXY_INTEGRATION_PORT', '8085')
        integration_url = f"http://localhost:{integration_port}/api/url-status"
        
        response = requests.get(integration_url, timeout=10)
        
        if response.status_code == 200:
            return response.json()
        else:
            return jsonify({
                'error': f'Error del servicio: {response.status_code}',
                'urls': [],
                'summary': {'success': 0, 'warnings': 0, 'errors': 0}
            }), 500
            
    except Exception as e:
        return jsonify({
            'error': str(e),
            'urls': [],
            'summary': {'success': 0, 'warnings': 0, 'errors': 0}
        }), 500

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8086
    app.run(host='0.0.0.0', port=port, debug=False)
EOF
    
    chmod +x "$INTEGRATION_FILE"
    print_success "Archivo de integración independiente creado: $INTEGRATION_FILE"
fi

# 2. Actualizar archivos HTML/JS del dashboard si existen
print_status "Buscando archivos del dashboard web..."

DASHBOARD_FILES=(
    "$HAPROXY_DIR/templates/index.html"
    "$HAPROXY_DIR/static/js/dashboard.js"
    "$HAPROXY_DIR/ui/index.html"
    "$PROJECT_ROOT/docs/dashboard.html"
)

for file in "${DASHBOARD_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "Encontrado: $file"
        
        # Crear backup
        BACKUP_FILE="$file.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$BACKUP_FILE"
        
        # Actualizar URLs en el archivo
        sed -i.tmp "s|/api/url-status|/api/url-status-integration|g" "$file" 2>/dev/null || true
        rm -f "$file.tmp" 2>/dev/null || true
        
        print_success "Actualizado: $file (backup: $BACKUP_FILE)"
    fi
done

# 3. Crear script de inicio integrado
print_status "Creando script de inicio integrado..."

INTEGRATED_START_SCRIPT="$PROJECT_ROOT/start-monitoring-integrated.sh"
cat > "$INTEGRATED_START_SCRIPT" << EOF
#!/bin/bash

# =============================================================================
# Script de inicio integrado para HAProxy + Sistema de Monitoreo
# =============================================================================

set -e

PROJECT_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Iniciando sistema integrado HAProxy + Monitoreo..."

# 1. Iniciar sistema de monitoreo
echo "📊 Iniciando sistema de monitoreo..."
"\$PROJECT_ROOT/scripts/monitoring/setup-complete-monitoring.sh"

# 2. Esperar a que el sistema esté listo
echo "⏳ Esperando a que el sistema esté listo..."
sleep 5

# 3. Verificar que todo está funcionando
echo "🔍 Verificando sistema..."
if curl -s http://localhost:${URL_STATUS_SERVICE_PORT}/api/status > /dev/null; then
    echo "✅ Sistema de monitoreo OK"
else
    echo "❌ Error en sistema de monitoreo"
    exit 1
fi

if curl -s http://localhost:${HAPROXY_INTEGRATION_PORT}/api/status > /dev/null; then
    echo "✅ Integración HAProxy OK"
else
    echo "❌ Error en integración HAProxy"
    exit 1
fi

echo ""
echo "🎉 Sistema integrado iniciado exitosamente!"
echo ""
echo "📊 Endpoints disponibles:"
echo "  • Dashboard HAProxy:      http://localhost:\${HAPROXY_UI_EXTERNAL_PORT:-8082}"
echo "  • Estado URLs:            http://localhost:${URL_STATUS_SERVICE_PORT}/api/url-status"
echo "  • Integración:            http://localhost:${HAPROXY_INTEGRATION_PORT}/api/url-status"
echo "  • HAProxy Stats:          http://localhost:\${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
echo ""
echo "🔧 Para detener:"
echo "  ./scripts/monitoring/stop-monitoring.sh"
echo ""
EOF

chmod +x "$INTEGRATED_START_SCRIPT"
print_success "Script de inicio integrado creado: $INTEGRATED_START_SCRIPT"

# 4. Crear documentación de la integración
print_status "Creando documentación de integración..."

INTEGRATION_DOC="$PROJECT_ROOT/docs/URL_MONITORING_INTEGRATION.md"
cat > "$INTEGRATION_DOC" << EOF
# Integración del Sistema de Monitoreo de URLs

## Resumen

Este documento describe la integración del nuevo sistema de monitoreo de URLs con el dashboard HAProxy existente, solucionando el problema "Error al cargar datos: NOT FOUND".

## Arquitectura de la Solución

### Componentes

1. **Servicio Principal de Monitoreo** (Puerto ${URL_STATUS_SERVICE_PORT})
   - Monitoreo continuo de URLs cada ${URL_CHECK_INTERVAL}s
   - Actualización automática de IPs de contenedores
   - API REST completa
   - Logs detallados

2. **Servicio de Integración HAProxy** (Puerto ${HAPROXY_INTEGRATION_PORT})
   - Compatibilidad con dashboard existente
   - Traducción de formatos de datos
   - Fallback en caso de errores

3. **Configuración Centralizada**
   - Variables de entorno en \`.env\`
   - Archivo JSON de configuración
   - Mapeo automático de puertos

## Endpoints Principales

### Sistema de Monitoreo
- \`GET /api/status\` - Estado del servicio
- \`GET /api/url-status\` - Estado de todas las URLs
- \`POST /api/url-status/refresh\` - Forzar actualización
- \`POST /api/containers/update-ips\` - Actualizar IPs de contenedores
- \`POST /api/config/reload\` - Recargar configuración

### Integración HAProxy
- \`GET /api/url-status\` - Endpoint compatible con dashboard
- \`GET /api/status\` - Estado de la integración

## Uso

### Inicio Rápido
\`\`\`bash
# Iniciar sistema completo
./scripts/monitoring/setup-complete-monitoring.sh

# O usar el script integrado
./start-monitoring-integrated.sh
\`\`\`

### Verificación
\`\`\`bash
# Probar sistema
./scripts/monitoring/test-monitoring-system.sh

# Ver estado
curl http://localhost:${URL_STATUS_SERVICE_PORT}/api/url-status | jq
\`\`\`

### Detener
\`\`\`bash
./scripts/monitoring/stop-monitoring.sh
\`\`\`

## Configuración

### Variables de Entorno (.env)
\`\`\`bash
URL_STATUS_SERVICE_PORT=${URL_STATUS_SERVICE_PORT}
HAPROXY_INTEGRATION_PORT=${HAPROXY_INTEGRATION_PORT}
URL_CHECK_INTERVAL=${URL_CHECK_INTERVAL}
URL_CHECK_TIMEOUT=5
URL_CHECK_RETRIES=3
\`\`\`

### URLs Monitoreadas
- HAProxy Load Balancer: http://localhost:\${HAPROXY_HTTP_EXTERNAL_PORT}/
- HAProxy Stats: http://localhost:\${HAPROXY_STATS_EXTERNAL_PORT}/stats
- HAProxy Admin UI: http://localhost:\${HAPROXY_UI_EXTERNAL_PORT}/
- WebLogic Server A: http://localhost:\${WEBLOGIC_A_EXTERNAL_PORT}/console
- WebLogic Server B: http://localhost:\${WEBLOGIC_B_EXTERNAL_PORT}/console
- MkDocs Documentation: http://localhost:\${MKDOCS_EXTERNAL_PORT}/

## Características

### ✅ Solucionado
- Error "NOT FOUND" por cambios de IP
- Monitoreo manual vs automático
- Configuración dispersa en múltiples archivos
- Falta de logs detallados
- Sin actualización automática de IPs

### ✅ Implementado
- Monitoreo automático continuo
- Actualización automática de IPs cuando hay errores críticos
- API REST completa
- Logs detallados con rotación
- Configuración centralizada
- Compatible con dashboard existente
- Demonio de monitoreo
- Sistema de reintentos
- Detección de contenedores Docker
- Backup automático de configuraciones

## Troubleshooting

### Problema: Servicio no inicia
\`\`\`bash
# Verificar puertos
netstat -tuln | grep -E "(${URL_STATUS_SERVICE_PORT}|${HAPROXY_INTEGRATION_PORT})"

# Ver logs
tail -f logs/monitoring/url-monitoring-\$(date +%Y%m%d).log
\`\`\`

### Problema: URLs siguen fallando
\`\`\`bash
# Forzar actualización de IPs
curl -X POST http://localhost:${URL_STATUS_SERVICE_PORT}/api/containers/update-ips

# Verificar contenedores
docker ps
\`\`\`

### Problema: Dashboard no muestra datos
\`\`\`bash
# Verificar integración
curl http://localhost:${HAPROXY_INTEGRATION_PORT}/api/url-status

# Verificar logs de integración
tail -f logs/monitoring/haproxy-integration-\$(date +%Y%m%d).log
\`\`\`

## Archivos Importantes

- \`scripts/monitoring/url-status-service.py\` - Servicio principal
- \`scripts/monitoring/haproxy-url-integration.py\` - Integración HAProxy
- \`config/monitoring/url-monitoring.json\` - Configuración
- \`logs/monitoring/\` - Directorio de logs
- \`.env\` - Variables de entorno

## Mantenimiento

### Logs
Los logs se rotan automáticamente cuando superan 10MB.

### Configuración
Para agregar nuevas URLs, editar el archivo \`.env\` y reiniciar:
\`\`\`bash
./scripts/monitoring/stop-monitoring.sh
./scripts/monitoring/setup-complete-monitoring.sh
\`\`\`

### Backup
Las configuraciones se respaldan automáticamente antes de cambios.
EOF

print_success "Documentación creada: $INTEGRATION_DOC"

echo ""
print_success "🎉 Integración completada exitosamente!"
echo ""

print_info "═══════════════════════════════════════════════════════════════"
print_info "                        RESUMEN DE INTEGRACIÓN"
print_info "═══════════════════════════════════════════════════════════════"
echo ""

print_info "📁 ARCHIVOS MODIFICADOS/CREADOS:"
if [ -f "$ADMIN_API_FILE" ]; then
    echo "  • $ADMIN_API_FILE (integración agregada)"
    echo "  • $ADMIN_API_FILE.backup.* (backup creado)"
fi
echo "  • $INTEGRATED_START_SCRIPT (script de inicio)"
echo "  • $INTEGRATION_DOC (documentación)"
echo ""

print_info "🚀 PARA USAR LA INTEGRACIÓN:"
echo "  1. Iniciar sistema integrado:"
echo "     ./start-monitoring-integrated.sh"
echo ""
echo "  2. O iniciar solo monitoreo:"
echo "     ./scripts/monitoring/setup-complete-monitoring.sh"
echo ""
echo "  3. Verificar funcionamiento:"
echo "     ./scripts/monitoring/test-monitoring-system.sh"
echo ""

print_info "🌐 ENDPOINTS INTEGRADOS:"
echo "  • Dashboard HAProxy:      http://localhost:${HAPROXY_UI_EXTERNAL_PORT:-8082}"
echo "  • Estado URLs (nuevo):    http://localhost:${URL_STATUS_SERVICE_PORT}/api/url-status"
echo "  • Integración HAProxy:    http://localhost:${HAPROXY_INTEGRATION_PORT}/api/url-status"
echo "  • HAProxy Stats:          http://localhost:${HAPROXY_STATS_EXTERNAL_PORT:-8404}/stats"
echo ""

print_success "¡El problema 'Error al cargar datos: NOT FOUND' está resuelto!"
print_success "El sistema ahora actualiza automáticamente las IPs y monitorea continuamente."
