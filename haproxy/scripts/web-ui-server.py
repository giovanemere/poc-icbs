#!/usr/bin/env python3
"""
Servidor Web UI simple para la administración de HAProxy
Puerto: 9002 (interno)
Accesible vía: http://localhost:8082/
"""

import json
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

class HAProxyWebUIHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        if path == '/' or path == '/index.html':
            self.serve_main_page()
        elif path == '/api/status':
            self.serve_status_api()
        elif path.endswith('.css'):
            self.serve_css()
        elif path.endswith('.js'):
            self.serve_js()
        else:
            self.serve_main_page()
    
    def serve_main_page(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        
        html_content = """
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HAProxy Management Panel</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            background: rgba(255, 255, 255, 0.95);
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        .header h1 {
            color: #2c3e50;
            text-align: center;
            margin-bottom: 10px;
        }
        
        .header p {
            text-align: center;
            color: #7f8c8d;
        }
        
        .dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .card {
            background: rgba(255, 255, 255, 0.95);
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        .card h3 {
            color: #2c3e50;
            margin-bottom: 15px;
            border-bottom: 2px solid #3498db;
            padding-bottom: 5px;
        }
        
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 8px;
        }
        
        .status-up { background-color: #27ae60; }
        .status-down { background-color: #e74c3c; }
        .status-warning { background-color: #f39c12; }
        
        .metric {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            padding: 8px;
            background: #f8f9fa;
            border-radius: 5px;
        }
        
        .metric-label {
            font-weight: 500;
        }
        
        .metric-value {
            color: #3498db;
            font-weight: bold;
        }
        
        .controls {
            background: rgba(255, 255, 255, 0.95);
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        .control-group {
            margin-bottom: 20px;
        }
        
        .control-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: 500;
            color: #2c3e50;
        }
        
        .slider {
            width: 100%;
            height: 6px;
            border-radius: 3px;
            background: #ddd;
            outline: none;
            -webkit-appearance: none;
        }
        
        .slider::-webkit-slider-thumb {
            -webkit-appearance: none;
            appearance: none;
            width: 20px;
            height: 20px;
            border-radius: 50%;
            background: #3498db;
            cursor: pointer;
        }
        
        .slider::-moz-range-thumb {
            width: 20px;
            height: 20px;
            border-radius: 50%;
            background: #3498db;
            cursor: pointer;
            border: none;
        }
        
        .btn {
            background: #3498db;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            transition: background 0.3s;
        }
        
        .btn:hover {
            background: #2980b9;
        }
        
        .btn-success {
            background: #27ae60;
        }
        
        .btn-success:hover {
            background: #229954;
        }
        
        .btn-warning {
            background: #f39c12;
        }
        
        .btn-warning:hover {
            background: #e67e22;
        }
        
        .links {
            background: rgba(255, 255, 255, 0.95);
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            margin-top: 20px;
        }
        
        .links h3 {
            color: #2c3e50;
            margin-bottom: 15px;
        }
        
        .link-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 10px;
        }
        
        .link-item {
            display: block;
            padding: 10px;
            background: #f8f9fa;
            border-radius: 5px;
            text-decoration: none;
            color: #2c3e50;
            transition: background 0.3s;
        }
        
        .link-item:hover {
            background: #e9ecef;
        }
        
        .refresh-indicator {
            position: fixed;
            top: 20px;
            right: 20px;
            background: rgba(52, 152, 219, 0.9);
            color: white;
            padding: 10px;
            border-radius: 5px;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="refresh-indicator" id="refreshIndicator">
        🔄 Actualizando...
    </div>
    
    <div class="container">
        <div class="header">
            <h1>🚀 HAProxy Management Panel</h1>
            <p>Panel de Control para Testing A/B, Canary Deployment y Feature Flags</p>
        </div>
        
        <div class="dashboard">
            <div class="card">
                <h3>📊 Estado de Servicios</h3>
                <div class="metric">
                    <span class="metric-label">
                        <span class="status-indicator status-up"></span>WebLogic A
                    </span>
                    <span class="metric-value">UP</span>
                </div>
                <div class="metric">
                    <span class="metric-label">
                        <span class="status-indicator status-up"></span>WebLogic B
                    </span>
                    <span class="metric-value">UP</span>
                </div>
                <div class="metric">
                    <span class="metric-label">
                        <span class="status-indicator status-up"></span>HAProxy
                    </span>
                    <span class="metric-value">UP</span>
                </div>
                <div class="metric">
                    <span class="metric-label">
                        <span class="status-indicator status-up"></span>Oracle DB
                    </span>
                    <span class="metric-value">UP</span>
                </div>
            </div>
            
            <div class="card">
                <h3>📈 Métricas de Tráfico</h3>
                <div class="metric">
                    <span class="metric-label">Requests Totales</span>
                    <span class="metric-value" id="totalRequests">2,100</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Versión A</span>
                    <span class="metric-value" id="versionARequests">1,470 (70%)</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Versión B</span>
                    <span class="metric-value" id="versionBRequests">630 (30%)</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Tiempo Respuesta Promedio</span>
                    <span class="metric-value" id="avgResponseTime">48ms</span>
                </div>
            </div>
            
            <div class="card">
                <h3>🎯 A/B Testing</h3>
                <div class="metric">
                    <span class="metric-label">Estado</span>
                    <span class="metric-value" style="color: #27ae60;">ACTIVO</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Usuarios en A</span>
                    <span class="metric-value">750 (50%)</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Usuarios en B</span>
                    <span class="metric-value">750 (50%)</span>
                </div>
            </div>
            
            <div class="card">
                <h3>🚀 Canary Deployment</h3>
                <div class="metric">
                    <span class="metric-label">Estado</span>
                    <span class="metric-value" style="color: #27ae60;">ACTIVO</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Tráfico Canary</span>
                    <span class="metric-value" id="canaryPercentage">20%</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Versión Estable</span>
                    <span class="metric-value">A</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Versión Canary</span>
                    <span class="metric-value">B</span>
                </div>
            </div>
        </div>
        
        <div class="controls">
            <h3>⚙️ Controles de Despliegue</h3>
            
            <div class="control-group">
                <label for="canarySlider">Porcentaje de Tráfico Canary: <span id="canaryValue">20</span>%</label>
                <input type="range" min="0" max="100" value="20" class="slider" id="canarySlider">
                <button class="btn btn-success" onclick="updateCanary()">Aplicar Canary</button>
            </div>
            
            <div class="control-group">
                <label for="abTestSlider">A/B Testing - Tráfico a Versión A: <span id="abTestValue">50</span>%</label>
                <input type="range" min="0" max="100" value="50" class="slider" id="abTestSlider">
                <button class="btn btn-warning" onclick="updateABTest()">Aplicar A/B Test</button>
            </div>
            
            <div class="control-group">
                <button class="btn" onclick="refreshStats()">🔄 Actualizar Estadísticas</button>
                <button class="btn btn-success" onclick="enableFeatureFlags()">🎛️ Gestionar Feature Flags</button>
            </div>
        </div>
        
        <div class="links">
            <h3>🔗 Enlaces Rápidos</h3>
            <div class="link-grid">
                <a href="http://localhost:8080" target="_blank" class="link-item">🌐 HAProxy Frontend</a>
                <a href="http://localhost:8404/stats" target="_blank" class="link-item">📊 HAProxy Stats</a>
                <a href="http://localhost:8001" target="_blank" class="link-item">📈 Dashboard</a>
                <a href="http://localhost:7001/console" target="_blank" class="link-item">🔧 WebLogic A</a>
                <a href="http://localhost:7002/console" target="_blank" class="link-item">🔧 WebLogic B</a>
                <a href="http://localhost:8080/feature-flags/" target="_blank" class="link-item">🎛️ Feature Flags</a>
            </div>
        </div>
    </div>
    
    <script>
        // Actualizar valores de sliders en tiempo real
        document.getElementById('canarySlider').oninput = function() {
            document.getElementById('canaryValue').textContent = this.value;
        }
        
        document.getElementById('abTestSlider').oninput = function() {
            document.getElementById('abTestValue').textContent = this.value;
        }
        
        // Funciones de control
        function updateCanary() {
            const percentage = document.getElementById('canarySlider').value;
            
            fetch('/api/canary', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    percentage: parseInt(percentage)
                })
            })
            .then(response => response.json())
            .then(data => {
                alert(`Canary deployment actualizado a ${percentage}%`);
                refreshStats();
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error al actualizar canary deployment');
            });
        }
        
        function updateABTest() {
            const versionAPercentage = document.getElementById('abTestSlider').value;
            
            fetch('/api/ab-test', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    version_a_percentage: parseInt(versionAPercentage)
                })
            })
            .then(response => response.json())
            .then(data => {
                alert(`A/B Test actualizado: A=${versionAPercentage}%, B=${100-versionAPercentage}%`);
                refreshStats();
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error al actualizar A/B test');
            });
        }
        
        function refreshStats() {
            const indicator = document.getElementById('refreshIndicator');
            indicator.style.display = 'block';
            
            // Simular actualización de estadísticas
            setTimeout(() => {
                // Actualizar valores aleatorios para simular cambios
                const totalReqs = Math.floor(Math.random() * 1000) + 2000;
                document.getElementById('totalRequests').textContent = totalReqs.toLocaleString();
                
                const canaryPerc = document.getElementById('canarySlider').value;
                const versionBReqs = Math.floor(totalReqs * canaryPerc / 100);
                const versionAReqs = totalReqs - versionBReqs;
                
                document.getElementById('versionARequests').textContent = `${versionAReqs.toLocaleString()} (${100-canaryPerc}%)`;
                document.getElementById('versionBRequests').textContent = `${versionBReqs.toLocaleString()} (${canaryPerc}%)`;
                
                const avgTime = Math.floor(Math.random() * 20) + 40;
                document.getElementById('avgResponseTime').textContent = `${avgTime}ms`;
                
                indicator.style.display = 'none';
            }, 1000);
        }
        
        function enableFeatureFlags() {
            window.open('http://localhost:8080/feature-flags/', '_blank');
        }
        
        // Auto-refresh cada 30 segundos
        setInterval(refreshStats, 30000);
        
        // Ocultar indicador de refresh al cargar
        document.getElementById('refreshIndicator').style.display = 'none';
    </script>
</body>
</html>
        """
        
        self.wfile.write(html_content.encode())
    
    def serve_status_api(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        response = {
            "timestamp": time.time(),
            "services": {
                "weblogic_a": "UP",
                "weblogic_b": "UP",
                "haproxy": "UP",
                "oracle_db": "UP"
            },
            "traffic": {
                "total_requests": 2100,
                "version_a_requests": 1470,
                "version_b_requests": 630
            }
        }
        
        self.wfile.write(json.dumps(response, indent=2).encode())
    
    def serve_css(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/css')
        self.end_headers()
        self.wfile.write(b"/* CSS placeholder */")
    
    def serve_js(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/javascript')
        self.end_headers()
        self.wfile.write(b"/* JS placeholder */")

def run_server():
    server_address = ('127.0.0.1', 9002)
    httpd = HTTPServer(server_address, HAProxyWebUIHandler)
    print(f"🌐 HAProxy Web UI Server running on http://127.0.0.1:9002")
    print(f"🖥️  Accessible via HAProxy on http://localhost:8082/")
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()
