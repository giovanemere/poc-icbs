# HAProxy Load Balancer

Esta guía cubre la configuración, monitoreo y optimización de HAProxy como load balancer para el cluster WebLogic.

## 🔧 Configuración de HAProxy

### Configuración Básica

El archivo principal está en `haproxy/haproxy.cfg`:

```haproxy
global
    daemon
    maxconn 4096
    log stdout local0
    stats socket /var/run/haproxy.sock mode 600 level admin

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option httplog
    option dontlognull
    retries 3

# Frontend - Punto de entrada
frontend weblogic_frontend
    bind *:8080
    
    # Logging
    capture request header Host len 32
    capture request header User-Agent len 64
    
    # Health check endpoint
    acl is_health path_beg /health
    use_backend health_check if is_health
    
    # Default backend
    default_backend weblogic_main

# Backend principal
backend weblogic_main
    balance roundrobin
    option httpchk GET /health
    
    server weblogic-1 weblogic-managed-1:7003 check
    server weblogic-2 weblogic-managed-2:7005 check

# Backend canary (opcional)
backend weblogic_canary
    balance roundrobin
    option httpchk GET /health
    
    server canary-1 weblogic-canary-1:7007 check
    server canary-2 weblogic-canary-2:7009 check

# Stats interface
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
```

### Configuración para Canary Deployment

```haproxy
frontend weblogic_frontend
    bind *:8080
    
    # Canary deployment basado en porcentaje
    acl canary_traffic rand(100) lt 10  # 10% a canary
    use_backend weblogic_canary if canary_traffic
    
    # A/B testing basado en cookies
    acl is_beta_user hdr_sub(cookie) beta=true
    use_backend weblogic_canary if is_beta_user
    
    # Canary para IPs específicas
    acl is_internal_ip src 192.168.1.0/24
    use_backend weblogic_canary if is_internal_ip
    
    default_backend weblogic_main
```

### Configuración SSL/TLS

```haproxy
frontend weblogic_frontend_ssl
    bind *:443 ssl crt /etc/ssl/certs/weblogic.pem
    
    # Redirect HTTP to HTTPS
    redirect scheme https if !{ ssl_fc }
    
    # HSTS Header
    http-response set-header Strict-Transport-Security max-age=31536000
    
    default_backend weblogic_main
```

## 📊 Dashboard y Monitoreo

### Acceso al Dashboard

El dashboard de HAProxy está disponible en:
- **URL**: http://localhost:8404/stats
- **Usuario**: admin
- **Contraseña**: admin

### Métricas Principales

| Métrica | Descripción | Ubicación en Dashboard |
|---------|-------------|----------------------|
| **Sessions** | Conexiones activas | Current Sessions |
| **Requests/sec** | Requests por segundo | Session Rate |
| **Response Time** | Tiempo de respuesta promedio | Response Time |
| **Health Status** | Estado de backends | Status column |
| **Error Rate** | Porcentaje de errores | Errors column |

### Interpretación del Dashboard

#### Estados de Servidores

| Color | Estado | Significado |
|-------|--------|-------------|
| 🟢 Verde | UP | Servidor saludable |
| 🟡 Amarillo | WARNING | Servidor con problemas menores |
| 🔴 Rojo | DOWN | Servidor no disponible |
| ⚫ Negro | MAINTENANCE | Servidor en mantenimiento |

#### Métricas Críticas

```bash
# Verificar métricas via API
curl -s http://localhost:8404/stats | grep -E "(weblogic-1|weblogic-2)" | \
  awk -F',' '{print $1 ": " $8 " requests, " $14 " errors"}'
```

## 🎯 A/B Testing

### Configuración de A/B Testing

#### Por Cookies

```haproxy
frontend weblogic_frontend
    bind *:8080
    
    # Capturar cookie de experimento
    capture request header Cookie len 128
    
    # A/B test basado en cookie
    acl experiment_a hdr_sub(cookie) experiment=a
    acl experiment_b hdr_sub(cookie) experiment=b
    
    use_backend weblogic_main if experiment_a
    use_backend weblogic_canary if experiment_b
    
    # Default: asignar aleatoriamente
    acl random_a rand(100) lt 50
    use_backend weblogic_main if random_a
    default_backend weblogic_canary
```

#### Por Headers Personalizados

