#!/usr/bin/env python3
"""
Servidor web simple para servir el dashboard profesional de HAProxy
"""

import http.server
import socketserver
import os
import json
import threading
import time
from urllib.parse import urlparse, parse_qs

# Configuración
PORT = 8000
DASHBOARD_DIR = "/dashboard"

class DashboardHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DASHBOARD_DIR, **kwargs)
    
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        # Servir el dashboard principal en la raíz
        if parsed_path.path == "/" or parsed_path.path == "/dashboard/":
            self.path = "/traffic-dashboard.html"
        
        # API endpoints para datos dinámicos
        elif parsed_path.path == "/api/stats":
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            # Datos simulados para el dashboard
            stats = {
                "timestamp": int(time.time()),
                "services": {
                    "weblogic-a": {"status": "UP", "requests": 1250, "response_time": 45},
                    "weblogic-b": {"status": "UP", "requests": 890, "response_time": 52},
                    "haproxy": {"status": "UP", "requests": 2140, "response_time": 12},
                    "oracle-db": {"status": "UP", "connections": 25, "response_time": 8}
                },
                "ab_testing": {
                    "enabled": True,
                    "version_a_percentage": 60,
                    "version_b_percentage": 40,
                    "total_requests": 2140
                },
                "canary": {
                    "enabled": True,
                    "percentage": 20,
                    "requests": 428
                },
                "traffic": {
                    "current_rps": 45,
                    "peak_rps": 120,
                    "avg_response_time": 38
                }
            }
            
            self.wfile.write(json.dumps(stats).encode())
            return
        
        elif parsed_path.path == "/api/health":
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "healthy"}).encode())
            return
        
        # Servir archivos estáticos normalmente
        super().do_GET()
    
    def log_message(self, format, *args):
        # Logging silencioso para evitar spam
        pass

def start_server():
    """Iniciar el servidor del dashboard"""
    try:
        with socketserver.TCPServer(("", PORT), DashboardHandler) as httpd:
            print(f"Dashboard server started on port {PORT}")
            print(f"Dashboard available at: http://localhost:{PORT}/")
            httpd.serve_forever()
    except Exception as e:
        print(f"Error starting dashboard server: {e}")

if __name__ == "__main__":
    start_server()
