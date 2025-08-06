#!/bin/bash

# Script simplificado de reestructuración del directorio applications
set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🏗️  Reestructurando directorio applications/${NC}"

# Directorio del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

# Cargar variables básicas
export WEBLOGIC_APP_PATH="applications/weblogic-feature-flags"
export HAPROXY_APP_PATH="applications/haproxy-advanced"
export MKDOCS_APP_PATH="applications/mkdocs-server"
export ORACLE_APP_PATH="applications/oracle-setup"
export DOCKER_NAMESPACE="edissonz8809"

echo -e "${BLUE}Variables configuradas:${NC}"
echo "  WEBLOGIC_APP_PATH: $WEBLOGIC_APP_PATH"
echo "  HAPROXY_APP_PATH: $HAPROXY_APP_PATH"
echo "  MKDOCS_APP_PATH: $MKDOCS_APP_PATH"
echo "  ORACLE_APP_PATH: $ORACLE_APP_PATH"

# Crear backup
BACKUP_DIR="backups/applications-$(date +%Y%m%d-%H%M%S)"
echo -e "${BLUE}Creando backup en: $BACKUP_DIR${NC}"
mkdir -p "$BACKUP_DIR"
if [[ -d "applications" ]]; then
    cp -r applications "$BACKUP_DIR/"
fi

