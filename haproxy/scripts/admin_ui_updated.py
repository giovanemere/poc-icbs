#!/usr/bin/env python3
"""
HAProxy Administration UI - Versión actualizada con configuración centralizada
"""

import os
import time
import requests
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from dotenv import load_dotenv

# Cargar variables de entorno desde .env
load_dotenv()

# Configuración desde variables de entorno
API_BASE_URL = os.getenv('HAPROXY_API_URL', 'http://127.0.0.1:8084/api')
HAPROXY_STATS_URL = os.getenv('HAPROXY_STATS_URL', 'http://localhost:8404/stats')
HAPROXY_STATS_USER = os.getenv('HAPROXY_STATS_USER', 'admin')
HAPROXY_STATS_PASSWORD = os.getenv('HAPROXY_STATS_PASSWORD', 'admin123')
WEBLOGIC_A_URL = os.getenv('WEBLOGIC_A_URL', 'http://localhost:7001')
WEBLOGIC_B_URL = os.getenv('WEBLOGIC_B_URL', 'http://localhost:7002')

# Configuración de Flask
app = Flask(__name__, 
            static_folder='/etc/haproxy/static',
            template_folder='/etc/haproxy/templates')
app.secret_key = os.getenv('FLASK_SECRET_KEY', 'haproxy-admin-secret-key')

# Función para evitar caché
@app.context_processor
def utility_processor():
    def now():
        return int(time.time())
    return dict(now=now)

def get_server_status():
    """Obtener estado de los servidores desde HAProxy."""
    try:
        # Obtener configuración actual
        config_response = requests.get(f"{API_BASE_URL}/config", timeout=5)
        config = config_response.json() if config_response.status_code == 200 else {}
        
        # Obtener estadísticas
        try:
            stats_response = requests.get(f"{API_BASE_URL}/stats", timeout=5)
            stats = stats_response.json() if stats_response.status_code == 200 else {}
            print(f"Estadísticas recibidas en admin_ui: {list(stats.keys())}")
        except Exception as e:
            print(f"Error obteniendo estadísticas: {e}")
            stats = {}
        
        # Obtener información de backends
        try:
            backends_response = requests.get(f"{API_BASE_URL}/backends", timeout=5)
            backends = backends_response.json() if backends_response.status_code == 200 else []
        except Exception as e:
            print(f"Error obteniendo backends: {e}")
            backends = []
        
        return {
            'config': config,
            'stats': stats,
            'backends': backends,
            'weblogic_a_url': WEBLOGIC_A_URL,
            'weblogic_b_url': WEBLOGIC_B_URL,
            'haproxy_stats_url': HAPROXY_STATS_URL
        }
    except Exception as e:
        print(f"Error en get_server_status: {e}")
        return {
            'config': {},
            'stats': {},
            'backends': [],
            'weblogic_a_url': WEBLOGIC_A_URL,
            'weblogic_b_url': WEBLOGIC_B_URL,
            'haproxy_stats_url': HAPROXY_STATS_URL
        }

@app.route('/')
def dashboard():
    """Dashboard principal."""
    server_data = get_server_status()
    return render_template('index.html', **server_data)

@app.route('/ab-testing', methods=['GET', 'POST'])
def ab_testing():
    """Configuración de A/B Testing."""
    if request.method == 'POST':
        try:
            weight_a = int(request.form.get('weight_a', 50))
            weight_b = 100 - weight_a
            
            data = {
                'enabled': True,
                'weight_b': weight_b,
                'weight_a': weight_a
            }
            response = requests.post(f"{API_BASE_URL}/config/ab", json=data, timeout=10)
            
            if response.status_code == 200:
                flash('Configuración de A/B Testing actualizada correctamente', 'success')
            else:
                flash('Error al actualizar la configuración de A/B Testing', 'error')
        except Exception as e:
            flash(f'Error: {str(e)}', 'error')
        
        return redirect(url_for('ab_testing'))
    
    # GET request
    try:
        # Obtener configuración actual
        response = requests.get(f"{API_BASE_URL}/config", timeout=5)
        config = response.json() if response.status_code == 200 else {}
        ab_config = config.get('ab_testing', {'enabled': False, 'weight_a': 50})
        
        server_data = get_server_status()
        server_data['ab_config'] = ab_config
        
        return render_template('ab_testing.html', **server_data)
    except Exception as e:
        flash(f'Error al obtener configuración: {str(e)}', 'error')
        return render_template('ab_testing.html', ab_config={'enabled': False, 'weight_a': 50})

@app.route('/canary', methods=['GET', 'POST'])
def canary():
    """Configuración de Canary Deployment."""
    if request.method == 'POST':
        try:
            percentage = int(request.form.get('percentage', 10))
            
            data = {
                'enabled': True,
                'percentage': percentage
            }
            response = requests.post(f"{API_BASE_URL}/config/canary", json=data, timeout=10)
            
            if response.status_code == 200:
                flash('Configuración de Canary Deployment actualizada correctamente', 'success')
            else:
                flash('Error al actualizar la configuración de Canary Deployment', 'error')
        except Exception as e:
            flash(f'Error: {str(e)}', 'error')
        
        return redirect(url_for('canary'))
    
    # GET request
    try:
        # Obtener configuración actual
        response = requests.get(f"{API_BASE_URL}/config", timeout=5)
        config = response.json() if response.status_code == 200 else {}
        canary_config = config.get('canary', {'enabled': False, 'percentage': 10})
        
        server_data = get_server_status()
        server_data['canary_config'] = canary_config
        
        return render_template('canary.html', **server_data)
    except Exception as e:
        flash(f'Error al obtener configuración: {str(e)}', 'error')
        return render_template('canary.html', canary_config={'enabled': False, 'percentage': 10})

