FROM haproxy:2.6

# Instalar dependencias
USER root
RUN apt-get update && apt-get install -y \
    python3 \
    python3-requests \
    python3-flask \
    lua5.3 \
    lua-socket \
    lua-json

# Crear directorios para scripts y configuración
RUN mkdir -p /scripts /var/run

# Copiar archivos de configuración y scripts
COPY config/haproxy-advanced-integrated-fixed.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY scripts/dynamic_routing.lua /scripts/
COPY scripts/admin_api.py /scripts/
COPY scripts/admin_ui.py /scripts/
COPY scripts/start-haproxy-fixed.sh /scripts/
COPY scripts/templates /scripts/templates
COPY scripts/static /scripts/static

# Dar permisos de ejecución
RUN chmod +x /scripts/start-haproxy-fixed.sh /scripts/admin_api.py /scripts/admin_ui.py

# Exponer solo los puertos necesarios
EXPOSE 80 8081 8082 8404

# Comando de inicio
CMD ["/scripts/start-haproxy-fixed.sh"]