# Función para crear estructura estándar
create_app_structure() {
    local app_path="$1"
    local app_name="$2"
    local description="$3"
    
    echo -e "${BLUE}📁 Creando estructura para: $app_name${NC}"
    
    # Crear directorios
    mkdir -p "$app_path"/{src,config,scripts,deploy,docs,tests}
    
    # Crear README
    cat > "$app_path/README.md" << EOF
# $app_name

## Descripción
$description

## Estructura
\`\`\`
$app_path/
├── src/                 # Código fuente
├── config/             # Configuraciones
├── scripts/            # Scripts específicos
├── deploy/             # Deployment files
├── docs/               # Documentación
├── tests/              # Tests
├── Dockerfile          # Dockerfile principal
└── README.md          # Esta documentación
\`\`\`

## Build
\`\`\`bash
docker build -t $DOCKER_NAMESPACE/$app_name:latest .
\`\`\`

## Variables
Las variables están centralizadas en \`scripts/.env\`

---
Generado: $(date +'%Y-%m-%d %H:%M:%S')
EOF

    # Crear Dockerfile básico
    cat > "$app_path/Dockerfile" << EOF
# Dockerfile para $app_name
FROM alpine:latest

LABEL maintainer="DevOps Team"
LABEL description="$description"

WORKDIR /app

# Copiar archivos
COPY src/ /app/src/
COPY config/ /app/config/
COPY scripts/ /app/scripts/

# Hacer scripts ejecutables
RUN find /app/scripts -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Comando por defecto
CMD ["/bin/sh"]
EOF

    echo -e "${GREEN}✅ Estructura creada para $app_name${NC}"
}

# Crear estructuras para cada aplicación
echo -e "${CYAN}=== Creando estructuras de aplicaciones ===${NC}"

create_app_structure "$WEBLOGIC_APP_PATH" "weblogic-feature-flags" "Aplicación WebLogic con Feature Flags"
create_app_structure "$HAPROXY_APP_PATH" "haproxy-advanced" "Load Balancer HAProxy avanzado"
create_app_structure "$MKDOCS_APP_PATH" "mkdocs-server" "Servidor de documentación MkDocs"
create_app_structure "$ORACLE_APP_PATH" "oracle-setup" "Configuración Oracle Database"

# Mover archivos existentes si existen
echo -e "${CYAN}=== Moviendo archivos existentes ===${NC}"

# WebLogic
if [[ -d "weblogic" ]]; then
    echo -e "${BLUE}📦 Moviendo archivos de weblogic/${NC}"
    cp -r weblogic/* "$WEBLOGIC_APP_PATH/src/" 2>/dev/null || true
    echo -e "${GREEN}✅ Archivos de WebLogic movidos${NC}"
fi

# HAProxy
if [[ -d "haproxy" ]]; then
    echo -e "${BLUE}📦 Moviendo archivos de haproxy/${NC}"
    cp -r haproxy/* "$HAPROXY_APP_PATH/src/" 2>/dev/null || true
    echo -e "${GREEN}✅ Archivos de HAProxy movidos${NC}"
fi

# Oracle
if [[ -d "oracle" ]]; then
    echo -e "${BLUE}📦 Moviendo archivos de oracle/${NC}"
    cp -r oracle/* "$ORACLE_APP_PATH/src/" 2>/dev/null || true
    echo -e "${GREEN}✅ Archivos de Oracle movidos${NC}"
fi

# MkDocs - copiar docs y mkdocs.yml
if [[ -d "docs" ]]; then
    echo -e "${BLUE}📦 Copiando documentación${NC}"
    cp -r docs "$MKDOCS_APP_PATH/"
    echo -e "${GREEN}✅ Documentación copiada${NC}"
fi

if [[ -f "mkdocs.yml" ]]; then
    cp mkdocs.yml "$MKDOCS_APP_PATH/"
    echo -e "${GREEN}✅ mkdocs.yml copiado${NC}"
fi

# Crear README principal de applications
echo -e "${BLUE}📄 Creando README principal${NC}"
cat > "applications/README.md" << EOF
# Applications Directory

Directorio de aplicaciones del proyecto Docker WebLogic Oracle.

## Estructura

\`\`\`
applications/
├── weblogic-feature-flags/    # WebLogic con Feature Flags
├── haproxy-advanced/          # Load Balancer HAProxy
├── mkdocs-server/             # Documentación MkDocs
├── oracle-setup/              # Oracle Database
└── README.md                  # Esta documentación
\`\`\`

## Variables Centralizadas

Las aplicaciones usan variables centralizadas:
- Base: \`scripts/.env\`
- Por ambiente: \`scripts/.env.{development|staging|production}\`

## Docker Hub

Namespace: **$DOCKER_NAMESPACE**

## Build

\`\`\`bash
# Build individual
cd applications/app-name
docker build -t $DOCKER_NAMESPACE/app-name:latest .

# Build todas (próximamente)
./scripts/build/build-all-applications.sh
\`\`\`

---
Generado: $(date +'%Y-%m-%d %H:%M:%S')
EOF

# Crear script de build simple
echo -e "${BLUE}🔧 Creando script de build${NC}"
mkdir -p scripts/build

cat > "scripts/build/build-all-applications.sh" << 'EOF'
#!/bin/bash
# Script de build para todas las aplicaciones

set -e

echo "🏗️  Building all applications..."

APPS=("weblogic-feature-flags" "haproxy-advanced" "mkdocs-server" "oracle-setup")
NAMESPACE="edissonz8809"

for app in "${APPS[@]}"; do
    if [[ -f "applications/$app/Dockerfile" ]]; then
        echo "📦 Building $app..."
        cd "applications/$app"
        docker build -t "$NAMESPACE/$app:latest" .
        cd "../.."
        echo "✅ $app built"
    else
        echo "⚠️  Dockerfile not found for $app"
    fi
done

echo "🎉 All applications built!"
EOF

chmod +x scripts/build/build-all-applications.sh

# Crear script de validación
cat > "scripts/validation/validate-applications-structure.sh" << 'EOF'
#!/bin/bash
# Validación de estructura de applications

echo "🔍 Validando estructura de applications..."

APPS=("weblogic-feature-flags" "haproxy-advanced" "mkdocs-server" "oracle-setup")
DIRS=("src" "config" "scripts" "deploy" "docs" "tests")

for app in "${APPS[@]}"; do
    echo "📁 $app:"
    if [[ -d "applications/$app" ]]; then
        echo "  ✅ Directorio existe"
        
        for dir in "${DIRS[@]}"; do
            if [[ -d "applications/$app/$dir" ]]; then
                echo "  ✅ $dir/"
            else
                echo "  ⚠️  $dir/ (faltante)"
            fi
        done
        
        if [[ -f "applications/$app/README.md" ]]; then
            echo "  ✅ README.md"
        else
            echo "  ❌ README.md (faltante)"
        fi
        
        if [[ -f "applications/$app/Dockerfile" ]]; then
            echo "  ✅ Dockerfile"
        else
            echo "  ❌ Dockerfile (faltante)"
        fi
    else
        echo "  ❌ Directorio no existe"
    fi
    echo ""
done

echo "🎯 Validación completada"
EOF

chmod +x scripts/validation/validate-applications-structure.sh

# Resumen final
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                 REESTRUCTURACIÓN COMPLETADA                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${GREEN}✅ Reestructuración completada exitosamente${NC}"
echo ""
echo -e "${CYAN}📊 RESUMEN:${NC}"
echo "• 4 aplicaciones reestructuradas"
echo "• Estructura estándar creada"
echo "• Archivos existentes preservados"
echo "• Scripts de build y validación creados"
echo "• Backup guardado en: $BACKUP_DIR"
echo ""
echo -e "${CYAN}🚀 PRÓXIMOS PASOS:${NC}"
echo "1. Validar: ./scripts/validation/validate-applications-structure.sh"
echo "2. Build: ./scripts/build/build-all-applications.sh"
echo "3. Test: ./scripts/services/manage-services.sh restart"
echo ""
echo -e "${GREEN}🎉 ¡Listo para continuar!${NC}"
