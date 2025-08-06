# ⚖️ HAProxy Load Balancer

## Introducción

HAProxy es el componente central de balanceado de carga en nuestro sistema, proporcionando distribución inteligente de tráfico, health checks automáticos y interfaces de administración avanzadas.

## Configuración Actual

### Puertos y Servicios

| Puerto | Servicio | Descripción | URL |
|--------|----------|-------------|-----|
| 8083 | Load Balancer | Balanceador principal | http://localhost:8083 |
| 8082 | Admin UI | Interfaz administrativa | http://localhost:8082 |
| 8404 | Stats UI | Estadísticas y métricas | http://localhost:8404/stats |
| 8444 | HTTPS | Balanceador HTTPS | https://localhost:8444 |
| 8087 | API | API de gestión | http://localhost:8087 |

### Credenciales de Acceso
- **Admin UI**: `admin:admin123`
- **Stats UI**: `admin:admin123`

## Arquitectura HAProxy

### Frontends Configurados

#### 1. WebLogic Frontend (Puerto 8083)
```haproxy
frontend weblogic_frontend
    bind *:80
    mode http
    
    # Routing de documentación
    acl is_docs path_beg /docs
    use_backend mkdocs_main if is_docs
    
    # Routing de aplicaciones
    acl is_feature_flags path_beg /feature-flags
    use_backend weblogic_main if is_feature_flags
    
    # Health check
    acl is_health path_beg /health
    use_backend health_backend if is_health
    
    # Default backend
    default_backend weblogic_main
```

#### 2. HTTPS Frontend (Puerto 8444)
```haproxy
frontend weblogic_https_frontend
    bind *:443 ssl crt /usr/local/etc/haproxy/certs/
    mode http
    redirect scheme https if !{ ssl_fc }
```

### Backends Configurados

#### 1. WebLogic Main Backend
- **Servidores**: weblogic-a:7001, weblogic-b:7002
- **Algoritmo**: roundrobin
- **Health Check**: GET /console
- **Balanceado**: 50/50 (configurable para canary)

#### 2. MkDocs Backends
- **mkdocs_main**: Documentación principal
- **mkdocs_dev**: Documentación desarrollo (sin cache)
- **mkdocs_v1**: Documentación versionada (cache 24h)

#### 3. Health Backend
- Endpoint de verificación de estado del sistema

## Funcionalidades Avanzadas

### 1. Despliegues Canary

#### Configuración de Tráfico
```bash
# Configurar distribución 70/30
./scripts/canary/manage-traffic.sh --weblogic-a 70 --weblogic-b 30

# Configuración 100% en A (rollback)
./scripts/canary/manage-traffic.sh --weblogic-a 100 --weblogic-b 0
```

#### Monitoreo Canary
- Métricas en tiempo real en Stats UI
- Logs detallados de distribución
- Alertas automáticas de fallos

### 2. Health Checks Inteligentes

#### Configuración Actual
```haproxy
option httpchk GET /console
http-check expect status 200
```

#### Tipos de Health Checks
- **HTTP**: Verificación de endpoints específicos
- **TCP**: Conectividad básica
- **Custom**: Scripts personalizados

### 3. SSL/TLS Termination

#### Configuración HTTPS
- Certificados en `/usr/local/etc/haproxy/certs/`
- Redirección automática HTTP → HTTPS
- Soporte SNI para múltiples dominios

## Interfaces de Administración

### 1. Admin UI (Puerto 8082)

#### Funcionalidades
- **Dashboard**: Vista general del sistema
- **Server Management**: Habilitar/deshabilitar servidores
- **Traffic Control**: Ajustar pesos de balanceo
- **Configuration**: Editar configuración en vivo
- **Logs**: Visualización de logs en tiempo real

#### Acceso
```bash
# Navegador
http://localhost:8082

# API
curl -u admin:admin123 http://localhost:8082/api/servers
```

### 2. Stats UI (Puerto 8404)

#### Métricas Disponibles
- **Requests/sec**: Tráfico por segundo
- **Response Times**: Tiempos de respuesta
- **Error Rates**: Tasas de error
- **Server Status**: Estado de backends
- **Connection Stats**: Estadísticas de conexiones

#### Formato de Datos
```bash
# CSV para análisis
curl -u admin:admin123 "http://localhost:8404/stats;csv"

# JSON para APIs
curl -u admin:admin123 "http://localhost:8404/stats;json"
```

## Configuración y Personalización

### 1. Archivo de Configuración Principal

**Ubicación**: `haproxy/config/haproxy.cfg`

#### Secciones Principales
```haproxy
# Configuración global
global
    daemon
    maxconn 4096
    log stdout local0

# Defaults
defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

# Frontends
frontend weblogic_frontend
    # ... configuración

# Backends  
backend weblogic_main
    # ... configuración
```

### 2. Actualización Dinámica

