// Configuración específica para Mermaid
window.mermaidConfig = {
  startOnLoad: true,
  theme: 'default',
  themeVariables: {
    primaryColor: '#1976d2',
    primaryTextColor: '#ffffff',
    primaryBorderColor: '#1565c0',
    lineColor: '#1976d2',
    sectionBkgColor: '#e3f2fd',
    altSectionBkgColor: '#bbdefb',
    gridColor: '#e0e0e0',
    secondaryColor: '#2196f3',
    tertiaryColor: '#64b5f6'
  },
  flowchart: {
    useMaxWidth: true,
    htmlLabels: true,
    curve: 'basis'
  },
  sequence: {
    diagramMarginX: 50,
    diagramMarginY: 10,
    actorMargin: 50,
    width: 150,
    height: 65,
    boxMargin: 10,
    boxTextMargin: 5,
    noteMargin: 10,
    messageMargin: 35,
    mirrorActors: true,
    bottomMarginAdj: 1,
    useMaxWidth: true,
    rightAngles: false,
    showSequenceNumbers: false
  },
  gantt: {
    titleTopMargin: 25,
    barHeight: 20,
    fontSizeFactor: 1,
    fontFamily: '"Open-Sans", "sans-serif"',
    numberSectionStyles: 4,
    axisFormat: '%Y-%m-%d'
  }
};

// Inicializar Mermaid cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', function() {
  if (typeof mermaid !== 'undefined') {
    mermaid.initialize(window.mermaidConfig);
  }
});

// Reinicializar Mermaid cuando cambie el tema
document.addEventListener('DOMContentLoaded', function() {
  const observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.type === 'attributes' && mutation.attributeName === 'data-md-color-scheme') {
        if (typeof mermaid !== 'undefined') {
          // Actualizar tema según el modo
          const isDark = document.body.getAttribute('data-md-color-scheme') === 'slate';
          const newConfig = {
            ...window.mermaidConfig,
            theme: isDark ? 'dark' : 'default'
          };
          
          mermaid.initialize(newConfig);
          
          // Re-renderizar diagramas existentes
          const diagrams = document.querySelectorAll('.mermaid');
          diagrams.forEach(function(diagram) {
            if (diagram.getAttribute('data-processed')) {
              diagram.removeAttribute('data-processed');
              mermaid.init(undefined, diagram);
            }
          });
        }
      }
    });
  });
  
  observer.observe(document.body, {
    attributes: true,
    attributeFilter: ['data-md-color-scheme']
  });
});
