#!/bin/bash

# =============================================================================
# Script para corregir la configuración del puerto del API de HAProxy
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

echo -e "${BLUE}🚀 Corrigiendo configuración del API de HAProxy${NC}"
echo ""

# Verificar que el contenedor HAProxy esté corriendo
if ! docker ps --format '{{.Names}}' | grep -q "^haproxy$"; then
    print_error "El contenedor HAProxy no está ejecutándose"
    exit 1
fi

print_success "Contenedor HAProxy está ejecutándose"

# Crear backup de la configuración
print_status "Creando backup de la configuración..."
backup_file="/usr/local/etc/haproxy/haproxy.cfg.bak.api_fix.$(date +%Y%m%d_%H%M%S)"
docker exec haproxy cp /usr/local/etc/haproxy/haproxy.cfg "$backup_file"
print_success "Backup creado: $backup_file"

# Mostrar configuración actual
print_status "Configuración actual del API:"
docker exec haproxy grep -A 10 -B 2 "listen api" /usr/local/etc/haproxy/haproxy.cfg || true
echo ""

# Corregir la configuración del puerto del API
print_status "Corrigiendo configuración del puerto del API..."

# Crear un script temporal para hacer los cambios
docker exec haproxy bash -c 'cat > /tmp/fix_api_config.sh << "EOF"
#!/bin/bash

# Leer el archivo de configuración
config_file="/usr/local/etc/haproxy/haproxy.cfg"

# Crear archivo temporal
temp_file="/tmp/haproxy_fixed.cfg"

# Procesar el archivo línea por línea
while IFS= read -r line; do
    # Si encontramos la sección del API, cambiar el puerto
    if [[ "$line" == *"listen api"* ]]; then
        echo "$line"
        # Leer las siguientes líneas hasta encontrar bind
        while IFS= read -r next_line; do
            if [[ "$next_line" == *"bind *:8083"* ]]; then
                echo "    bind *:8081"
            else
                echo "$next_line"
            fi
            # Si llegamos a una nueva sección, salir del bucle interno
            if [[ "$next_line" == *"listen "* ]] || [[ "$next_line" == *"frontend "* ]] || [[ "$next_line" == *"backend "* ]]; then
                break
            fi
        done
    else
        echo "$line"
    fi
done < "$config_file" > "$temp_file"

# Reemplazar el archivo original
mv "$temp_file" "$config_file"
EOF'

# Ejecutar el script de corrección
docker exec haproxy chmod +x /tmp/fix_api_config.sh
docker exec haproxy /tmp/fix_api_config.sh

print_success "Configuración del puerto corregida"

# Mostrar nueva configuración
print_status "Nueva configuración del API:"
docker exec haproxy grep -A 10 -B 2 "listen api" /usr/local/etc/haproxy/haproxy.cfg || true
echo ""

# Recargar HAProxy
print_status "Recargando HAProxy..."
current_pid=$(docker exec haproxy cat /var/run/haproxy.pid 2>/dev/null || echo "")

if [ -n "$current_pid" ]; then
    docker exec haproxy haproxy -f /usr/local/etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -sf "$current_pid"
else
    docker exec haproxy haproxy -f /usr/local/etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid
fi

if [ $? -eq 0 ]; then
    print_success "HAProxy recargado exitosamente"
else
    print_error "Error al recargar HAProxy"
    exit 1
fi

# Esperar un momento para que se estabilice
print_status "Esperando a que los servicios se estabilicen..."
sleep 3

# Iniciar el API de administración en el puerto correcto
print_status "Iniciando API de administración..."

# Detener procesos existentes del API
docker exec haproxy pkill -f "admin_api.py" 2>/dev/null || true
sleep 2

# Iniciar el API en el puerto 8081
docker exec -d haproxy bash -c 'cd /scripts && HAPROXY_API_EXTERNAL_PORT=8081 python3 admin_api.py'

print_success "API de administración iniciado en puerto 8081"

# Probar el API
print_status "Probando el API..."
sleep 3

if curl -s -m 5 "http://localhost:8081/api/status" | grep -q "status.*ok"; then
    print_success "✓ API funcionando correctamente en puerto 8081"
else
    print_warning "⚠️  API puede necesitar más tiempo para iniciar"
fi

# Probar endpoint de URL status
print_status "Probando endpoint de estado de URLs..."
if curl -s -m 5 "http://localhost:8081/api/url-status" | grep -q "urls\|error"; then
    print_success "✓ Endpoint de estado de URLs funcionando"
else
    print_warning "⚠️  Endpoint de estado de URLs puede necesitar más tiempo"
fi

echo ""
print_success "🎉 Corrección del API completada!"
echo ""
print_status "URLs para verificar:"
echo "  • API Status: http://localhost:8081/api/status"
echo "  • URL Status: http://localhost:8081/api/url-status"
echo "  • HAProxy Stats: http://localhost:8404/stats"
echo "  • HAProxy Admin UI: http://localhost:8082/"
echo ""

# Limpiar archivos temporales
docker exec haproxy rm -f /tmp/fix_api_config.sh 2>/dev/null || true

print_status "Para verificar que todo funciona correctamente:"
echo "  curl http://localhost:8081/api/status"
echo "  curl http://localhost:8081/api/url-status"
echo ""
