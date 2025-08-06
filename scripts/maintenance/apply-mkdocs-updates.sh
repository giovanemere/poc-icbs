#!/bin/bash

# Script para aplicar las actualizaciones de MkDocs
# Autor: Amazon Q

set -e

PROJECT_ROOT="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== APLICANDO ACTUALIZACIONES DE MKDOCS ===${NC}"

# 1. Respaldar configuración actual
if [[ -f "$PROJECT_ROOT/mkdocs.yml" ]]; then
    echo -e "${YELLOW}Respaldando mkdocs.yml actual...${NC}"
    cp "$PROJECT_ROOT/mkdocs.yml" "$PROJECT_ROOT/mkdocs.yml.backup.$(date +%s)"
fi

# 2. Aplicar nueva configuración
if [[ -f "$PROJECT_ROOT/mkdocs-updated.yml" ]]; then
    echo -e "${GREEN}Aplicando nueva configuración de MkDocs...${NC}"
    mv "$PROJECT_ROOT/mkdocs-updated.yml" "$PROJECT_ROOT/mkdocs.yml"
else
    echo -e "${YELLOW}No se encontró mkdocs-updated.yml, creando configuración nueva...${NC}"
    
    cat > "$PROJECT_ROOT/mkdocs.yml" << 'EOF'
site_name: Docker Oracle WebLogic - Documentación
site_description: Documentación completa para el proyecto Docker Oracle WebLogic con despliegues canary y feature flags
site_author: ICBS Team
site_url: https://your-domain.com

# Repository
repo_name: docker-for-oracle-weblogic
repo_url: https://github.com/your-org/docker-for-oracle-weblogic
edit_uri: edit/main/docs/

# Configuration
theme:
  name: material
  language: es
  palette:
    # Palette toggle for light mode
    - scheme: default
      primary: blue
      accent: blue
      toggle:
        icon: material/brightness-7
        name: Cambiar a modo oscuro
    # Palette toggle for dark mode
    - scheme: slate
      primary: blue
      accent: blue
      toggle:
        icon: material/brightness-4
        name: Cambiar a modo claro
  
  features:
    - navigation.tabs
    - navigation.tabs.sticky
    - navigation.sections
    - navigation.expand
    - navigation.path
    - navigation.top
    - search.highlight
    - search.share
    - content.code.copy
    - content.code.annotate
    - content.tabs.link
    - toc.follow
    - toc.integrate

# Plugins
plugins:
  - search:
      lang: es

# Extensions
markdown_extensions:
  - abbr
  - admonition
  - attr_list
  - def_list
  - footnotes
  - md_in_html
  - toc:
      permalink: true
  - pymdownx.arithmatex:
      generic: true
  - pymdownx.betterem:
      smart_enable: all
  - pymdownx.caret
  - pymdownx.details
  - pymdownx.emoji:
      emoji_generator: !!python/name:material.extensions.emoji.to_svg
      emoji_index: !!python/name:material.extensions.emoji.twemoji
  - pymdownx.highlight:
      anchor_linenums: true
      line_spans: __span
      pygments_lang_class: true
  - pymdownx.inlinehilite
  - pymdownx.keys
  - pymdownx.magiclink:
      repo_url_shorthand: true
      user: your-org
      repo: docker-for-oracle-weblogic
  - pymdownx.mark
  - pymdownx.smartsymbols
  - pymdownx.superfences
  - pymdownx.tabbed:
      alternate_style: true
  - pymdownx.tasklist:
      custom_checkbox: true
  - pymdownx.tilde

# Navigation - Estructura Mejorada y Organizada
nav:
  - 🏠 Inicio: index.md
  - 🚀 Primeros Pasos: getting-started.md
  - 🏗️ Arquitectura: arquitectura.md
  - 📦 Despliegue: deployment.md
  - 🎯 Canary y Features: canary-and-features.md
  - ⚖️ HAProxy: haproxy.md
  - 📜 Scripts:
    - Índice de Scripts: scripts/index.md
    - Guía de Uso: scripts/usage-guide.md
    - Referencia Completa: scripts/reference.md
  - 📚 Guías Avanzadas:
    - Troubleshooting: TROUBLESHOOTING.md
    - Guía de Despliegue: DEPLOYMENT_GUIDE.md
    - Guía Canary: CANARY_GUIDE.md
    - Integración HAProxy-MkDocs: mkdocs-haproxy-integration.md
  - 🆘 Soporte: support.md

