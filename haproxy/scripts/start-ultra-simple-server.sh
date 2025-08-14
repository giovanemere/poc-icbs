#!/bin/bash

# Servidor web ultra simple usando socat
PORT=9002

echo "🚀 Starting Ultra Simple Web Server on port $PORT..."

# Crear respuesta HTML
create_response() {
    cat << 'EOF'
HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: 1847
Connection: close

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HAProxy Deployment Manager</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .card { border-radius: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }
        .card-header { background: linear-gradient(45deg, #2c3e50, #34495e); color: white; }
        .btn-custom { background: linear-gradient(45deg, #3498db, #2980b9); border: none; color: white; margin: 5px; }
        .status-active { background: #27ae60; color: white; padding: 8px 16px; border-radius: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header text-center">
                <h1>🚀 HAProxy Deployment Manager</h1>
                <p class="mb-0">Professional WebLogic A/B Testing & Canary Deployment</p>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-6">
                        <h5>📊 A/B Testing</h5>
                        <div class="status-active mb-3">Active - 70% A / 30% B</div>
                        <div class="progress mb-3">
                            <div class="progress-bar bg-primary" style="width: 70%">A: 70%</div>
                            <div class="progress-bar bg-secondary" style="width: 30%">B: 30%</div>
                        </div>
                        <button class="btn btn-custom btn-sm" onclick="alert('A/B Testing: 50/50 Split')">50/50 Split</button>
                        <button class="btn btn-custom btn-sm" onclick="alert('A/B Testing: 80/20 Split')">80/20 Split</button>
                    </div>
                    <div class="col-md-6">
                        <h5>🐤 Canary Deployment</h5>
                        <div class="status-active mb-3">Active - 20% Canary</div>
                        <div class="progress mb-3">
                            <div class="progress-bar bg-success" style="width: 20%">Canary: 20%</div>
                            <div class="progress-bar bg-info" style="width: 80%">Stable: 80%</div>
                        </div>
                        <button class="btn btn-custom btn-sm" onclick="alert('Canary: 5% activated')">Start 5%</button>
                        <button class="btn btn-custom btn-sm" onclick="alert('Canary: 50% activated')">Increase 50%</button>
                    </div>
                </div>
                <hr>
                <h5>🔗 Quick Actions</h5>
                <button class="btn btn-outline-primary btn-sm" onclick="window.open('/stats','_blank')">HAProxy Stats</button>
                <button class="btn btn-outline-success btn-sm" onclick="window.open('http://localhost:8001','_blank')">Dashboard</button>
                <button class="btn btn-outline-info btn-sm" onclick="window.open('http://localhost:7001/console','_blank')">WebLogic A</button>
                <button class="btn btn-outline-info btn-sm" onclick="window.open('http://localhost:7002/console','_blank')">WebLogic B</button>
                <button class="btn btn-outline-warning btn-sm" onclick="alert('Config reloaded')">Reload Config</button>
            </div>
        </div>
    </div>
</body>
</html>
EOF
}

# Función para servir usando socat de forma continua
serve_forever() {
    while true; do
        create_response | socat - TCP-LISTEN:$PORT,reuseaddr,fork &
        sleep 1
    done
}

# Iniciar servidor
serve_forever &
SERVER_PID=$!
echo $SERVER_PID > /tmp/ultra-simple-server.pid

echo "✅ Ultra Simple Web Server started on port $PORT (PID: $SERVER_PID)"
echo "🌐 Accessible via HAProxy on http://localhost:8082/"

# Mantener corriendo
wait $SERVER_PID