#### Auto-actualización
```bash
# Actualización automática con IPs dinámicas
./scripts/auto-update-haproxy.sh

# Recarga sin downtime
docker exec haproxy haproxy -f /usr/local/etc/haproxy/haproxy.cfg -c
docker kill -USR2 haproxy
```

#### Validación de Configuración
```bash
# Validar sintaxis
docker exec haproxy haproxy -f /usr/local/etc/haproxy/haproxy.cfg -c

# Test de configuración
./scripts/validation/validate-config-consistency.sh
```

## Monitoreo y Alertas

### 1. Métricas Clave

#### Performance
- **Request Rate**: > 100 req/s normal
- **Response Time**: < 500ms objetivo
- **Error Rate**: < 1% aceptable
- **Availability**: > 99.9% objetivo

#### Recursos
- **CPU Usage**: < 80% normal
- **Memory Usage**: < 70% normal
- **Connections**: < 80% del máximo
- **Bandwidth**: Monitoreo continuo

### 2. Logs y Diagnóstico

#### Ubicaciones de Logs
```bash
# Logs del contenedor
docker logs haproxy

# Logs específicos de HAProxy
docker exec haproxy tail -f /var/log/haproxy.log

# Logs de acceso
docker exec haproxy tail -f /var/log/access.log
```

#### Análisis de Logs
```bash
# Errores recientes
docker logs haproxy 2>&1 | grep -i error | tail -10

# Requests por minuto
docker logs haproxy 2>&1 | grep "$(date '+%d/%b/%Y:%H:%M')" | wc -l

# Top IPs
docker logs haproxy 2>&1 | awk '{print $9}' | sort | uniq -c | sort -nr | head -10
```

## Troubleshooting

### Problemas Comunes

#### 1. Backends No Disponibles
```bash
# Verificar estado
curl http://localhost:8404/stats

# Verificar conectividad
docker exec haproxy nc -zv weblogic-a 7001
docker exec haproxy nc -zv weblogic-b 7002

# Reiniciar backends
./scripts/core/docker-compose-wrapper.sh restart weblogic-a weblogic-b
```

#### 2. Configuración Inválida
```bash
# Validar configuración
docker exec haproxy haproxy -f /usr/local/etc/haproxy/haproxy.cfg -c

# Restaurar backup
cp haproxy/config/haproxy.cfg.bak haproxy/config/haproxy.cfg
./scripts/auto-update-haproxy.sh
```

#### 3. Performance Issues
```bash
# Verificar recursos
docker stats haproxy

# Ajustar configuración
# Aumentar maxconn en haproxy.cfg
# Ajustar timeouts
# Optimizar algoritmos de balanceo
```

### Comandos de Diagnóstico

```bash
# Estado completo del sistema
./scripts/utilities/diagnose-and-fix.sh

# Debug específico de HAProxy
./scripts/validation/debug-haproxy.sh

# Verificar URLs
./scripts/validation/check-urls.sh

# Test de performance
./scripts/testing/test-performance.sh
```

## Optimización y Tuning

### 1. Performance Tuning

#### Configuración Optimizada
```haproxy
global
    maxconn 8192
    nbproc 2
    cpu-map 1 0
    cpu-map 2 1

defaults
    option httplog
    option dontlognull
    option http-server-close
    option forwardfor
    option redispatch
```

#### Algoritmos de Balanceo
- **roundrobin**: Distribución equitativa
- **leastconn**: Menor número de conexiones
- **source**: Basado en IP origen
- **uri**: Basado en URI

### 2. Seguridad

#### Configuración Segura
```haproxy
# Rate limiting
stick-table type ip size 100k expire 30s store http_req_rate(10s)
http-request track-sc0 src
http-request deny if { sc_http_req_rate(0) gt 20 }

# Headers de seguridad
http-response set-header X-Frame-Options DENY
http-response set-header X-Content-Type-Options nosniff
http-response set-header X-XSS-Protection "1; mode=block"
```

#### SSL/TLS Hardening
```haproxy
# Configuración SSL segura
bind *:443 ssl crt /certs/ no-sslv3 no-tlsv10 no-tlsv11
ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384
ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11
```

## Integración con Otros Servicios

### 1. MkDocs Integration
- Routing automático `/docs` → mkdocs-server
- Cache headers configurables
- Múltiples versiones de documentación

### 2. WebLogic Integration
- Health checks específicos para WebLogic
- Session affinity para aplicaciones stateful
- Failover automático entre instancias

### 3. Monitoring Integration
- Exportación de métricas a Prometheus
- Integración con Grafana
- Alertas automáticas

---

## Enlaces Relacionados

- [Configuración Detallada HAProxy](guides/haproxy-setup.md)
- [Integración HAProxy-MkDocs](mkdocs-haproxy-integration.md)
- [Guía de Troubleshooting](guides/troubleshooting.md)
- [Scripts de Automatización](scripts/index.md)
- [Arquitectura del Sistema](arquitectura.md)