@app.route('/server-weight', methods=['GET', 'POST'])
def server_weight():
    """Configuración de pesos de servidores."""
    if request.method == 'POST':
        try:
            backend = request.form.get('backend')
            server = request.form.get('server')
            weight = int(request.form.get('weight', 100))
            
            data = {
                'backend': backend,
                'server': server,
                'weight': weight
            }
            response = requests.post(f"{API_BASE_URL}/server/weight", json=data, timeout=10)
            
            if response.status_code == 200:
                flash('Peso del servidor actualizado correctamente', 'success')
            else:
                flash('Error al actualizar el peso del servidor', 'error')
        except Exception as e:
            flash(f'Error: {str(e)}', 'error')
        
        return redirect(url_for('server_weight'))
    
    # GET request
    try:
        # Obtener información de backends
        backends_response = requests.get(f"{API_BASE_URL}/backends", timeout=5)
        backends = backends_response.json() if backends_response.status_code == 200 else {}
        
        # Obtener información de servidores para cada backend
        backend_servers = {}
        for backend_name in backends:
            servers_response = requests.get(f"{API_BASE_URL}/servers/{backend_name}", timeout=5)
            if servers_response.status_code == 200:
                backend_servers[backend_name] = servers_response.json()
        
        server_data = get_server_status()
        server_data['backend_servers'] = backend_servers
        
        return render_template('server_weight.html', **server_data)
    except Exception as e:
        flash(f'Error al obtener información de servidores: {str(e)}', 'error')
        return render_template('server_weight.html', backend_servers={})

@app.route('/url-status')
def url_status():
    """Estado de URLs."""
    server_data = get_server_status()
    return render_template('url_status.html', **server_data)

@app.route('/api/status')
def api_status():
    """Endpoint para verificar el estado de la API."""
    try:
        response = requests.get(f"{API_BASE_URL}/config", timeout=5)
        if response.status_code == 200:
            return jsonify({'status': 'ok', 'message': 'API conectada correctamente'})
        else:
            return jsonify({'status': 'error', 'message': 'API no responde correctamente'}), 500
    except Exception as e:
        return jsonify({'status': 'error', 'message': f'Error de conexión: {str(e)}'}), 500

def check_api_availability():
    """Verificar si la API está disponible."""
    try:
        response = requests.get(f"{API_BASE_URL}/status", timeout=5)
        if response.status_code == 200:
            return jsonify({'status': 'ok', 'message': 'API conectada correctamente'})
        else:
            return jsonify({'status': 'error', 'message': 'API no disponible'}), 500
    except Exception as e:
        return jsonify({'status': 'error', 'message': f'Error: {str(e)}'}), 500

@app.route('/api/server-weights')
def get_server_weights():
    """Obtener pesos actuales de los servidores."""
    try:
        # Hacer una solicitud a la API de HAProxy para obtener los servidores
        response = requests.get(f"{API_BASE_URL}/server/weights", timeout=5)
        
        if response.status_code == 200:
            return jsonify(response.json())
        else:
            return jsonify({'error': 'No se pudieron obtener los pesos de los servidores'}), 500
    except Exception as e:
        return jsonify({'error': f'Error de conexión: {str(e)}'}), 500

@app.route('/api/update-server-weight', methods=['POST'])
def update_server_weight():
    """Actualizar peso de un servidor."""
    try:
        data = request.get_json()
        
        if not data or 'backend' not in data or 'server' not in data or 'weight' not in data:
            return jsonify({'error': 'Datos incompletos'}), 400
        
        # Enviar la solicitud a la API de HAProxy
        response = requests.post(f"{API_BASE_URL}/server/weight", json=data, timeout=10)
        
        if response.status_code == 200:
            return jsonify({'success': True, 'message': 'Peso actualizado correctamente'})
        else:
            return jsonify({'error': 'Error al actualizar el peso del servidor'}), 500
    except Exception as e:
        return jsonify({'error': f'Error: {str(e)}'}), 500

if __name__ == '__main__':
    print(f"🚀 Iniciando HAProxy Admin UI...")
    print(f"📡 API Base URL: {API_BASE_URL}")
    print(f"📊 HAProxy Stats URL: {HAPROXY_STATS_URL}")
    print(f"🔗 WebLogic A URL: {WEBLOGIC_A_URL}")
    print(f"🔗 WebLogic B URL: {WEBLOGIC_B_URL}")
    
    app.run(host='0.0.0.0', port=int(os.getenv('HAPROXY_UI_PORT', 8082)), debug=True)
