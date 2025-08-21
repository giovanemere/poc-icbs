#!/usr/bin/env python3
"""
Servidor web simple para servir el panel de administración HAProxy
"""

from http.server import HTTPServer, SimpleHTTPRequestHandler
import os
import sys

class AdminPanelHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.path.dirname(os.path.abspath(__file__)), **kwargs)
    
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

def run_server(port=8092):
    server_address = ('', port)
    httpd = HTTPServer(server_address, AdminPanelHandler)
    
    print(f"🎛️ HAProxy Admin Panel Server iniciado en puerto {port}")
    print(f"📱 Panel disponible en: http://localhost:{port}/index-functional.html")
    print(f"🔧 Directorio: {os.path.dirname(os.path.abspath(__file__))}")
    print("🛑 Presiona Ctrl+C para detener")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Servidor detenido")
        httpd.server_close()

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8092
    run_server(port)
