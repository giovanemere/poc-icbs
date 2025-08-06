FROM haproxy:2.6

# Instalar dependencias
USER root
RUN apt-get update && apt-get install -y \
    python3 \
    python3-requests \
    python3-flask \
    lua5.3 \
    lua-socket \
    lua-json \
    socat

# Crear directorios para scripts y configuración
RUN mkdir -p /scripts /var/run

# Copiar archivos de configuración y scripts
COPY haproxy/config/haproxy-advanced.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY haproxy/scripts/dynamic_routing.lua /scripts/
COPY haproxy/scripts/admin_api.py /scripts/
COPY haproxy/scripts/admin_ui.py /scripts/
COPY haproxy/scripts/start-haproxy.sh /scripts/
COPY haproxy/scripts/templates /scripts/templates
COPY haproxy/scripts/static /scripts/static

# Dar permisos de ejecución
RUN chmod +x /scripts/start-haproxy.sh /scripts/admin_api.py /scripts/admin_ui.py

# Exponer puertos
EXPOSE 80 443 8404 8080 8081 8082

# Comando de inicio
CMD ["/scripts/start-haproxy.sh"]
