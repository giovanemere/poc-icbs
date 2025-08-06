#!/usr/bin/env python3
"""
Integración del servicio de monitoreo de URLs con HAProxy
Proporciona endpoints compatibles con el dashboard existente
"""

import os
import sys
import json
import requests
from flask import Flask, jsonify, request
from flask_cors import CORS

class HAProxyURLIntegration:
    def __init__(self):
        self.app = Flask(__name__)
        CORS(self.app)
        
        # URL del servicio de monitoreo
        self.monitoring_service_url = f"http://localhost:{os.getenv('URL_STATUS_SERVICE_PORT', '8090')}"
        
        self.setup_routes()
        
    def setup_routes(self):
        """Configurar rutas compatibles con HAProxy"""
        
        @self.app.route('/api/url-status', methods=['GET'])
        def get_url_status():
            """Endpoint compatible con el dashboard de HAProxy"""
            try:
                # Obtener datos del servicio de monitoreo
                response = requests.get(f"{self.monitoring_service_url}/api/url-status", timeout=10)
                
                if response.status_code == 200:
                    data = response.json()
                    
                    # Convertir formato para compatibilidad con dashboard
                    urls = []
                    for url_data in data.get('urls', []):
                        urls.append({
                            'url': url_data['url'],
                            'status': url_data['status'],
                            'code': str(url_data['code']),
                            'type': url_data['type'],
                            'name': url_data['name'],
                            'response_time': url_data.get('response_time', 0)
                        })
                    
                    return jsonify({
                        'urls': urls,
                        'summary': data.get('summary', {}),
                        'last_check': data.get('last_check'),
                        'container_status': data.get('container_status', {}),
                        'raw_output': self.generate_raw_output(urls)
                    })
                else:
                    return jsonify({
                        'error': f'Error del servicio de monitoreo: {response.status_code}',
                        'urls': [],
                        'summary': {'success': 0, 'warnings': 0, 'errors': 0}
                    }), 500
                    
            except requests.exceptions.ConnectionError:
                return jsonify({
                    'error': 'Servicio de monitoreo no disponible',
                    'urls': [],
                    'summary': {'success': 0, 'warnings': 0, 'errors': 0},
                    'suggestion': 'Ejecutar: ./scripts/monitoring/start-url-monitoring.sh'
                }), 503
                
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
                response = requests.post(f"{self.monitoring_service_url}/api/url-status/refresh", timeout=30)
                
                if response.status_code == 200:
                    return response.json()
                else:
                    return jsonify({'error': 'Error al actualizar estado'}), 500
                    
            except Exception as e:
                return jsonify({'error': str(e)}), 500
        
        @self.app.route('/api/containers/update-ips', methods=['POST'])
        def update_container_ips():
            """Actualizar IPs de contenedores"""
            try:
                response = requests.post(f"{self.monitoring_service_url}/api/containers/update-ips", timeout=60)
                
                if response.status_code == 200:
                    return response.json()
                else:
                    return jsonify({'error': 'Error al actualizar IPs'}), 500
                    
            except Exception as e:
                return jsonify({'error': str(e)}), 500
        
        @self.app.route('/api/status', methods=['GET'])
        def api_status():
            """Estado de la integración"""
            try:
                # Verificar servicio de monitoreo
                response = requests.get(f"{self.monitoring_service_url}/api/status", timeout=5)
                monitoring_status = response.json() if response.status_code == 200 else {'error': 'No disponible'}
                
                return jsonify({
                    'status': 'ok',
                    'service': 'HAProxy URL Integration',
                    'version': '1.0.0',
                    'monitoring_service': monitoring_status
                })
                
            except Exception as e:
                return jsonify({
                    'status': 'error',
                    'service': 'HAProxy URL Integration',
                    'error': str(e),
                    'monitoring_service': {'error': 'No disponible'}
                })
        
        @self.app.route('/health', methods=['GET'])
        def health_check():
            """Health check endpoint"""
            return jsonify({'status': 'healthy'})
    
    def generate_raw_output(self, urls):
        """Generar salida raw compatible con el formato anterior"""
        output_lines = []
        output_lines.append("=== Verificando URLs desde cada nodo y HAProxy ===")
        output_lines.append("")
        
        for url_data in urls:
            status_icon = "✅" if url_data['type'] == 'success' else "⚠️" if url_data['type'] == 'warning' else "❌"
            output_lines.append(f"{status_icon} {url_data['url']} - {url_data['status']} ({url_data['code']})")
        
        output_lines.append("")
        output_lines.append("=== Resumen de la verificación ===")
        
        return "\n".join(output_lines)
    
    def run(self, port=8085):
        """Ejecutar el servicio de integración"""
        print(f"Iniciando HAProxy URL Integration en puerto {port}")
        print(f"Servicio de monitoreo: {self.monitoring_service_url}")
        
        self.app.run(
            host='0.0.0.0',
            port=port,
            debug=False,
            threaded=True
        )

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8085
    integration = HAProxyURLIntegration()
    integration.run(port)
