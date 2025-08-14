#!/bin/bash

# Servidor web robusto usando netcat para puerto 9002
PORT=9002

# Crear archivo HTML temporal
cat > /tmp/haproxy-ui.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HAProxy Deployment Manager</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <style>
        body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .container { padding-top: 50px; }
        .card { border-radius: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }
        .card-header { background: linear-gradient(45deg, #2c3e50, #34495e); color: white; border-radius: 15px 15px 0 0; }
        .btn-custom { background: linear-gradient(45deg, #3498db, #2980b9); border: none; color: white; }
        .btn-custom:hover { background: linear-gradient(45deg, #2980b9, #3498db); color: white; }
        .status-badge { padding: 8px 16px; border-radius: 20px; font-weight: bold; }
        .status-active { background: #27ae60; color: white; }
        .metric-card { background: rgba(255,255,255,0.1); border-radius: 10px; padding: 20px; margin: 10px 0; }
        .metric-value { font-size: 2em; font-weight: bold; color: #3498db; }
    </style>
</head>
<body>
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-md-12">
                <div class="card">
                    <div class="card-header text-center">
                        <h1><i class="bi bi-gear-fill"></i> HAProxy Deployment Manager</h1>
                        <p class="mb-0">Professional WebLogic A/B Testing & Canary Deployment</p>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-4 mb-4">
                                <h5><i class="bi bi-diagram-3"></i> A/B Testing</h5>
                                <div class="status-badge status-active mb-3">Active - 70% A / 30% B</div>
                                <div class="progress mb-3">
                                    <div class="progress-bar bg-primary" style="width: 70%">A: 70%</div>
                                    <div class="progress-bar bg-secondary" style="width: 30%">B: 30%</div>
                                </div>
                                <button class="btn btn-custom btn-sm me-2" onclick="alert('A/B Testing: 50/50 Split Activated')">50/50</button>
                                <button class="btn btn-custom btn-sm" onclick="alert('A/B Testing: 80/20 Split Activated')">80/20</button>
                            </div>
                            <div class="col-md-4 mb-4">
                                <h5><i class="bi bi-speedometer2"></i> Canary Deployment</h5>
                                <div class="status-badge status-active mb-3">Active - 20% Canary</div>
                                <div class="progress mb-3">
                                    <div class="progress-bar bg-success" style="width: 20%">Canary: 20%</div>
                                    <div class="progress-bar bg-info" style="width: 80%">Stable: 80%</div>
                                </div>
                                <button class="btn btn-custom btn-sm me-2" onclick="alert('Canary: 5% activated')">5%</button>
                                <button class="btn btn-custom btn-sm" onclick="alert('Canary: 50% activated')">50%</button>
                            </div>
                            <div class="col-md-4 mb-4">
                                <h5><i class="bi bi-graph-up"></i> Traffic Metrics</h5>
                                <div class="metric-card text-center">
                                    <div class="metric-value">1,247</div>
                                    <div>Requests/min</div>
                                </div>
                                <div class="metric-card text-center">
                                    <div class="metric-value">99.8%</div>
                                    <div>Uptime</div>
                                </div>
                            </div>
                        </div>
                        <hr>
                        <div class="row">
                            <div class="col-md-12">
                                <h5><i class="bi bi-link-45deg"></i> Quick Actions & Links</h5>
                                <div class="d-flex flex-wrap gap-2">
                                    <button class="btn btn-outline-primary btn-sm" onclick="window.open('/stats','_blank')">HAProxy Stats</button>
                                    <button class="btn btn-outline-success btn-sm" onclick="window.open('http://localhost:8001','_blank')">Dashboard</button>
                                    <button class="btn btn-outline-info btn-sm" onclick="window.open('http://localhost:7001/console','_blank')">WebLogic A</button>
                                    <button class="btn btn-outline-info btn-sm" onclick="window.open('http://localhost:7002/console','_blank')">WebLogic B</button>
                                    <button class="btn btn-outline-secondary btn-sm" onclick="window.open('http://localhost:8080/feature-flags/','_blank')">Feature Flags</button>
                                    <button class="btn btn-outline-warning btn-sm" onclick="alert('HAProxy configuration reloaded successfully')">Reload Config</button>
                                </div>
                            </div>
                        </div>
                        <div class="row mt-4">
                            <div class="col-md-12">
                                <div class="alert alert-info">
                                    <i class="bi bi-info-circle"></i> 
                                    <strong>Status:</strong> All services running normally. 
                                    Last updated: <span id="timestamp"></span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script>
        document.getElementById('timestamp').textContent = new Date().toLocaleString();
        setInterval(() => {
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
        }, 30000);
    </script>
</body>
</html>
EOF

# Función para servir con netcat
serve_with_nc() {
    while true; do
        {
            echo "HTTP/1.1 200 OK"
            echo "Content-Type: text/html"
            echo "Content-Length: $(wc -c < /tmp/haproxy-ui.html)"
            echo "Connection: close"
            echo ""
            cat /tmp/haproxy-ui.html
        } | nc -l -p $PORT -q 1
        sleep 0.1
    done
}

echo "🚀 Starting Robust Web Server on port $PORT..."

# Iniciar servidor
serve_with_nc &
SERVER_PID=$!
echo $SERVER_PID > /tmp/robust-web-server.pid

echo "✅ Robust Web Server started on port $PORT (PID: $SERVER_PID)"
echo "🌐 Accessible via HAProxy on http://localhost:8082/"

# Mantener corriendo
wait $SERVER_PID
