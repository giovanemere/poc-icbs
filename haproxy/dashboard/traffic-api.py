#!/usr/bin/env python3
"""
API y servidor web para el Dashboard de Tráfico WebLogic
Proporciona análisis de tráfico, estado de backends y gestión A/B Testing/Canary
"""

from flask import Flask, jsonify, request, send_from_directory, render_template_string
from flask_cors import CORS
import requests
import json
import os
import time
import random
import threading

app = Flask(__name__)
CORS(app)

# Configuración
HAPROXY_STATS_URL = "http://localhost:8404/stats"
HAPROXY_STATS_AUTH = ("admin", "admin123")
DASHBOARD_DIR = "/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/dashboard"

# Variables globales para estadísticas
traffic_stats = {
    "version_a_requests": 0,
    "version_b_requests": 0,
    "weblogic_a_requests": 0,
    "weblogic_b_requests": 0,
    "ab_enabled": False,
    "canary_enabled": False,
    "ab_percentage": 50,
    "canary_percentage": 10,
    "total_requests": 0,
    "current_rps": 0,
    "peak_rps": 0,
    "avg_response_time": 0
}

def simulate_traffic():
    """Simular tráfico en tiempo real"""
    global traffic_stats
    while True:
        # Simular requests
        base_requests = random.randint(5, 15)
        traffic_stats["total_requests"] += base_requests
        
        if traffic_stats["ab_enabled"]:
            a_requests = int(base_requests * traffic_stats["ab_percentage"] / 100)
            b_requests = base_requests - a_requests
            traffic_stats["version_a_requests"] += a_requests
            traffic_stats["version_b_requests"] += b_requests
        else:
            traffic_stats["version_a_requests"] += base_requests
        
        if traffic_stats["canary_enabled"]:
            canary_requests = int(base_requests * traffic_stats["canary_percentage"] / 100)
            stable_requests = base_requests - canary_requests
            traffic_stats["weblogic_b_requests"] += canary_requests
            traffic_stats["weblogic_a_requests"] += stable_requests
        else:
            traffic_stats["weblogic_a_requests"] += base_requests
        
        # Simular métricas
        traffic_stats["current_rps"] = random.randint(20, 80)
        traffic_stats["peak_rps"] = max(traffic_stats["peak_rps"], traffic_stats["current_rps"])
        traffic_stats["avg_response_time"] = random.randint(30, 100)
        
        time.sleep(2)

