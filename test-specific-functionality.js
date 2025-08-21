// Script para probar funcionalidades específicas del Dashboard
// Ejecutar en la consola del navegador

console.log('🧪 PRUEBA ESPECÍFICA DE FUNCIONALIDADES');
console.log('=====================================');

// 1. Verificar elementos HTML
console.log('\n1. Verificando elementos HTML:');
const abToggle = document.getElementById('ab-toggle');
const abSlider = document.getElementById('ab-slider');
const canaryToggle = document.getElementById('canary-toggle');
const canarySlider = document.getElementById('canary-slider');
const trafficChart = window.trafficChart;

console.log('ab-toggle:', abToggle ? '✅ Presente' : '❌ Faltante');
console.log('ab-slider:', abSlider ? '✅ Presente' : '❌ Faltante');
console.log('canary-toggle:', canaryToggle ? '✅ Presente' : '❌ Faltante');
console.log('canary-slider:', canarySlider ? '✅ Presente' : '❌ Faltante');
console.log('trafficChart:', trafficChart ? '✅ Presente' : '❌ Faltante');

// 2. Verificar variables globales
console.log('\n2. Verificando variables globales:');
console.log('isABEnabled:', window.isABEnabled);
console.log('isCanaryEnabled:', window.isCanaryEnabled);
console.log('urlHealthStatus:', window.urlHealthStatus);

// 3. Verificar funciones críticas
console.log('\n3. Verificando funciones críticas:');
console.log('getTrafficPercentage:', typeof window.getTrafficPercentage);
console.log('updateTrafficPercentages:', typeof window.updateTrafficPercentages);
console.log('updateChartWithCurrentData:', typeof window.updateChartWithCurrentData);
console.log('setupEventListeners:', typeof window.setupEventListeners);

// 4. Probar getTrafficPercentage
console.log('\n4. Probando getTrafficPercentage:');
if (typeof window.getTrafficPercentage === 'function') {
    console.log('version-a:', window.getTrafficPercentage('version-a') + '%');
    console.log('version-b:', window.getTrafficPercentage('version-b') + '%');
    console.log('weblogic-a:', window.getTrafficPercentage('weblogic-a') + '%');
    console.log('weblogic-b:', window.getTrafficPercentage('weblogic-b') + '%');
} else {
    console.log('❌ getTrafficPercentage no disponible');
}

// 5. Probar cambio de slider
console.log('\n5. Probando cambio de slider A/B:');
if (abSlider) {
    console.log('Valor actual del slider:', abSlider.value);
    
    // Simular cambio de slider
    abSlider.value = 70;
    const event = new Event('input', { bubbles: true });
    abSlider.dispatchEvent(event);
    
    console.log('Nuevo valor del slider:', abSlider.value);
    
    // Verificar si se actualizaron los displays
    const versionAPercent = document.getElementById('version-a-percent');
    const versionBPercent = document.getElementById('version-b-percent');
    console.log('Display A:', versionAPercent ? versionAPercent.textContent : 'No encontrado');
    console.log('Display B:', versionBPercent ? versionBPercent.textContent : 'No encontrado');
} else {
    console.log('❌ Slider A/B no encontrado');
}

// 6. Probar actualización de URLs
console.log('\n6. Probando actualización de URLs:');
if (typeof window.updateTrafficPercentages === 'function') {
    window.updateTrafficPercentages();
    console.log('✅ updateTrafficPercentages ejecutada');
} else {
    console.log('❌ updateTrafficPercentages no disponible');
}

// 7. Probar actualización de gráfico
console.log('\n7. Probando actualización de gráfico:');
if (typeof window.updateChartWithCurrentData === 'function') {
    window.updateChartWithCurrentData();
    console.log('✅ updateChartWithCurrentData ejecutada');
} else {
    console.log('❌ updateChartWithCurrentData no disponible');
}

// 8. Verificar URLs cards
console.log('\n8. Verificando URL cards:');
const urlCards = ['version-a', 'version-b', 'weblogic-a', 'weblogic-b', 'feature-flags'];
urlCards.forEach(urlKey => {
    const card = document.getElementById(`url-${urlKey}`);
    const traffic = document.getElementById(`traffic-${urlKey}`);
    console.log(`${urlKey}:`, {
        card: card ? '✅' : '❌',
        traffic: traffic ? traffic.textContent : 'No encontrado',
        classes: card ? card.className : 'N/A'
    });
});

// 9. Probar toggle A/B
console.log('\n9. Probando toggle A/B:');
if (abToggle) {
    console.log('Estado actual del toggle:', abToggle.checked);
    
    // Simular click en toggle
    abToggle.checked = true;
    const toggleEvent = new Event('change', { bubbles: true });
    abToggle.dispatchEvent(toggleEvent);
    
    console.log('Nuevo estado del toggle:', abToggle.checked);
    console.log('isABEnabled después del toggle:', window.isABEnabled);
} else {
    console.log('❌ Toggle A/B no encontrado');
}

console.log('\n🎯 PRUEBA COMPLETADA');
console.log('Revisa los resultados arriba para identificar problemas específicos');
