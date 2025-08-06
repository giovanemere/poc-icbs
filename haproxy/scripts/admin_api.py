#!/usr/bin/env python3
"""
API de administración para HAProxy.
Este script proporciona una API REST para configurar HAProxy dinámicamente.

NOTA: Este script requiere que las variables de entorno estén cargadas.
Ejecutar antes: source scripts/load-env.sh
"""

import os
import json
import socket
import time
import threading
import subprocess
from flask import Flask, request, jsonify

# Importar el módulo de verificación de URLs
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Crear la aplicación Flask
app = Flask(__name__)

# Función para ejecutar check-urls.sh y procesar su salida
def run_check_urls():
    """Ejecutar el script check-urls.sh y procesar su salida."""
    try:
        # Determinar la ruta al script check-urls.sh de forma dinámica
        current_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(os.path.dirname(current_dir))
        script_path = os.path.join(project_root, "scripts", "check-urls.sh")
        
        # Si el script no existe en la ruta calculada, usar rutas alternativas
        if not os.path.exists(script_path):
            # Intentar ruta del contenedor
            script_path = "/scripts/check-urls.sh"
            
        if not os.path.exists(script_path):
            # Intentar ruta relativa
            script_path = "../scripts/check-urls.sh"
        
        # Ejecutar el script
        result = subprocess.run([script_path], 
                               stdout=subprocess.PIPE, 
                               stderr=subprocess.PIPE, 
                               text=True, 
                               env={"NO_COLOR": "1"})
        
        # Procesar la salida
        output = result.stdout
        
        # Extraer información de las URLs
        urls_status = parse_check_urls_output(output)
        
        # Extraer resumen
        summary = parse_summary(output)
        
        return {
            'urls': urls_status,
            'summary': summary,
            'raw_output': output
        }
    except Exception as e:
        return {
            'error': str(e),
            'urls': [],
            'summary': {
                'success': 0,
                'warnings': 0,
                'errors': 0
            },
            'raw_output': f"Error al ejecutar check-urls.sh: {str(e)}"
        }

def parse_check_urls_output(output):
    """Parsear la salida del script check-urls.sh para extraer el estado de las URLs."""
    import re
    urls_status = []
    
    # Patrones para extraer información
    # Modificado para manejar los emojis y colores ANSI
    url_pattern = r"http://[^\s]+"
    status_pattern = r"(OK|ERROR|ADVERTENCIA)"
    code_pattern = r"\(([^)]*)\)"
    
    # Buscar todas las líneas que contienen URLs
    lines = output.split('\n')
    for line in lines:
        if "http://" in line:
            # Extraer URL
            url_match = re.search(url_pattern, line)
            if url_match:
                url = url_match.group(0)
                
                # Extraer estado
                status_match = re.search(status_pattern, line)
                status = status_match.group(1) if status_match else "DESCONOCIDO"
                
                # Extraer código
                code_match = re.search(code_pattern, line)
                code = code_match.group(1) if code_match else "N/A"
                
                # Determinar el tipo de estado
                if status == "OK":
                    status_type = "success"
                elif status == "ERROR":
                    status_type = "error"
                else:
                    status_type = "warning"
                
                urls_status.append({
                    'url': url,
                    'status': status,
                    'code': code,
                    'type': status_type
                })
    
    return urls_status
    
    return urls_status

def parse_summary(output):
    """Extraer el resumen de la verificación."""
    import re
    summary = {
        'success': 0,
        'warnings': 0,
        'errors': 0
    }
    
    # Patrones para extraer información del resumen
    success_pattern = r"URLs exitosas: (\d+)"
    warnings_pattern = r"URLs con advertencias: (\d+)"
    errors_pattern = r"URLs con errores: (\d+)"
    
    # Buscar coincidencias
    success_match = re.search(success_pattern, output)
    warnings_match = re.search(warnings_pattern, output)
    errors_match = re.search(errors_pattern, output)
    
    if success_match:
        summary['success'] = int(success_match.group(1))
    
    if warnings_match:
        summary['warnings'] = int(warnings_match.group(1))
    
    if errors_match:
        summary['errors'] = int(errors_match.group(1))
    
    return summary

