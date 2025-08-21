#!/bin/bash

# Script para iniciar el Dashboard Unificado WebLogic

PROJECT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
DASHBOARD_FILE="$PROJECT_DIR/unified-dashboard.html"
UNIFIED_PID_FILE="$PROJECT_DIR/unified-dashboard.pid"

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🎛️ Iniciando Dashboard Unificado WebLogic...${NC}"

# Verificar si ya está corriendo
if [ -f "$UNIFIED_PID_FILE" ]; then
    UNIFIED_PID=$(cat "$UNIFIED_PID_FILE")
    if ps -p $UNIFIED_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Dashboard Unificado ya está corriendo (PID: $UNIFIED_PID)${NC}"
        echo -e "${GREEN}🎛️ Dashboard disponible en: http://localhost:8085${NC}"
        exit 0
    else
        rm -f "$UNIFIED_PID_FILE"
    fi
fi

cd "$PROJECT_DIR"

# Verificar que el archivo del dashboard existe
if [ ! -f "$DASHBOARD_FILE" ]; then
    echo -e "${RED}❌ Archivo unified-dashboard.html no encontrado${NC}"
    exit 1
fi

# Crear servidor web simple con Python
echo -e "${BLUE}🚀 Iniciando servidor web para Dashboard Unificado...${NC}"

# Crear script de servidor temporal
cat > temp-unified-server.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import json
from urllib.parse import urlparse

PORT = 8085

class UnifiedDashboardHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.getcwd(), **kwargs)
    
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        # Servir el dashboard en la raíz
        if parsed_path.path == "/" or parsed_path.path == "/dashboard":
            self.path = "/unified-dashboard.html"
        
        # Agregar headers CORS
        def end_headers_override():
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', 'Content-Type')
            original_end_headers()
        
        original_end_headers = self.end_headers
        self.end_headers = end_headers_override
        
        super().do_GET()
    
    def log_message(self, format, *args):
        # Logging silencioso
        pass

print("🎛️ Dashboard Unificado WebLogic")
print(f"📡 Servidor iniciado en puerto {PORT}")
print(f"🌐 Dashboard disponible en: http://localhost:{PORT}")
print("🛑 Presiona Ctrl+C para detener")

try:
    with socketserver.TCPServer(("", PORT), UnifiedDashboardHandler) as httpd:
        httpd.serve_forever()
except KeyboardInterrupt:
    print("\n🛑 Servidor detenido")
except Exception as e:
    print(f"❌ Error: {e}")
EOF

# Iniciar servidor en segundo plano
nohup python3 temp-unified-server.py > unified-dashboard.log 2>&1 &
UNIFIED_PID=$!
echo $UNIFIED_PID > "$UNIFIED_PID_FILE"

# Esperar un momento para que el servidor se inicie
sleep 3

if ps -p $UNIFIED_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Dashboard Unificado iniciado correctamente (PID: $UNIFIED_PID)${NC}"
else
    echo -e "${RED}❌ Error al iniciar el Dashboard Unificado${NC}"
    rm -f "$UNIFIED_PID_FILE"
    exit 1
fi

echo
echo -e "${GREEN}🎉 Dashboard Unificado WebLogic iniciado correctamente${NC}"
echo
echo -e "${BLUE}📋 Información del Dashboard:${NC}"
echo -e "${GREEN}🎛️ Dashboard Unificado:        http://localhost:8085${NC}"
echo -e "${GREEN}📊 Funcionalidades:${NC}"
echo -e "   🎯 A/B Testing con control en tiempo real"
echo -e "   🚀 Canary Deployment con porcentajes dinámicos"
echo -e "   📈 Métricas de tráfico en tiempo real"
echo -e "   🔍 Estado de todos los backends"
echo -e "   📊 Gráficos interactivos de distribución"
echo
echo -e "${YELLOW}📝 Log disponible en: unified-dashboard.log${NC}"

# Probar conectividad
echo
echo -e "${BLUE}🧪 Probando conectividad...${NC}"
sleep 2

if curl -s http://localhost:8085/ > /dev/null; then
    echo -e "${GREEN}✅ Dashboard Unificado accesible${NC}"
    
    # Verificar conectividad con APIs
    echo -e "${BLUE}🔗 Verificando conectividad con APIs...${NC}"
    
    if curl -s http://localhost:8084/api/health > /dev/null; then
        echo -e "${GREEN}✅ API de Tráfico conectada${NC}"
    else
        echo -e "${YELLOW}⚠️ API de Tráfico no disponible${NC}"
    fi
    
    if curl -s http://localhost:8093/api/health > /dev/null; then
        echo -e "${GREEN}✅ API de Administración conectada${NC}"
    else
        echo -e "${YELLOW}⚠️ API de Administración no disponible${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Dashboard aún no accesible (puede tardar unos segundos)${NC}"
fi

echo
echo -e "${GREEN}🎛️ ¡Dashboard Unificado listo!${NC}"
echo -e "${BLUE}💡 Características principales:${NC}"
echo -e "   🎯 Control completo de A/B Testing"
echo -e "   🚀 Gestión de Canary Deployment"
echo -e "   📊 Visualización de tráfico en tiempo real"
echo -e "   🔍 Monitoreo de estado de servicios"
echo -e "   📈 Métricas y gráficos interactivos"
echo -e "   🎛️ Interfaz unificada para todo el sistema"

# Limpiar archivo temporal
rm -f temp-unified-server.py
