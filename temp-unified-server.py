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