# Función para obtener el estado de las URLs
def get_url_status():
    """Obtener el estado de las URLs."""
    return run_check_urls()

# Rutas de la API

@app.route('/api/config', methods=['GET'])
def get_config():
    """Obtener la configuración actual de HAProxy."""
    try:
        # Leer el archivo de configuración
        config_file = '/etc/haproxy/config.json'
        if not os.path.exists(config_file):
            # Si no existe, crear uno con valores predeterminados
            config = {
                'ab_testing': {
                    'enabled': False,
                    'weight_a': 50
                },
                'canary': {
                    'enabled': False,
                    'percentage': 10
                }
            }
            with open(config_file, 'w') as f:
                json.dump(config, f)
        else:
            # Leer la configuración existente
            with open(config_file, 'r') as f:
                config = json.load(f)
        
        return jsonify(config)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/config/ab', methods=['POST'])
def update_ab_config():
    """Actualizar la configuración de A/B Testing."""
    try:
        data = request.json
        
        # Validar datos
        if 'enabled' not in data or 'weight_a' not in data:
            return jsonify({'error': 'Faltan parámetros requeridos'}), 400
        
        if not isinstance(data['enabled'], bool):
            return jsonify({'error': 'El parámetro enabled debe ser un booleano'}), 400
        
        if not isinstance(data['weight_a'], int) or data['weight_a'] < 0 or data['weight_a'] > 100:
            return jsonify({'error': 'El parámetro weight_a debe ser un entero entre 0 y 100'}), 400
        
        # Leer la configuración actual
        config_file = '/etc/haproxy/config.json'
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                config = json.load(f)
        else:
            config = {}
        
        # Actualizar la configuración
        if 'ab_testing' not in config:
            config['ab_testing'] = {}
        
        config['ab_testing']['enabled'] = data['enabled']
        config['ab_testing']['weight_a'] = data['weight_a']
        
        # Guardar la configuración
        with open(config_file, 'w') as f:
            json.dump(config, f)
        
        # Aplicar la configuración a HAProxy
        apply_ab_config(data['enabled'], data['weight_a'])
        
        return jsonify({'success': True, 'message': 'Configuración actualizada correctamente'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/config/canary', methods=['POST'])
def update_canary_config():
    """Actualizar la configuración de Canary Deployment."""
    try:
        data = request.json
        
        # Validar datos
        if 'enabled' not in data or 'percentage' not in data:
            return jsonify({'error': 'Faltan parámetros requeridos'}), 400
        
        if not isinstance(data['enabled'], bool):
            return jsonify({'error': 'El parámetro enabled debe ser un booleano'}), 400
        
        if not isinstance(data['percentage'], int) or data['percentage'] < 0 or data['percentage'] > 100:
            return jsonify({'error': 'El parámetro percentage debe ser un entero entre 0 y 100'}), 400
        
        # Leer la configuración actual
        config_file = '/etc/haproxy/config.json'
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                config = json.load(f)
        else:
            config = {}
        
        # Actualizar la configuración
        if 'canary' not in config:
            config['canary'] = {}
        
        config['canary']['enabled'] = data['enabled']
        config['canary']['percentage'] = data['percentage']
        
        # Guardar la configuración
        with open(config_file, 'w') as f:
            json.dump(config, f)
        
        # Aplicar la configuración a HAProxy
        apply_canary_config(data['enabled'], data['percentage'])
        
        return jsonify({'success': True, 'message': 'Configuración actualizada correctamente'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/server/weight', methods=['POST'])
def update_server_weight():
    """Actualizar el peso de un servidor."""
    try:
        data = request.json
        
        # Validar datos
        if 'backend' not in data or 'server' not in data or 'weight' not in data:
            return jsonify({'error': 'Faltan parámetros requeridos'}), 400
        
        if not isinstance(data['weight'], int) or data['weight'] < 0 or data['weight'] > 256:
            return jsonify({'error': 'El parámetro weight debe ser un entero entre 0 y 256'}), 400
        
        # Aplicar el peso al servidor
        apply_server_weight(data['backend'], data['server'], data['weight'])
        
        return jsonify({'success': True, 'message': 'Peso actualizado correctamente'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/backends', methods=['GET'])
def get_backends():
    """Obtener la lista de backends."""
    try:
        # Obtener la lista de backends desde HAProxy
        backends = get_haproxy_backends()
        
        return jsonify(backends)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/servers/<backend>', methods=['GET'])
def get_servers(backend):
    """Obtener la lista de servidores de un backend."""
    try:
        # Obtener la lista de servidores desde HAProxy
        servers = get_haproxy_servers(backend)
        
        return jsonify(servers)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Obtener estadísticas de HAProxy."""
    try:
        # Obtener estadísticas desde HAProxy
        stats = get_haproxy_stats()
        
        # Imprimir los backends que se han procesado
        print(f"Backends disponibles en /api/stats: {list(stats.keys())}")
        
        return jsonify(stats)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/status', methods=['GET'])
def get_status():
    """Obtener el estado de la API."""
    return jsonify({'status': 'ok', 'message': 'API funcionando correctamente'})

@app.route('/api/url-status', methods=['GET'])
def api_url_status():
    """Endpoint para obtener el estado de las URLs usando el nuevo sistema de monitoreo."""
    try:
        import requests
        
        # Intentar usar el nuevo sistema de monitoreo primero
        try:
            integration_port = os.getenv('HAPROXY_INTEGRATION_PORT', '8085')
            integration_url = f"http://localhost:{integration_port}/api/url-status"
            
            response = requests.get(integration_url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                # Agregar información de que está usando el nuevo sistema
                data['monitoring_system'] = 'new_integrated_system'
                data['monitoring_active'] = True
                return jsonify(data)
            else:
                raise Exception(f"Error del servicio de monitoreo: {response.status_code}")
                
        except requests.exceptions.ConnectionError:
            # Si el nuevo sistema no está disponible, usar fallback al sistema anterior
            print("⚠️  Nuevo sistema de monitoreo no disponible, usando fallback...")
            fallback_data = get_url_status()
            fallback_data['monitoring_system'] = 'fallback_legacy_system'
            fallback_data['monitoring_active'] = False
            fallback_data['warning'] = 'Usando sistema anterior - Ejecutar: ./scripts/monitoring/setup-complete-monitoring.sh'
            return jsonify(fallback_data)
            
        except Exception as e:
            print(f"Error en nuevo sistema de monitoreo: {e}")
            # Fallback al sistema anterior
            fallback_data = get_url_status()
            fallback_data['monitoring_system'] = 'fallback_legacy_system'
            fallback_data['monitoring_active'] = False
            fallback_data['error'] = str(e)
            return jsonify(fallback_data)
            
    except Exception as e:
        return jsonify({
            'error': str(e), 
            'urls': [], 
            'summary': {'success': 0, 'warnings': 0, 'errors': 0},
            'monitoring_system': 'error',
            'monitoring_active': False
        })

@app.route('/ab-testing-status', methods=['GET'])
def ab_testing_status():
    """Endpoint para verificar si A/B testing está habilitado."""
    try:
        # Leer la configuración actual
        config_file = '/etc/haproxy/config.json'
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                config = json.load(f)
        else:
            config = {}
        
        # Verificar si A/B testing está habilitado
        ab_enabled = config.get('ab_testing', {}).get('enabled', False)
        
        if ab_enabled:
            return "1", 200
        else:
            return "0", 200
    except Exception as e:
        print(f"Error al verificar el estado de A/B testing: {str(e)}")
        return "0", 500

@app.route('/canary-status', methods=['GET'])
def canary_status():
    """Endpoint para verificar si Canary deployment está habilitado."""
    try:
        # Leer la configuración actual
        config_file = '/etc/haproxy/config.json'
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                config = json.load(f)
        else:
            config = {}
        
        # Verificar si Canary deployment está habilitado
        canary_enabled = config.get('canary', {}).get('enabled', False)
        
        if canary_enabled:
            return "1", 200
        else:
            return "0", 200
    except Exception as e:
        print(f"Error al verificar el estado de Canary deployment: {str(e)}")
        return "0", 500

# Funciones auxiliares

def apply_ab_config(enabled, weight_a):
    """Aplicar la configuración de A/B Testing a HAProxy."""
    try:
        # Calcular los pesos para los servidores
        weight_b = 100 - weight_a
        
        if enabled:
            # Configurar los pesos de los servidores
            apply_server_weight('version-a-backend', 'weblogic-a-version', weight_a)
            apply_server_weight('version-b-backend', 'weblogic-b-version', weight_b)
            
            # Asegurarse de que el backend version-b esté activo
            apply_server_weight('version-b-backend', 'weblogic-b-version', 100)
        else:
            # Restaurar los pesos predeterminados
            apply_server_weight('version-a-backend', 'weblogic-a-version', 100)
            
            # Desactivar completamente el tráfico a version-b-backend
            apply_server_weight('version-b-backend', 'weblogic-b-version', 0)
            
            # Desactivar el servidor B en version-a-backend si existe
            try:
                apply_server_weight('version-a-backend', 'weblogic-b-version', 0)
            except:
                pass  # Ignorar si el servidor no existe en este backend
    except Exception as e:
        print(f"Error al aplicar la configuración de A/B Testing: {str(e)}")
        raise

def apply_canary_config(enabled, percentage):
    """Aplicar la configuración de Canary Deployment a HAProxy."""
    try:
        # Calcular los pesos para los servidores
        weight_a = 100 - percentage
        weight_b = percentage
        
        if enabled:
            # Configurar los pesos de los servidores
            apply_server_weight('weblogic-features-a', 'weblogic-a-features', weight_a)
            apply_server_weight('weblogic-features-b', 'weblogic-b-features', weight_b)
            
            # Asegurarse de que el backend weblogic-features-b esté activo
            if weight_b > 0:
                # Activar el backend weblogic-features-b
                command = f"echo 'enable server weblogic-features-b/weblogic-b-features' | socat stdio /var/run/haproxy.sock"
                subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        else:
            # Restaurar los pesos predeterminados
            apply_server_weight('weblogic-features-a', 'weblogic-a-features', 100)
            apply_server_weight('weblogic-features-b', 'weblogic-b-features', 0)
            
            # Desactivar completamente el backend weblogic-features-b
            command = f"echo 'disable server weblogic-features-b/weblogic-b-features' | socat stdio /var/run/haproxy.sock"
            subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    except Exception as e:
        print(f"Error al aplicar la configuración de Canary Deployment: {str(e)}")
        raise

def apply_server_weight(backend, server, weight):
    """Aplicar el peso a un servidor en HAProxy."""
    try:
        # Comando para cambiar el peso del servidor
        command = f"echo 'set server {backend}/{server} weight {weight}' | socat stdio /var/run/haproxy.sock"
        
        # Ejecutar el comando
        result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        if result.returncode != 0:
            raise Exception(f"Error al cambiar el peso del servidor: {result.stderr}")
    except Exception as e:
        print(f"Error al aplicar el peso al servidor: {str(e)}")
        raise

def get_haproxy_backends():
    """Obtener la lista de backends desde HAProxy."""
    try:
        # Comando para obtener la lista de backends
        command = "echo 'show backend' | socat stdio /var/run/haproxy.sock"
        
        # Ejecutar el comando
        result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        if result.returncode != 0:
            raise Exception(f"Error al obtener la lista de backends: {result.stderr}")
        
        # Procesar la salida
        backends = result.stdout.strip().split('\n')
        
        # Filtrar el encabezado "# name" y cualquier línea vacía
        backends = [backend for backend in backends if backend and backend != "# name"]
        
        return backends
    except Exception as e:
        print(f"Error al obtener la lista de backends: {str(e)}")
        raise

def get_haproxy_servers(backend):
    """Obtener la lista de servidores de un backend desde HAProxy."""
    try:
        # Comando para obtener la lista de servidores
        command = f"echo 'show servers state {backend}' | socat stdio /var/run/haproxy.sock"
        
        # Ejecutar el comando
        result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        if result.returncode != 0:
            raise Exception(f"Error al obtener la lista de servidores: {result.stderr}")
        
        # Procesar la salida
        lines = result.stdout.strip().split('\n')
        servers = []
        
        for line in lines:
            if line.startswith('#'):
                continue
            
            parts = line.split(' ')
            if len(parts) >= 2:
                servers.append({
                    'name': parts[1],
                    'backend': backend
                })
        
        return servers
    except Exception as e:
        print(f"Error al obtener la lista de servidores: {str(e)}")
        raise

def get_haproxy_stats():
    """Obtener estadísticas desde HAProxy."""
    try:
        # Comando para obtener estadísticas
        command = "echo 'show stat' | socat stdio /var/run/haproxy.sock"
        
        # Ejecutar el comando
        result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        if result.returncode != 0:
            raise Exception(f"Error al obtener estadísticas: {result.stderr}")
        
        # Procesar la salida
        lines = result.stdout.strip().split('\n')
        stats = {}
        
        for line in lines:
            if line.startswith('#'):
                continue
            
            parts = line.split(',')
            if len(parts) >= 2:
                backend = parts[0]
                server = parts[1]
                
                # Imprimir los backends que se están procesando
                print(f"Procesando backend: {backend}, servidor: {server}")
                
                if backend not in stats:
                    stats[backend] = {}
                
                stats[backend][server] = {
                    'status': parts[17] if len(parts) > 17 else 'unknown',
                    'weight': parts[18] if len(parts) > 18 else 'unknown',
                    'active': parts[19] if len(parts) > 19 else 'unknown',
                    'backup': parts[20] if len(parts) > 20 else 'unknown'
                }
        
        # Imprimir los backends que se han procesado
        print(f"Backends procesados: {list(stats.keys())}")
        
        return stats
    except Exception as e:
        print(f"Error al obtener estadísticas: {str(e)}")
        raise

if __name__ == '__main__':
    # Obtener puerto desde variables de entorno (usar puerto interno dentro del contenedor)
    api_port = int(os.getenv('HAPROXY_API_INTERNAL_PORT', '8084'))
    # Iniciar la aplicación
    app.run(host='0.0.0.0', port=api_port, debug=True)
@app.route('/api/server/weights', methods=['GET'])
def get_server_weights():
    """Obtener la lista de servidores con pesos ajustables."""
    try:
        # Obtener la lista de backends
        backends = get_haproxy_backends()
        
        # Lista para almacenar los servidores con pesos ajustables
        adjustable_servers = []
        
        # Servidores específicos que queremos mostrar
        target_servers = {
            "weblogic-a": {
                "backend": "weblogic-a",
                "description": "WebLogic Server A"
            },
            "weblogic-b": {
                "backend": "weblogic-b",
                "description": "WebLogic Server B"
            }
        }
        
        # Para cada backend, obtener sus servidores
        for backend in backends:
            servers = get_haproxy_servers(backend)
            
            for server in servers:
                server_name = server.get('name')
                
                # Si el servidor está en nuestra lista de objetivos
                if server_name in target_servers:
                    # Obtener el peso actual del servidor
                    weight = get_server_weight(backend, server_name)
                    
                    # Añadir el servidor a la lista
                    adjustable_servers.append({
                        "name": server_name,
                        "backend": backend,
                        "weight": weight,
                        "description": target_servers[server_name]["description"]
                    })
        
        return jsonify(adjustable_servers)
    except Exception as e:
        print(f"Error al obtener la lista de servidores con pesos ajustables: {str(e)}")
        return jsonify([]), 500

def get_server_weight(backend, server_name):
    """Obtener el peso actual de un servidor."""
    try:
        # Comando para obtener el peso del servidor
        command = f"echo 'get weight {backend}/{server_name}' | socat stdio /var/run/haproxy.sock"
        
        # Ejecutar el comando
        result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        if result.returncode != 0:
            print(f"Error al obtener el peso del servidor: {result.stderr}")
            return 100  # Valor predeterminado
        
        # Procesar la salida
        output = result.stdout.strip()
        
        # El formato de la salida es "0 (initial 100)"
        # Extraer el valor inicial
        if "initial" in output:
            weight = output.split("initial")[1].strip().rstrip(")")
            return int(weight)
        else:
            # Si no hay valor inicial, usar el valor actual
            return int(output)
    except Exception as e:
        print(f"Error al obtener el peso del servidor: {str(e)}")
        return 100  # Valor predeterminado

# =============================================================================
# INTEGRACIÓN CON SISTEMA DE MONITOREO DE URLs
# =============================================================================

@app.route('/api/url-status-integration', methods=['GET'])
def get_url_status_integration():
    """Endpoint integrado con el nuevo sistema de monitoreo de URLs."""
    try:
        import requests
        import os
        
        # URL del servicio de integración
        integration_port = os.getenv('HAPROXY_INTEGRATION_PORT', '8085')
        integration_url = f"http://localhost:{integration_port}/api/url-status"
        
        # Obtener datos del servicio de monitoreo
        response = requests.get(integration_url, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            
            # Agregar información adicional del sistema HAProxy
            data['haproxy_info'] = {
                'integration_active': True,
                'integration_port': integration_port,
                'monitoring_service_port': os.getenv('URL_STATUS_SERVICE_PORT', '8090'),
                'auto_ip_update': True
            }
            
            return jsonify(data)
        else:
            return jsonify({
                'error': f'Error del servicio de monitoreo: {response.status_code}',
                'fallback': True,
                'urls': [],
                'summary': {'success': 0, 'warnings': 0, 'errors': 0}
            }), 500
            
    except requests.exceptions.ConnectionError:
        return jsonify({
            'error': 'Sistema de monitoreo no disponible',
            'suggestion': 'Ejecutar: ./scripts/monitoring/setup-complete-monitoring.sh',
            'fallback': True,
            'urls': [],
            'summary': {'success': 0, 'warnings': 0, 'errors': 0}
        }), 503
        
    except Exception as e:
        return jsonify({
            'error': str(e),
            'fallback': True,
            'urls': [],
            'summary': {'success': 0, 'warnings': 0, 'errors': 0}
        }), 500

@app.route('/api/monitoring/status', methods=['GET'])
def get_monitoring_system_status():
    """Estado del sistema de monitoreo integrado."""
    try:
        import requests
        import os
        
        monitoring_port = os.getenv('URL_STATUS_SERVICE_PORT', '8090')
        integration_port = os.getenv('HAPROXY_INTEGRATION_PORT', '8085')
        
        # Verificar servicio principal
        try:
            monitoring_response = requests.get(f"http://localhost:{monitoring_port}/api/status", timeout=5)
            monitoring_status = monitoring_response.json() if monitoring_response.status_code == 200 else {'error': 'No disponible'}
        except:
            monitoring_status = {'error': 'No disponible'}
        
        # Verificar integración
        try:
            integration_response = requests.get(f"http://localhost:{integration_port}/api/status", timeout=5)
            integration_status = integration_response.json() if integration_response.status_code == 200 else {'error': 'No disponible'}
        except:
            integration_status = {'error': 'No disponible'}
        
        return jsonify({
            'system_status': 'integrated',
            'monitoring_service': monitoring_status,
            'integration_service': integration_status,
            'endpoints': {
                'monitoring': f"http://localhost:{monitoring_port}/api/url-status",
                'integration': f"http://localhost:{integration_port}/api/url-status",
                'haproxy_admin': f"http://localhost:{os.getenv('HAPROXY_UI_EXTERNAL_PORT', '8082')}"
            }
        })
        
    except Exception as e:
        return jsonify({
            'system_status': 'error',
            'error': str(e)
        })

@app.route('/api/monitoring/force-update', methods=['POST'])
def force_monitoring_update():
    """Forzar actualización del sistema de monitoreo."""
    try:
        import requests
        import os
        
        monitoring_port = os.getenv('URL_STATUS_SERVICE_PORT', '8090')
        
        # Forzar refresh
        refresh_response = requests.post(f"http://localhost:{monitoring_port}/api/url-status/refresh", timeout=30)
        
        # Actualizar IPs si es necesario
        ip_response = requests.post(f"http://localhost:{monitoring_port}/api/containers/update-ips", timeout=60)
        
        return jsonify({
            'success': True,
            'refresh_result': refresh_response.json() if refresh_response.status_code == 200 else {'error': 'Error en refresh'},
            'ip_update_result': ip_response.json() if ip_response.status_code == 200 else {'error': 'Error en actualización de IPs'}
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        })