# Iniciar simulación de tráfico en hilo separado
traffic_thread = threading.Thread(target=simulate_traffic, daemon=True)
traffic_thread.start()

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
            <title>Dashboard de Tráfico - Error</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; text-align: center; }
                .error { color: #dc3545; background: #f8d7da; padding: 20px; border-radius: 10px; }
            </style>
        </head>
        <body>
            <div class="error">
                <h1>❌ Dashboard no encontrado</h1>
                <p>El archivo traffic-dashboard.html no se encuentra en: {{ dashboard_dir }}</p>
                <p><a href="/api/stats">Ver API de estadísticas</a></p>
            </div>
        </body>
        </html>
        """, dashboard_dir=DASHBOARD_DIR)

@app.route('/api/stats')
def get_stats():
    """Obtener estadísticas de tráfico en tiempo real"""
    global traffic_stats
    
    # Obtener estado de HAProxy si está disponible
    haproxy_status = "unknown"
    try:
        response = requests.get(HAPROXY_STATS_URL, auth=HAPROXY_STATS_AUTH, timeout=3)
        haproxy_status = "online" if response.status_code == 200 else "offline"
    except:
        haproxy_status = "offline"
    
    # Obtener estado de WebLogic
    weblogic_a_status = "unknown"
    weblogic_b_status = "unknown"
    
    try:
        response = requests.get("http://localhost:7001/console", timeout=3)
        weblogic_a_status = "online" if response.status_code in [200, 302] else "offline"
    except:
        weblogic_a_status = "offline"
    
    try:
        response = requests.get("http://localhost:7002/console", timeout=3)
        weblogic_b_status = "online" if response.status_code in [200, 302] else "offline"
    except:
        weblogic_b_status = "offline"
    
    return jsonify({
        "timestamp": int(time.time()),
        "traffic": traffic_stats,
        "backends": {
            "haproxy": {
                "status": haproxy_status,
                "requests": traffic_stats["total_requests"],
                "response_time": traffic_stats["avg_response_time"]
            },
            "weblogic_a": {
                "status": weblogic_a_status,
                "requests": traffic_stats["weblogic_a_requests"],
                "response_time": random.randint(40, 80)
            },
            "weblogic_b": {
                "status": weblogic_b_status,
                "requests": traffic_stats["weblogic_b_requests"],
                "response_time": random.randint(45, 85)
            }
        },
        "deployment": {
            "ab_testing": {
                "enabled": traffic_stats["ab_enabled"],
                "version_a_percentage": traffic_stats["ab_percentage"],
                "version_b_percentage": 100 - traffic_stats["ab_percentage"],
                "version_a_requests": traffic_stats["version_a_requests"],
                "version_b_requests": traffic_stats["version_b_requests"]
            },
            "canary": {
                "enabled": traffic_stats["canary_enabled"],
                "percentage": traffic_stats["canary_percentage"],
                "stable_requests": traffic_stats["weblogic_a_requests"],
                "canary_requests": traffic_stats["weblogic_b_requests"]
            }
        },
        "metrics": {
            "current_rps": traffic_stats["current_rps"],
            "peak_rps": traffic_stats["peak_rps"],
            "avg_response_time": traffic_stats["avg_response_time"],
            "total_requests": traffic_stats["total_requests"]
        }
    })

@app.route('/api/ab/enable', methods=['POST'])
def enable_ab():
    """Activar A/B Testing"""
    global traffic_stats
    data = request.get_json() or {}
    
    traffic_stats["ab_enabled"] = True
    if "percentage" in data:
        traffic_stats["ab_percentage"] = max(0, min(100, int(data["percentage"])))
    
    return jsonify({
        "success": True,
        "message": f"A/B Testing activado con {traffic_stats['ab_percentage']}% para versión A",
        "ab_enabled": traffic_stats["ab_enabled"],
        "ab_percentage": traffic_stats["ab_percentage"]
    })

@app.route('/api/ab/disable', methods=['POST'])
def disable_ab():
    """Desactivar A/B Testing"""
    global traffic_stats
    traffic_stats["ab_enabled"] = False
    
    return jsonify({
        "success": True,
        "message": "A/B Testing desactivado",
        "ab_enabled": traffic_stats["ab_enabled"]
    })

@app.route('/api/canary/enable', methods=['POST'])
def enable_canary():
    """Activar Canary Deployment"""
    global traffic_stats
    data = request.get_json() or {}
    
    traffic_stats["canary_enabled"] = True
    if "percentage" in data:
        traffic_stats["canary_percentage"] = max(0, min(100, int(data["percentage"])))
    
    return jsonify({
        "success": True,
        "message": f"Canary Deployment activado con {traffic_stats['canary_percentage']}% de tráfico",
        "canary_enabled": traffic_stats["canary_enabled"],
        "canary_percentage": traffic_stats["canary_percentage"]
    })

@app.route('/api/canary/disable', methods=['POST'])
def disable_canary():
    """Desactivar Canary Deployment"""
    global traffic_stats
    traffic_stats["canary_enabled"] = False
    
    return jsonify({
        "success": True,
        "message": "Canary Deployment desactivado",
        "canary_enabled": traffic_stats["canary_enabled"]
    })

@app.route('/api/reset', methods=['POST'])
def reset_stats():
    """Resetear estadísticas"""
    global traffic_stats
    traffic_stats.update({
        "version_a_requests": 0,
        "version_b_requests": 0,
        "weblogic_a_requests": 0,
        "weblogic_b_requests": 0,
        "total_requests": 0,
        "peak_rps": 0
    })
    
    return jsonify({
        "success": True,
        "message": "Estadísticas reseteadas"
    })

@app.route('/api/health')
def health():
    """Health check"""
    return jsonify({
        "status": "healthy",
        "service": "Traffic Dashboard API",
        "timestamp": int(time.time())
    })

@app.route('/dashboard')
def dashboard_redirect():
    """Redirección al dashboard"""
    return dashboard()

# Servir archivos estáticos del dashboard
@app.route('/<path:filename>')
def serve_static(filename):
    """Servir archivos estáticos"""
    try:
        return send_from_directory(DASHBOARD_DIR, filename)
    except FileNotFoundError:
        return jsonify({"error": "File not found"}), 404

if __name__ == '__main__':
    print("🚀 Iniciando Dashboard de Tráfico WebLogic...")
    print("📊 Dashboard disponible en: http://localhost:8084")
    print("📡 API disponible en: http://localhost:8084/api/stats")
    print("🔧 Endpoints: /api/ab/enable, /api/canary/enable, /api/stats")
    print("📈 Simulación de tráfico: ACTIVA")
    app.run(host='0.0.0.0', port=8084, debug=False)
