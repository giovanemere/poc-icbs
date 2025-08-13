#!/bin/bash
#
# Script para probar el despliegue canary
#

set -e

echo "=== Prueba de despliegue canary ==="
echo ""

# Verificar si se proporcionó un número de peticiones
if [ $# -eq 0 ]; then
    NUM_REQUESTS=100
    echo "No se proporcionó un número de peticiones, usando el valor por defecto: $NUM_REQUESTS"
else
    NUM_REQUESTS=$1
    
    # Verificar si el número de peticiones es un número positivo
    if ! [[ "$NUM_REQUESTS" =~ ^[0-9]+$ ]] || [ "$NUM_REQUESTS" -le 0 ]; then
        echo "Error: El número de peticiones debe ser un número positivo"
        exit 1
    fi
    
    echo "Usando el número de peticiones proporcionado: $NUM_REQUESTS"
fi

# Verificar si el contenedor está en ejecución
if ! docker ps | grep -q weblogic-feature-flags; then
    echo "Error: El contenedor weblogic-feature-flags no está en ejecución"
    echo "Por favor, inicie el contenedor con:"
    echo "  docker-compose -f config/docker-compose.yml up -d"
    exit 1
fi

# Obtener el porcentaje de tráfico
if [ -f "/tmp/canary-percentage.txt" ]; then
    PERCENTAGE=$(cat /tmp/canary-percentage.txt)
else
    PERCENTAGE=0
fi

# Crear script Python para probar el despliegue canary
cat > /tmp/test_canary.py << EOF
import sys
import urllib.request
import random
import time
from collections import Counter

# Configuración
base_url_a = 'http://localhost:9001/weblogic-features-a/'
base_url_b = 'http://localhost:9001/weblogic-features-b/'
num_requests = $NUM_REQUESTS
percentage = $PERCENTAGE

# Realizar peticiones
results = []
print(f'Realizando {num_requests} peticiones con {percentage}% de tráfico a la versión B...')

for i in range(num_requests):
    # Generar un número aleatorio entre 0 y 99
    rand = random.randint(0, 99)
    
    # Determinar qué versión usar
    if rand < percentage:
        url = base_url_b
        version = 'B'
    else:
        url = base_url_a
        version = 'A'
    
    # Realizar la petición
    try:
        with urllib.request.urlopen(url) as response:
            results.append(version)
            sys.stdout.write('.')
            sys.stdout.flush()
    except urllib.error.HTTPError as e:
        sys.stdout.write('E')
        sys.stdout.flush()
    except urllib.error.URLError as e:
        sys.stdout.write('X')
        sys.stdout.flush()
    
    # Esperar un poco entre peticiones
    time.sleep(0.1)

# Contar resultados
counter = Counter(results)
version_a_count = counter.get('A', 0)
version_b_count = counter.get('B', 0)

# Calcular porcentajes
version_a_percentage = (version_a_count / num_requests) * 100
version_b_percentage = (version_b_count / num_requests) * 100

print('\n\nResultados:')
print(f'Versión A: {version_a_count} peticiones ({version_a_percentage:.2f}%)')
print(f'Versión B: {version_b_count} peticiones ({version_b_percentage:.2f}%)')
EOF

# Ejecutar script Python
echo "Probando despliegue canary con $NUM_REQUESTS peticiones..."
python3 /tmp/test_canary.py

# Limpiar
rm -f /tmp/test_canary.py

echo ""
echo "=== Prueba de despliegue canary completada ==="
echo ""
