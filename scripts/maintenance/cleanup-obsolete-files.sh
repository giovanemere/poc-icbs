#!/bin/bash

# Script de limpieza de archivos obsoletos
# Después de completar Docker Hub Integration
set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🧹 LIMPIEZA DE ARCHIVOS OBSOLETOS${NC}"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

# Crear directorio de backup antes de limpiar
BACKUP_DIR="backups/cleanup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}📦 Creando backup en: $BACKUP_DIR${NC}"

# Función para mover archivo a backup
backup_and_remove() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo -e "${YELLOW}📄 Moviendo a backup: $file${NC}"
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        mv "$file" "$BACKUP_DIR/$file"
    fi
}

# Función para mover directorio a backup
backup_and_remove_dir() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        echo -e "${YELLOW}📁 Moviendo directorio a backup: $dir${NC}"
        mv "$dir" "$BACKUP_DIR/"
    fi
}

echo -e "${BLUE}🗑️  Limpiando archivos de documentación obsoletos...${NC}"

# Archivos de documentación obsoletos (ya integrados en docs/)
backup_and_remove "SOLUCION_URL_MONITORING.md"
backup_and_remove "DOCKER-HUB-MKDOCS-COMPLETADO.md"
backup_and_remove "DOCKER-HUB-HAPROXY-COMPLETADO.md"
backup_and_remove "SCRIPTS_ORGANIZATION_REPORT.md"
backup_and_remove "COMPREHENSIVE_CLEANUP_PLAN.md"
backup_and_remove "PROJECT_SUMMARY.md"
backup_and_remove "STRATEGIC_CLEANUP_PLAN.md"
backup_and_remove "ORGANIZATION_SUMMARY_FINAL.md"
backup_and_remove "SCRIPTS_ORGANIZATION_SUMMARY.md"
backup_and_remove "FINAL_ORGANIZATION_REPORT.md"
backup_and_remove "CLEANUP_PLAN_FINAL.md"
backup_and_remove "VARIABLES-CENTRALIZADAS-COMPLETADO.md"
backup_and_remove "APPLICATIONS-RESTRUCTURE-COMPLETADO.md"
backup_and_remove "ESTADO-ACTUAL.md"
backup_and_remove "ESTADO_ACTUAL.md"
backup_and_remove "DOCS_README.md"

echo -e "${BLUE}🗑️  Limpiando Dockerfiles obsoletos...${NC}"

# Dockerfiles obsoletos (ya en applications/)
backup_and_remove "Dockerfile.mkdocs"
backup_and_remove "Dockerfile.mkdocs-fixed"
backup_and_remove "Dockerfile.mkdocs-dev"

echo -e "${BLUE}🗑️  Limpiando archivos de configuración obsoletos...${NC}"

# Archivos de configuración obsoletos
backup_and_remove "mkdocs-dev.yml"
backup_and_remove "requirements.txt"  # Ahora en applications/mkdocs-server/

echo -e "${BLUE}🗑️  Limpiando directorios obsoletos...${NC}"

# Directorios que ya no se usan
backup_and_remove_dir "temp"
backup_and_remove_dir "deploy"  # Funcionalidad movida a scripts/
backup_and_remove_dir "autodeploy"  # Funcionalidad movida a scripts/
backup_and_remove_dir "container-scripts"  # Funcionalidad movida a applications/
backup_and_remove_dir "references"  # Información ya integrada en docs/
backup_and_remove_dir "install"  # Scripts movidos a scripts/setup/

echo -e "${BLUE}🗑️  Limpiando archivos de entorno obsoletos...${NC}"

# Archivos de entorno obsoletos
backup_and_remove ".env.example"  # Ya tenemos .env completo
backup_and_remove_dir "mkdocs-env"  # Entorno virtual no necesario con Docker

echo -e "${BLUE}🗑️  Limpieza de logs antiguos...${NC}"

# Limpiar logs antiguos (mantener últimos 7 días)
if [[ -d "logs" ]]; then
    find logs/ -name "*.log" -mtime +7 -exec mv {} "$BACKUP_DIR/logs/" \; 2>/dev/null || true
fi

