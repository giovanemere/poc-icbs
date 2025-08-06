#!/bin/bash
# Script de corrección inmediata para problemas críticos

echo "=== CORRECCIÓN INMEDIATA DE PROBLEMAS CRÍTICOS ==="

# 1. CORREGIR DOCKERFILE DE WEBLOGIC - Cambiar rutas de applications/ a war-projects/
echo "1. Corrigiendo Dockerfile de WebLogic..."

# Backup del Dockerfile original
cp docker/Dockerfile.weblogic docker/Dockerfile.weblogic.backup

# Crear nuevo Dockerfile corregido
cat > docker/Dockerfile.weblogic << 'EOF'
# =============================================================================
# WebLogic Feature Flags Application - CORREGIDO
# Base Image: Oracle WebLogic 12.2.1.3
# Registry: edissonz8809/weblogic-feature-flags
# =============================================================================

FROM vulhub/weblogic:12.2.1.3-2018

# Build arguments
ARG VERSION=A
ARG ADMIN_PASSWORD=welcome1

# Switch to root for installation
USER root

# Environment variables
ENV VERSION=${VERSION}
ENV ADMIN_PASSWORD=${ADMIN_PASSWORD}
ENV ORACLE_HOME=/u01/oracle
ENV DOMAIN_HOME=/u01/oracle/user_projects/domains/base_domain
ENV PATH=$PATH:$ORACLE_HOME/oracle_common/common/bin:$ORACLE_HOME/wlserver/common/bin

# Labels for Docker Hub
LABEL maintainer="edissonz8809"
LABEL version="1.0.0"
LABEL description="WebLogic Server with Feature Flags support"
LABEL application="weblogic-feature-flags"
LABEL environment="development"

# Install required packages
RUN yum -y install unzip curl && \
    yum clean all

# Setup directories and permissions FIRST
RUN mkdir -p /u01/oracle/config && \
    mkdir -p /u01/oracle/user_projects/domains && \
    mkdir -p /u01/oracle/logs/weblogic-monitoring && \
    mkdir -p /u01/oracle/deploy && \
    mkdir -p /u01/oracle/container-scripts && \
    chown -R oracle:oracle /u01/oracle && \
    chmod -R 755 /u01/oracle

# Copy container scripts (usando la estructura correcta)
COPY applications/weblogic-feature-flags/container-scripts/ /u01/oracle/container-scripts/

# Copy domain creation script
COPY applications/weblogic-feature-flags/config/create-domain.py /u01/oracle/config/

# Copy WAR files from applications (ya están compilados)
COPY applications/weblogic-feature-flags/deploy/*.war /u01/oracle/deploy/

# Set permissions for all copied files
RUN chown -R oracle:oracle /u01/oracle/container-scripts && \
    chown -R oracle:oracle /u01/oracle/deploy && \
    chown -R oracle:oracle /u01/oracle/config && \
    chmod +x /u01/oracle/container-scripts/*.sh

# Set working directory
WORKDIR /u01/oracle

# Expose ports
EXPOSE 7001 7002

# Health check with longer timeout for domain creation
HEALTHCHECK --interval=30s --timeout=15s --start-period=300s --retries=10 \
    CMD curl -f http://localhost:7001/console || exit 1

# Run as oracle user
USER oracle

# Start WebLogic with improved startup script
CMD ["/u01/oracle/container-scripts/start-weblogic.sh"]
EOF

echo "✅ Dockerfile de WebLogic corregido"

# 2. CORREGIR PROBLEMA DE HAPROXY
echo "2. Verificando HAProxy..."

# Verificar que el script existe
if [ -f "haproxy/scripts/start-haproxy.sh" ]; then
    echo "✅ Script start-haproxy.sh existe"
    chmod +x haproxy/scripts/start-haproxy.sh
else
    echo "❌ Script start-haproxy.sh NO existe"
    echo "Creando script básico..."
    mkdir -p haproxy/scripts
    cat > haproxy/scripts/start-haproxy.sh << 'EOF'
#!/bin/bash
echo "Iniciando HAProxy..."
haproxy -f /usr/local/etc/haproxy/haproxy.cfg -db
EOF
    chmod +x haproxy/scripts/start-haproxy.sh
fi

# 3. VERIFICAR ESTRUCTURA DE APLICACIONES
echo "3. Verificando estructura de aplicaciones..."

# Verificar que los WAR files existen en applications/
if [ ! -d "applications/weblogic-feature-flags/deploy" ]; then
    echo "❌ Directorio deploy no existe en applications"
    echo "Creando y copiando desde war-projects..."
    mkdir -p applications/weblogic-feature-flags/deploy
    
    # Crear WAR files desde war-projects si no existen
    cd war-projects
    for dir in */; do
        if [ -d "$dir" ]; then
            app_name=$(basename "$dir")
            echo "Creando WAR para $app_name..."
            cd "$dir"
            jar -cf "../applications/weblogic-feature-flags/deploy/${app_name}.war" *
            cd ..
        fi
    done
    cd ..
fi

# 4. VERIFICAR PERMISOS
echo "4. Corrigiendo permisos..."
find applications/weblogic-feature-flags/container-scripts/ -name "*.sh" -exec chmod +x {} \;
find haproxy/scripts/ -name "*.sh" -exec chmod +x {} \;

echo "=== CORRECCIÓN COMPLETADA ==="
echo ""
echo "PRÓXIMOS PASOS:"
echo "1. Ejecutar: docker-compose build --no-cache"
echo "2. Ejecutar: docker-compose up -d orcldb"
echo "3. Esperar que Oracle esté healthy"
echo "4. Ejecutar: docker-compose up -d weblogic-a weblogic-b"
echo "5. Ejecutar: docker-compose up -d haproxy"
echo ""
EOF

chmod +x fix-immediate-issues.sh
