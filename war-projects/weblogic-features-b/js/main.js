/**
 * Main JavaScript for WebLogic Features B
 */

document.addEventListener('DOMContentLoaded', function() {
    // Inicializar componentes
    initThemeToggle();
    initAnimations();
    initTabs();
    initFeatureCards();
    initStatCounters();
    initNotifications();
    
    // Mostrar mensaje de bienvenida
    showWelcomeMessage();
});

/**
 * Inicializa el toggle de tema claro/oscuro
 */
function initThemeToggle() {
    const themeToggle = document.getElementById('theme-toggle');
    if (!themeToggle) return;
    
    // Verificar si hay una preferencia guardada
    const isDarkMode = localStorage.getItem('darkMode') === 'true';
    
    // Aplicar tema inicial
    if (isDarkMode) {
        document.body.classList.add('dark-mode');
        themeToggle.innerHTML = '<i class="fas fa-sun"></i>';
    } else {
        themeToggle.innerHTML = '<i class="fas fa-moon"></i>';
    }
    
    // Manejar cambio de tema
    themeToggle.addEventListener('click', function() {
        document.body.classList.toggle('dark-mode');
        const isDark = document.body.classList.contains('dark-mode');
        
        // Guardar preferencia
        localStorage.setItem('darkMode', isDark);
        
        // Cambiar icono
        themeToggle.innerHTML = isDark ? 
            '<i class="fas fa-sun"></i>' : 
            '<i class="fas fa-moon"></i>';
    });
}

/**
 * Inicializa las animaciones de entrada
 */
function initAnimations() {
    // Animar elementos al entrar en el viewport
    const animatedElements = document.querySelectorAll('.animate-on-scroll');
    
    if (animatedElements.length === 0) return;
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate-fade-in');
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.1 });
    
    animatedElements.forEach(el => {
        observer.observe(el);
    });
}

/**
 * Inicializa las pestañas
 */
function initTabs() {
    const tabButtons = document.querySelectorAll('.tab');
    const tabContents = document.querySelectorAll('.tab-content');
    
    if (tabButtons.length === 0) return;
    
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            // Remover clase activa de todas las pestañas
            tabButtons.forEach(btn => btn.classList.remove('active'));
            tabContents.forEach(content => content.classList.remove('active'));
            
            // Añadir clase activa a la pestaña seleccionada
            button.classList.add('active');
            
            // Mostrar contenido correspondiente
            const tabId = button.getAttribute('data-tab');
            const tabContent = document.getElementById(tabId);
            if (tabContent) {
                tabContent.classList.add('active');
            }
        });
    });
    
    // Activar la primera pestaña por defecto
    if (tabButtons[0]) {
        tabButtons[0].click();
    }
}

/**
 * Inicializa las tarjetas de características
 */
function initFeatureCards() {
    const featureCards = document.querySelectorAll('.feature-card');
    
    featureCards.forEach(card => {
        card.addEventListener('click', function() {
            // Añadir efecto de pulsación
            this.style.transform = 'scale(0.98)';
            setTimeout(() => {
                this.style.transform = '';
            }, 200);
            
            // Mostrar más información si hay un botón de detalles
            const detailsBtn = this.querySelector('.feature-details');
            if (detailsBtn) {
                detailsBtn.click();
            }
        });
    });
}

/**
 * Inicializa los contadores de estadísticas
 */
function initStatCounters() {
    const statValues = document.querySelectorAll('.stat-value');
    
    if (statValues.length === 0) return;
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const target = entry.target;
                const finalValue = parseInt(target.getAttribute('data-value'));
                
                animateCounter(target, 0, finalValue, 2000);
                observer.unobserve(target);
            }
        });
    }, { threshold: 0.5 });
    
    statValues.forEach(value => {
        // Guardar el valor final como atributo
        const finalValue = value.textContent;
        value.setAttribute('data-value', finalValue);
        value.textContent = '0';
        
        observer.observe(value);
    });
}

/**
 * Anima un contador desde un valor inicial hasta un valor final
 */
function animateCounter(element, start, end, duration) {
    let startTimestamp = null;
    const step = (timestamp) => {
        if (!startTimestamp) startTimestamp = timestamp;
        const progress = Math.min((timestamp - startTimestamp) / duration, 1);
        const currentValue = Math.floor(progress * (end - start) + start);
        element.textContent = currentValue.toLocaleString();
        
        if (progress < 1) {
            window.requestAnimationFrame(step);
        }
    };
    window.requestAnimationFrame(step);
}

/**
 * Inicializa el sistema de notificaciones
 */
function initNotifications() {
    const notificationContainer = document.getElementById('notification-container');
    if (!notificationContainer) return;
    
    // Función para mostrar notificaciones
    window.showNotification = function(message, type = 'info', duration = 5000) {
        const notification = document.createElement('div');
        notification.className = `notification notification-${type} animate-fade-in`;
        notification.innerHTML = `
            <div class="notification-content">
                <span>${message}</span>
                <button class="notification-close">&times;</button>
            </div>
        `;
        
        notificationContainer.appendChild(notification);
        
        // Configurar cierre de notificación
        const closeBtn = notification.querySelector('.notification-close');
        closeBtn.addEventListener('click', () => {
            notification.classList.add('notification-hide');
            setTimeout(() => {
                notification.remove();
            }, 300);
        });
        
        // Auto-cerrar después de la duración especificada
        if (duration > 0) {
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.classList.add('notification-hide');
                    setTimeout(() => {
                        notification.remove();
                    }, 300);
                }
            }, duration);
        }
    };
}

/**
 * Muestra un mensaje de bienvenida
 */
function showWelcomeMessage() {
    const welcomeAlert = document.getElementById('welcome-alert');
    if (welcomeAlert) {
        setTimeout(() => {
            welcomeAlert.classList.add('animate-fade-in');
            welcomeAlert.style.display = 'block';
        }, 500);
    }
}
