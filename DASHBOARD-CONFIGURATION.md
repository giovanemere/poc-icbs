# Configuración del Dashboard Profesional

## Resumen de Cambios Realizados

### 1. Servicio Dashboard en Docker Compose

Se agregó el servicio `dashboard` en `config/docker-compose-images.yml`:

```yaml
dashboard:
  build:
    context: ../haproxy/dashboard
    dockerfile: Dockerfile
  container_name: dashboard
  ports:
    - "8001:8000"   # Dashboard profesional (puerto alternativo para evitar conflictos)
  networks:
    weblogic-network:
      ipv4_address: 172.23.0.7
  environment:
    - TZ=${TZ:-America/Mexico_City}
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/api/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 30s
  restart: unless-stopped
```

### 2. Configuración de HAProxy

HAProxy ya tenía la configuración correcta para el dashboard:

- **ACL**: `acl path_dashboard path_beg /dashboard`
- **Backend**: `dashboard-backend` apuntando a `dashboard:8000`
- **Reescritura de rutas**: Elimina `/dashboard` del path antes de enviar al backend

### 3. Scripts Creados

#### `scripts/test-dashboard.sh`
Script completo para probar el dashboard:
- Verifica contenedores en ejecución
- Prueba acceso directo (puerto 8001)
- Prueba acceso vía HAProxy (puerto 8080/dashboard)
- Verifica APIs de health check y estadísticas
- Muestra logs y configuración

#### `scripts/build-dashboard.sh`
Script para construir y desplegar el dashboard:
- Construye la imagen Docker
- Despliega el contenedor
- Verifica el despliegue
- Prueba conectividad

### 4. Documentación Actualizada

Se actualizó `README.md` con:
- Información del dashboard en la tabla de URLs
- Sección dedicada "Dashboard Profesional"
- Instrucciones de uso y prueba

### 5. Script Principal Actualizado

Se actualizó `start-with-images.sh` para incluir:
- Dashboard en la lista de servicios
- URLs del dashboard en el estado

## URLs de Acceso

| Tipo de Acceso | URL | Descripción |
|----------------|-----|-------------|
| **Vía HAProxy (Recomendado)** | `http://localhost:8080/dashboard/` | Acceso a través del load balancer |
| **Acceso Directo** | `http://localhost:8001/` | Acceso directo al contenedor |
| **API Health Check** | `http://localhost:8080/dashboard/api/health` | Verificación de salud |
| **API Estadísticas** | `http://localhost:8080/dashboard/api/stats` | Datos en tiempo real |

## Arquitectura de Red

```
Cliente
   ↓
HAProxy (172.23.0.5:80)
   ↓ /dashboard/*
Dashboard (172.23.0.7:8000)
```

## Comandos de Uso

### Construcción y Despliegue
```bash
# Construir y desplegar dashboard
./scripts/build-dashboard.sh

# Probar dashboard completo
./scripts/test-dashboard.sh

# Iniciar todos los servicios (incluyendo dashboard)
./start-with-images.sh start
```

### Verificación
```bash
# Ver estado de todos los servicios
./start-with-images.sh status

# Ver logs del dashboard
./start-with-images.sh logs dashboard

# Probar API directamente
curl -s http://localhost:8001/api/health | jq .
curl -s http://localhost:8080/dashboard/api/stats | jq .
```

### Solución de Problemas
```bash
# Reconstruir dashboard
docker stop dashboard
docker rm dashboard
./scripts/build-dashboard.sh

# Ver logs detallados
docker logs dashboard -f

# Verificar conectividad interna
docker exec haproxy curl -s http://dashboard:8000/api/health
```

## Características del Dashboard

### 1. Monitoreo en Tiempo Real
- Estado de servicios (WebLogic A/B, HAProxy, Oracle DB)
- Métricas de rendimiento y tiempo de respuesta
- Estadísticas de tráfico actual y pico

### 2. Visualización de Estrategias
- Estado del A/B Testing con porcentajes
- Información del Canary Deployment
- Distribución de requests entre versiones

### 3. API REST
- `/api/health` - Health check
- `/api/stats` - Estadísticas en tiempo real

### 4. Interfaz Profesional
- Dashboard HTML responsivo
- Actualización automática de datos
- Visualización clara de métricas

## Notas Técnicas

1. **Puertos**: El dashboard usa el puerto interno 8000 y se expone en el puerto 8001 para evitar conflictos con HAProxy.

2. **Health Checks**: Configurados tanto en Docker como en HAProxy para monitoreo automático.

3. **Reescritura de Rutas**: HAProxy elimina el prefijo `/dashboard` antes de enviar requests al backend.

4. **Datos Simulados**: El dashboard actualmente usa datos simulados. En producción, estos deberían conectarse a métricas reales de HAProxy y los servicios.

5. **Seguridad**: El acceso vía HAProxy está disponible públicamente. En producción, considera agregar autenticación.