```haproxy
frontend weblogic_frontend
    bind *:8080
    
    # A/B test basado en header personalizado
    acl version_a hdr(X-Version) -i "a"
    acl version_b hdr(X-Version) -i "b"
    
    use_backend weblogic_main if version_a
    use_backend weblogic_canary if version_b
    
    default_backend weblogic_main
```

#### Por Geolocalización

```haproxy
frontend weblogic_frontend
    bind *:8080
    
    # A/B test por país (usando header de CDN)
    acl us_users hdr(CF-IPCountry) -i "US"
    acl eu_users hdr(CF-IPCountry) -i "DE" "FR" "UK"
    
    use_backend weblogic_main if us_users
    use_backend weblogic_canary if eu_users
    
    default_backend weblogic_main
```

### Script de Control de A/B Testing

```bash
#!/bin/bash
# ab-test-control.sh

ACTION="$1"
PERCENTAGE="$2"

case "$ACTION" in
    "start")
        echo "Iniciando A/B test con $PERCENTAGE% en versión B"
        # Actualizar configuración HAProxy
        sed -i "s/rand(100) lt [0-9]*/rand(100) lt $PERCENTAGE/" haproxy/haproxy.cfg
        docker-compose restart haproxy-lb
        ;;
    "stop")
        echo "Deteniendo A/B test"
        sed -i "s/rand(100) lt [0-9]*/rand(100) lt 0/" haproxy/haproxy.cfg
        docker-compose restart haproxy-lb
        ;;
    "status")
        echo "Estado actual del A/B test:"
        curl -s http://localhost:8404/stats | grep -E "(main|canary)" | \
            awk -F',' '{print $1 ": " $8 " requests (" $9 " req/s)"}'
        ;;
    *)
        echo "Uso: $0 {start|stop|status} [percentage]"
        exit 1
        ;;
esac
```

## 🔍 Monitoreo Avanzado

### Logs Personalizados

```haproxy
# Configuración de logging avanzado
global
    log stdout local0 info

defaults
    log global
    option httplog
    
    # Log format personalizado
    capture request header Host len 32
    capture request header User-Agent len 64
    capture request header X-Forwarded-For len 64
```

### Métricas en Tiempo Real

```bash
#!/bin/bash
# real-time-metrics.sh

while true; do
    clear
    echo "=== HAProxy Metrics - $(date) ==="
    echo
    
    # Requests por backend
    echo "📊 Requests por Backend:"
    curl -s http://localhost:8404/stats | grep -E "weblogic-(main|canary)" | \
        awk -F',' '{printf "%-20s: %8s requests (%s req/s)\n", $1, $8, $9}'
    
    echo
    
    # Errores por backend
    echo "❌ Errores por Backend:"
    curl -s http://localhost:8404/stats | grep -E "weblogic-(main|canary)" | \
        awk -F',' '{printf "%-20s: %8s errors\n", $1, $14}'
    
    echo
    
    # Tiempo de respuesta
    echo "⏱️  Tiempo de Respuesta:"
    for i in {1..3}; do
        time=$(curl -w "%{time_total}" -s -o /dev/null http://localhost:8080/health)
        echo "Test $i: ${time}s"
    done
    
    sleep 5
done
```

### Alertas Automáticas

```bash
#!/bin/bash
# haproxy-alerts.sh

# Configuración
ERROR_THRESHOLD=10
RESPONSE_TIME_THRESHOLD=2.0
CHECK_INTERVAL=30

while true; do
    # Verificar errores
    errors=$(curl -s http://localhost:8404/stats | grep weblogic-main | \
             awk -F',' '{print $14}')
    
    if [ "$errors" -gt "$ERROR_THRESHOLD" ]; then
        echo "🚨 ALERTA: $errors errores detectados (threshold: $ERROR_THRESHOLD)"
        # Enviar notificación (email, Slack, etc.)
    fi
    
    # Verificar tiempo de respuesta
    response_time=$(curl -w "%{time_total}" -s -o /dev/null http://localhost:8080/health)
    
    if (( $(echo "$response_time > $RESPONSE_TIME_THRESHOLD" | bc -l) )); then
        echo "🚨 ALERTA: Tiempo de respuesta alto: ${response_time}s"
    fi
    
    sleep $CHECK_INTERVAL
done
```

## ⚡ Optimización de Rendimiento

### Configuración de Performance

