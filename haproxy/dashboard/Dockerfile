FROM python:3.11-alpine

# Instalar dependencias del sistema
RUN apk add --no-cache curl

# Crear directorio de trabajo
WORKDIR /dashboard

# Copiar archivos del dashboard
COPY . .

# Hacer ejecutable el servidor
RUN chmod +x serve-dashboard.py

# Exponer puerto
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/health || exit 1

# Comando de inicio
CMD ["python3", "serve-dashboard.py"]
