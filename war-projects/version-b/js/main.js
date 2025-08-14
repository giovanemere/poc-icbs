/**
 * Main JavaScript for Version B
 */

document.addEventListener('DOMContentLoaded', function() {
    // Inicializar componentes
    initThemeToggle();
    initAnimations();
    initFeatureCards();
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
