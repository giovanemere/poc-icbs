#!/usr/bin/env python3
"""
HAProxy Advanced Admin API
Provides REST API for HAProxy management and monitoring
"""

from flask import Flask, jsonify, request
import requests
import json
import subprocess
import os
import time

app = Flask(__name__)

# Configuration
HAPROXY_STATS_URL = "http://localhost:8404/stats"
HAPROXY_SOCKET = "/var/run/haproxy/admin.sock"

@app.route('/api/status', methods=['GET'])
def get_status():
    """Get overall HAProxy status"""
    try:
        # Get basic stats
        response = requests.get(HAPROXY_STATS_URL + ";csv", timeout=5)
        if response.status_code == 200:
            lines = response.text.strip().split('\n')
            stats = []
            for line in lines[1:]:  # Skip header
                if line.strip():
                    fields = line.split(',')
                    if len(fields) > 1:
                        stats.append({
                            'name': fields[0],
                            'service': fields[1],
                            'status': fields[17] if len(fields) > 17 else 'UNKNOWN'
                        })
            
            return jsonify({
                'status': 'ok',
                'timestamp': time.time(),
                'backends': len([s for s in stats if 'weblogic' in s.get('name', '')]),
                'active_servers': len([s for s in stats if s.get('status') == 'UP']),
                'stats': stats[:10]  # Limit response size
            })
        else:
            return jsonify({'status': 'error', 'message': 'Cannot reach HAProxy stats'}), 500
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/backends', methods=['GET'])
def get_backends():
    """Get backend server information"""
    try:
        response = requests.get(HAPROXY_STATS_URL + ";csv", timeout=5)
        if response.status_code == 200:
            lines = response.text.strip().split('\n')
            backends = []
            for line in lines[1:]:
                if line.strip():
                    fields = line.split(',')
                    if len(fields) > 17 and 'weblogic' in fields[0]:
                        backends.append({
                            'proxy': fields[0],
                            'server': fields[1],
                            'status': fields[17],
                            'weight': fields[18] if len(fields) > 18 else '1',
                            'sessions': fields[7] if len(fields) > 7 else '0',
                            'bytes_in': fields[8] if len(fields) > 8 else '0',
                            'bytes_out': fields[9] if len(fields) > 9 else '0'
                        })
            
            return jsonify({
                'status': 'ok',
                'backends': backends,
                'count': len(backends)
            })
        else:
            return jsonify({'status': 'error', 'message': 'Cannot reach HAProxy stats'}), 500
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'haproxy-admin-api',
        'timestamp': time.time(),
        'version': '1.0.0'
    })

@app.route('/api/config', methods=['GET'])
def get_config():
    """Get HAProxy configuration info"""
    return jsonify({
        'status': 'ok',
        'config': {
            'stats_url': HAPROXY_STATS_URL,
            'socket': HAPROXY_SOCKET,
            'admin_api_port': 8082,
            'admin_ui_port': 8084,
            'stats_port': 8404
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8082, debug=False)