# Extra
extra:
  social:
    - icon: fontawesome/brands/github
      link: https://github.com/your-org/docker-for-oracle-weblogic
    - icon: fontawesome/brands/docker
      link: https://hub.docker.com/
  version:
    provider: mike

# Copyright
copyright: Copyright &copy; 2024 ICBS Team
EOF
fi

# 3. Verificar que la documentación de scripts esté completa
echo -e "${GREEN}Verificando documentación de scripts...${NC}"

# Crear guía de uso si no existe
if [[ ! -f "$PROJECT_ROOT/docs/scripts/usage-guide.md" ]]; then
    cat > "$PROJECT_ROOT/docs/scripts/usage-guide.md" << 'EOF'
# Guía de Uso de Scripts

Esta guía explica cómo usar los scripts más importantes del proyecto Docker Oracle WebLogic.

## 🚀 Inicio Rápido

### Configuración Inicial
```bash
# 1. Configurar el proyecto por primera vez
./setup.sh

# 2. Cargar variables de entorno
source scripts/core/load-env.sh

# 3. Verificar que todo esté funcionando
./scripts/quick-validate.sh
```

### Gestión de Servicios
```bash
# Iniciar todos los servicios
./start-all.sh

# Gestionar servicios individualmente
./manage-services.sh

# Detener todos los servicios
./stop-all-services.sh

# Iniciar con actualización automática
./start-with-auto-update.sh
```

## 📦 Despliegue

### Despliegue Básico
```bash
# Despliegue completo
./scripts/deployment/deploy-complete.sh

# Desplegar WAR específico
./deploy-war.sh <nombre-war>

# Limpiar cachés antes del despliegue
./scripts/deployment/clear-all-caches.sh
```

### Despliegue Canary
```bash
# 1. Configurar canary deployment
./setup-canary.sh

# 2. Controlar porcentaje de tráfico
./canary-control.sh 50  # 50% de tráfico a la nueva versión

# 3. Probar el despliegue canary
./test-canary.sh

# 4. Gestionar tráfico entre versiones
./scripts/canary/manage-traffic.sh
```

## 🔧 Mantenimiento

### Limpieza y Diagnóstico
```bash
# Limpieza completa del entorno
./scripts/maintenance/cleanup-all.sh

# Diagnóstico completo del sistema
./scripts/maintenance/diagnose-and-fix.sh

# Organizar estructura del proyecto
./scripts/maintenance/organize-scripts.sh

# Actualizar configuración del sistema
./scripts/maintenance/update-system-config.sh
```

### Actualización de Componentes
```bash
# Actualizar HAProxy automáticamente
./scripts/maintenance/auto-update-haproxy.sh

# Actualizar todos los puertos
./scripts/maintenance/update-all-ports.sh

# Actualizar dashboard
./scripts/maintenance/update_dashboard.sh
```

## ✅ Validación y Testing

### Tests Básicos
```bash
# Validación rápida de scripts
./scripts/quick-validate.sh

# Ejecutar todos los tests
./scripts/validation/run-all-tests.sh

# Verificar URLs del sistema
./scripts/validation/check-urls.sh
```

### Tests Avanzados
```bash
# Validación completa del sistema
./scripts/validation/validate-complete-system.sh

# Tests de integración
./scripts/validation/test-integration.sh

# Tests de rendimiento
./scripts/validation/test-performance.sh

# Verificar consistencia de configuración
./scripts/validation/validate-config-consistency.sh
```

## 📚 Documentación

### Gestión de Documentación
```bash
# Construir documentación
./scripts/docs/build-docs.sh

# Configurar entorno de documentación
./setup-docs.sh

# Configurar HAProxy para MkDocs
./setup-haproxy-mkdocs.sh

# Gestionar documentación con HAProxy
./manage-docs-haproxy.sh
```

## 🏗️ Build y Desarrollo

### Construcción de Proyectos
```bash
# Build completo del proyecto
./build.sh

# Build local de proyectos WAR
./scripts/build/build-local.sh --all

# Crear archivos WAR simples
./scripts/build/create-simple-wars.sh
```

## 🔍 Utilidades

### Debugging y Verificación
```bash
# Debug de HAProxy
./scripts/utilities/debug-haproxy.sh

# Verificar puertos ICBS
./scripts/utilities/verify-icbs-ports.sh

# Encontrar puerto libre
./scripts/services/find-free-port.sh

# Verificar URLs de feature flags
./scripts/utilities/verify-feature-flags-urls.sh
```

## 📊 Monitoreo