```haproxy
global
    # Optimizaciones globales
    maxconn 10000
    nbproc 2                    # Usar 2 procesos
    cpu-map 1 0                 # Mapear proceso 1 a CPU 0
    cpu-map 2 1                 # Mapear proceso 2 a CPU 1

defaults
    # Timeouts optimizados
    timeout connect 3s
    timeout client 30s
    timeout server 30s
    timeout http-keep-alive 10s
    timeout http-request 5s
    
    # Optimizaciones HTTP
    option http-server-close
    option forwardfor
    option redispatch
    
    # Compresión
    compression algo gzip
    compression type text/html text/plain text/css text/javascript application/javascript
```

### Balanceado Avanzado

```haproxy
backend weblogic_main
    # Algoritmos de balanceado
    balance leastconn           # Menos conexiones
    # balance source            # Por IP origen
    # balance uri               # Por URI
    # balance hdr(Host)         # Por header Host
    
    # Health checks avanzados
    option httpchk GET /health HTTP/1.1\r\nHost:\ localhost
    http-check expect status 200
    
    # Configuración de servidores
    server weblogic-1 weblogic-managed-1:7003 check inter 5s rise 2 fall 3 weight 100
    server weblogic-2 weblogic-managed-2:7005 check inter 5s rise 2 fall 3 weight 100
    
    # Servidor de backup
    server backup-server backup-weblogic:7003 check backup
```

### Sticky Sessions

```haproxy
backend weblogic_main
    # Sticky sessions por cookie
    cookie JSESSIONID prefix nocache
    
    server weblogic-1 weblogic-managed-1:7003 check cookie s1
    server weblogic-2 weblogic-managed-2:7005 check cookie s2
```

## 🔒 Seguridad

### Rate Limiting

```haproxy
frontend weblogic_frontend
    bind *:8080
    
    # Rate limiting por IP
    stick-table type ip size 100k expire 30s store http_req_rate(10s)
    http-request track-sc0 src
    http-request deny if { sc_http_req_rate(0) gt 20 }
    
    default_backend weblogic_main
```

### Protección DDoS

```haproxy
frontend weblogic_frontend
    bind *:8080
    
    # Protección contra DDoS
    stick-table type ip size 100k expire 30s store gpc0,http_req_rate(10s)
    
    # Bloquear IPs con muchas conexiones
    http-request track-sc0 src
    http-request deny if { sc_get_gpc0(0) gt 0 }
    
    # Marcar IPs sospechosas
    http-request sc-inc-gpc0(0) if { sc_http_req_rate(0) gt 50 }
    
    default_backend weblogic_main
```

### Headers de Seguridad

```haproxy
frontend weblogic_frontend
    bind *:8080
    
    # Headers de seguridad
    http-response set-header X-Frame-Options DENY
    http-response set-header X-Content-Type-Options nosniff
    http-response set-header X-XSS-Protection "1; mode=block"
    http-response set-header Referrer-Policy strict-origin-when-cross-origin
    
    default_backend weblogic_main
```

## 🛠️ Troubleshooting

### Problemas Comunes

#### Backend Servers Down

```bash
# Verificar estado de servidores
curl -s http://localhost:8404/stats | grep -E "weblogic-[12]" | \
    awk -F',' '{print $1 ": " $18}'

# Reiniciar servidor específico
docker-compose restart weblogic-managed-1

# Verificar logs
docker-compose logs haproxy-lb | tail -50
```

#### High Response Time

```bash
# Verificar tiempo de respuesta por servidor
for server in weblogic-managed-1:7003 weblogic-managed-2:7005; do
    echo "Testing $server:"
    curl -w "Time: %{time_total}s\n" -s -o /dev/null http://$server/health
done

# Verificar carga del sistema
docker stats
```

#### SSL/TLS Issues

```bash
# Verificar certificado
openssl x509 -in /path/to/cert.pem -text -noout

# Test SSL
curl -I https://localhost:443

# Verificar configuración SSL en HAProxy
haproxy -c -f haproxy/haproxy.cfg
```

### Logs de Debug

```haproxy
global
    # Habilitar debug
    debug
    
defaults
    # Logs detallados
    option httplog
    option log-health-checks
    
    # Capturar más información
    capture request header Authorization len 64
    capture response header Set-Cookie len 64
```

## 📚 Integración con Documentación MkDocs

### Configuración para Servir Documentación

HAProxy puede servir tanto las aplicaciones WebLogic como la documentación MkDocs de manera unificada:

