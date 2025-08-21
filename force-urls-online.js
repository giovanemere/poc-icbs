// Script para forzar que todas las URLs aparezcan como online
// Ejecutar en la consola del navegador

console.log('🔧 Forzando URLs como online...');

// Establecer estado online para todas las URLs
window.urlHealthStatus = {
    'version-a': 'online',
    'version-b': 'online', 
    'feature-flags': 'online',
    'weblogic-a': 'online',
    'weblogic-b': 'online'
};

// Función para actualizar estado visual
function forceUpdateURLs() {
    const urls = ['version-a', 'version-b', 'feature-flags', 'weblogic-a', 'weblogic-b'];
    
    urls.forEach(urlKey => {
        // Actualizar indicador de estado
        const statusIndicator = document.getElementById(`status-${urlKey}`);
        if (statusIndicator) {
            statusIndicator.className = 'status-indicator status-online';
            console.log(`✅ ${urlKey}: Indicador actualizado a online`);
        }
        
        // Actualizar texto de salud
        const healthSpan = document.getElementById(`health-${urlKey}`);
        if (healthSpan) {
            healthSpan.textContent = 'Online';
            console.log(`✅ ${urlKey}: Texto actualizado a Online`);
        }
        
        // Actualizar tarjeta
        const urlCard = document.getElementById(`url-${urlKey}`);
        if (urlCard) {
            // Determinar clase basada en porcentaje de tráfico
            const percentage = window.getTrafficPercentage ? window.getTrafficPercentage(urlKey) : 100;
            
            urlCard.classList.remove('active', 'inactive', 'partial');
            
            if (percentage >= 80) {
                urlCard.classList.add('active');
            } else if (percentage > 0) {
                urlCard.classList.add('partial');
            } else {
                urlCard.classList.add('inactive');
            }
            
            console.log(`✅ ${urlKey}: Tarjeta actualizada (${percentage}%)`);
        }
    });
}

// Ejecutar actualización
forceUpdateURLs();

// Actualizar porcentajes si la función existe
if (window.updateTrafficPercentages) {
    window.updateTrafficPercentages();
}

// Actualizar estado de despliegue si la función existe
if (window.updateDeploymentStatus) {
    window.updateDeploymentStatus();
}

console.log('✅ URLs forzadas como online');
console.log('Estado actual:', window.urlHealthStatus);
