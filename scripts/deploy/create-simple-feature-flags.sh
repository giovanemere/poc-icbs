#!/bin/bash
# Script para crear una versión simple de feature-flags

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directorio del proyecto
ROOT_DIR="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"
TEMP_DIR=$(mktemp -d)
WAR_DIR="$TEMP_DIR/feature-flags"

echo -e "${YELLOW}Creando una versión simple de feature-flags...${NC}"

# Crear estructura de directorios
mkdir -p "$WAR_DIR/WEB-INF/classes/com/icbs/weblogic/ff4j"
mkdir -p "$WAR_DIR/js"

# Copiar archivos existentes del proyecto
if [ -d "$ROOT_DIR/war-projects/feature-flags" ]; then
    cp -r "$ROOT_DIR/war-projects/feature-flags/index.html" "$WAR_DIR/" 2>/dev/null || true
    cp -r "$ROOT_DIR/war-projects/feature-flags/info.html" "$WAR_DIR/" 2>/dev/null || true
    cp -r "$ROOT_DIR/war-projects/feature-flags/admin.html" "$WAR_DIR/" 2>/dev/null || true
    cp -r "$ROOT_DIR/war-projects/feature-flags/js" "$WAR_DIR/" 2>/dev/null || true
fi

# Crear web.xml si no existe
if [ ! -f "$WAR_DIR/WEB-INF/web.xml" ]; then
    cat > "$WAR_DIR/WEB-INF/web.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-app_3_1.xsd"
         version="3.1">
    
    <display-name>Feature Flags</display-name>
    
    <welcome-file-list>
        <welcome-file>index.html</welcome-file>
    </welcome-file-list>
</web-app>
EOF
fi

