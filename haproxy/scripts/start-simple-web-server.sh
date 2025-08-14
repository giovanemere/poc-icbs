#!/bin/bash

# Servidor web simple usando socat para puerto 9002
# Sirve la interfaz HAProxy Web UI

PORT=9002
HTML_CONTENT='HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: 2847
Connection: close

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
        .status-inactive { background: #e74c3c; color: white; }
    </style>
</head>
<body>
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-md-10">
                <div class="card">
                    <div class="card-header text-center">
                        <h1><i class="bi bi-gear-fill"></i> HAProxy Deployment Manager</h1>
                        <p class="mb-0">Professional WebLogic A/B Testing & Canary Deployment</p>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-6 mb-4">
                                <h5><i class="bi bi-diagram-3"></i> A/B Testing</h5>
                                <div class="status-badge status-active mb-3">Active - 70% A / 30% B</div>
                                <div class="progress mb-3">
                                    <div class="progress-bar bg-primary" style="width: 70%">Version A: 70%</div>
                                    <div class="progress-bar bg-secondary" style="width: 30%">Version B: 30%</div>
                                </div>
                                <button class="btn btn-custom btn-sm me-2" onclick="alert('"'"'A/B Testing: 50/50 Split Activated'"'"')">50/50 Split</button>
                                <button class="btn btn-custom btn-sm" onclick="alert('"'"'A/B Testing: 80/20 Split Activated'"'"')">80/20 Split</button>
                            </div>
                            <div class="col-md-6 mb-4">
                                <h5><i class="bi bi-speedometer2"></i> Canary Deployment</h5>
                                <div class="status-badge status-active mb-3">Active - 20% Canary Traffic</div>
                                <div class="progress mb-3">
                                    <div class="progress-bar bg-success" style="width: 20%">Canary: 20%</div>
                                    <div class="progress-bar bg-info" style="width: 80%">Stable: 80%</div>
                                </div>
                                <button class="btn btn-custom btn-sm me-2" onclick="alert('"'"'Canary: 5% traffic activated'"'"')">Start 5%</button>
                                <button class="btn btn-custom btn-sm" onclick="alert('"'"'Canary: 50% traffic activated'"'"')">Increase 50%</button>
                            </div>
                        </div>
                        <hr>
                        <div class="row">
                            <div class="col-md-12">
                                <h5><i class="bi bi-link-45deg"></i> Quick Actions</h5>
                                <div class="d-flex flex-wrap gap-2">
                                    <button class="btn btn-outline-primary btn-sm" onclick="window.open('"'"'/stats'"'"','"'"'_blank'"'"')">HAProxy Stats</button>
                                    <button class="btn btn-outline-success btn-sm" onclick="window.open('"'"'http://localhost:8001'"'"','"'"'_blank'"'"')">Dashboard</button>
                                    <button class="btn btn-outline-info btn-sm" onclick="window.open('"'"'http://localhost:7001/console'"'"','"'"'_blank'"'"')">WebLogic A</button>
                                    <button class="btn btn-outline-info btn-sm" onclick="window.open('"'"'http://localhost:7002/console'"'"','"'"'_blank'"'"')">WebLogic B</button>
                                    <button class="btn btn-outline-warning btn-sm" onclick="alert('"'"'HAProxy configuration reloaded'"'"')">Reload Config</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>'

echo "🚀 Starting Simple Web Server on port $PORT..."

# Función para servir contenido
serve_content() {
    while true; do
        echo -e "$HTML_CONTENT" | socat - TCP-LISTEN:$PORT,reuseaddr,fork
    done
}

# Iniciar servidor
serve_content &
SERVER_PID=$!
echo $SERVER_PID > /tmp/simple-web-server.pid

echo "✅ Simple Web Server started on port $PORT (PID: $SERVER_PID)"
echo "🌐 Accessible via HAProxy on http://localhost:8082/"

# Mantener el script corriendo
wait $SERVER_PID
