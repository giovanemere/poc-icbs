#!/bin/bash
#
# Script de instalación y configuración inicial del proyecto
#

set -e

echo "=== Configuración inicial del proyecto Docker para Oracle WebLogic ==="
echo ""

# Verificar requisitos
echo "Verificando requisitos..."

if ! command -v docker &> /dev/null; then
    echo "Error: Docker no está instalado. Por favor, instale Docker antes de continuar."
    exit 1
fi

if ! command -v java &> /dev/null; then
    echo "Advertencia: Java no está instalado. Se recomienda instalar Java para compilar los proyectos."
fi

if ! command -v mvn &> /dev/null; then
    echo "Advertencia: Maven no está instalado. Se recomienda instalar Maven para compilar los proyectos."
fi

# Verificar archivos necesarios
echo "Verificando archivos necesarios..."

if [ ! -f "install/fmw_14.1.1.0.0_wls_Disk1_1of1.zip" ]; then
    echo "Advertencia: No se encontró el archivo install/fmw_14.1.1.0.0_wls_Disk1_1of1.zip"
    echo "Por favor, descargue el archivo desde el sitio web de Oracle y colóquelo en el directorio install/ del proyecto."
fi

if [ ! -f "install/sqlcl-25.2.2.199.0918.zip" ]; then
    echo "Advertencia: No se encontró el archivo install/sqlcl-25.2.2.199.0918.zip"
    echo "Por favor, descargue el archivo desde el sitio web de Oracle y colóquelo en el directorio install/ del proyecto."
fi

# Crear directorios necesarios
echo "Creando directorios necesarios..."
mkdir -p autodeploy
mkdir -p deploy
mkdir -p war-projects
mkdir -p install
mkdir -p backup
mkdir -p config
mkdir -p docker
mkdir -p docs
mkdir -p references

# Configurar permisos
echo "Configurando permisos..."
chmod +x scripts/build/*.sh
chmod +x scripts/deploy/*.sh
chmod +x scripts/canary/*.sh
chmod +x container-scripts/*.sh
chmod +x run.sh

# Crear enlace simbólico a docker-compose.yml en el directorio raíz
echo "Creando enlaces simbólicos..."
ln -sf config/docker-compose.yml docker-compose.yml
ln -sf scripts/build/build.sh build.sh
ln -sf scripts/deploy/deploy-war.sh deploy-war.sh
ln -sf scripts/canary/setup-canary.sh setup-canary.sh
ln -sf scripts/canary/canary-control.sh canary-control.sh
ln -sf scripts/canary/test-canary.sh test-canary.sh

echo ""
echo "=== Configuración completada ==="
echo ""
echo "Para construir la imagen Docker, ejecute:"
echo "  ./run.sh build"
echo ""
echo "Para desplegar los archivos WAR, ejecute:"
echo "  ./run.sh deploy --all"
echo ""
echo "Para configurar el despliegue canary, ejecute:"
echo "  ./run.sh setup-canary [porcentaje]"
echo ""
echo "Para más información, consulte la documentación en el directorio docs/"
echo ""
