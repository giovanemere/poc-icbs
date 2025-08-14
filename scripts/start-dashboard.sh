#!/bin/bash
#
# Script para iniciar el dashboard de tráfico
#

set -e

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Iniciando Dashboard de Tráfico WebLogic ===${NC}"
echo ""

# Verificar si Python está instalado
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 no está instalado${NC}"
    echo "Por favor, instale Python 3 con:"
    echo "  sudo apt-get install python3"
    exit 1
fi

# Verificar si HAProxy está en ejecución
if ! docker ps | grep -q haproxy; then
    echo -e "${YELLOW}Advertencia: El contenedor HAProxy no está en ejecución${NC}"
    echo "El dashboard funcionará en modo simulación"
fi

# Crear servidor web simple con Python
echo -e "${GREEN}Iniciando servidor web en http://localhost:8000${NC}"
echo "Presione Ctrl+C para detener el servidor"
echo ""

# Cambiar al directorio del dashboard
cd /home/giovanemere/periferia/icbs/poc-icbs-weblogic/haproxy/dashboard

# Crear API simulada para el dashboard
mkdir -p api

# Crear script Python para la API simulada
cat > api/server.py << EOF
#!/usr/bin/env python3
import http.server
import socketserver
import json
import random
import time
from urllib.parse import urlparse, parse_qs

# Configuración
PORT = 8000
HANDLER = http.server.SimpleHTTPRequestHandler

# Variables para almacenar el estado
ab_enabled = False
canary_enabled = False
ab_percentage = 50
canary_percentage = 10
version_a_requests = 0
version_b_requests = 0
weblogic_a_requests = 0
weblogic_b_requests = 0

class APIHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        global ab_enabled, canary_enabled, ab_percentage, canary_percentage
        global version_a_requests, version_b_requests, weblogic_a_requests, weblogic_b_requests
        
        # Parsear la URL
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        
        # Manejar solicitudes a la API
        if path == '/api/stats':
            # Incrementar contadores de peticiones
            if ab_enabled:
                version_a_requests += random.randint(1, 10)
                version_b_requests += random.randint(1, 10) if random.random() < ab_percentage / 100 else 0
            else:
                version_a_requests += random.randint(1, 10)
                
            if canary_enabled:
                weblogic_a_requests += random.randint(1, 10)
                weblogic_b_requests += random.randint(1, 10) if random.random() < canary_percentage / 100 else 0
            else:
                weblogic_a_requests += random.randint(1, 10)
            
            # Crear respuesta JSON
            response = {
                'ab': {
                    'enabled': ab_enabled,
                    'percentage': ab_percentage
                },
                'canary': {
                    'enabled': canary_enabled,
                    'percentage': canary_percentage
                },
                'requests': {
                    'versionA': version_a_requests,
                    'versionB': version_b_requests,
                    'weblogicA': weblogic_a_requests,
                    'weblogicB': weblogic_b_requests
                },
                'timestamp': int(time.time())
            }
            
            # Enviar respuesta
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
            return
        
        # Manejar solicitudes a archivos estáticos
        return http.server.SimpleHTTPRequestHandler.do_GET(self)
    
    def do_POST(self):
        global ab_enabled, canary_enabled, ab_percentage, canary_percentage
        
        # Parsear la URL
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        
        # Leer el cuerpo de la solicitud
        content_length = int(self.headers['Content-Length']) if 'Content-Length' in self.headers else 0
        post_data = self.rfile.read(content_length).decode('utf-8')
        
        try:
            data = json.loads(post_data) if post_data else {}
        except:
            data = {}
        
        # Manejar solicitudes a la API
        if path == '/api/ab/enable':
            ab_enabled = True
            if 'percentage' in data:
                ab_percentage = data['percentage']
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'success': True}).encode())
            return
        
        elif path == '/api/ab/disable':
            ab_enabled = False
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'success': True}).encode())
            return
        
        elif path == '/api/canary/enable':
            canary_enabled = True
            if 'percentage' in data:
                canary_percentage = data['percentage']
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'success': True}).encode())
            return
        
        elif path == '/api/canary/disable':
            canary_enabled = False
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'success': True}).encode())
            return
        
        # Manejar solicitudes no reconocidas
        self.send_response(404)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'error': 'Not found'}).encode())

# Iniciar servidor
with socketserver.TCPServer(("", PORT), APIHandler) as httpd:
    print(f"Servidor iniciado en http://localhost:{PORT}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("Servidor detenido")
EOF

# Hacer ejecutable el script
chmod +x api/server.py

# Iniciar el servidor
python3 api/server.py
