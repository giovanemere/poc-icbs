#!/usr/bin/env python3
"""
Panel de administración web para gestionar estrategias de despliegue en HAProxy.
Este script proporciona una interfaz web para configurar Testing A/B y Canary Deployment.
"""

import os
import json
import time
import requests
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify

app = Flask(__name__, 
            static_folder='/etc/haproxy/static',
            template_folder='/etc/haproxy/templates')
app.secret_key = 'haproxy-admin-secret-key'

# Configuración de la API de administración
API_BASE_URL = 'http://localhost:8081/api'

# Función para evitar caché
@app.context_processor
def utility_processor():
    def now():
        return int(time.time())
    return dict(now=now)

@app.route('/')
def index():
    """Página principal del panel de administración."""
    try:
        # Obtener configuración actual
        config_response = requests.get(f"{API_BASE_URL}/config")
        config = config_response.json() if config_response.status_code == 200 else {}
        
        # Obtener estadísticas
        try:
            stats_response = requests.get(f"{API_BASE_URL}/stats")
            stats = stats_response.json() if stats_response.status_code == 200 else {}
            print(f"Estadísticas recibidas en admin_ui: {list(stats.keys())}")
        except Exception as e:
            print(f"Error al obtener estadísticas: {str(e)}")
            stats = {}
        
        # Obtener información de backends
        try:
            backends_response = requests.get(f"{API_BASE_URL}/backends")
            backends = backends_response.json() if backends_response.status_code == 200 else []
        except Exception as e:
            print(f"Error al obtener backends: {str(e)}")
            backends = []
        
        return render_template('index.html', 
                              config=config, 
                              stats=stats, 
                              backends=backends)
    except Exception as e:
        return render_template('error.html', error=str(e))

@app.route('/ab-testing', methods=['GET', 'POST'])
def ab_testing():
    """Gestionar configuración de A/B Testing."""
    if request.method == 'POST':
        try:
            enabled = request.form.get('enabled') == 'on'
            weight_a = int(request.form.get('weight_a', 50))
            
            # Validar datos
            if weight_a < 0 or weight_a > 100:
                flash('El peso debe estar entre 0 y 100', 'error')
                return redirect(url_for('ab_testing'))
            
            # Enviar configuración a la API
            data = {
                'enabled': enabled,
                'weight_a': weight_a
            }
            response = requests.post(f"{API_BASE_URL}/config/ab", json=data)
            
            if response.status_code == 200:
                flash('Configuración de A/B Testing actualizada correctamente', 'success')
            else:
                flash(f'Error al actualizar la configuración: {response.text}', 'error')
                
            return redirect(url_for('index'))
        except Exception as e:
            flash(f'Error: {str(e)}', 'error')
            return redirect(url_for('ab_testing'))
    else:
        try:
            # Obtener configuración actual
            response = requests.get(f"{API_BASE_URL}/config")
            config = response.json() if response.status_code == 200 else {}
            ab_config = config.get('ab_testing', {'enabled': False, 'weight_a': 50})
            
            return render_template('ab_testing.html', config=ab_config)
        except Exception as e:
            return render_template('error.html', error=str(e))

@app.route('/canary', methods=['GET', 'POST'])
def canary():
    """Gestionar configuración de Canary Deployment."""
    if request.method == 'POST':
        try:
            enabled = request.form.get('enabled') == 'on'
            percentage = int(request.form.get('percentage', 10))
            
            # Validar datos
            if percentage < 0 or percentage > 100:
                flash('El porcentaje debe estar entre 0 y 100', 'error')
                return redirect(url_for('canary'))
            
            # Enviar configuración a la API
            data = {
                'enabled': enabled,
                'percentage': percentage
            }
            response = requests.post(f"{API_BASE_URL}/config/canary", json=data)
            
            if response.status_code == 200:
                flash('Configuración de Canary Deployment actualizada correctamente', 'success')
            else:
                flash(f'Error al actualizar la configuración: {response.text}', 'error')
                
            return redirect(url_for('index'))
        except Exception as e:
            flash(f'Error: {str(e)}', 'error')
            return redirect(url_for('canary'))
    else:
        try:
            # Obtener configuración actual
            response = requests.get(f"{API_BASE_URL}/config")
            config = response.json() if response.status_code == 200 else {}
            canary_config = config.get('canary', {'enabled': False, 'percentage': 10})
            
            return render_template('canary.html', config=canary_config)
        except Exception as e:
            return render_template('error.html', error=str(e))

