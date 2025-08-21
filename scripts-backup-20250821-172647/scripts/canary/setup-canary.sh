#!/bin/bash
#
# Script para configurar el despliegue canary
#

set -e

echo "=== Configurando despliegue canary ==="
echo ""

# Verificar si se proporcionó un porcentaje
if [ $# -eq 0 ]; then
    PERCENTAGE=10
    echo "No se proporcionó un porcentaje, usando el valor por defecto: $PERCENTAGE%"
else
    PERCENTAGE=$1
    
    # Verificar si el porcentaje es un número entre 0 y 100
    if ! [[ "$PERCENTAGE" =~ ^[0-9]+$ ]] || [ "$PERCENTAGE" -lt 0 ] || [ "$PERCENTAGE" -gt 100 ]; then
        echo "Error: El porcentaje debe ser un número entre 0 y 100"
        exit 1
    fi
    
    echo "Usando el porcentaje proporcionado: $PERCENTAGE%"
fi

# Verificar si el contenedor está en ejecución
if ! docker ps | grep -q weblogic-feature-flags; then
    echo "Error: El contenedor weblogic-feature-flags no está en ejecución"
    echo "Por favor, inicie el contenedor con:"
    echo "  docker-compose -f config/docker-compose.yml up -d"
    exit 1
fi

# Verificar si las aplicaciones están desplegadas
echo "Verificando si las aplicaciones están desplegadas..."

# Desplegar las aplicaciones si no están desplegadas
./scripts/deploy/deploy-war.sh --canary

# Configurar el porcentaje de tráfico
echo "Configurando el porcentaje de tráfico a $PERCENTAGE%..."

# Crear un archivo de configuración para el porcentaje de tráfico
echo "$PERCENTAGE" > /tmp/canary-percentage.txt

echo ""
echo "=== Configuración de despliegue canary completada ==="
echo ""
echo "Porcentaje de tráfico a la versión B: $PERCENTAGE%"
echo ""
echo "Para probar el despliegue canary, ejecute:"
echo "  ./scripts/canary/test-canary.sh [número-peticiones]"
echo ""
