#!/bin/bash
#
# Script para construir los archivos WAR
#

set -e

echo "=== Construyendo archivos WAR ==="
echo ""

# Crear directorio de despliegue si no existe
mkdir -p deploy

# Construir Feature Flags
echo "Construyendo Feature Flags..."
if [ -f "./scripts/build/build-feature-flags.sh" ]; then
    ./scripts/build/build-feature-flags.sh
else
    echo "Advertencia: No se encontró el script build-feature-flags.sh"
    echo "Creando un WAR simple para feature-flags..."
    ./scripts/deploy/create-simple-feature-flags.sh
fi

# Construir versiones A y B para pruebas A/B
echo "Construyendo versiones A y B para pruebas A/B..."
./scripts/build/create-simple-wars.sh version-a
./scripts/build/create-simple-wars.sh version-b

# Construir versiones A y B para Canary
echo "Construyendo versiones A y B para Canary..."
./scripts/build/create-simple-wars.sh weblogic-features-a
./scripts/build/create-simple-wars.sh weblogic-features-b

# Construir FF4J Simple
echo "Construyendo FF4J Simple..."
./scripts/build/create-simple-wars.sh ff4j-simple

echo ""
echo "=== Construcción de WARs completada ==="
echo ""
echo "Los archivos WAR se encuentran en el directorio deploy/"
echo ""
ls -la deploy/
echo ""
