#!/usr/bin/env python3
"""
HAProxy Advanced Admin UI
Web interface for HAProxy management and monitoring
"""

from flask import Flask, render_template_string, jsonify, request
import requests
import json
import time

app = Flask(__name__)

# HTML Template for Admin UI
ADMIN_UI_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HAProxy Advanced Admin</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; min-height: 100vh; padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { text-align: center; margin-bottom: 30px; }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header p { font-size: 1.2em; opacity: 0.9; }
        .dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { 
            background: rgba(255,255,255,0.1); 
            backdrop-filter: blur(10px); 
            border-radius: 15px; 
            padding: 25px; 
            border: 1px solid rgba(255,255,255,0.2);
        }
        .card h3 { margin-bottom: 15px; color: #90EE90; }
        .status-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .status-item { 
            background: rgba(255,255,255,0.1); 
            padding: 10px; 
            border-radius: 8px; 
            text-align: center;
        }
        .status-value { font-size: 1.5em; font-weight: bold; color: #90EE90; }
        .status-label { font-size: 0.9em; opacity: 0.8; }
        .backend-list { max-height: 200px; overflow-y: auto; }
        .backend-item { 
            background: rgba(255,255,255,0.1); 
            margin: 5px 0; 
            padding: 10px; 
            border-radius: 8px;
            display: flex; 
            justify-content: space-between;
        }
        .status-up { color: #90EE90; }
        .status-down { color: #FFB6C1; }
        .links { display: flex; gap: 15px; flex-wrap: wrap; }
        .link { 
            background: rgba(255,255,255,0.2); 
            padding: 10px 20px; 
            border-radius: 25px; 
            text-decoration: none; 
            color: white; 
            transition: all 0.3s;
        }
        .link:hover { background: rgba(255,255,255,0.3); transform: translateY(-2px); }
        .refresh-btn { 
            background: #28a745; 
            border: none; 
            color: white; 
            padding: 10px 20px; 
            border-radius: 25px; 
            cursor: pointer; 
            font-size: 1em;
        }
        .refresh-btn:hover { background: #218838; }
        .timestamp { text-align: center; margin-top: 20px; opacity: 0.7; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 HAProxy Advanced Admin</h1>
            <p>WebLogic Load Balancer Management Console</p>
        </div>
        
        <div class="dashboard">
            <div class="card">
                <h3>📊 System Status</h3>
                <div class="status-grid">
                    <div class="status-item">
                        <div class="status-value" id="backend-count">-</div>
                        <div class="status-label">Backends</div>
                    </div>
                    <div class="status-item">
                        <div class="status-value" id="active-servers">-</div>
                        <div class="status-label">Active Servers</div>
                    </div>
                    <div class="status-item">
                        <div class="status-value" id="total-sessions">-</div>
                        <div class="status-label">Total Sessions</div>
                    </div>
                    <div class="status-item">
                        <div class="status-value" id="system-status">-</div>
                        <div class="status-label">System Status</div>
                    </div>
                </div>
                <button class="refresh-btn" onclick="refreshData()">🔄 Refresh Data</button>
            </div>
            
            <div class="card">
                <h3>🎯 Backend Servers</h3>
                <div class="backend-list" id="backend-list">
                    <div class="backend-item">
                        <span>Loading backend information...</span>
                    </div>
                </div>
            </div>
            
            <div class="card">
                <h3>🔗 Quick Links</h3>
                <div class="links">
                    <a href="http://localhost:8404/stats" target="_blank" class="link">📈 HAProxy Stats</a>
                    <a href="http://localhost:8082" target="_blank" class="link">🔧 Admin API</a>
                    <a href="http://localhost:7001/console" target="_blank" class="link">🅰️ WebLogic A</a>
                    <a href="http://localhost:7002/console" target="_blank" class="link">🅱️ WebLogic B</a>
                    <a href="http://localhost:8083/console" target="_blank" class="link">⚖️ Load Balanced</a>
                    <a href="http://localhost:8000" target="_blank" class="link">📚 Documentation</a>
                </div>
            </div>
            
            <div class="card">
                <h3>⚙️ Configuration</h3>
                <p><strong>Load Balancer:</strong> HAProxy 2.6</p>
                <p><strong>Algorithm:</strong> Round Robin</p>
                <p><strong>Health Checks:</strong> Enabled</p>
                <p><strong>SSL/TLS:</strong> Available</p>
                <p><strong>Admin API:</strong> Port 8082</p>
                <p><strong>Statistics:</strong> Port 8404</p>
            </div>
        </div>
        
        <div class="timestamp">
            Last updated: <span id="last-update">-</span>
        </div>
    </div>

    <script>
        async function refreshData() {
            try {
                // Get status data
                const statusResponse = await fetch('/api/status');
                const statusData = await statusResponse.json();
                
                if (statusData.status === 'ok') {
                    document.getElementById('backend-count').textContent = statusData.backends || 0;
                    document.getElementById('active-servers').textContent = statusData.active_servers || 0;
                    document.getElementById('system-status').textContent = 'HEALTHY';
                    document.getElementById('system-status').className = 'status-value status-up';
                }
                
                // Get backend data
                const backendResponse = await fetch('/api/backends');
                const backendData = await backendResponse.json();
                
                if (backendData.status === 'ok') {
                    const backendList = document.getElementById('backend-list');
                    backendList.innerHTML = '';
                    
                    backendData.backends.forEach(backend => {
                        const item = document.createElement('div');
                        item.className = 'backend-item';
                        item.innerHTML = `
                            <span>${backend.server}</span>
                            <span class="${backend.status === 'UP' ? 'status-up' : 'status-down'}">
                                ${backend.status}
                            </span>
                        `;
                        backendList.appendChild(item);
                    });
                }
                
                document.getElementById('last-update').textContent = new Date().toLocaleString();
                
            } catch (error) {
                console.error('Error refreshing data:', error);
                document.getElementById('system-status').textContent = 'ERROR';
                document.getElementById('system-status').className = 'status-value status-down';
            }
        }
        
        // Auto-refresh every 30 seconds
        setInterval(refreshData, 30000);
        
        // Initial load
        refreshData();
    </script>
</body>
</html>
"""

@app.route('/')
def admin_ui():
    """Main admin UI page"""
    return render_template_string(ADMIN_UI_TEMPLATE)

@app.route('/api/status')
def api_status():
    """Proxy to admin API"""
    try:
        response = requests.get('http://localhost:8082/api/status', timeout=5)
        return response.json()
    except:
        return jsonify({'status': 'error', 'message': 'Admin API unavailable'})

@app.route('/api/backends')
def api_backends():
    """Proxy to admin API"""
    try:
        response = requests.get('http://localhost:8082/api/backends', timeout=5)
        return response.json()
    except:
        return jsonify({'status': 'error', 'message': 'Admin API unavailable'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8084, debug=False)
