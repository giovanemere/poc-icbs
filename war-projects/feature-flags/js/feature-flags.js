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
