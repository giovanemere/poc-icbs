#!/bin/bash
#
# Script para desplegar solo los archivos WAR de weblogic-features-a y weblogic-features-b
#

set -e

echo "=== Desplegando archivos WAR de Canary en WebLogic ==="
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

# Desplegar versiones A y B para Canary
deploy_canary() {
    echo "Desplegando versiones A y B para Canary..."
    
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
    
    echo "Versiones A y B para Canary han sido desplegadas"
}

# Ejecutar el despliegue de Canary
deploy_canary

echo ""
echo "=== Despliegue completado ==="
echo ""
echo "Para acceder a las aplicaciones desplegadas:"
echo "  - Versión A: http://localhost:8001/weblogic-features-a/"
echo "  - Versión B: http://localhost:8001/weblogic-features-b/"
echo ""
