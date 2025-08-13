#!/bin/bash
#
# Script para crear archivos WAR simples
#

set -e

# Verificar si se proporcionó un nombre
if [ $# -eq 0 ]; then
    echo "Error: No se proporcionó un nombre para el archivo WAR"
    echo "Uso: $0 [nombre-aplicacion]"
    exit 1
fi

APP_NAME=$1
TEMP_DIR=$(mktemp -d)
WAR_DIR="$TEMP_DIR/$APP_NAME"

echo "=== Creando archivo WAR simple: $APP_NAME ==="
echo ""

# Crear estructura de directorios
mkdir -p "$WAR_DIR/WEB-INF/classes/com/icbs/weblogic"

# Crear web.xml
cat > "$WAR_DIR/WEB-INF/web.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-app_3_1.xsd"
         version="3.1">
    
    <display-name>$APP_NAME</display-name>
    
    <welcome-file-list>
        <welcome-file>index.html</welcome-file>
    </welcome-file-list>
</web-app>
EOF

# Crear index.html
if [[ "$APP_NAME" == *"-a" ]]; then
    VERSION="A"
    COLOR="#4CAF50"  # Verde
    HOVER_COLOR="#45a049"
elif [[ "$APP_NAME" == *"-b" ]]; then
    VERSION="B"
    COLOR="#2196F3"  # Azul
    HOVER_COLOR="#0b7dda"
else
    VERSION=""
    COLOR="#ff9800"  # Naranja
    HOVER_COLOR="#e68a00"
fi

# Crear index.html
cat > "$WAR_DIR/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$APP_NAME</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            line-height: 1.6;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 5px;
            background-color: ${COLOR}10;
        }
        h1 {
            color: $COLOR;
        }
        .version {
            display: inline-block;
            padding: 5px 10px;
            background-color: $COLOR;
            color: white;
            border-radius: 4px;
            font-weight: bold;
        }
        .links {
            margin-top: 20px;
        }
        .links a {
            display: inline-block;
            margin-right: 10px;
            padding: 10px 15px;
            background-color: $COLOR;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .links a:hover {
            background-color: $HOVER_COLOR;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$APP_NAME</h1>
        
        <p>Esta es una aplicación de ejemplo para Oracle WebLogic Server.</p>
        
        <p>Versión: <span class="version">${VERSION}</span></p>
        
        <p>Fecha de construcción: $(date)</p>
        
        <div class="links">
            <a href="info.html">Información</a>
        </div>
    </div>
</body>
</html>
EOF

# Crear info.html
cat > "$WAR_DIR/info.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Información</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            line-height: 1.6;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 5px;
            background-color: ${COLOR}10;
        }
        h1 {
            color: $COLOR;
        }
        .back {
            display: inline-block;
            margin-top: 20px;
            padding: 10px 15px;
            background-color: $COLOR;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .back:hover {
            background-color: $HOVER_COLOR;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Información</h1>
        
        <p>Esta es una aplicación de ejemplo para Oracle WebLogic Server.</p>
        
        <p>Aplicación: <strong>$APP_NAME</strong></p>
        
        <p>Esta aplicación se utiliza para demostrar el despliegue de aplicaciones en Oracle WebLogic Server.</p>
        
        <a href="index.html" class="back">Volver</a>
    </div>
</body>
</html>
EOF

# Crear archivo WAR
echo "Creando archivo WAR..."
mkdir -p war-projects/$APP_NAME
cp -r $WAR_DIR/* war-projects/$APP_NAME/

mkdir -p deploy
cd $TEMP_DIR
jar -cf $APP_NAME.war -C $APP_NAME .
cp $APP_NAME.war /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/deploy/
cd - > /dev/null

# Limpiar
rm -rf $TEMP_DIR

echo ""
echo "=== Creación de $APP_NAME.war completada ==="
echo ""
echo "El archivo WAR se encuentra en deploy/$APP_NAME.war"
echo ""