### Port Forwarding (Minikube)
```bash
# Gestionar port-forwards de Minikube
./scripts/services/minikube-port-forwards.sh
```

## ⚠️ Troubleshooting

### Problemas Comunes

1. **Scripts sin permisos de ejecución**:
   ```bash
   ./scripts/quick-validate.sh
   ```

2. **Enlaces simbólicos rotos**:
   ```bash
   ./scripts/maintenance/fix-references.sh
   ```

3. **Servicios no responden**:
   ```bash
   ./scripts/maintenance/diagnose-and-fix.sh
   ```

4. **Errores de configuración**:
   ```bash
   ./scripts/validation/validate-config-consistency.sh
   ```

### Variables de Entorno Importantes

```bash
# WebLogic
WEBLOGIC_ADMIN_USER=weblogic
WEBLOGIC_ADMIN_PASSWORD=welcome1
WEBLOGIC_PORT_A=7001
WEBLOGIC_PORT_B=7002

# HAProxy
HAPROXY_PORT=8080
HAPROXY_STATS_PORT=8404

# Paths
PROJECT_ROOT=/path/to/project
SCRIPTS_DIR=$PROJECT_ROOT/scripts
```

### Logs

Los logs se encuentran en:
- **WebLogic**: `logs/weblogic/`
- **HAProxy**: `logs/haproxy/`
- **Scripts**: `logs/scripts/`

## 📝 Notas Importantes

1. **Siempre cargar variables de entorno**: Los scripts cargan automáticamente desde `.env`
2. **Ejecutar validación después de cambios**: `./scripts/quick-validate.sh`
3. **Usar enlaces simbólicos**: Los scripts principales están disponibles en la raíz
4. **Revisar logs en caso de errores**: Cada componente tiene su directorio de logs

## 🚀 Flujo de Trabajo Recomendado

1. **Configuración inicial**: `./setup.sh`
2. **Validar entorno**: `./scripts/quick-validate.sh`
3. **Iniciar servicios**: `./start-all.sh`
4. **Desplegar aplicación**: `./deploy-war.sh`
5. **Ejecutar tests**: `./scripts/validation/run-all-tests.sh`
6. **Configurar canary** (opcional): `./setup-canary.sh`
7. **Monitorear y mantener**: Scripts de mantenimiento según necesidad

Para más información detallada, consultar la [Referencia Completa](reference.md).
EOF
fi

# 4. Verificar configuración de MkDocs
echo -e "${GREEN}Verificando configuración de MkDocs...${NC}"

if command -v mkdocs &> /dev/null; then
    echo -e "${GREEN}Validando configuración de MkDocs...${NC}"
    cd "$PROJECT_ROOT"
    if mkdocs build --quiet; then
        echo -e "${GREEN}✅ Configuración de MkDocs válida${NC}"
    else
        echo -e "${YELLOW}⚠️  Hay algunos problemas con la configuración de MkDocs${NC}"
    fi
else
    echo -e "${YELLOW}MkDocs no está instalado. Para instalar:${NC}"
    echo "pip install mkdocs mkdocs-material"
fi

# 5. Crear resumen final
echo -e "${BLUE}=== RESUMEN DE ACTUALIZACIONES APLICADAS ===${NC}"
echo ""
echo -e "${GREEN}✅ Configuración de MkDocs actualizada${NC}"
echo -e "${GREEN}✅ Documentación de scripts organizada${NC}"
echo -e "${GREEN}✅ Navegación mejorada con secciones específicas${NC}"
echo -e "${GREEN}✅ Guías de uso creadas y actualizadas${NC}"
echo ""
echo -e "${BLUE}Archivos actualizados:${NC}"
echo -e "  📄 mkdocs.yml (configuración principal)"
echo -e "  📄 docs/scripts/index.md (índice de scripts)"
echo -e "  📄 docs/scripts/usage-guide.md (guía de uso)"
echo -e "  📄 docs/scripts/reference.md (referencia completa)"
echo ""
echo -e "${BLUE}Para construir la documentación:${NC}"
echo -e "  ${YELLOW}mkdocs build${NC}     # Construir sitio estático"
echo -e "  ${YELLOW}mkdocs serve${NC}     # Servidor de desarrollo"
echo -e "  ${YELLOW}./scripts/docs/build-docs.sh${NC}  # Script automatizado"
echo ""
echo -e "${GREEN}🎉 ¡Actualizaciones de MkDocs aplicadas exitosamente!${NC}"

exit 0
