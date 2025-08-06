#!/usr/bin/env python3
"""
API temporal para obtener datos de HAProxy directamente.
"""

from flask import Flask, jsonify
import subprocess
import json
import requests
from requests.auth import HTTPBasicAuth

app = Flask(__name__)

def get_haproxy_json_stats():
    """Obtener estadísticas de HAProxy en formato JSON."""
    try:
        response = requests.get('http://localhost:8404/stats;json', 
                              auth=HTTPBasicAuth('admin', 'admin123'),
                              timeout=5)
        
        if response.status_code == 200:
            return response.json()
        else:
            return None
    except Exception as e:
        print(f"Error al obtener estadísticas: {e}")
        return None

@app.route('/api/status')
def api_status():
    """Verificar estado de la API."""
    return jsonify({'status': 'ok', 'message': 'API funcionando correctamente'})

@app.route('/api/stats')
def get_stats():
    """Obtener estadísticas de servidores."""
    try:
        data = get_haproxy_json_stats()
        if not data:
            return jsonify({})
        
        stats = {}
        
        for item in data:
            if isinstance(item, list):
                current_server = None
                current_proxy = None
                server_data = {}
                
                for entry in item:
                    if entry.get('objType') == 'Server':
                        field_name = entry.get('field', {}).get('name')
                        value = entry.get('value', {}).get('value')
                        
                        if field_name == 'pxname':
                            current_proxy = value
                        elif field_name == 'svname':
                            current_server = value
                        elif field_name == 'status':
                            server_data['status'] = value
                        elif field_name == 'scur':
                            server_data['connections'] = value or 0
                        elif field_name == 'rtime':
                            server_data['response_time'] = value or 0
                
                if (current_proxy == 'weblogic_main' and 
                    current_server in ['weblogic-a', 'weblogic-b']):
                    
                    stats[current_server] = {
                        'status': 'UP' if server_data.get('status') == 'UP' else 'DOWN',
                        'connections': server_data.get('connections', 0),
                        'response_time': server_data.get('response_time', 0),
                        'active': server_data.get('status') == 'UP'
                    }
        
        return jsonify(stats)
        
    except Exception as e:
        print(f"Error en get_stats: {e}")
        return jsonify({})

@app.route('/api/backends')
def get_backends():
    """Obtener lista de backends."""
    return jsonify(['weblogic_main'])

@app.route('/api/config')
def get_config():
    """Obtener configuración actual."""
    return jsonify({
        'ab_testing': {'enabled': False, 'weight_a': 100},
        'canary': {'enabled': False, 'percentage': 0}
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8085, debug=True)
