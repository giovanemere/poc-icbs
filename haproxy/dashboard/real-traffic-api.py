#!/usr/bin/env python3
"""
API y servidor web REAL para el Dashboard de Tráfico WebLogic
Se conecta realmente con HAProxy para aplicar cambios de A/B Testing y Canary Deployment
"""

from flask import Flask, jsonify, request, send_from_directory, render_template_string
from flask_cors import CORS
import requests
import json
import os
import time
import csv
import io
import subprocess
import re

app = Flask(__name__)
CORS(app)

# Configuración
HAPROXY_STATS_URL = "http://localhost:8404/stats"
HAPROXY_STATS_CSV_URL = "http://localhost:8404/stats;csv"
HAPROXY_STATS_AUTH = ("admin", "admin123")
HAPROXY_CONFIG_PATH = "/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/config/haproxy.cfg"
DASHBOARD_DIR = "/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/dashboard"

def get_haproxy_stats():
    """Obtener estadísticas reales de HAProxy"""
    try:
        response = requests.get(HAPROXY_STATS_CSV_URL, auth=HAPROXY_STATS_AUTH, timeout=5)
        if response.status_code == 200:
            # Parsear CSV
            csv_data = csv.DictReader(io.StringIO(response.text))
            stats = {}
            
            for row in csv_data:
                pxname = row.get('# pxname', '')
                svname = row.get('svname', '')
                
                if pxname not in stats:
                    stats[pxname] = {}
                
                stats[pxname][svname] = {
                    'status': row.get('status', 'UNKNOWN'),
                    'weight': int(row.get('weight', 0)) if row.get('weight', '').isdigit() else 0,
                    'requests': int(row.get('stot', 0)) if row.get('stot', '').isdigit() else 0,
                    'response_time': int(row.get('rtime', 0)) if row.get('rtime', '').isdigit() else 0,
                    'current_sessions': int(row.get('scur', 0)) if row.get('scur', '').isdigit() else 0,
                    'max_sessions': int(row.get('smax', 0)) if row.get('smax', '').isdigit() else 0,
                    'bytes_in': int(row.get('bin', 0)) if row.get('bin', '').isdigit() else 0,
                    'bytes_out': int(row.get('bout', 0)) if row.get('bout', '').isdigit() else 0
                }
            
            return stats
        else:
            print(f"Error obteniendo estadísticas de HAProxy: {response.status_code}")
            return {}
    except Exception as e:
        print(f"Error conectando con HAProxy: {e}")
        return {}

