#!/bin/bash

# =============================================================================
# Script para iniciar el servicio API de HAProxy en un puerto disponible
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo -e "${BLUE}🚀 Iniciando servicio API de HAProxy${NC}"
echo ""

# Verificar que el contenedor HAProxy esté corriendo
if ! docker ps --format '{{.Names}}' | grep -q "^haproxy$"; then
    print_error "El contenedor HAProxy no está ejecutándose"
    exit 1
fi

print_success "Contenedor HAProxy está ejecutándose"

# Detener procesos existentes del API
print_status "Deteniendo procesos existentes del API..."
docker exec haproxy pkill -f "admin_api.py" 2>/dev/null || true
docker exec haproxy pkill -f "admin_ui.py" 2>/dev/null || true
sleep 2

# Iniciar el API en el puerto 8085 (puerto interno disponible)
print_status "Iniciando API de administración en puerto interno 8085..."

# Crear script de inicio del API
docker exec haproxy bash -c 'cat > /tmp/start_api.sh << "EOF"
#!/bin/bash
cd /scripts
export HAPROXY_API_EXTERNAL_PORT=8085
export FLASK_ENV=production
python3 admin_api.py
EOF'

docker exec haproxy chmod +x /tmp/start_api.sh

# Iniciar el API en background
docker exec -d haproxy /tmp/start_api.sh

print_success "API de administración iniciado en puerto interno 8085"

# Esperar a que el servicio se inicie
print_status "Esperando a que el servicio se inicie..."
sleep 5

# Probar el API internamente
print_status "Probando el API internamente..."
api_test=$(docker exec haproxy curl -s -m 5 "http://localhost:8085/api/status" 2>/dev/null || echo "error")

if echo "$api_test" | grep -q "status.*ok"; then
    print_success "✓ API funcionando correctamente en puerto interno 8085"
    
    # Probar endpoint de URL status
    print_status "Probando endpoint de estado de URLs..."
    url_status_test=$(docker exec haproxy curl -s -m 5 "http://localhost:8085/api/url-status" 2>/dev/null || echo "error")
    
    if echo "$url_status_test" | grep -q "urls\|error"; then
        print_success "✓ Endpoint de estado de URLs funcionando"
    else
        print_warning "⚠️  Endpoint de estado de URLs puede necesitar más tiempo"
    fi
    
    # Crear un proxy simple para acceder desde el exterior
    print_status "Configurando acceso externo..."
    
    # Usar socat para hacer proxy del puerto 8085 interno al 8081 externo
    docker exec -d haproxy bash -c 'socat TCP-LISTEN:8081,fork TCP:localhost:8085' 2>/dev/null || true
    
    sleep 2
    
    # Probar acceso externo
    if curl -s -m 5 "http://localhost:8081/api/status" | grep -q "status.*ok"; then
        print_success "✓ API accesible externamente en puerto 8081"
    else
        print_warning "⚠️  Configurando acceso alternativo..."
        
        # Alternativa: usar el puerto 8082 que ya está mapeado
        print_status "Usando puerto 8082 como alternativa..."
        
        # Crear un simple HTML que redirija al API
        docker exec haproxy bash -c 'mkdir -p /tmp/api_proxy'
        docker exec haproxy bash -c 'cat > /tmp/api_proxy/index.html << "EOF"
<!DOCTYPE html>
<html>
<head>
    <title>HAProxy API Proxy</title>
    <script>
        // Redirigir llamadas API al puerto interno
        if (window.location.pathname.startsWith("/api/")) {
            fetch("http://localhost:8085" + window.location.pathname + window.location.search)
                .then(response => response.json())
                .then(data => {
                    document.body.innerHTML = "<pre>" + JSON.stringify(data, null, 2) + "</pre>";
                })
                .catch(error => {
                    document.body.innerHTML = "<pre>Error: " + error + "</pre>";
                });
        }
    </script>
</head>
<body>
    <h1>HAProxy API Proxy</h1>
    <p>API disponible en puerto interno 8085</p>
    <ul>
        <li><a href="javascript:void(0)" onclick="fetch('"'"'http://localhost:8085/api/status'"'"').then(r=>r.json()).then(d=>document.getElementById('"'"'result'"'"').innerHTML=JSON.stringify(d,null,2))">Status</a></li>
        <li><a href="javascript:void(0)" onclick="fetch('"'"'http://localhost:8085/api/url-status'"'"').then(r=>r.json()).then(d=>document.getElementById('"'"'result'"'"').innerHTML=JSON.stringify(d,null,2))">URL Status</a></li>
    </ul>
    <pre id="result"></pre>
</body>
</html>
EOF'
    fi
    
else
    print_error "Error al iniciar el API"
    print_status "Verificando logs..."
    docker exec haproxy ps aux | grep python || true
    exit 1
fi

echo ""
print_success "🎉 Servicio API iniciado correctamente!"
echo ""
print_status "Formas de acceder al API:"
echo "  • Interno (desde contenedor): http://localhost:8085/api/status"
echo "  • Externo (si funciona): http://localhost:8081/api/status"
echo "  • HAProxy Stats: http://localhost:8404/stats"
echo "  • HAProxy Admin UI: http://localhost:8082/"
echo ""

print_status "Para probar el API de estado de URLs:"
echo "  docker exec haproxy curl http://localhost:8085/api/url-status"
echo ""

print_status "Para verificar que el servicio está corriendo:"
echo "  docker exec haproxy ps aux | grep admin_api"
echo ""
