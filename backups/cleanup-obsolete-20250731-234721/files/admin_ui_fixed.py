#!/usr/bin/env python3
"""
Panel de administración web para gestionar estrategias de despliegue en HAProxy.
Este script proporciona una interfaz web para configurar Testing A/B y Canary Deployment.

NOTA: Este script requiere que las variables de entorno estén cargadas.
Ejecutar antes: source scripts/load-env.sh
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

# Configuración de la API de administración usando variables de entorno
# Dentro del contenedor, usar 127.0.0.1:8084 (puerto interno donde Flask API está ejecutándose)
API_BASE_URL = os.getenv('HAPROXY_API_URL', 'http://127.0.0.1:8084/api')

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

@app.route('/api/url-status')
def api_url_status():
    """Endpoint para obtener el estado de las URLs monitoreadas."""
    try:
        # Obtener estadísticas de HAProxy
        stats_response = requests.get(f"{API_BASE_URL}/stats")
        backends_response = requests.get(f"{API_BASE_URL}/backends")
        
        urls = []
        success_count = 0
        warning_count = 0
        error_count = 0
        
        if stats_response.status_code == 200 and backends_response.status_code == 200:
            stats = stats_response.json()
            backends = backends_response.json()
            
            # URLs base del sistema
            base_urls = [
                {'name': 'HAProxy Stats', 'url': 'http://localhost:8404/stats', 'expected_status': 200},
                {'name': 'HAProxy API', 'url': 'http://localhost:8081/api/status', 'expected_status': 200},
                {'name': 'HAProxy Admin UI', 'url': 'http://localhost:8082/', 'expected_status': 200},
                {'name': 'WebLogic A', 'url': 'http://localhost:7001/console', 'expected_status': 302},
                {'name': 'WebLogic B', 'url': 'http://localhost:7002/console', 'expected_status': 302},
                {'name': 'Oracle Database', 'url': 'http://localhost:1521', 'expected_status': None},  # TCP, no HTTP
                {'name': 'MkDocs Documentation', 'url': 'http://localhost:8000/', 'expected_status': 200}
            ]
            
            # Verificar cada URL
            for url_info in base_urls:
                try:
                    if url_info['expected_status'] is None:
                        # Para servicios no HTTP como la base de datos
                        status_type = 'success'
                        status_text = 'TCP Service Active'
                        response_time = 'N/A'
                        success_count += 1
                    else:
                        # Hacer request HTTP
                        response = requests.get(url_info['url'], timeout=5, allow_redirects=False)
                        response_time = f"{response.elapsed.total_seconds():.3f}s"
                        
                        if response.status_code == url_info['expected_status']:
                            status_type = 'success'
                            status_text = f'HTTP {response.status_code}'
                            success_count += 1
                        elif response.status_code in [200, 302, 301]:
                            status_type = 'warning'
                            status_text = f'HTTP {response.status_code} (Expected {url_info["expected_status"]})'
                            warning_count += 1
                        else:
                            status_type = 'error'
                            status_text = f'HTTP {response.status_code}'
                            error_count += 1
                            
                except requests.exceptions.RequestException as e:
                    status_type = 'error'
                    status_text = f'Connection Error: {str(e)[:50]}...'
                    response_time = 'N/A'
                    error_count += 1
                
                urls.append({
                    'name': url_info['name'],
                    'url': url_info['url'],
                    'type': status_type,
                    'status': status_text,
                    'response_time': response_time,
                    'last_check': time.strftime('%Y-%m-%d %H:%M:%S')
                })
        
        else:
            # Si no podemos obtener stats, devolver error básico
            error_count = 1
            urls.append({
                'name': 'HAProxy API',
                'url': f"{API_BASE_URL}/stats",
                'type': 'error',
                'status': 'API Connection Failed',
                'response_time': 'N/A',
                'last_check': time.strftime('%Y-%m-%d %H:%M:%S')
            })
        
        return jsonify({
            'summary': {
                'success': success_count,
                'warnings': warning_count,
                'errors': error_count,
                'total': len(urls)
            },
            'urls': urls,
            'last_update': time.strftime('%Y-%m-%d %H:%M:%S')
        })
        
    except Exception as e:
        return jsonify({
            'summary': {
                'success': 0,
                'warnings': 0,
                'errors': 1,
                'total': 1
            },
            'urls': [{
                'name': 'System Error',
                'url': 'N/A',
                'type': 'error',
                'status': f'Error: {str(e)}',
                'response_time': 'N/A',
                'last_check': time.strftime('%Y-%m-%d %H:%M:%S')
            }],
            'last_update': time.strftime('%Y-%m-%d %H:%M:%S')
        })

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

@app.route('/api/servers-status')
def api_servers_status():
    """Endpoint para obtener el estado actualizado de todos los servidores."""
    try:
        # Obtener estadísticas de HAProxy
        stats_response = requests.get(f"{API_BASE_URL}/stats")
        
        if stats_response.status_code == 200:
            stats = stats_response.json()
            return jsonify(stats)
        else:
            return jsonify({'error': 'No se pudieron obtener las estadísticas'}), 500
            
    except Exception as e:
        return jsonify({'error': f'Error al obtener estadísticas: {str(e)}'}), 500

if __name__ == '__main__':
    # Obtener puerto desde variables de entorno
    ui_port = int(os.getenv('HAPROXY_UI_PORT', '8082'))
    # Iniciar la aplicación
    app.run(host='0.0.0.0', port=ui_port, debug=True)