def update_server_weight(backend, server, weight):
    """Actualizar el peso de un servidor en HAProxy usando socat"""
    try:
        # Comando para cambiar el peso del servidor usando el socket correcto
        cmd = f'echo "set weight {backend}/{server} {weight}" | socat stdio /var/run/haproxy.sock'
        
        # Ejecutar usando docker exec en el contenedor HAProxy
        docker_cmd = f'docker exec haproxy sh -c \'{cmd}\''
        
        result = subprocess.run(docker_cmd, shell=True, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✅ Peso actualizado: {backend}/{server} = {weight}")
            print(f"📝 Respuesta HAProxy: {result.stdout.strip()}")
            return True
        else:
            print(f"❌ Error actualizando peso: {result.stderr}")
            # Intentar comando alternativo
            alt_cmd = f'echo "set server {backend}/{server} weight {weight}" | socat stdio /var/run/haproxy.sock'
            alt_docker_cmd = f'docker exec haproxy sh -c \'{alt_cmd}\''
            
            alt_result = subprocess.run(alt_docker_cmd, shell=True, capture_output=True, text=True)
            if alt_result.returncode == 0:
                print(f"✅ Peso actualizado (comando alternativo): {backend}/{server} = {weight}")
                print(f"📝 Respuesta HAProxy: {alt_result.stdout.strip()}")
                return True
            else:
                print(f"❌ Error con comando alternativo: {alt_result.stderr}")
                return False
            
    except Exception as e:
        print(f"❌ Error ejecutando comando: {e}")
        return False

def apply_ab_testing(percentage_a):
    """Aplicar configuración de A/B Testing real"""
    try:
        percentage_b = 100 - percentage_a
        
        # Actualizar pesos en HAProxy
        success_a = update_server_weight("weblogic_main_backend", "weblogic-a", percentage_a)
        success_b = update_server_weight("weblogic_main_backend", "weblogic-b", percentage_b)
        
        if success_a and success_b:
            return True, f"A/B Testing aplicado: {percentage_a}% A, {percentage_b}% B"
        else:
            return False, "Error aplicando configuración A/B Testing"
            
    except Exception as e:
        return False, f"Error en A/B Testing: {e}"

def apply_canary_deployment(canary_percentage):
    """Aplicar configuración de Canary Deployment real"""
    try:
        stable_percentage = 100 - canary_percentage
        
        # En canary, la versión B es la nueva (canary) y A es la estable
        success_stable = update_server_weight("weblogic_main_backend", "weblogic-a", stable_percentage)
        success_canary = update_server_weight("weblogic_main_backend", "weblogic-b", canary_percentage)
        
        if success_stable and success_canary:
            return True, f"Canary Deployment aplicado: {canary_percentage}% canary, {stable_percentage}% estable"
        else:
            return False, "Error aplicando configuración Canary"
            
    except Exception as e:
        return False, f"Error en Canary Deployment: {e}"

def reset_weights():
    """Resetear pesos a configuración por defecto (50/50)"""
    try:
        success_a = update_server_weight("weblogic_main_backend", "weblogic-a", 50)
        success_b = update_server_weight("weblogic_main_backend", "weblogic-b", 50)
        
        if success_a and success_b:
            return True, "Pesos reseteados a 50/50"
        else:
            return False, "Error reseteando pesos"
            
    except Exception as e:
        return False, f"Error reseteando: {e}"

@app.route('/')
def dashboard():
    """Servir el dashboard principal"""
    try:
        with open(os.path.join(DASHBOARD_DIR, 'traffic-dashboard.html'), 'r', encoding='utf-8') as f:
            content = f.read()
        return content
    except FileNotFoundError:
        return render_template_string("""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Dashboard de Tráfico Real - HAProxy</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
                .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                .header { text-align: center; margin-bottom: 30px; }
                .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 30px; }
                .stat-card { background: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 4px solid #007bff; }
                .controls { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
                .control-panel { background: #f8f9fa; padding: 20px; border-radius: 8px; }
                button { background: #007bff; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; margin: 5px; }
                button:hover { background: #0056b3; }
                button.danger { background: #dc3545; }
                button.danger:hover { background: #c82333; }
                input[type="range"] { width: 100%; margin: 10px 0; }
                .status-online { color: #28a745; }
                .status-offline { color: #dc3545; }
                .refresh-btn { position: fixed; top: 20px; right: 20px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🚀 Dashboard de Tráfico Real - HAProxy</h1>
                    <p>Conectado directamente con HAProxy para control real de A/B Testing y Canary Deployment</p>
                    <button class="refresh-btn" onclick="location.reload()">🔄 Actualizar</button>
                </div>
                
                <div class="stats-grid" id="stats-grid">
                    <div class="stat-card">
                        <h3>📊 Cargando estadísticas...</h3>
                        <p>Conectando con HAProxy...</p>
                    </div>
                </div>
                
                <div class="controls">
                    <div class="control-panel">
                        <h3>🔄 A/B Testing</h3>
                        <label>Porcentaje Versión A: <span id="ab-percentage">50</span>%</label>
                        <input type="range" id="ab-slider" min="0" max="100" value="50" oninput="updateABPercentage()">
                        <div>
                            <button onclick="applyABTesting()">Aplicar A/B Testing</button>
                            <button class="danger" onclick="disableABTesting()">Desactivar</button>
                        </div>
                    </div>
                    
                    <div class="control-panel">
                        <h3>🚀 Canary Deployment</h3>
                        <label>Porcentaje Canary: <span id="canary-percentage">10</span>%</label>
                        <input type="range" id="canary-slider" min="0" max="100" value="10" oninput="updateCanaryPercentage()">
                        <div>
                            <button onclick="applyCanaryDeployment()">Aplicar Canary</button>
                            <button class="danger" onclick="disableCanaryDeployment()">Desactivar</button>
                        </div>
                    </div>
                </div>
                
                <div style="text-align: center; margin-top: 30px;">
                    <button onclick="resetWeights()">🔄 Resetear Pesos (50/50)</button>
                    <button onclick="refreshStats()">📊 Actualizar Estadísticas</button>
                </div>
                
                <div id="messages" style="margin-top: 20px;"></div>
            </div>
            
            <script>
                function updateABPercentage() {
                    const slider = document.getElementById('ab-slider');
                    const display = document.getElementById('ab-percentage');
                    display.textContent = slider.value;
                }
                
                function updateCanaryPercentage() {
                    const slider = document.getElementById('canary-slider');
                    const display = document.getElementById('canary-percentage');
                    display.textContent = slider.value;
                }
                
                function showMessage(message, type = 'info') {
                    const messagesDiv = document.getElementById('messages');
                    const messageEl = document.createElement('div');
                    messageEl.style.padding = '10px';
                    messageEl.style.margin = '5px 0';
                    messageEl.style.borderRadius = '5px';
                    messageEl.style.backgroundColor = type === 'success' ? '#d4edda' : type === 'error' ? '#f8d7da' : '#d1ecf1';
                    messageEl.style.color = type === 'success' ? '#155724' : type === 'error' ? '#721c24' : '#0c5460';
                    messageEl.textContent = message;
                    messagesDiv.appendChild(messageEl);
                    
                    setTimeout(() => messageEl.remove(), 5000);
                }
                
                async function applyABTesting() {
                    const percentage = document.getElementById('ab-slider').value;
                    try {
                        const response = await fetch('/api/ab/apply', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ percentage: parseInt(percentage) })
                        });
                        const result = await response.json();
                        showMessage(result.message, result.success ? 'success' : 'error');
                        if (result.success) refreshStats();
                    } catch (error) {
                        showMessage('Error aplicando A/B Testing: ' + error.message, 'error');
                    }
                }
                
                async function applyCanaryDeployment() {
                    const percentage = document.getElementById('canary-slider').value;
                    try {
                        const response = await fetch('/api/canary/apply', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ percentage: parseInt(percentage) })
                        });
                        const result = await response.json();
                        showMessage(result.message, result.success ? 'success' : 'error');
                        if (result.success) refreshStats();
                    } catch (error) {
                        showMessage('Error aplicando Canary Deployment: ' + error.message, 'error');
                    }
                }
                
                async function disableABTesting() {
                    await resetWeights();
                    showMessage('A/B Testing desactivado', 'success');
                }
                
                async function disableCanaryDeployment() {
                    await resetWeights();
                    showMessage('Canary Deployment desactivado', 'success');
                }
                
                async function resetWeights() {
                    try {
                        const response = await fetch('/api/reset', { method: 'POST' });
                        const result = await response.json();
                        showMessage(result.message, result.success ? 'success' : 'error');
                        if (result.success) refreshStats();
                    } catch (error) {
                        showMessage('Error reseteando pesos: ' + error.message, 'error');
                    }
                }
                
                async function refreshStats() {
                    try {
                        const response = await fetch('/api/stats');
                        const stats = await response.json();
                        updateStatsDisplay(stats);
                    } catch (error) {
                        showMessage('Error obteniendo estadísticas: ' + error.message, 'error');
                    }
                }
                
                function updateStatsDisplay(stats) {
                    const grid = document.getElementById('stats-grid');
                    grid.innerHTML = '';
                    
                    // Mostrar estadísticas de backends
                    if (stats.backends) {
                        Object.keys(stats.backends).forEach(backend => {
                            const backendStats = stats.backends[backend];
                            Object.keys(backendStats).forEach(server => {
                                const serverStats = backendStats[server];
                                const card = document.createElement('div');
                                card.className = 'stat-card';
                                card.innerHTML = `
                                    <h3>${backend} - ${server}</h3>
                                    <p><strong>Estado:</strong> <span class="status-${serverStats.status.toLowerCase()}">${serverStats.status}</span></p>
                                    <p><strong>Peso:</strong> ${serverStats.weight}</p>
                                    <p><strong>Requests:</strong> ${serverStats.requests}</p>
                                    <p><strong>Sesiones actuales:</strong> ${serverStats.current_sessions}</p>
                                    <p><strong>Tiempo respuesta:</strong> ${serverStats.response_time}ms</p>
                                `;
                                grid.appendChild(card);
                            });
                        });
                    }
                }
                
                // Actualizar estadísticas cada 5 segundos
                setInterval(refreshStats, 5000);
                
                // Cargar estadísticas iniciales
                refreshStats();
            </script>
        </body>
        </html>
        """)

@app.route('/api/stats')
def get_stats():
    """Obtener estadísticas reales de HAProxy"""
    stats = get_haproxy_stats()
    
    # Obtener estado de servicios
    service_status = {}
    
    # Verificar HAProxy
    try:
        response = requests.get(HAPROXY_STATS_URL, auth=HAPROXY_STATS_AUTH, timeout=3)
        service_status['haproxy'] = 'online' if response.status_code == 200 else 'offline'
    except:
        service_status['haproxy'] = 'offline'
    
    # Verificar WebLogic A y B
    for port, name in [(7001, 'weblogic_a'), (7002, 'weblogic_b')]:
        try:
            response = requests.get(f"http://localhost:{port}/console", timeout=3)
            service_status[name] = 'online' if response.status_code in [200, 302] else 'offline'
        except:
            service_status[name] = 'offline'
    
    return jsonify({
        "timestamp": int(time.time()),
        "backends": stats,
        "services": service_status,
        "haproxy_available": service_status['haproxy'] == 'online'
    })

@app.route('/api/ab/apply', methods=['POST'])
def apply_ab():
    """Aplicar configuración de A/B Testing real"""
    data = request.get_json() or {}
    percentage = int(data.get('percentage', 50))
    
    success, message = apply_ab_testing(percentage)
    
    return jsonify({
        "success": success,
        "message": message,
        "percentage_a": percentage,
        "percentage_b": 100 - percentage
    })

@app.route('/api/canary/apply', methods=['POST'])
def apply_canary():
    """Aplicar configuración de Canary Deployment real"""
    data = request.get_json() or {}
    percentage = int(data.get('percentage', 10))
    
    success, message = apply_canary_deployment(percentage)
    
    return jsonify({
        "success": success,
        "message": message,
        "canary_percentage": percentage,
        "stable_percentage": 100 - percentage
    })

@app.route('/api/reset', methods=['POST'])
def reset():
    """Resetear configuración a valores por defecto"""
    success, message = reset_weights()
    
    return jsonify({
        "success": success,
        "message": message
    })

@app.route('/api/health')
def health():
    """Health check"""
    haproxy_stats = get_haproxy_stats()
    haproxy_available = len(haproxy_stats) > 0
    
    return jsonify({
        "status": "healthy",
        "service": "Real HAProxy Traffic Dashboard API",
        "haproxy_connected": haproxy_available,
        "timestamp": int(time.time())
    })

# Servir archivos estáticos del dashboard
@app.route('/<path:filename>')
def serve_static(filename):
    """Servir archivos estáticos"""
    try:
        return send_from_directory(DASHBOARD_DIR, filename)
    except FileNotFoundError:
        return jsonify({"error": "File not found"}), 404

if __name__ == '__main__':
    print("🚀 Iniciando Dashboard de Tráfico REAL - HAProxy...")
    print("📊 Dashboard disponible en: http://localhost:8084")
    print("📡 API disponible en: http://localhost:8084/api/stats")
    print("🔧 Endpoints: /api/ab/apply, /api/canary/apply, /api/reset")
    print("⚡ CONECTADO REALMENTE CON HAPROXY")
    
    # Verificar conexión inicial con HAProxy
    stats = get_haproxy_stats()
    if stats:
        print("✅ Conexión con HAProxy establecida")
        print(f"📈 Backends detectados: {list(stats.keys())}")
    else:
        print("⚠️  No se pudo conectar con HAProxy - verificar configuración")
    
    app.run(host='0.0.0.0', port=8084, debug=False)