```haproxy
frontend weblogic_frontend
    bind *:8080
    bind *:443 ssl crt /etc/ssl/certs/weblogic.pem
    
    # === ROUTING DE DOCUMENTACIÓN ===
    
    # Documentación principal
    acl is_docs path_beg /docs
    use_backend mkdocs_main if is_docs
    
    # Documentación por versión
    acl is_docs_v1 path_beg /docs/v1
    acl is_docs_v2 path_beg /docs/v2
    use_backend mkdocs_v1 if is_docs_v1
    use_backend mkdocs_v2 if is_docs_v2
    
    # Documentación de desarrollo
    acl is_docs_dev path_beg /docs/dev
    use_backend mkdocs_dev if is_docs_dev
    
    # === ROUTING DE APLICACIONES ===
    
    # Health checks
    acl is_health path_beg /health
    use_backend health_check if is_health
    
    # Aplicaciones WebLogic (default)
    default_backend weblogic_main

# === BACKENDS DE DOCUMENTACIÓN ===

# Documentación principal (producción)
backend mkdocs_main
    balance roundrobin
    option httpchk GET /
    
    # Reescribir path para MkDocs
    http-request set-path %[path,regsub(^/docs,/)]
    
    # Headers para documentación estática
    http-response set-header Cache-Control "public, max-age=3600"
    http-response set-header X-Content-Type-Options nosniff
    
    server mkdocs-prod mkdocs-server:8000 check

# Documentación desarrollo (sin cache)
backend mkdocs_dev
    balance roundrobin
    option httpchk GET /
    
    http-request set-path %[path,regsub(^/docs/dev,/)]
    http-response set-header Cache-Control "no-cache, no-store"
    
    server mkdocs-dev mkdocs-dev-server:8000 check

# Documentación versionada
backend mkdocs_v1
    balance roundrobin
    option httpchk GET /
    
    http-request set-path %[path,regsub(^/docs/v1,/)]
    http-response set-header Cache-Control "public, max-age=86400"
    
    server mkdocs-v1 mkdocs-v1-server:8000 check
```

### Docker Compose para MkDocs

Agrega estos servicios a tu `docker-compose.yml`:

```yaml
services:
  # Documentación principal
  mkdocs-server:
    build:
      context: .
      dockerfile: Dockerfile.mkdocs
    container_name: mkdocs-server
    volumes:
      - ./site:/app/site:ro
    ports:
      - "8000:8000"
    networks:
      - weblogic-network
    restart: unless-stopped

  # Documentación desarrollo
  mkdocs-dev-server:
    build:
      context: .
      dockerfile: Dockerfile.mkdocs-dev
    container_name: mkdocs-dev-server
    volumes:
      - ./docs:/app/docs
      - ./mkdocs.yml:/app/mkdocs.yml
    ports:
      - "8001:8000"
    networks:
      - weblogic-network
    restart: unless-stopped
    command: mkdocs serve --dev-addr 0.0.0.0:8000

  # HAProxy actualizado
  haproxy-lb:
    image: haproxy:2.8
    container_name: haproxy-lb
    ports:
      - "8080:8080"
      - "8404:8404"
      - "443:443"
    volumes:
      - ./haproxy:/usr/local/etc/haproxy:ro
    networks:
      - weblogic-network
    depends_on:
      - weblogic-admin
      - mkdocs-server
      - mkdocs-dev-server
    restart: unless-stopped
```

### Dockerfile para MkDocs

```dockerfile
# Dockerfile.mkdocs
FROM nginx:alpine

# Copiar sitio construido
COPY site/ /usr/share/nginx/html/

# Configuración nginx para MkDocs
COPY nginx/mkdocs.conf /etc/nginx/conf.d/default.conf

EXPOSE 8000

CMD ["nginx", "-g", "daemon off;"]
```

### Configuración Nginx para MkDocs

```nginx
# nginx/mkdocs.conf
server {
    listen 8000;
    server_name _;
    
    root /usr/share/nginx/html;
    index index.html;
    
    # Configuración para MkDocs
    location / {
        try_files $uri $uri/ /index.html;
        
        # Headers de cache para HTML
        expires 1h;
        add_header Cache-Control "public";
    }
    
    # Assets estáticos con cache largo
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # API de búsqueda
    location /search/ {
        expires 5m;
        add_header Cache-Control "public";
    }
}
```

### Script de Gestión de Documentación