# Crear index.html si no existe
if [ ! -f "$WAR_DIR/index.html" ]; then
    cat > "$WAR_DIR/index.html" << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Feature Flags - Control de Versiones</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            line-height: 1.6;
            color: #333;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 5px;
            background-color: #f9f9f9;
        }
        h1 {
            color: #2196F3;
        }
        .feature {
            margin-bottom: 20px;
            padding: 15px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .feature-enabled {
            background-color: #e6f7ff;
            border-color: #91d5ff;
        }
        .feature-disabled {
            background-color: #fff1f0;
            border-color: #ffa39e;
        }
        .toggle {
            display: inline-block;
            width: 60px;
            height: 34px;
            position: relative;
            margin-right: 10px;
        }
        .toggle input {
            opacity: 0;
            width: 0;
            height: 0;
        }
        .slider {
            position: absolute;
            cursor: pointer;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: #ccc;
            transition: .4s;
            border-radius: 34px;
        }
        .slider:before {
            position: absolute;
            content: "";
            height: 26px;
            width: 26px;
            left: 4px;
            bottom: 4px;
            background-color: white;
            transition: .4s;
            border-radius: 50%;
        }
        input:checked + .slider {
            background-color: #2196F3;
        }
        input:checked + .slider:before {
            transform: translateX(26px);
        }
        .links {
            margin-top: 20px;
        }
        .links a {
            display: inline-block;
            margin-right: 10px;
            margin-bottom: 10px;
            padding: 10px 15px;
            background-color: #2196F3;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }
        .links a:hover {
            background-color: #0b7dda;
        }
        .version-a {
            background-color: #4CAF50;
        }
        .version-a:hover {
            background-color: #45a049;
        }
        .version-b {
            background-color: #FF9800;
        }
        .version-b:hover {
            background-color: #e68a00;
        }
        .version-info {
            margin-top: 20px;
            padding: 15px;
            background-color: #f0f0f0;
            border-radius: 4px;
        }
        .current-version {
            font-weight: bold;
            color: #2196F3;
        }
        .btn-redirect {
            background-color: #FF5722;
        }
        .btn-redirect:hover {
            background-color: #e64a19;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Feature Flags - Control de Versiones</h1>
        
        <p>Esta aplicación permite controlar las características y versiones de la aplicación.</p>
        
        <div class="version-info">
            <h2>Control de Versiones A/B</h2>
            <p>Versión actual: <span class="current-version" id="currentVersion">A</span></p>
            <p>
                <strong>Versión A URL:</strong> <a href="http://localhost:8080/version-a/" target="_blank">http://localhost:8080/version-a/</a><br>
                <strong>Versión B URL:</strong> <a href="http://localhost:8080/version-b/" target="_blank">http://localhost:8080/version-b/</a>
            </p>
        </div>
        
        <div class="feature feature-enabled">
            <h2>
                <label class="toggle">
                    <input type="checkbox" id="toggle-new-ui" checked>
                    <span class="slider"></span>
                </label>
                Nuevo Diseño de UI
            </h2>
            <p>Habilita el nuevo diseño de interfaz de usuario (Versión B).</p>
        </div>
        
        <div class="feature feature-disabled">
            <h2>
                <label class="toggle">
                    <input type="checkbox" id="toggle-version-b">
                    <span class="slider"></span>
                </label>
                Versión B
            </h2>
            <p>Activa la versión B (desactivado = versión A).</p>
        </div>
        
        <div class="links">
            <a href="http://localhost:8080/version-a/" class="version-a" target="_blank">Ver Versión A</a>
            <a href="http://localhost:8080/version-b/" class="version-b" target="_blank">Ver Versión B</a>
            <a href="#" class="btn-redirect" id="btnRedirect">Ir a Versión con Nuevo Diseño</a>
            <a href="admin.html">Administración</a>
            <a href="info.html">Información</a>
        </div>
    </div>
    
    <script>
        // Función para redirigir a la versión con nuevo diseño (Versión B)
        document.getElementById('btnRedirect').addEventListener('click', function(e) {
            e.preventDefault();
            window.location.href = 'http://localhost:8080/version-b/';
        });
        
        // Función para cambiar entre versiones
        document.getElementById('toggle-version-b').addEventListener('change', function() {
            const currentVersion = document.getElementById('currentVersion');
            const feature = this.closest('.feature');
            
            if (this.checked) {
                currentVersion.textContent = 'B';
                feature.classList.remove('feature-disabled');
                feature.classList.add('feature-enabled');
                // En una aplicación real, esto enviaría una solicitud al backend
                console.log('Cambiando a Versión B');
            } else {
                currentVersion.textContent = 'A';
                feature.classList.remove('feature-enabled');
                feature.classList.add('feature-disabled');
                // En una aplicación real, esto enviaría una solicitud al backend
                console.log('Cambiando a Versión A');
            }
        });
        
        // Función para el toggle de nuevo diseño UI
        document.getElementById('toggle-new-ui').addEventListener('change', function() {
            const feature = this.closest('.feature');
            
            if (this.checked) {
                feature.classList.remove('feature-disabled');
                feature.classList.add('feature-enabled');
                // En una aplicación real, esto enviaría una solicitud al backend
                console.log('Nuevo diseño UI habilitado');
                
                // Redirigir a la versión B que tiene el nuevo diseño
                setTimeout(() => {
                    if (confirm('¿Desea ver el nuevo diseño de UI en la Versión B?')) {
                        window.location.href = 'http://localhost:8080/version-b/';
                    }
                }, 500);
            } else {
                feature.classList.remove('feature-enabled');
                feature.classList.add('feature-disabled');
                // En una aplicación real, esto enviaría una solicitud al backend
                console.log('Nuevo diseño UI deshabilitado');
            }
        });
    </script>
</body>
</html>
EOF
fi

# Crear js/feature-flags.js si no existe
if [ ! -f "$WAR_DIR/js/feature-flags.js" ]; then
    mkdir -p "$WAR_DIR/js"
    cat > "$WAR_DIR/js/feature-flags.js" << EOF
/**
 * Feature Flags - Control de versiones
 * 
 * Este script maneja la lógica para controlar las características y versiones
 * de la aplicación mediante feature flags.
 */

// Configuración de las URLs
const CONFIG = {
    versionA: 'http://localhost:8080/version-a/',
    versionB: 'http://localhost:8080/version-b/',
    apiUrl: '/api/version-switch'
};

// Estado actual de las características
let featureState = {
    newUiDesign: true,
    versionB: false,
    darkMode: false,
    advancedDashboard: false,
    realTimeNotifications: false
};

/**
 * Inicializa los controles de feature flags
 */
function initFeatureFlags() {
    // Cargar estado actual desde el servidor (simulado)
    fetchFeatureState();
    
    // Configurar event listeners para los toggles
    setupEventListeners();
}

/**
 * Configura los event listeners para los toggles de características
 */
function setupEventListeners() {
    // Toggle para nuevo diseño UI
    const newUiToggle = document.getElementById('toggle-new-ui');
    if (newUiToggle) {
        newUiToggle.addEventListener('change', function() {
            toggleFeature('newUiDesign', this.checked);
            
            // Si se activa el nuevo diseño, preguntar si quiere ver la versión B
            if (this.checked) {
                setTimeout(() => {
                    if (confirm('¿Desea ver el nuevo diseño de UI en la Versión B?')) {
                        window.location.href = CONFIG.versionB;
                    }
                }, 500);
            }
        });
    }
    
    // Toggle para versión B
    const versionBToggle = document.getElementById('toggle-version-b');
    if (versionBToggle) {
        versionBToggle.addEventListener('change', function() {
            toggleFeature('versionB', this.checked);
            updateCurrentVersion(this.checked ? 'B' : 'A');
        });
    }
    
    // Botón de redirección a versión con nuevo diseño
    const redirectButton = document.getElementById('btnRedirect');
    if (redirectButton) {
        redirectButton.addEventListener('click', function(e) {
            e.preventDefault();
            window.location.href = CONFIG.versionB;
        });
    }
}

/**
 * Actualiza el estado de una característica
 * @param {string} feature - Nombre de la característica
 * @param {boolean} enabled - Estado de la característica (true = habilitada, false = deshabilitada)
 */
function toggleFeature(feature, enabled) {
    featureState[feature] = enabled;
    
    // Actualizar la UI
    const featureElement = document.querySelector(`.feature:has(#toggle-${feature.replace(/([A-Z])/g, '-$1').toLowerCase()})`);
    if (featureElement) {
        if (enabled) {
            featureElement.classList.remove('feature-disabled');
            featureElement.classList.add('feature-enabled');
        } else {
            featureElement.classList.remove('feature-enabled');
            featureElement.classList.add('feature-disabled');
        }
    }
    
    // En una aplicación real, esto enviaría una solicitud al backend
    console.log(`Característica ${feature} ${enabled ? 'habilitada' : 'deshabilitada'}`);
    
    // Simular envío al servidor
    saveFeatureState();
}

/**
 * Actualiza la versión actual mostrada en la UI
 * @param {string} version - Versión actual ('A' o 'B')
 */
function updateCurrentVersion(version) {
    const currentVersionElement = document.getElementById('currentVersion');
    if (currentVersionElement) {
        currentVersionElement.textContent = version;
    }
}

/**
 * Simula la obtención del estado de las características desde el servidor
 */
function fetchFeatureState() {
    // En una aplicación real, esto haría una solicitud AJAX al servidor
    console.log('Obteniendo estado de características desde el servidor...');
    
    // Simular respuesta del servidor
    setTimeout(() => {
        // Actualizar toggles según el estado
        updateTogglesFromState();
    }, 300);
}

/**
 * Simula el guardado del estado de las características en el servidor
 */
function saveFeatureState() {
    // En una aplicación real, esto haría una solicitud AJAX al servidor
    console.log('Guardando estado de características en el servidor...', featureState);
}

/**
 * Actualiza los toggles en la UI según el estado actual
 */
function updateTogglesFromState() {
    // Actualizar toggle de nuevo diseño UI
    const newUiToggle = document.getElementById('toggle-new-ui');
    if (newUiToggle) {
        newUiToggle.checked = featureState.newUiDesign;
        const feature = newUiToggle.closest('.feature');
        if (feature) {
            if (featureState.newUiDesign) {
                feature.classList.remove('feature-disabled');
                feature.classList.add('feature-enabled');
            } else {
                feature.classList.remove('feature-enabled');
                feature.classList.add('feature-disabled');
            }
        }
    }
    
    // Actualizar toggle de versión B
    const versionBToggle = document.getElementById('toggle-version-b');
    if (versionBToggle) {
        versionBToggle.checked = featureState.versionB;
        const feature = versionBToggle.closest('.feature');
        if (feature) {
            if (featureState.versionB) {
                feature.classList.remove('feature-disabled');
                feature.classList.add('feature-enabled');
            } else {
                feature.classList.remove('feature-enabled');
                feature.classList.add('feature-disabled');
            }
        }
    }
    
    // Actualizar versión actual
    updateCurrentVersion(featureState.versionB ? 'B' : 'A');
}

// Inicializar cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', initFeatureFlags);
EOF
fi

# Crear archivo WAR
echo -e "${YELLOW}Creando archivo WAR...${NC}"
mkdir -p "$ROOT_DIR/war-projects/feature-flags"
cp -r $WAR_DIR/* "$ROOT_DIR/war-projects/feature-flags/"

mkdir -p "$ROOT_DIR/deploy"
cd $TEMP_DIR
jar -cf feature-flags.war -C feature-flags .
cp feature-flags.war "$ROOT_DIR/deploy/"
cd - > /dev/null

# Limpiar
rm -rf $TEMP_DIR

echo -e "${GREEN}¡Archivo feature-flags.war creado correctamente!${NC}"
echo -e "El archivo WAR se encuentra en: ${YELLOW}$ROOT_DIR/deploy/feature-flags.war${NC}"
echo ""
echo -e "${YELLOW}Para desplegar el archivo WAR, ejecuta:${NC}"
echo -e "cd $ROOT_DIR"
echo -e "./scripts/deploy/deploy-war.sh deploy/feature-flags.war"
