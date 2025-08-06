# Dockerfile para MkDocs Server
FROM python:3.11-slim

# Metadata
LABEL maintainer="DevOps Team"
LABEL version="v1.1.0"
LABEL description="MkDocs Documentation Server for Docker WebLogic Oracle Project"

# Variables de entorno
ENV APP_NAME="mkdocs-server"
ENV VERSION="v1.1.0"
ENV DOCKER_NAMESPACE="edissonz8809"
ENV PYTHONUNBUFFERED=1

# Instalar dependencias del sistema
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /app

# Copiar requirements y instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar archivos de la aplicación
COPY mkdocs.yml .
COPY docs/ ./docs/

# Crear usuario no-root
RUN useradd -m -u 1001 mkdocs && \
    chown -R mkdocs:mkdocs /app

# Cambiar a usuario no-root
USER mkdocs

# Exponer puerto MkDocs
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Comando por defecto
CMD ["mkdocs", "serve", "--dev-addr=0.0.0.0:8000"]
