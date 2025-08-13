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
echo "=== Copiando WAR a autodeploy/ para despliegue automático ==="
echo ""

# Copiar archivos WAR a autodeploy para despliegue automático en WebLogic
cp deploy/*.war autodeploy/

echo "✓ Archivos WAR copiados a autodeploy/"
echo ""
echo "Archivos en autodeploy/:"
ls -lh autodeploy/*.war

echo ""
echo "=== Proceso Completado ==="
echo ""
echo "Los archivos WAR están listos para despliegue automático en WebLogic."
echo ""
echo "Próximos pasos:"
echo "1. Iniciar los contenedores: ./start-all.sh"
echo "2. WebLogic detectará automáticamente los WAR en autodeploy/"
echo "3. Verificar despliegue en las consolas de administración:"
echo "   - WebLogic A: http://localhost:7001/console"
echo "   - WebLogic B: http://localhost:7002/console"
echo ""
