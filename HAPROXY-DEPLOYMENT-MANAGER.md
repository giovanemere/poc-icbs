# HAProxy Deployment Manager

## 🎯 Descripción

El **HAProxy Deployment Manager** es un sistema avanzado de gestión de despliegues que encontramos en tu proyecto. Proporciona una interfaz web profesional para gestionar estrategias de despliegue como Testing A/B, Canary Deployment y monitoreo en tiempo real.

## 📁 Ubicación de Archivos

### Servidor Principal
- **API de Administración**: `haproxy/scripts/admin_api.py`
- **Interfaz Web**: `haproxy/scripts/admin_ui.py`
- **Verificación de URLs**: `haproxy/scripts/url_status.py`

### Templates HTML
- **Layout Principal**: `haproxy/scripts/templates/layout.html`
- **Dashboard**: `haproxy/scripts/templates/index.html`
- **Testing A/B**: `haproxy/scripts/templates/ab_testing.html`
- **Canary Deployment**: `haproxy/scripts/templates/canary.html`
- **Gestión de Servidores**: `haproxy/scripts/templates/server_weights.html`
- **Mapa de Servicios**: `haproxy/scripts/templates/service_map.html`
- **Estado de URLs**: `haproxy/scripts/templates/url_status.html`

### Templates Alternativos
- **Base Template**: `haproxy/templates/base.html`
- **Server Weights**: `haproxy/templates/server_weights.html`

## 🚀 Características Principales

### 1. **Dashboard Principal**
- Vista general del estado de todos los servicios
- Métricas en tiempo real
- Estado de Testing A/B y Canary Deployment
- Información de backends (WebLogic A, B, Feature Flags)

### 2. **Testing A/B**
- Configuración de porcentajes de tráfico
- Visualización con barras de progreso
- Activación/desactivación dinámica
- Interfaz intuitiva para ajustar pesos

### 3. **Canary Deployment**
- Despliegue gradual de nuevas versiones
- Control de porcentaje de tráfico canary
- Monitoreo del estado de despliegue
- Rollback rápido si es necesario

### 4. **Gestión de Servidores**
- Activar/desactivar servidores backend
- Ajustar pesos de balanceeo
- Estado en tiempo real de cada servidor
- Configuración dinámica sin reiniciar HAProxy

### 5. **Monitoreo y Estadísticas**
- Estado de conectividad de URLs
- Métricas de rendimiento
- Logs en tiempo real
- Mapa visual de servicios

### 6. **API REST**
- Endpoints para configuración dinámica
- Integración con scripts automatizados
- Respuestas en formato JSON
- Autenticación y seguridad

## 🌐 URLs de Acceso

| Componente | URL | Descripción |
|------------|-----|-------------|
| **Panel Principal** | `http://localhost:8082` | Interfaz web principal del manager |
| **API de Administración** | `http://localhost:8081/api` | API REST para configuración |
| **Estadísticas HAProxy** | `http://localhost:8404/stats` | Estadísticas nativas de HAProxy |
| **HAProxy Frontend** | `http://localhost:8080` | Load balancer principal |

## 🔧 Endpoints de la API

### Configuración
- `GET /api/config` - Obtener configuración actual
- `POST /api/config/ab` - Configurar Testing A/B
- `POST /api/config/canary` - Configurar Canary Deployment

### Estadísticas
- `GET /api/stats` - Obtener estadísticas de HAProxy
- `GET /api/backends` - Información de backends
- `GET /api/servers` - Estado de servidores

### Gestión
- `POST /api/server/enable` - Activar servidor
- `POST /api/server/disable` - Desactivar servidor
- `POST /api/server/weight` - Cambiar peso de servidor

## 🎛️ Funcionalidades del Panel Web

### Dashboard Principal
```
┌─────────────────┬─────────────────┬─────────────────┬─────────────────┐
│   Testing A/B   │ Canary Deploy   │   WebLogic A    │   WebLogic B    │
│   [Activo/Inac] │  [Activo/Inac]  │  [UP/DOWN]      │  [UP/DOWN]      │
│   A: 60% B: 40% │  Canary: 20%    │  Conexiones: 25 │  Conexiones: 15 │
│   [Configurar]  │  [Configurar]   │  [Gestionar]    │  [Gestionar]    │
└─────────────────┴─────────────────┴─────────────────┴─────────────────┘
```

