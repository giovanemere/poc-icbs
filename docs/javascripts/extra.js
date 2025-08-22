// JavaScript personalizado para la documentación WebLogic

document.addEventListener('DOMContentLoaded', function() {
    // Función para verificar URLs del sistema
    function checkSystemUrls() {
        const urls = [
            { url: 'http://localhost:8085/unified-dashboard-fixed.html', name: 'Dashboard Unificado' },
            { url: 'http://localhost:8084/', name: 'Dashboard de Tráfico' },
            { url: 'http://localhost:8092/', name: 'Panel HAProxy' },
            { url: 'http://localhost:8100/', name: 'Frontend Principal' }
        ];

        urls.forEach(item => {
            fetch(item.url, { mode: 'no-cors' })
                .then(() => {
                    console.log(`✅ ${item.name} está disponible`);
                    addStatusIndicator(item.name, 'online');
                })
                .catch(() => {
                    console.log(`❌ ${item.name} no está disponible`);
                    addStatusIndicator(item.name, 'offline');
                });
        });
    }

    // Función para agregar indicadores de estado
    function addStatusIndicator(serviceName, status) {
        const links = document.querySelectorAll(`a[href*="localhost"]`);
        links.forEach(link => {
            if (link.textContent.includes(serviceName) || link.href.includes(serviceName.toLowerCase())) {
                const indicator = document.createElement('span');
                indicator.className = `status-indicator ${status}`;
                indicator.innerHTML = status === 'online' ? ' 🟢' : ' 🔴';
                indicator.title = `${serviceName} está ${status === 'online' ? 'en línea' : 'fuera de línea'}`;
                
                if (!link.querySelector('.status-indicator')) {
                    link.appendChild(indicator);
                }
            }
        });
    }

    // Función para mejorar las tablas
    function enhanceTables() {
        const tables = document.querySelectorAll('table');
        tables.forEach(table => {
            // Agregar clase para tablas responsivas
            table.classList.add('responsive-table');
            
            // Envolver tabla en contenedor scrollable
            const wrapper = document.createElement('div');
            wrapper.className = 'table-wrapper';
            table.parentNode.insertBefore(wrapper, table);
            wrapper.appendChild(table);
        });
    }

    // Función para agregar botones de copia a bloques de código
    function addCopyButtons() {
        const codeBlocks = document.querySelectorAll('pre code');
        codeBlocks.forEach(block => {
            const button = document.createElement('button');
            button.className = 'copy-button';
            button.innerHTML = '📋 Copiar';
            button.title = 'Copiar código';
            
            button.addEventListener('click', () => {
                navigator.clipboard.writeText(block.textContent).then(() => {
                    button.innerHTML = '✅ Copiado';
                    setTimeout(() => {
                        button.innerHTML = '📋 Copiar';
                    }, 2000);
                });
            });
            
            const pre = block.parentElement;
            pre.style.position = 'relative';
            pre.appendChild(button);
        });
    }

    // Función para crear enlaces rápidos a servicios
    function createQuickLinks() {
        const quickLinksContainer = document.createElement('div');
        quickLinksContainer.className = 'quick-links-container';
        quickLinksContainer.innerHTML = `
            <div class="quick-links">
                <h4>🔗 Enlaces Rápidos del Sistema</h4>
                <div class="quick-links-grid">
                    <a href="http://localhost:8085/unified-dashboard-fixed.html" target="_blank" class="quick-link">
                        🎛️ Dashboard Principal
                    </a>
                    <a href="http://localhost:8084/" target="_blank" class="quick-link">
                        📊 Dashboard de Tráfico
                    </a>
                    <a href="http://localhost:8092/" target="_blank" class="quick-link">
                        🎛️ Panel HAProxy
                    </a>
                    <a href="http://localhost:8100/" target="_blank" class="quick-link">
                        🌐 Frontend Principal
                    </a>
                </div>
            </div>
        `;

        // Agregar al final del contenido principal
        const content = document.querySelector('.md-content__inner');
        if (content) {
            content.appendChild(quickLinksContainer);
        }
    }

    // Función para mejorar la navegación
    function enhanceNavigation() {
        // Agregar iconos a elementos de navegación
        const navItems = document.querySelectorAll('.md-nav__item .md-nav__link');
        navItems.forEach(item => {
            const text = item.textContent.trim();
            let icon = '';
            
            if (text.includes('Inicio') || text.includes('Home')) icon = '🏠';
            else if (text.includes('Arquitectura')) icon = '🏗️';
            else if (text.includes('Despliegue') || text.includes('Deploy')) icon = '🚀';
            else if (text.includes('HAProxy')) icon = '⚖️';
            else if (text.includes('Testing')) icon = '🧪';
            else if (text.includes('Dashboard')) icon = '📊';
            else if (text.includes('Scripts')) icon = '📜';
            else if (text.includes('API')) icon = '🔌';
            else if (text.includes('Desarrollo')) icon = '💻';
            else if (text.includes('Troubleshooting')) icon = '🔧';
            
            if (icon && !item.textContent.includes(icon)) {
                item.innerHTML = `${icon} ${item.innerHTML}`;
            }
        });
    }

    // Función para agregar tooltips
    function addTooltips() {
        const links = document.querySelectorAll('a[href*="localhost"]');
        links.forEach(link => {
            if (!link.title) {
                const url = link.href;
                if (url.includes(':8085')) link.title = 'Dashboard Unificado - Puerto 8085';
                else if (url.includes(':8084')) link.title = 'Dashboard de Tráfico - Puerto 8084';
                else if (url.includes(':8092')) link.title = 'Panel HAProxy - Puerto 8092';
                else if (url.includes(':8093')) link.title = 'API de Administración - Puerto 8093';
                else if (url.includes(':8100')) link.title = 'Frontend Principal - Puerto 8100';
                else if (url.includes(':8404')) link.title = 'Estadísticas HAProxy - Puerto 8404';
                else if (url.includes(':7001')) link.title = 'WebLogic A Console - Puerto 7001';
                else if (url.includes(':7002')) link.title = 'WebLogic B Console - Puerto 7002';
            }
        });
    }

    // Función para crear índice de contenido mejorado
    function enhanceTOC() {
        const headings = document.querySelectorAll('h1, h2, h3, h4');
        if (headings.length > 3) {
            const toc = document.createElement('div');
            toc.className = 'enhanced-toc';
            toc.innerHTML = '<h4>📋 Contenido de esta página</h4>';
            
            const list = document.createElement('ul');
            headings.forEach(heading => {
                const item = document.createElement('li');
                const link = document.createElement('a');
                link.href = `#${heading.id}`;
                link.textContent = heading.textContent;
                link.className = `toc-${heading.tagName.toLowerCase()}`;
                item.appendChild(link);
                list.appendChild(item);
            });
            
            toc.appendChild(list);
            
            // Insertar después del primer párrafo
            const firstP = document.querySelector('.md-content p');
            if (firstP) {
                firstP.parentNode.insertBefore(toc, firstP.nextSibling);
            }
        }
    }

    // Ejecutar funciones de mejora
    setTimeout(() => {
        checkSystemUrls();
        enhanceTables();
        addCopyButtons();
        enhanceNavigation();
        addTooltips();
        enhanceTOC();
    }, 1000);

    // Verificar URLs cada 30 segundos
    setInterval(checkSystemUrls, 30000);
});