@app.route('/server-weight', methods=['GET', 'POST'])
def server_weight():
    """Gestionar pesos de servidores."""
    if request.method == 'POST':
        try:
            backend = request.form.get('backend')
            server = request.form.get('server')
            weight = int(request.form.get('weight', 100))
            
            # Validar datos
            if weight < 0 or weight > 256:
                flash('El peso debe estar entre 0 y 256', 'error')
                return redirect(url_for('server_weight'))
            
            # Enviar configuración a la API
            data = {
                'backend': backend,
                'server': server,
                'weight': weight
            }
            response = requests.post(f"{API_BASE_URL}/server/weight", json=data)
            
            if response.status_code == 200:
                flash('Peso del servidor actualizado correctamente', 'success')
            else:
                flash(f'Error al actualizar el peso: {response.text}', 'error')
                
            return redirect(url_for('index'))
        except Exception as e:
            flash(f'Error: {str(e)}', 'error')
            return redirect(url_for('server_weight'))
    else:
        try:
            # Obtener información de backends
            backends_response = requests.get(f"{API_BASE_URL}/backends")
            backends = backends_response.json() if backends_response.status_code == 200 else {}
            
            # Preparar datos para el formulario
            backend_servers = {}
            for backend_name in backends:
                servers_response = requests.get(f"{API_BASE_URL}/servers/{backend_name}")
                if servers_response.status_code == 200:
                    backend_servers[backend_name] = servers_response.json()
            
            return render_template('server_weight.html', backends=backends, backend_servers=backend_servers)
        except Exception as e:
            return render_template('error.html', error=str(e))

@app.route('/url-status')
def url_status():
    """Mostrar el estado de las URLs."""
    try:
        return render_template('url_status.html')
    except Exception as e:
        return render_template('error.html', error=str(e))

@app.route('/api/status')
def api_status():
    """Endpoint para verificar el estado de la API."""
    try:
        response = requests.get(f"{API_BASE_URL}/config")
        if response.status_code == 200:
            return jsonify({'status': 'ok', 'message': 'API conectada correctamente'})
        else:
            return jsonify({'status': 'error', 'message': f'Error al conectar con la API: {response.status_code}'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': f'Error al conectar con la API: {str(e)}'})

if __name__ == '__main__':
    # Iniciar la aplicación
    app.run(host='0.0.0.0', port=8082, debug=True)

@app.route('/api/check-api')
def check_api():
    """Verificar si la API está disponible."""
    try:
        response = requests.get(f"{API_BASE_URL}/status")
        if response.status_code == 200:
            return jsonify({'status': 'ok', 'message': 'API conectada correctamente'})
        else:
            return jsonify({'status': 'error', 'message': f'Error al conectar con la API: {response.status_code}'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': f'Error al conectar con la API: {str(e)}'})

@app.route('/server-weights')
def server_weights():
    """Página para configurar los pesos de los servidores."""
    return render_template('server_weights.html')

@app.route('/api/servers')
def get_servers():
    """Obtener la lista de servidores con pesos ajustables."""
    try:
        # Hacer una solicitud a la API de HAProxy para obtener los servidores
        response = requests.get(f"{API_BASE_URL}/server/weights")
        
        if response.status_code == 200:
            return jsonify(response.json())
        else:
            # Si falla, usar datos de prueba para desarrollo
            test_data = [
                {
                    "name": "weblogic-a",
                    "backend": "weblogic-a",
                    "weight": 100,
                    "description": "WebLogic Server A"
                },
                {
                    "name": "weblogic-b",
                    "backend": "weblogic-b",
                    "weight": 100,
                    "description": "WebLogic Server B"
                }
            ]
            return jsonify(test_data)
    except Exception as e:
        print(f"Error al obtener la lista de servidores: {str(e)}")
        # Usar datos de prueba para desarrollo
        test_data = [
            {
                "name": "weblogic-a",
                "backend": "weblogic-a",
                "weight": 100,
                "description": "WebLogic Server A"
            },
            {
                "name": "weblogic-b",
                "backend": "weblogic-b",
                "weight": 100,
                "description": "WebLogic Server B"
            }
        ]
        return jsonify(test_data)

@app.route('/api/servers/weight', methods=['POST'])
def update_server_weight():
    """Actualizar el peso de un servidor."""
    try:
        data = request.json
        
        # Validar datos
        if 'server' not in data or 'backend' not in data or 'weight' not in data:
            return jsonify({'status': 'error', 'message': 'Faltan parámetros requeridos'}), 400
        
        # Enviar la solicitud a la API de HAProxy
        response = requests.post(f"{API_BASE_URL}/server/weight", json=data)
        
        if response.status_code == 200:
            return jsonify({'status': 'success', 'message': 'Peso actualizado correctamente'})
        else:
            return jsonify({'status': 'error', 'message': 'Error al actualizar el peso del servidor'}), 500
    except Exception as e:
        print(f"Error al actualizar el peso del servidor: {str(e)}")
        return jsonify({'status': 'error', 'message': f'Error al actualizar el peso del servidor: {str(e)}'}), 500
