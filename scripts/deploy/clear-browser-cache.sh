#!/bin/bash
#
# Script para generar una página HTML que ayuda a limpiar la caché del navegador
#

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Generando página para limpiar caché del navegador ===${NC}"

# Crear directorio si no existe
mkdir -p deploy/cache-cleaner

# Crear archivo HTML
cat > deploy/cache-cleaner/clear-cache.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Limpiador de Caché</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
        }
        h1 {
            color: #2196F3;
            border-bottom: 2px solid #2196F3;
            padding-bottom: 10px;
        }
        .card {
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .card h2 {
            margin-top: 0;
            color: #2196F3;
        }
        .btn {
            display: inline-block;
            background-color: #2196F3;
            color: white;
            padding: 10px 15px;
            border-radius: 4px;
            text-decoration: none;
            margin-right: 10px;
            margin-bottom: 10px;
            cursor: pointer;
            border: none;
            font-size: 16px;
        }
        .btn:hover {
            background-color: #0b7dda;
        }
        .btn-danger {
            background-color: #f44336;
        }
        .btn-danger:hover {
            background-color: #d32f2f;
        }
        .btn-success {
            background-color: #4CAF50;
        }
        .btn-success:hover {
            background-color: #388E3C;
        }
        .btn-warning {
            background-color: #FF9800;
        }
        .btn-warning:hover {
            background-color: #F57C00;
        }
        .instructions {
            background-color: #f9f9f9;
            padding: 15px;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        .instructions h3 {
            margin-top: 0;
        }
        .instructions ul {
            padding-left: 20px;
        }
        .result {
            margin-top: 20px;
            padding: 15px;
            border-radius: 4px;
            display: none;
        }
        .success {
            background-color: #dff0d8;
            color: #3c763d;
        }
        .error {
            background-color: #f2dede;
            color: #a94442;
        }
        .warning {
            background-color: #fcf8e3;
            color: #8a6d3b;
        }
        .tabs {
            display: flex;
            margin-bottom: 20px;
            border-bottom: 1px solid #ddd;
        }
        .tab {
            padding: 10px 15px;
            cursor: pointer;
            border: 1px solid transparent;
            border-bottom: none;
            margin-right: 5px;
            border-radius: 4px 4px 0 0;
        }
        .tab.active {
            border-color: #ddd;
            background-color: white;
            border-bottom: 1px solid white;
            margin-bottom: -1px;
        }
        .tab-content {
            display: none;
        }
        .tab-content.active {
            display: block;
        }
        .browser-icon {
            width: 24px;
            height: 24px;
            vertical-align: middle;
            margin-right: 5px;
        }
        .flex-container {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
        }
        .flex-item {
            flex: 1 1 300px;
        }
        @media (max-width: 600px) {
            .flex-container {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <h1>Limpiador de Caché para WebLogic</h1>
    
    <div class="card">
        <h2>Limpiar Caché del Navegador</h2>
        <p>Esta herramienta te ayudará a limpiar la caché de tu navegador para asegurar que estás viendo la versión más reciente de las aplicaciones.</p>
        
        <div class="tabs">
            <div class="tab active" data-tab="automatic">Limpieza Automática</div>
            <div class="tab" data-tab="manual">Instrucciones Manuales</div>
            <div class="tab" data-tab="advanced">Opciones Avanzadas</div>
        </div>
        
        <div class="tab-content active" id="automatic">
            <p>Haz clic en el botón para intentar limpiar la caché automáticamente:</p>
            <button id="clearCacheBtn" class="btn btn-danger">Limpiar Caché Ahora</button>
            <button id="reloadBtn" class="btn btn-success">Recargar Aplicaciones</button>
            
            <div id="cacheResult" class="result"></div>
        </div>
        
        <div class="tab-content" id="manual">
            <div class="instructions">
                <h3>Chrome</h3>
                <ul>
                    <li>Presiona <strong>Ctrl+Shift+Delete</strong> (Windows/Linux) o <strong>Cmd+Shift+Delete</strong> (Mac)</li>
                    <li>Selecciona "Cookies y datos de sitios" y "Imágenes y archivos almacenados en caché"</li>
                    <li>Haz clic en "Borrar datos"</li>
                </ul>
            </div>
            
            <div class="instructions">
                <h3>Firefox</h3>
                <ul>
                    <li>Presiona <strong>Ctrl+Shift+Delete</strong> (Windows/Linux) o <strong>Cmd+Shift+Delete</strong> (Mac)</li>
                    <li>Selecciona "Cookies" y "Caché"</li>
                    <li>Haz clic en "Limpiar ahora"</li>
                </ul>
            </div>
            
            <div class="instructions">
                <h3>Safari</h3>
                <ul>
                    <li>Ve a Safari > Preferencias > Avanzado</li>
                    <li>Marca "Mostrar menú Desarrollo en la barra de menús"</li>
                    <li>Ve a Desarrollo > Vaciar cachés</li>
                </ul>
            </div>
            
            <div class="instructions">
                <h3>Edge</h3>
                <ul>
                    <li>Presiona <strong>Ctrl+Shift+Delete</strong></li>
                    <li>Selecciona "Cookies y datos guardados" y "Archivos e imágenes en caché"</li>
                    <li>Haz clic en "Borrar ahora"</li>
                </ul>
            </div>
        </div>
        
        <div class="tab-content" id="advanced">
            <h3>Opciones Avanzadas de Limpieza</h3>
            
            <div class="flex-container">
                <div class="flex-item">
                    <div class="card">
                        <h3>Limpiar por Aplicación</h3>
                        <p>Selecciona la aplicación específica para limpiar su caché:</p>
                        <button class="btn" onclick="clearAppCache('feature-flags')">Feature Flags</button>
                        <button class="btn" onclick="clearAppCache('ff4j-simple')">FF4J Simple</button>
                        <button class="btn" onclick="clearAppCache('version-a')">Versión A</button>
                        <button class="btn" onclick="clearAppCache('version-b')">Versión B</button>
                        <button class="btn" onclick="clearAppCache('weblogic-features-a')">WebLogic Features A</button>
                        <button class="btn" onclick="clearAppCache('weblogic-features-b')">WebLogic Features B</button>
                    </div>
                </div>
                
                <div class="flex-item">
                    <div class="card">
                        <h3>Limpiar Cookies</h3>
                        <p>Limpiar cookies específicas:</p>
                        <button class="btn btn-warning" onclick="clearSpecificCookies(['ab_test'])">Cookies de A/B Testing</button>
                        <button class="btn btn-warning" onclick="clearSpecificCookies(['canary'])">Cookies de Canary</button>
                        <button class="btn btn-danger" onclick="clearAllCookies()">Todas las Cookies</button>
                    </div>
                </div>
            </div>
            
            <div id="advancedResult" class="result"></div>
        </div>
    </div>
    
    <div class="card">
        <h2>Acceso a Aplicaciones</h2>
        <p>Accede a las aplicaciones desplegadas:</p>
        
        <a href="http://localhost:8080/feature-flags/" target="_blank" class="btn">Feature Flags</a>
        <a href="http://localhost:8080/ff4j-simple/" target="_blank" class="btn">FF4J Simple</a>
        <a href="http://localhost:8080/version-a/" target="_blank" class="btn">Versión A</a>
        <a href="http://localhost:8080/version-b/" target="_blank" class="btn">Versión B</a>
        <a href="http://localhost:8080/weblogic-features-a/" target="_blank" class="btn">WebLogic Features A</a>
        <a href="http://localhost:8080/weblogic-features-b/" target="_blank" class="btn">WebLogic Features B</a>
    </div>
    
    <script>
        // Función para cambiar entre pestañas
        document.querySelectorAll('.tab').forEach(tab => {
            tab.addEventListener('click', function() {
                // Desactivar todas las pestañas
                document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
                document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
                
                // Activar la pestaña seleccionada
                this.classList.add('active');
                document.getElementById(this.dataset.tab).classList.add('active');
            });
        });
        
        // Función para limpiar la caché
        document.getElementById('clearCacheBtn').addEventListener('click', function() {
            const resultDiv = document.getElementById('cacheResult');
            resultDiv.style.display = 'block';
            
            try {
                // Limpiar caché de navegación
                if ('caches' in window) {
                    caches.keys().then(cacheNames => {
                        return Promise.all(
                            cacheNames.map(cacheName => {
                                return caches.delete(cacheName);
                            })
                        );
                    }).then(() => {
                        resultDiv.className = 'result success';
                        resultDiv.innerHTML = '✅ Caché limpiada correctamente. Para asegurar que los cambios se apliquen, recarga las páginas de las aplicaciones.';
                    }).catch(error => {
                        resultDiv.className = 'result error';
                        resultDiv.innerHTML = '❌ Error al limpiar la caché: ' + error.message;
                    });
                } else {
                    // Alternativa para navegadores que no soportan la API Cache
                    localStorage.clear();
                    sessionStorage.clear();
                    
                    // Limpiar cookies
                    document.cookie.split(";").forEach(function(c) {
                        document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
                    });
                    
                    resultDiv.className = 'result warning';
                    resultDiv.innerHTML = '⚠️ Tu navegador no soporta la API Cache. Se han limpiado cookies y almacenamiento local. Para mejores resultados, limpia la caché manualmente siguiendo las instrucciones.';
                }
            } catch (error) {
                resultDiv.className = 'result error';
                resultDiv.innerHTML = '❌ Error al limpiar la caché: ' + error.message;
            }
        });
        
        // Función para recargar aplicaciones
        document.getElementById('reloadBtn').addEventListener('click', function() {
            const resultDiv = document.getElementById('cacheResult');
            resultDiv.style.display = 'block';
            resultDiv.className = 'result warning';
            resultDiv.innerHTML = '⏳ Recargando aplicaciones...';
            
            // Lista de aplicaciones a recargar
            const apps = [
                'feature-flags',
                'ff4j-simple',
                'version-a',
                'version-b',
                'weblogic-features-a',
                'weblogic-features-b'
            ];
            
            // Recargar cada aplicación en un iframe oculto
            let loadedCount = 0;
            
            apps.forEach(app => {
                const iframe = document.createElement('iframe');
                iframe.style.display = 'none';
                iframe.src = `http://localhost:8080/${app}/?nocache=${new Date().getTime()}`;
                
                iframe.onload = function() {
                    loadedCount++;
                    if (loadedCount === apps.length) {
                        resultDiv.className = 'result success';
                        resultDiv.innerHTML = '✅ Todas las aplicaciones han sido recargadas correctamente.';
                    }
                };
                
                iframe.onerror = function() {
                    loadedCount++;
                    if (loadedCount === apps.length) {
                        resultDiv.className = 'result warning';
                        resultDiv.innerHTML = '⚠️ Algunas aplicaciones no pudieron ser recargadas. Intenta acceder a ellas manualmente.';
                    }
                };
                
                document.body.appendChild(iframe);
                
                // Eliminar el iframe después de un tiempo
                setTimeout(() => {
                    document.body.removeChild(iframe);
                }, 5000);
            });
        });
        
        // Función para limpiar caché de una aplicación específica
        function clearAppCache(appName) {
            const resultDiv = document.getElementById('advancedResult');
            resultDiv.style.display = 'block';
            
            try {
                if ('caches' in window) {
                    caches.keys().then(cacheNames => {
                        const appCaches = cacheNames.filter(cacheName => cacheName.includes(appName));
                        return Promise.all(
                            appCaches.map(cacheName => {
                                return caches.delete(cacheName);
                            })
                        );
                    }).then(() => {
                        resultDiv.className = 'result success';
                        resultDiv.innerHTML = `✅ Caché de ${appName} limpiada correctamente.`;
                    }).catch(error => {
                        resultDiv.className = 'result error';
                        resultDiv.innerHTML = '❌ Error al limpiar la caché: ' + error.message;
                    });
                } else {
                    resultDiv.className = 'result warning';
                    resultDiv.innerHTML = '⚠️ Tu navegador no soporta la API Cache. Para mejores resultados, limpia la caché manualmente.';
                }
            } catch (error) {
                resultDiv.className = 'result error';
                resultDiv.innerHTML = '❌ Error al limpiar la caché: ' + error.message;
            }
        }
        
        // Función para limpiar cookies específicas
        function clearSpecificCookies(cookieNames) {
            const resultDiv = document.getElementById('advancedResult');
            resultDiv.style.display = 'block';
            
            try {
                cookieNames.forEach(cookieName => {
                    document.cookie = `${cookieName}=;expires=${new Date(0).toUTCString()};path=/`;
                });
                
                resultDiv.className = 'result success';
                resultDiv.innerHTML = `✅ Cookies [${cookieNames.join(', ')}] eliminadas correctamente.`;
            } catch (error) {
                resultDiv.className = 'result error';
                resultDiv.innerHTML = '❌ Error al eliminar cookies: ' + error.message;
            }
        }
        
        // Función para limpiar todas las cookies
        function clearAllCookies() {
            const resultDiv = document.getElementById('advancedResult');
            resultDiv.style.display = 'block';
            
            try {
                document.cookie.split(";").forEach(function(c) {
                    document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
                });
                
                resultDiv.className = 'result success';
                resultDiv.innerHTML = '✅ Todas las cookies han sido eliminadas correctamente.';
            } catch (error) {
                resultDiv.className = 'result error';
                resultDiv.innerHTML = '❌ Error al eliminar cookies: ' + error.message;
            }
        }
    </script>
</body>
</html>
EOF

# Crear un script para abrir la página en el navegador
cat > deploy/cache-cleaner/open-cleaner.sh << 'EOF'
#!/bin/bash

# Detectar el sistema operativo
case "$(uname -s)" in
    Linux*)     
        xdg-open clear-cache.html
        ;;
    Darwin*)    
        open clear-cache.html
        ;;
    CYGWIN*|MINGW*|MSYS*)
        start clear-cache.html
        ;;
    *)
        echo "No se pudo detectar el sistema operativo. Por favor, abre manualmente el archivo clear-cache.html"
        ;;
esac
EOF

# Dar permisos de ejecución
chmod +x deploy/cache-cleaner/open-cleaner.sh

echo -e "${GREEN}Página de limpieza de caché generada correctamente${NC}"
echo -e "La página está disponible en: ${YELLOW}deploy/cache-cleaner/clear-cache.html${NC}"
echo -e "Para abrirla, ejecuta: ${YELLOW}cd deploy/cache-cleaner && ./open-cleaner.sh${NC}"
echo ""
