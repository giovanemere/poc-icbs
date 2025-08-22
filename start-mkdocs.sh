#!/bin/bash

# =============================================================================
# Script para Iniciar MkDocs - Documentación WebLogic
# =============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${PURPLE}"
echo "============================================================================="
echo "📚 INICIANDO MKDOCS - DOCUMENTACIÓN WEBLOGIC"
echo "============================================================================="
echo -e "${NC}"

# Cambiar al directorio correcto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Verificar si MkDocs está instalado
if ! command -v mkdocs &> /dev/null; then
    echo -e "${YELLOW}⚠️  MkDocs no está instalado. Instalando...${NC}"
    
    # Intentar instalar MkDocs
    if command -v pip3 &> /dev/null; then
        pip3 install mkdocs mkdocs-material mkdocs-git-revision-date-localized-plugin
    elif command -v pip &> /dev/null; then
        pip install mkdocs mkdocs-material mkdocs-git-revision-date-localized-plugin
    else
        echo -e "${RED}❌ No se encontró pip. Instala MkDocs manualmente:${NC}"
        echo -e "${CYAN}   pip install mkdocs mkdocs-material${NC}"
        exit 1
    fi
fi

# Verificar que el archivo mkdocs.yml existe
if [ ! -f "mkdocs.yml" ]; then
    echo -e "${RED}❌ Archivo mkdocs.yml no encontrado${NC}"
    exit 1
fi

# Verificar puerto disponible
PORT=8111
if netstat -tlnp 2>/dev/null | grep -q ":$PORT "; then
    echo -e "${YELLOW}⚠️  Puerto $PORT ocupado. Intentando puerto 8112...${NC}"
    PORT=8112
    
    if netstat -tlnp 2>/dev/null | grep -q ":$PORT "; then
        echo -e "${YELLOW}⚠️  Puerto $PORT también ocupado. Intentando puerto 8000...${NC}"
        PORT=8000
    fi
fi

echo -e "${CYAN}📋 Información de MkDocs:${NC}"
echo -e "   📁 Directorio: $(pwd)"
echo -e "   🌐 Puerto: $PORT"
echo -e "   📚 Documentación: http://localhost:$PORT"
echo ""

echo -e "${GREEN}🚀 Iniciando servidor MkDocs...${NC}"
echo -e "${CYAN}💡 Presiona Ctrl+C para parar el servidor${NC}"
echo ""

# Mostrar URLs del sistema para referencia
echo -e "${PURPLE}🔗 URLs del Sistema WebLogic:${NC}"
echo -e "   🎛️ Dashboard Principal: ${YELLOW}http://localhost:8085/unified-dashboard-fixed.html${NC}"
echo -e "   📊 Dashboard de Tráfico: ${YELLOW}http://localhost:8084/${NC}"
echo -e "   🌐 Frontend Principal: ${YELLOW}http://localhost:8100/${NC}"
echo ""

echo -e "${GREEN}📚 Documentación disponible en: ${YELLOW}http://localhost:$PORT${NC}"
echo ""

# Función para manejar Ctrl+C
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Parando servidor MkDocs...${NC}"
    echo -e "${GREEN}✅ Servidor MkDocs parado${NC}"
    exit 0
}

# Capturar Ctrl+C
trap cleanup SIGINT

# Iniciar MkDocs
if [ "$PORT" = "8111" ]; then
    mkdocs serve --dev-addr=0.0.0.0:8111 --livereload
else
    mkdocs serve --dev-addr=0.0.0.0:$PORT --livereload
fi