### Testing A/B
- Slider para ajustar porcentaje de tráfico
- Vista previa de la distribución
- Botón de activar/desactivar
- Historial de cambios

### Canary Deployment
- Control de porcentaje canary
- Plan de despliegue gradual
- Métricas de éxito/fallo
- Rollback automático

## 🚀 Cómo Iniciar el HAProxy Deployment Manager

### Método 1: Script Dedicado
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./start-haproxy-manager.sh
```

### Método 2: Con el Entorno Completo
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./start-dashboard-integrated.sh
```

### Método 3: Solo HAProxy
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./start-multi-env.sh start haproxy
```

## 🔐 Credenciales

### HAProxy Stats
- **Usuario**: `admin`
- **Contraseña**: `admin123`

### Panel de Administración
- No requiere autenticación (configuración local)
- Acceso restringido a localhost por seguridad

## 🛠️ Configuración Técnica

### Puertos Utilizados
- **8080**: HAProxy Frontend (HTTP)
- **8081**: API de Administración
- **8082**: Panel Web de Administración
- **8404**: Estadísticas de HAProxy
- **8443**: HAProxy Frontend (HTTPS)

### Dependencias Python
- Flask (servidor web)
- Requests (comunicación con API)
- Jinja2 (templates)

### Archivos de Configuración
- `haproxy.cfg`: Configuración principal de HAProxy
- Templates HTML con Bootstrap 5
- CSS personalizado para tema oscuro/claro

## 📊 Casos de Uso

### 1. Despliegue de Nueva Versión
1. Acceder al panel: `http://localhost:8082`
2. Ir a "Canary Deployment"
3. Configurar 5% de tráfico inicial
4. Monitorear métricas
5. Aumentar gradualmente hasta 100%

### 2. Testing A/B
1. Acceder al panel: `http://localhost:8082`
2. Ir a "Testing A/B"
3. Configurar 50/50 o cualquier proporción
4. Analizar resultados
5. Decidir versión ganadora

### 3. Mantenimiento de Servidores
1. Acceder a "Gestión de Servidores"
2. Desactivar servidor para mantenimiento
3. Realizar actualizaciones
4. Reactivar servidor
5. Verificar balanceeo

## 🔍 Solución de Problemas

### Panel no accesible
```bash
# Verificar HAProxy
docker ps | grep haproxy

# Ver logs
docker logs haproxy

# Verificar puertos
netstat -tulpn | grep -E ':(8080|8081|8082|8404)'
```

### API no responde
```bash
# Probar API directamente
curl http://localhost:8081/api/config

# Verificar procesos internos de HAProxy
docker exec haproxy ps aux
```

### Configuración no se aplica
```bash
# Verificar socket de HAProxy
docker exec haproxy ls -la /var/run/haproxy.sock

# Probar comando manual
docker exec haproxy echo "show stat" | socat stdio /var/run/haproxy.sock
```

## 🎨 Personalización

### Temas
- Soporte para modo oscuro/claro
- Bootstrap 5 con iconos
- CSS personalizable

### Extensiones
- Agregar nuevos backends
- Métricas personalizadas
- Alertas y notificaciones
- Integración con sistemas externos

## 📈 Métricas Disponibles

- **Conexiones activas** por backend
- **Tiempo de respuesta** promedio
- **Tasa de errores** (4xx, 5xx)
- **Throughput** (requests/segundo)
- **Estado de salud** de servidores
- **Distribución de tráfico** actual

## 🔄 Integración con CI/CD

El HAProxy Deployment Manager puede integrarse con pipelines de CI/CD:

```bash
# Activar canary deployment via API
curl -X POST http://localhost:8081/api/config/canary \
  -H "Content-Type: application/json" \
  -d '{"enabled": true, "percentage": 10}'

# Verificar métricas
curl http://localhost:8081/api/stats

# Promover a producción
curl -X POST http://localhost:8081/api/config/canary \
  -H "Content-Type: application/json" \
  -d '{"enabled": false, "percentage": 0}'
```

---

## 🎉 Conclusión

El **HAProxy Deployment Manager** es una herramienta poderosa y completa que ya tenías en tu proyecto. Proporciona todas las funcionalidades necesarias para gestionar despliegues avanzados de manera profesional y segura.

**¡Ya no necesitas buscar más! Tu HAProxy Deployment Manager está aquí y listo para usar.**
