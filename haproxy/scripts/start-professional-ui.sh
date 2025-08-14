#!/bin/bash

# Script para iniciar la interfaz profesional de HAProxy
set -e

echo "🚀 Iniciando HAProxy Professional UI..."

# Instalar dependencias si no están instaladas
if ! python3 -c "import flask" 2>/dev/null; then
    echo "📦 Instalando Flask..."
    pip3 install flask requests
fi

# Configurar variables de entorno
export FLASK_APP=admin_ui.py
export FLASK_ENV=production
export FLASK_HOST=0.0.0.0
export FLASK_PORT=9082

# Crear directorios necesarios
mkdir -p /etc/haproxy/templates
mkdir -p /etc/haproxy/static/css
mkdir -p /etc/haproxy/static/js

# Copiar templates al directorio correcto
cp -r /scripts/templates/* /etc/haproxy/templates/ 2>/dev/null || true

# Crear archivo CSS básico
cat > /etc/haproxy/static/css/styles.css << 'EOF'
/* HAProxy Professional UI Styles */
.card-dashboard {
    transition: transform 0.2s;
}

.card-dashboard:hover {
    transform: translateY(-2px);
}

.border-left-primary {
    border-left: 0.25rem solid #4e73df !important;
}

.text-primary {
    color: #4e73df !important;
}

.bg-gradient-primary {
    background: linear-gradient(180deg, #4e73df 10%, #224abe 100%);
}

.sidebar {
    background: #343a40;
}

.sidebar .nav-link {
    color: #adb5bd;
}

.sidebar .nav-link:hover {
    color: #fff;
}

.sidebar .nav-link.active {
    color: #fff;
    background: #495057;
}

/* Dark mode improvements */
[data-bs-theme="dark"] .card {
    background: #2d3748;
    border: 1px solid #4a5568;
}

[data-bs-theme="dark"] .sidebar {
    background: #1a202c;
}
EOF

# Modificar admin_ui.py para usar puerto 9082
sed -i 's/port=8082/port=9082/g' /scripts/admin_ui.py

echo "🌐 Iniciando servidor Flask en puerto 9082..."

# Iniciar la aplicación Flask
cd /scripts
python3 admin_ui.py &

# Guardar PID
echo $! > /tmp/professional-ui.pid

echo "✅ HAProxy Professional UI iniciado en puerto 9082"
echo "🔗 Accesible via HAProxy en http://localhost:8082"

# Mantener el script corriendo
wait
