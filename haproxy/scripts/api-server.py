#!/usr/bin/env python3
"""
Servidor API REST simple para la administración de HAProxy
Puerto: 9001 (interno)
Accesible vía: http://localhost:8081/api/
"""

import json
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import threading
import time

class HAProxyAPIHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        # CORS headers
        self.send_cors_headers()
        
        if path == '/api/health':
            self.handle_health()
        elif path == '/api/stats':
            self.handle_stats()
        elif path == '/api/canary':
            self.handle_canary_status()
        elif path == '/api/ab-test':
            self.handle_ab_test_status()
        else:
            self.handle_api_info()
    
    def do_POST(self):
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        # CORS headers
        self.send_cors_headers()
        
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length).decode('utf-8')
        
        try:
            data = json.loads(post_data) if post_data else {}
        except json.JSONDecodeError:
            data = {}
        
        if path == '/api/canary':
            self.handle_canary_update(data)
        elif path == '/api/ab-test':
            self.handle_ab_test_update(data)
        else:
            self.send_error(404, "Endpoint not found")
    
    def do_OPTIONS(self):
        self.send_cors_headers()
        self.send_response(200)
        self.end_headers()
    
    def send_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
    
    def handle_health(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        response = {
            "status": "healthy",
            "service": "HAProxy Management API",
            "timestamp": time.time(),
            "version": "1.0"
        }
        
        self.wfile.write(json.dumps(response, indent=2).encode())
    
    def handle_stats(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        # Simular estadísticas (en una implementación real, obtendríamos esto de HAProxy)
        response = {
            "backends": {
                "weblogic-a": {"status": "UP", "requests": 1250, "response_time": "45ms"},
                "weblogic-b": {"status": "UP", "requests": 850, "response_time": "52ms"},
                "version-a": {"status": "UP", "requests": 750, "response_time": "38ms"},
                "version-b": {"status": "UP", "requests": 450, "response_time": "41ms"}
            },
            "traffic_distribution": {
                "version_a": 70,
                "version_b": 30
            },
            "canary_percentage": 20,
            "ab_test_active": True
        }
        
        self.wfile.write(json.dumps(response, indent=2).encode())
    
    def handle_canary_status(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        response = {
            "canary_enabled": True,
            "canary_percentage": 20,
            "canary_version": "B",
            "stable_version": "A"
        }
        
        self.wfile.write(json.dumps(response, indent=2).encode())
    
    def handle_ab_test_status(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        response = {
            "ab_test_enabled": True,
            "version_a_percentage": 50,
            "version_b_percentage": 50,
            "total_users": 1500,
            "version_a_users": 750,
            "version_b_users": 750
        }
        
        self.wfile.write(json.dumps(response, indent=2).encode())
    
    def handle_canary_update(self, data):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        percentage = data.get('percentage', 20)
        
        response = {
            "message": f"Canary deployment updated to {percentage}%",
            "canary_percentage": percentage,
            "status": "success"
        }
        
        self.wfile.write(json.dumps(response, indent=2).encode())
    
    def handle_ab_test_update(self, data):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        version_a_percentage = data.get('version_a_percentage', 50)
        version_b_percentage = 100 - version_a_percentage
        
        response = {
            "message": f"A/B test updated: A={version_a_percentage}%, B={version_b_percentage}%",
            "version_a_percentage": version_a_percentage,
            "version_b_percentage": version_b_percentage,
            "status": "success"
        }
        
        self.wfile.write(json.dumps(response, indent=2).encode())
    
    def handle_api_info(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        response = {
            "message": "HAProxy Management API",
            "version": "1.0",
            "endpoints": {
                "GET /api/health": "Health check",
                "GET /api/stats": "Get traffic statistics",
                "GET /api/canary": "Get canary deployment status",
                "POST /api/canary": "Update canary deployment",
                "GET /api/ab-test": "Get A/B test status",
                "POST /api/ab-test": "Update A/B test configuration"
            },
            "documentation": "http://localhost:8082"
        }
        
        self.wfile.write(json.dumps(response, indent=2).encode())

def run_server():
    server_address = ('127.0.0.1', 9001)
    httpd = HTTPServer(server_address, HAProxyAPIHandler)
    print(f"🚀 HAProxy API Server running on http://127.0.0.1:9001")
    print(f"📡 Accessible via HAProxy on http://localhost:8081/api/")
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()
