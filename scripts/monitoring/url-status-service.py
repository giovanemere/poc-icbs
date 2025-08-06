#!/usr/bin/env python3
"""
Servicio centralizado de monitoreo de URLs del sistema
Utiliza variables de entorno para configuración dinámica
Incluye demonio de actualización automática de IPs
"""

import os
import sys
import json
import time
import docker
import requests
import threading
import subprocess
from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS

# Configuración desde variables de entorno
class Config:
    def __init__(self):
        self.load_config()
        
    def load_config(self):
        """Cargar configuración desde archivo JSON o variables de entorno"""
        # Intentar cargar desde archivo JSON primero
        config_file = os.path.join(os.path.dirname(__file__), '../../config/monitoring/url-monitoring.json')
        
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r') as f:
                    config_data = json.load(f)
                
                # Cargar configuración del servicio
                service_config = config_data.get('service', {})
                self.service_port = service_config.get('port', 8090)
                self.check_interval = service_config.get('check_interval', 30)
                self.timeout = service_config.get('timeout', 5)
                self.max_retries = service_config.get('max_retries', 3)
                
                # Cargar URLs desde JSON
                self.urls_to_check = config_data.get('urls', [])
                
                print(f"✅ Configuración cargada desde JSON: {len(self.urls_to_check)} URLs")
                return
                
            except Exception as e:
                print(f"⚠️  Error cargando JSON, usando variables de entorno: {e}")
        
        # Fallback: cargar desde variables de entorno
        self.load_env_vars()
        
    def load_env_vars(self):
        """Cargar variables de entorno desde .env"""
        env_file = os.path.join(os.path.dirname(__file__), '../../.env')
        if os.path.exists(env_file):
            with open(env_file, 'r') as f:
                for line in f:
                    if line.strip() and not line.startswith('#') and '=' in line:
                        key, value = line.strip().split('=', 1)
                        # Expandir variables de entorno en el valor
                        value = os.path.expandvars(value)
                        os.environ[key] = value
        
        # URLs del sistema basadas en variables de entorno (fallback)
        self.urls_to_check = [
            {
                'name': 'HAProxy Load Balancer',
                'url': f"http://localhost:{os.getenv('HAPROXY_HTTP_EXTERNAL_PORT', '8083')}/",
                'type': 'load_balancer',
                'critical': True
            },
            {
                'name': 'HAProxy Stats',
                'url': f"http://localhost:{os.getenv('HAPROXY_STATS_EXTERNAL_PORT', '8404')}/stats",
                'type': 'monitoring',
                'critical': False
            },
            {
                'name': 'HAProxy Admin UI',
                'url': f"http://localhost:{os.getenv('HAPROXY_UI_EXTERNAL_PORT', '8082')}/",
                'type': 'admin',
                'critical': False
            },
            {
                'name': 'WebLogic Server A',
                'url': f"http://localhost:{os.getenv('WEBLOGIC_A_EXTERNAL_PORT', '7001')}/console",
                'type': 'weblogic',
                'critical': True
            },
            {
                'name': 'WebLogic Server B',
                'url': f"http://localhost:{os.getenv('WEBLOGIC_B_EXTERNAL_PORT', '7002')}/console",
                'type': 'weblogic',
                'critical': True
            },
            {
                'name': 'MkDocs Documentation',
                'url': f"http://localhost:{os.getenv('MKDOCS_EXTERNAL_PORT', '8000')}/",
                'type': 'documentation',
                'critical': False
            }
        ]
        
        # Configuración del servicio
        self.service_port = int(os.getenv('URL_STATUS_SERVICE_PORT', '8090'))
        self.check_interval = int(os.getenv('URL_CHECK_INTERVAL', '30'))
        self.timeout = int(os.getenv('URL_CHECK_TIMEOUT', '5'))
        self.max_retries = int(os.getenv('URL_CHECK_RETRIES', '3'))