```bash
#!/bin/bash
# manage-docs.sh

ACTION="$1"
VERSION="${2:-main}"

case "$ACTION" in
    "deploy")
        echo "🚀 Desplegando documentación..."
        
        # Construir documentación
        ./build-docs.sh build
        
        # Reiniciar contenedor
        docker-compose restart mkdocs-server
        
        echo "✅ Documentación desplegada en: http://localhost:8080/docs"
        ;;
        
    "deploy-dev")
        echo "🚀 Desplegando documentación de desarrollo..."
        
        docker-compose restart mkdocs-dev-server
        
        echo "✅ Docs de desarrollo en: http://localhost:8080/docs/dev"
        ;;
        
    "status")
        echo "📊 Estado de servicios de documentación:"
        docker-compose ps | grep mkdocs
        
        echo -e "\n📈 Tráfico de documentación:"
        curl -s http://localhost:8404/stats | grep mkdocs | \
            awk -F',' '{printf "%-20s: %8s requests\n", $1, $8}'
        ;;
        
    *)
        echo "Uso: $0 {deploy|deploy-dev|status}"
        exit 1
        ;;
esac
```

### Configuración con Autenticación

Para documentación interna protegida:

```haproxy
frontend weblogic_frontend
    bind *:8080
    
    # Documentación pública
    acl is_public_docs path_beg /docs/public
    use_backend mkdocs_public if is_public_docs
    
    # Documentación interna (requiere auth)
    acl is_internal_docs path_beg /docs/internal
    acl is_authenticated http_auth(docs-users)
    
    http-request auth realm "Documentación Interna" if is_internal_docs !is_authenticated
    use_backend mkdocs_internal if is_internal_docs is_authenticated
    
    default_backend weblogic_main

# Lista de usuarios
userlist docs-users
    user admin password $6$rounds=10000$salt$hash
    user developer password $6$rounds=10000$salt$hash

backend mkdocs_internal
    http-request set-path %[path,regsub(^/docs/internal,/)]
    server mkdocs-internal mkdocs-internal-server:8000 check
```

### Monitoreo de Documentación

En el dashboard de HAProxy podrás ver:

- **Requests a documentación**: Tráfico específico a `/docs`
- **Tiempo de respuesta**: Performance de la documentación
- **Errores**: Problemas de acceso a docs
- **Backends activos**: Estado de servidores MkDocs

### URLs de Acceso Final

Con esta configuración tendrás:

| Servicio | URL | Descripción |
|----------|-----|-------------|
| **Documentación Principal** | http://localhost:8080/docs | Docs de producción |
| **Documentación Desarrollo** | http://localhost:8080/docs/dev | Docs en desarrollo |
| **Documentación v1** | http://localhost:8080/docs/v1 | Versión específica |
| **Aplicación Principal** | http://localhost:8080 | WebLogic apps |
| **HAProxy Stats** | http://localhost:8404/stats | Estadísticas |

### Script de Actualización de HAProxy

```bash
#!/bin/bash
# update-haproxy-docs.sh

echo "🔄 Actualizando configuración HAProxy para documentación..."

# Backup configuración actual
cp haproxy/haproxy.cfg haproxy/haproxy.cfg.backup

# Validar nueva configuración
if docker exec haproxy-lb haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg; then
    echo "✅ Configuración válida"
    
    # Recargar HAProxy sin downtime
    docker exec haproxy-lb kill -USR2 1
    
    echo "✅ HAProxy recargado exitosamente"
else
    echo "❌ Error en configuración, restaurando backup"
    cp haproxy/haproxy.cfg.backup haproxy/haproxy.cfg
    exit 1
fi
```

## 📋 Mejores Prácticas

### Configuración
- Usa health checks apropiados para tu aplicación
- Configura timeouts según tu SLA
- Implementa rate limiting para proteger backends
- Usa sticky sessions solo si es necesario

### Documentación
- Configura cache apropiado para docs estáticas
- Usa diferentes backends para dev/prod docs
- Implementa autenticación para docs internas
- Monitorea tráfico de documentación

### Monitoreo
- Monitorea métricas clave constantemente
- Configura alertas para umbrales críticos
- Mantén logs por tiempo suficiente para análisis
- Usa dashboards externos para mejor visualización

### Seguridad
- Implementa rate limiting
- Usa headers de seguridad
- Configura SSL/TLS correctamente
- Mantén HAProxy actualizado

### Performance
- Ajusta timeouts según tu aplicación
- Usa algoritmos de balanceado apropiados
- Configura compresión para contenido estático
- Monitorea y ajusta según métricas reales
