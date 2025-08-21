#!/bin/bash
#
# Script para controlar el porcentaje de tráfico en el despliegue canary
#

set -e

echo "=== Control de despliegue canary ==="
echo ""

# Verificar si se proporcionó un porcentaje
if [ $# -eq 0 ]; then
    echo "Error: No se proporcionó un porcentaje"
    echo "Uso: $0 [porcentaje]"
    exit 1
fi

PERCENTAGE=$1

# Verificar si el porcentaje es un número entre 0 y 100
if ! [[ "$PERCENTAGE" =~ ^[0-9]+$ ]] || [ "$PERCENTAGE" -lt 0 ] || [ "$PERCENTAGE" -gt 100 ]; then
    echo "Error: El porcentaje debe ser un número entre 0 y 100"
    exit 1
fi

# Verificar si el contenedor está en ejecución
if ! docker ps | grep -q weblogic-feature-flags; then
    echo "Error: El contenedor weblogic-feature-flags no está en ejecución"
    echo "Por favor, inicie el contenedor con:"
    echo "  docker-compose -f config/docker-compose.yml up -d"
    exit 1
fi

# Crear script Python para actualizar el porcentaje
cat > /tmp/update_canary.py << EOF
import sys
import urllib.request
import urllib.parse
import base64

# Configuración
url = 'http://localhost:9001/feature-flags/api/ff4j/propertyStore/canary-percentage'
username = 'weblogic'
password = 'welcome1'
percentage = '$PERCENTAGE'

# Crear autenticación básica
auth = base64.b64encode(f'{username}:{password}'.encode()).decode()

# Crear solicitud
data = urllib.parse.urlencode({'value': percentage}).encode()
headers = {
    'Authorization': f'Basic {auth}',
    'Content-Type': 'application/x-www-form-urlencoded'
}

# Enviar solicitud
req = urllib.request.Request(url, data=data, headers=headers, method='POST')

try:
    with urllib.request.urlopen(req) as response:
        print(f'Porcentaje de tráfico actualizado a {percentage}%')
except urllib.error.HTTPError as e:
    print(f'Error al actualizar el porcentaje: {e.code} {e.reason}')
    sys.exit(1)
except urllib.error.URLError as e:
    print(f'Error al conectar con el servidor: {e.reason}')
    sys.exit(1)
EOF

# Ejecutar script Python
echo "Actualizando porcentaje de tráfico a $PERCENTAGE%..."
python3 /tmp/update_canary.py

# Limpiar
rm -f /tmp/update_canary.py

echo ""
echo "=== Control de despliegue canary completado ==="
echo ""
echo "Porcentaje de tráfico a la versión B: $PERCENTAGE%"
echo ""
echo "Para probar el despliegue canary, ejecute:"
echo "  ./scripts/canary/test-canary.sh [número-peticiones]"
echo ""
