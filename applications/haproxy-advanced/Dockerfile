# Dockerfile para HAProxy Advanced - Ubuntu Base (Corregido)
FROM ubuntu:24.04

# Metadata
LABEL maintainer="DevOps Team"
LABEL version="v1.1.0"
LABEL description="HAProxy Advanced Load Balancer - Docker WebLogic Oracle Project"

# Variables de entorno
ENV APP_NAME="haproxy-advanced"
ENV VERSION="v1.1.0"
ENV DOCKER_NAMESPACE="edissonz8809"
ENV DEBIAN_FRONTEND=noninteractive

# Instalar HAProxy y herramientas
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        haproxy \
        curl \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

# Crear directorios necesarios (el usuario haproxy ya existe)
RUN mkdir -p /run/haproxy /var/log/haproxy && \
    chown -R haproxy:haproxy /run/haproxy /var/log/haproxy

# Copiar archivos de configuración
COPY config/haproxy.cfg /etc/haproxy/haproxy.cfg
COPY scripts/start.sh /usr/local/bin/start.sh

# Hacer script ejecutable
RUN chmod +x /usr/local/bin/start.sh

# Verificar instalación HAProxy
RUN haproxy -v

# Exponer puertos
EXPOSE 80 443 8081 8082 8083 8404

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8404/stats || exit 1

# Comando por defecto
CMD ["/usr/local/bin/start.sh"]
