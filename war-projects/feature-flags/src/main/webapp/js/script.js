/**
 * Script para la aplicación de Feature Flags
 */
document.addEventListener('DOMContentLoaded', function() {
    console.log('Aplicación de Feature Flags inicializada');
    
    // Simular gráficos si el dashboard avanzado está habilitado
    const charts = document.querySelectorAll('.chart');
    if (charts.length > 0) {
        charts.forEach(function(chart, index) {
            drawSimpleChart(chart, index);
        });
    }
    
    // Simular notificaciones en tiempo real
    const notification = document.querySelector('.notification');
    if (notification) {
        let count = 3;
        setInterval(function() {
            count++;
            notification.textContent = `Tienes ${count} nuevas notificaciones`;
        }, 5000);
    }
});

/**
 * Dibuja un gráfico simple en el elemento proporcionado
 */
function drawSimpleChart(element, index) {
    // Crear un canvas para el gráfico
    const canvas = document.createElement('canvas');
    canvas.width = element.clientWidth;
    canvas.height = element.clientHeight;
    element.innerHTML = '';
    element.appendChild(canvas);
    
    const ctx = canvas.getContext('2d');
    
    // Datos simulados para los gráficos
    const data = [
        [10, 25, 15, 30, 20, 35, 25, 40, 30, 45],
        [5, 15, 25, 10, 30, 20, 35, 15, 40, 25],
        [30, 25, 20, 15, 25, 30, 35, 20, 15, 25]
    ];
    
    // Colores para los gráficos
    const colors = ['#2196F3', '#4CAF50', '#FF9800'];
    
    // Dibujar el gráfico
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Dibujar ejes
    ctx.beginPath();
    ctx.moveTo(30, 20);
    ctx.lineTo(30, canvas.height - 30);
    ctx.lineTo(canvas.width - 20, canvas.height - 30);
    ctx.strokeStyle = '#999';
    ctx.stroke();
    
    // Dibujar datos
    const dataSet = data[index % data.length];
    const maxData = Math.max(...dataSet);
    const barWidth = (canvas.width - 60) / dataSet.length;
    const barMaxHeight = canvas.height - 50;
    
    ctx.fillStyle = colors[index % colors.length];
    
    for (let i = 0; i < dataSet.length; i++) {
        const barHeight = (dataSet[i] / maxData) * barMaxHeight;
        const x = 40 + i * barWidth;
        const y = canvas.height - 30 - barHeight;
        
        ctx.fillRect(x, y, barWidth - 10, barHeight);
    }
    
    // Etiquetas
    ctx.fillStyle = document.body.classList.contains('dark-mode') ? '#f5f5f5' : '#333';
    ctx.font = '10px Arial';
    ctx.fillText('Gráfico ' + (index + 1), canvas.width / 2 - 30, canvas.height - 10);
}