echo -e "${BLUE}🗑️  Limpieza de site generado...${NC}"

# Site generado por MkDocs (ya no necesario con Docker)
backup_and_remove_dir "site"

echo -e "${BLUE}📊 Generando reporte de limpieza...${NC}"

# Crear reporte de limpieza
cat > "CLEANUP-REPORT-$(date +%Y%m%d).md" << EOF
# Reporte de Limpieza - $(date +'%Y-%m-%d %H:%M:%S')

## 📋 Resumen
- **Fecha**: $(date +'%Y-%m-%d %H:%M:%S')
- **Backup Creado**: $BACKUP_DIR
- **Estado**: ✅ Limpieza completada exitosamente

## 🗑️ Archivos Movidos a Backup

### Documentación Obsoleta
- SOLUCION_URL_MONITORING.md
- DOCKER-HUB-MKDOCS-COMPLETADO.md
- DOCKER-HUB-HAPROXY-COMPLETADO.md
- SCRIPTS_ORGANIZATION_REPORT.md
- COMPREHENSIVE_CLEANUP_PLAN.md
- PROJECT_SUMMARY.md
- STRATEGIC_CLEANUP_PLAN.md
- ORGANIZATION_SUMMARY_FINAL.md
- SCRIPTS_ORGANIZATION_SUMMARY.md
- FINAL_ORGANIZATION_REPORT.md
- CLEANUP_PLAN_FINAL.md
- VARIABLES-CENTRALIZADAS-COMPLETADO.md
- APPLICATIONS-RESTRUCTURE-COMPLETADO.md
- ESTADO-ACTUAL.md
- ESTADO_ACTUAL.md
- DOCS_README.md

### Dockerfiles Obsoletos
- Dockerfile.mkdocs
- Dockerfile.mkdocs-fixed
- Dockerfile.mkdocs-dev

### Configuración Obsoleta
- mkdocs-dev.yml
- requirements.txt (movido a applications/)
- .env.example

### Directorios Obsoletos
- temp/
- deploy/
- autodeploy/
- container-scripts/
- references/
- install/
- mkdocs-env/
- site/

### Logs Antiguos
- Logs con más de 7 días de antigüedad

## 📁 Estructura Actual Limpia

\`\`\`
docker-for-oracle-weblogic/
├── applications/           # ✅ Aplicaciones organizadas
│   ├── haproxy-advanced/
│   ├── mkdocs-server/
│   ├── oracle-setup/
│   └── weblogic-feature-flags/
├── scripts/               # ✅ Scripts organizados
├── docs/                  # ✅ Documentación centralizada
├── config/                # ✅ Configuraciones activas
├── backups/               # ✅ Backups organizados
└── logs/                  # ✅ Logs recientes
\`\`\`

## 🎯 Beneficios de la Limpieza
- **Estructura más clara**: Archivos organizados por función
- **Menos confusión**: Eliminados archivos duplicados y obsoletos
- **Mejor mantenimiento**: Documentación centralizada en docs/
- **Backup seguro**: Todos los archivos respaldados antes de eliminar

## 🔄 Recuperación
Si necesitas recuperar algún archivo:
\`\`\`bash
# Restaurar archivo específico
cp $BACKUP_DIR/path/to/file ./

# Ver contenido del backup
ls -la $BACKUP_DIR/
\`\`\`

---
**Generado automáticamente por**: scripts/maintenance/cleanup-obsolete-files.sh
EOF

echo -e "${GREEN}✅ Limpieza completada exitosamente${NC}"
echo -e "${BLUE}📊 Estadísticas:${NC}"
echo "  • Backup creado en: $BACKUP_DIR"
echo "  • Archivos movidos: $(find "$BACKUP_DIR" -type f | wc -l)"
echo "  • Directorios movidos: $(find "$BACKUP_DIR" -mindepth 1 -type d | wc -l)"
echo ""
echo -e "${CYAN}📄 Reporte detallado: CLEANUP-REPORT-$(date +%Y%m%d).md${NC}"
echo ""
echo -e "${GREEN}🎯 Proyecto limpio y organizado para continuar con Docker Hub Integration${NC}"