class URLStatusService:
    def __init__(self):
        self.config = Config()
        self.app = Flask(__name__)
        CORS(self.app)
        self.docker_client = None
        self.last_check_results = {}
        self.last_check_time = None
        self.setup_routes()
        self.setup_docker_client()
        
    def setup_docker_client(self):
        """Configurar cliente Docker para monitoreo de contenedores"""
        try:
            self.docker_client = docker.from_env()
        except Exception as e:
            print(f"Warning: No se pudo conectar a Docker: {e}")
            
    def setup_routes(self):
        """Configurar rutas de la API"""
        
        @self.app.route('/api/status', methods=['GET'])
        def api_status():
            return jsonify({
                'status': 'ok',
                'service': 'URL Status Service',
                'version': '1.0.0',
                'last_check': self.last_check_time,
                'urls_monitored': len(self.config.urls_to_check)
            })
            
        @self.app.route('/api/url-status', methods=['GET'])
        def get_url_status():
            """Endpoint principal para obtener estado de URLs"""
            try:
                # Forzar verificación si no hay datos recientes
                if not self.last_check_results or not self.last_check_time:
                    self.check_all_urls()
                    
                return jsonify({
                    'urls': self.last_check_results.get('urls', []),
                    'summary': self.last_check_results.get('summary', {}),
                    'last_check': self.last_check_time,
                    'container_status': self.get_container_status()
                })
            except Exception as e:
                return jsonify({
                    'error': str(e),
                    'urls': [],
                    'summary': {'success': 0, 'warnings': 0, 'errors': 0}
                }), 500
                
        @self.app.route('/api/url-status/refresh', methods=['POST'])
        def refresh_url_status():
            """Forzar actualización del estado de URLs"""
            try:
                self.check_all_urls()
                return jsonify({
                    'success': True,
                    'message': 'Estado de URLs actualizado',
                    'last_check': self.last_check_time
                })
            except Exception as e:
                return jsonify({'error': str(e)}), 500
                
        @self.app.route('/api/containers/update-ips', methods=['POST'])
        def update_container_ips():
            """Actualizar IPs de contenedores en HAProxy"""
            try:
                result = self.update_haproxy_ips()
                return jsonify(result)
            except Exception as e:
                return jsonify({'error': str(e)}), 500
                
        @self.app.route('/api/config/reload', methods=['POST'])
        def reload_config():
            """Recargar configuración desde variables de entorno"""
            try:
                self.config = Config()
                return jsonify({
                    'success': True,
                    'message': 'Configuración recargada',
                    'urls_count': len(self.config.urls_to_check)
                })
            except Exception as e:
                return jsonify({'error': str(e)}), 500

    def check_url(self, url_config):
        """Verificar una URL específica"""
        url = url_config['url']
        name = url_config['name']
        
        # Obtener códigos esperados de la configuración, con fallback a códigos por defecto
        expected_codes = url_config.get('expected_codes', [200, 302, 301])
        
        # Configurar autenticación si está presente
        auth = None
        if 'auth' in url_config:
            auth_config = url_config['auth']
            if auth_config.get('type') == 'basic':
                from requests.auth import HTTPBasicAuth
                auth = HTTPBasicAuth(
                    auth_config.get('username', ''),
                    auth_config.get('password', '')
                )
        
        for attempt in range(self.config.max_retries):
            try:
                response = requests.get(
                    url, 
                    timeout=self.config.timeout,
                    allow_redirects=True,
                    verify=False,
                    auth=auth
                )
                
                status_code = response.status_code
                
                # Verificar si el código está en los códigos esperados
                if status_code in expected_codes:
                    return {
                        'name': name,
                        'url': url,
                        'status': 'OK',
                        'code': status_code,
                        'type': 'success',
                        'response_time': response.elapsed.total_seconds(),
                        'attempt': attempt + 1,
                        'description': url_config.get('description', '')
                    }
                elif status_code == 404:
                    return {
                        'name': name,
                        'url': url,
                        'status': 'NOT FOUND',
                        'code': status_code,
                        'type': 'warning',
                        'response_time': response.elapsed.total_seconds(),
                        'attempt': attempt + 1,
                        'description': url_config.get('description', '')
                    }
                else:
                    if attempt == self.config.max_retries - 1:
                        return {
                            'name': name,
                            'url': url,
                            'status': 'ERROR',
                            'code': status_code,
                            'type': 'error',
                            'response_time': response.elapsed.total_seconds(),
                            'attempt': attempt + 1,
                            'expected_codes': expected_codes,
                            'description': url_config.get('description', '')
                        }
                        
            except requests.exceptions.Timeout:
                if attempt == self.config.max_retries - 1:
                    return {
                        'name': name,
                        'url': url,
                        'status': 'TIMEOUT',
                        'code': 'TIMEOUT',
                        'type': 'error',
                        'response_time': self.config.timeout,
                        'attempt': attempt + 1,
                        'description': url_config.get('description', '')
                    }
            except requests.exceptions.ConnectionError:
                if attempt == self.config.max_retries - 1:
                    return {
                        'name': name,
                        'url': url,
                        'status': 'CONNECTION ERROR',
                        'code': 'CONNECTION_ERROR',
                        'type': 'error',
                        'response_time': 0,
                        'attempt': attempt + 1,
                        'description': url_config.get('description', '')
                    }
            except Exception as e:
                if attempt == self.config.max_retries - 1:
                    return {
                        'name': name,
                        'url': url,
                        'status': 'UNKNOWN ERROR',
                        'code': str(e),
                        'type': 'error',
                        'response_time': 0,
                        'attempt': attempt + 1,
                        'description': url_config.get('description', '')
                    }
                    
            # Esperar antes del siguiente intento
            if attempt < self.config.max_retries - 1:
                time.sleep(1)

    def check_all_urls(self):
        """Verificar todas las URLs configuradas"""
        results = []
        summary = {'success': 0, 'warnings': 0, 'errors': 0}
        
        for url_config in self.config.urls_to_check:
            result = self.check_url(url_config)
            results.append(result)
            
            if result['type'] == 'success':
                summary['success'] += 1
            elif result['type'] == 'warning':
                summary['warnings'] += 1
            else:
                summary['errors'] += 1
                
        self.last_check_results = {
            'urls': results,
            'summary': summary
        }
        self.last_check_time = datetime.now().isoformat()
        
        return self.last_check_results

    def get_container_status(self):
        """Obtener estado de contenedores Docker"""
        if not self.docker_client:
            return {'error': 'Docker client not available'}
            
        try:
            containers = {}
            for container_name in ['haproxy', 'weblogic-a', 'weblogic-b', 'mkdocs-server']:
                try:
                    container = self.docker_client.containers.get(container_name)
                    networks = container.attrs['NetworkSettings']['Networks']
                    ip_address = None
                    for network_name, network_info in networks.items():
                        if network_info['IPAddress']:
                            ip_address = network_info['IPAddress']
                            break
                            
                    containers[container_name] = {
                        'status': container.status,
                        'ip_address': ip_address,
                        'ports': container.attrs['NetworkSettings']['Ports']
                    }
                except docker.errors.NotFound:
                    containers[container_name] = {
                        'status': 'not_found',
                        'ip_address': None,
                        'ports': {}
                    }
                    
            return containers
        except Exception as e:
            return {'error': str(e)}

    def update_haproxy_ips(self):
        """Actualizar IPs de contenedores en HAProxy"""
        if not self.docker_client:
            return {'error': 'Docker client not available'}
            
        try:
            # Obtener IPs actuales de los contenedores
            weblogic_a_ip = self.get_container_ip('weblogic-a')
            weblogic_b_ip = self.get_container_ip('weblogic-b')
            
            if not weblogic_a_ip or not weblogic_b_ip:
                return {'error': 'No se pudieron obtener las IPs de los contenedores WebLogic'}
            
            # Actualizar configuración de HAProxy
            haproxy_container = self.docker_client.containers.get('haproxy')
            
            # Crear backup de la configuración
            backup_cmd = f'cp /usr/local/etc/haproxy/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg.bak.{int(time.time())}'
            haproxy_container.exec_run(backup_cmd)
            
            # Actualizar IPs en la configuración
            update_a_cmd = f'sed -i "s/server weblogic-a [0-9.]*:7001/server weblogic-a {weblogic_a_ip}:7001/g" /usr/local/etc/haproxy/haproxy.cfg'
            update_b_cmd = f'sed -i "s/server weblogic-b [0-9.]*:7001/server weblogic-b {weblogic_b_ip}:7001/g" /usr/local/etc/haproxy/haproxy.cfg'
            
            haproxy_container.exec_run(update_a_cmd)
            haproxy_container.exec_run(update_b_cmd)
            
            # Recargar HAProxy
            reload_cmd = 'haproxy -f /usr/local/etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid)'
            result = haproxy_container.exec_run(reload_cmd)
            
            if result.exit_code == 0:
                return {
                    'success': True,
                    'message': 'IPs de HAProxy actualizadas correctamente',
                    'weblogic_a_ip': weblogic_a_ip,
                    'weblogic_b_ip': weblogic_b_ip,
                    'timestamp': datetime.now().isoformat()
                }
            else:
                return {
                    'error': 'Error al recargar HAProxy',
                    'details': result.output.decode() if result.output else 'No output'
                }
                
        except Exception as e:
            return {'error': f'Error actualizando IPs: {str(e)}'}

    def get_container_ip(self, container_name):
        """Obtener IP de un contenedor específico"""
        try:
            container = self.docker_client.containers.get(container_name)
            networks = container.attrs['NetworkSettings']['Networks']
            for network_name, network_info in networks.items():
                if network_info['IPAddress']:
                    return network_info['IPAddress']
            return None
        except:
            return None

    def start_monitoring_daemon(self):
        """Iniciar demonio de monitoreo continuo"""
        def monitoring_loop():
            while True:
                try:
                    print(f"[{datetime.now()}] Verificando URLs...")
                    self.check_all_urls()
                    
                    # Si hay errores críticos, intentar actualizar IPs
                    critical_errors = [
                        url for url in self.last_check_results.get('urls', [])
                        if url['type'] == 'error' and any(
                            config['name'] == url['name'] and config.get('critical', False)
                            for config in self.config.urls_to_check
                        )
                    ]
                    
                    if critical_errors:
                        print(f"[{datetime.now()}] Errores críticos detectados, actualizando IPs...")
                        self.update_haproxy_ips()
                        
                except Exception as e:
                    print(f"[{datetime.now()}] Error en monitoreo: {e}")
                    
                time.sleep(self.config.check_interval)
                
        # Iniciar hilo de monitoreo
        monitoring_thread = threading.Thread(target=monitoring_loop, daemon=True)
        monitoring_thread.start()
        print(f"Demonio de monitoreo iniciado (intervalo: {self.config.check_interval}s)")

    def run(self):
        """Ejecutar el servicio"""
        print(f"Iniciando URL Status Service en puerto {self.config.service_port}")
        print(f"URLs monitoreadas: {len(self.config.urls_to_check)}")
        
        # Verificación inicial
        self.check_all_urls()
        
        # Iniciar demonio de monitoreo
        self.start_monitoring_daemon()
        
        # Iniciar servidor Flask
        self.app.run(
            host='0.0.0.0',
            port=self.config.service_port,
            debug=False,
            threaded=True
        )

if __name__ == '__main__':
    service = URLStatusService()
    service.run()
