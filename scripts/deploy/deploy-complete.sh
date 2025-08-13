#!/bin/bash
#
# Script para desplegar todos los archivos WAR necesarios
#

set -e

echo "=== Desplegando archivos WAR para estrategias completas ==="
echo ""

# Verificar si los contenedores están en ejecución
if ! docker ps | grep -q weblogic-a; then
    echo "Error: El contenedor weblogic-a no está en ejecución"
    echo "Por favor, inicie los contenedores con:"
    echo "  ./start-all.sh"
    exit 1
fi

if ! docker ps | grep -q weblogic-b; then
    echo "Error: El contenedor weblogic-b no está en ejecución"
    echo "Por favor, inicie los contenedores con:"
    echo "  ./start-all.sh"
    exit 1
fi

# Función para desplegar un archivo WAR
deploy_war() {
    local war_file=$1
    local war_name=$(basename $war_file .war)
    
    echo "Desplegando $war_file..."
    
    # Copiar el archivo WAR al directorio autodeploy de ambos contenedores
    docker cp $war_file weblogic-a:/u01/oracle/user_projects/domains/base_domain/autodeploy/
    docker cp $war_file weblogic-b:/u01/oracle/user_projects/domains/base_domain/autodeploy/
    
    echo "Archivo $war_file desplegado en el directorio autodeploy"
    echo "Esperando a que WebLogic lo despliegue..."
    sleep 5
    
    echo "Despliegue de $war_name completado"
    echo ""
}

# Desplegar versiones A y B para Canary (weblogic-features)
echo "Desplegando versiones A y B para Canary (weblogic-features)..."
if [ -f "deploy/weblogic-features-a.war" ]; then
    deploy_war deploy/weblogic-features-a.war
else
    echo "Error: No se encontró el archivo deploy/weblogic-features-a.war"
    echo "Por favor, construya el archivo WAR con:"
    echo "  ./scripts/build/create-simple-wars.sh weblogic-features-a"
    exit 1
fi

if [ -f "deploy/weblogic-features-b.war" ]; then
    deploy_war deploy/weblogic-features-b.war
else
    echo "Error: No se encontró el archivo deploy/weblogic-features-b.war"
    echo "Por favor, construya el archivo WAR con:"
    echo "  ./scripts/build/create-simple-wars.sh weblogic-features-b"
    exit 1
fi

# Desplegar versiones A y B para Canary (version)
echo "Desplegando versiones A y B para Canary (version)..."
if [ -f "deploy/version-a.war" ]; then
    deploy_war deploy/version-a.war
else
    echo "Error: No se encontró el archivo deploy/version-a.war"
    echo "Por favor, construya el archivo WAR con:"
    echo "  ./scripts/build/create-simple-wars.sh version-a"
    exit 1
fi

if [ -f "deploy/version-b.war" ]; then
    deploy_war deploy/version-b.war
else
    echo "Error: No se encontró el archivo deploy/version-b.war"
    echo "Por favor, construya el archivo WAR con:"
    echo "  ./scripts/build/create-simple-wars.sh version-b"
    exit 1
fi

# Desplegar Feature Flags
echo "Desplegando Feature Flags..."
if [ -f "deploy/feature-flags.war" ]; then
    deploy_war deploy/feature-flags.war
else
    echo "Error: No se encontró el archivo deploy/feature-flags.war"
    echo "Por favor, construya el archivo WAR con:"
    echo "  ./scripts/build/create-simple-wars.sh feature-flags"
    exit 1
fi

echo ""
echo "=== Despliegue completado ==="
echo ""
echo "Para acceder a las aplicaciones desplegadas:"
echo "  - Feature Flags: http://localhost:8001/feature-flags/"
echo "  - Versión A (weblogic-features): http://localhost:8001/weblogic-features-a/"
echo "  - Versión B (weblogic-features): http://localhost:8001/weblogic-features-b/"
echo "  - Versión A (version): http://localhost:8001/version-a/"
echo "  - Versión B (version): http://localhost:8001/version-b/"
echo ""
