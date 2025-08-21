#!/usr/bin/env python3
"""
API de administración para HAProxy Deployment Manager
Proporciona endpoints REST para gestionar A/B Testing, Canary Deployment y Feature Flags
"""

from flask import Flask, jsonify, request, render_template_string
from flask_cors import CORS
import requests
import json
import os
import time

app = Flask(__name__)
CORS(app)  # Habilitar CORS para todas las rutas

# Configuración
HAPROXY_STATS_URL = "http://localhost:8404/stats"
HAPROXY_STATS_AUTH = ("admin", "admin123")

@app.route('/api/health')
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": int(time.time()),
        "service": "HAProxy Deployment Manager API"
    })

@app.route('/api/status')
def status():
    """Estado general del sistema"""
    try:
        # Verificar HAProxy Stats
        try:
            haproxy_response = requests.get(HAPROXY_STATS_URL, auth=HAPROXY_STATS_AUTH, timeout=5)
            haproxy_status = "online" if haproxy_response.status_code == 200 else "offline"
        except:
            haproxy_status = "offline"
        
        # Verificar WebLogic A
        try:
            weblogic_a_response = requests.get("http://localhost:7001/console", timeout=5)
            weblogic_a_status = "online" if weblogic_a_response.status_code in [200, 302] else "offline"
        except:
            weblogic_a_status = "offline"
            
        # Verificar WebLogic B
        try:
            weblogic_b_response = requests.get("http://localhost:7002/console", timeout=5)
            weblogic_b_status = "online" if weblogic_b_response.status_code in [200, 302] else "offline"
        except:
            weblogic_b_status = "offline"
        
        return jsonify({
            "timestamp": int(time.time()),
            "services": {
                "haproxy": haproxy_status,
                "weblogic_a": weblogic_a_status,
                "weblogic_b": weblogic_b_status
            },
            "deployment": {
                "ab_testing": {
                    "enabled": False,
                    "version_a_percentage": 50,
                    "version_b_percentage": 50
                },
                "canary": {
                    "enabled": False,
                    "percentage": 0
                }
            }
        })
    except Exception as e:
        return jsonify({
            "error": str(e),
            "timestamp": int(time.time())
        }), 500

@app.route('/api/ab-testing', methods=['GET', 'POST'])
def ab_testing():
    """Configuración de A/B Testing"""
    if request.method == 'GET':
        return jsonify({
            "enabled": False,
            "version_a_percentage": 50,
            "version_b_percentage": 50,
            "description": "A/B Testing configuration"
        })
    
    elif request.method == 'POST':
        data = request.get_json()
        enabled = data.get('enabled', False)
        version_a_percentage = data.get('version_a_percentage', 50)
        version_b_percentage = 100 - version_a_percentage
        
        # Aquí iría la lógica para actualizar HAProxy
        # Por ahora, solo devolvemos la configuración
        
        return jsonify({
            "success": True,
            "enabled": enabled,
            "version_a_percentage": version_a_percentage,
            "version_b_percentage": version_b_percentage,
            "message": f"A/B Testing {'enabled' if enabled else 'disabled'}"
        })

@app.route('/api/canary', methods=['GET', 'POST'])
def canary():
    """Configuración de Canary Deployment"""
    if request.method == 'GET':
        return jsonify({
            "enabled": False,
            "percentage": 0,
            "description": "Canary Deployment configuration"
        })
    
    elif request.method == 'POST':
        data = request.get_json()
        enabled = data.get('enabled', False)
        percentage = data.get('percentage', 0)
        
        # Aquí iría la lógica para actualizar HAProxy
        # Por ahora, solo devolvemos la configuración
        
        return jsonify({
            "success": True,
            "enabled": enabled,
            "percentage": percentage,
            "message": f"Canary Deployment {'enabled' if enabled else 'disabled'} at {percentage}%"
        })

@app.route('/api/backends')
def backends():
    """Información de backends de HAProxy"""
    try:
        # Simular información de backends
        return jsonify([
            {
                "name": "weblogic-a",
                "status": "UP",
                "weight": 50,
                "sessions": 0,
                "health_check": "OK"
            },
            {
                "name": "weblogic-b", 
                "status": "UP",
                "weight": 50,
                "sessions": 0,
                "health_check": "OK"
            }
        ])
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/')
def index():
    """Página principal de la API"""
    html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>HAProxy Deployment Manager API</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
            .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            h1 { color: #333; }
            .endpoint { background: #f8f9fa; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid #007bff; }
            .method { font-weight: bold; color: #007bff; }
            .url { font-family: monospace; background: #e9ecef; padding: 2px 6px; border-radius: 3px; }
            .status { color: green; font-weight: bold; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎛️ HAProxy Deployment Manager API</h1>
            <p>API REST para gestionar A/B Testing, Canary Deployment y Feature Flags</p>
            
            <div class="status">✅ API Funcionando - CORS Habilitado</div>
            
            <h2>📡 Endpoints Disponibles</h2>
            
            <div class="endpoint">
                <span class="method">GET</span> <span class="url">/api/health</span><br>
                Health check del servicio
            </div>
            
            <div class="endpoint">
                <span class="method">GET</span> <span class="url">/api/status</span><br>
                Estado general del sistema
            </div>
            
            <div class="endpoint">
                <span class="method">GET/POST</span> <span class="url">/api/ab-testing</span><br>
                Configuración de A/B Testing
            </div>
            
            <div class="endpoint">
                <span class="method">GET/POST</span> <span class="url">/api/canary</span><br>
                Configuración de Canary Deployment
            </div>
            
            <div class="endpoint">
                <span class="method">GET</span> <span class="url">/api/backends</span><br>
                Información de backends de HAProxy
            </div>
            
            <h2>🔗 Enlaces Útiles</h2>
            <ul>
                <li><a href="http://localhost:8092/index-functional.html" target="_blank">Panel de Administración</a></li>
                <li><a href="http://localhost:8404/stats" target="_blank">HAProxy Stats</a> (admin/admin123)</li>
                <li><a href="http://localhost:8100/" target="_blank">Frontend Principal</a></li>
                <li><a href="http://localhost:7001/console" target="_blank">WebLogic A Console</a></li>
                <li><a href="http://localhost:7002/console" target="_blank">WebLogic B Console</a></li>
            </ul>
            
            <p><strong>Estado:</strong> <span class="status">✅ API Funcionando con CORS</span></p>
        </div>
    </body>
    </html>
    """
    return render_template_string(html)

if __name__ == '__main__':
    print("🚀 Iniciando HAProxy Deployment Manager API...")
    print("📡 API disponible en: http://localhost:8093")
    print("🔧 Endpoints: /api/health, /api/status, /api/ab-testing, /api/canary")
    print("🌐 CORS habilitado para conexiones desde el panel web")
    app.run(host='0.0.0.0', port=8093, debug=False)