// CSS adicional inyectado via JavaScript
const additionalCSS = `
    .copy-button {
        position: absolute;
        top: 8px;
        right: 8px;
        background: rgba(33, 150, 243, 0.8);
        color: white;
        border: none;
        padding: 4px 8px;
        border-radius: 4px;
        font-size: 12px;
        cursor: pointer;
        opacity: 0;
        transition: opacity 0.3s ease;
    }
    
    pre:hover .copy-button {
        opacity: 1;
    }
    
    .copy-button:hover {
        background: rgba(33, 150, 243, 1);
    }
    
    .status-indicator {
        font-size: 0.8em;
        margin-left: 4px;
    }
    
    .quick-links-container {
        margin: 2rem 0;
        padding: 1rem;
        background: rgba(33, 150, 243, 0.05);
        border-radius: 8px;
        border-left: 4px solid #1976d2;
    }
    
    .quick-links-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 0.5rem;
        margin-top: 1rem;
    }
    
    .quick-link {
        display: block;
        padding: 0.5rem 1rem;
        background: rgba(33, 150, 243, 0.1);
        border-radius: 4px;
        text-decoration: none;
        color: #1976d2;
        transition: all 0.3s ease;
        text-align: center;
    }
    
    .quick-link:hover {
        background: rgba(33, 150, 243, 0.2);
        transform: translateY(-2px);
    }
    
    .enhanced-toc {
        background: rgba(33, 150, 243, 0.05);
        padding: 1rem;
        border-radius: 8px;
        margin: 1rem 0;
        border-left: 4px solid #1976d2;
    }
    
    .enhanced-toc ul {
        margin: 0.5rem 0 0 0;
        padding-left: 1rem;
    }
    
    .enhanced-toc li {
        margin: 0.25rem 0;
    }
    
    .toc-h1 { font-weight: bold; }
    .toc-h2 { margin-left: 1rem; }
    .toc-h3 { margin-left: 2rem; font-size: 0.9em; }
    .toc-h4 { margin-left: 3rem; font-size: 0.8em; }
    
    .table-wrapper {
        overflow-x: auto;
        margin: 1rem 0;
    }
    
    .responsive-table {
        min-width: 100%;
        white-space: nowrap;
    }
`;

// Inyectar CSS adicional
const style = document.createElement('style');
style.textContent = additionalCSS;
document.head.appendChild(style);
