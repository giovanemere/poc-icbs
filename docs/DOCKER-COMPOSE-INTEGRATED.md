# Solución Integrada Docker Compose para Oracle WebLogic

Esta documentación describe la nueva solución integrada que reemplaza la necesidad de ejecutar manualmente comandos complejos como `cd /path && ./run-integrated-command.sh`.

## 🎯 Objetivo

Proporcionar una gestión unificada y simplificada del entorno Oracle WebLogic usando Docker Compose, con todas las funcionalidades integradas en un solo sistema.

## 📁 Archivos de la Solución

### Archivos Principales

| Archivo | Descripción |
|---------|-------------|
| `config/docker-compose-integrated.yml` | Configuración Docker Compose con servicio de gestión integrada |
| `manage-integrated.sh` | Script principal de gestión integrada |
| `quick-start-integrated.sh` | Script de inicio rápido |
| `.env.integrated` | Variables de entorno específicas para la gestión integrada |

### Servicios Docker Compose

| Servicio | IP | Puertos | Descripción |
|----------|----|---------| ------------|
| `integrated-manager` | 172.23.0.10 | - | Contenedor de gestión con todas las herramientas |
| `weblogic-a` | 172.23.0.4 | 7001 | WebLogic Server versión A |
| `weblogic-b` | 172.23.0.3 | 7002 | WebLogic Server versión B |
| `haproxy` | 172.23.0.5 | 8080, 8443, 8404, 8081, 8082 | HAProxy con gestión avanzada |
| `orcldb` | 172.23.0.2 | 1521, 5500 | Oracle Database Express |
| `dashboard` | 172.23.0.6 | 8001 | Dashboard profesional |

## 🚀 Inicio Rápido

### Opción 1: Inicio Automático (Recomendado)

```bash
# Cambiar al directorio del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Ejecutar inicio rápido integrado
./quick-start-integrated.sh
```

### Opción 2: Gestión Manual

```bash
# Iniciar todos los servicios
./manage-integrated.sh start

# Ejecutar comando integrado (equivale a ./run-integrated-command.sh)
./manage-integrated.sh run-integrated

# Ver estado
./manage-integrated.sh status
```

## 🛠️ Comandos Disponibles

### Script de Gestión Integrada (`manage-integrated.sh`)

```bash
# Comandos básicos
./manage-integrated.sh start           # Iniciar todos los servicios
./manage-integrated.sh stop            # Detener todos los servicios
./manage-integrated.sh restart         # Reiniciar todos los servicios
./manage-integrated.sh status          # Ver estado de servicios

# Comandos avanzados
./manage-integrated.sh run-integrated  # Ejecutar comando integrado completo
./manage-integrated.sh logs [servicio] # Ver logs (opcional: servicio específico)
./manage-integrated.sh cleanup         # Limpiar entorno y volúmenes
./manage-integrated.sh update-ips      # Actualizar IPs de HAProxy
./manage-integrated.sh dashboard       # Abrir dashboard en navegador

# Ejecutar comandos personalizados
./manage-integrated.sh exec ./cleanup-environment.sh light
./manage-integrated.sh exec ./update-haproxy-ips.sh
./manage-integrated.sh exec ./scripts/build/build-wars.sh
```

## 🔄 Equivalencias con Comandos Anteriores

### Comando Original vs Nuevo Sistema

| Comando Original | Nuevo Comando Integrado |
|------------------|-------------------------|
| `cd /path && ./run-integrated-command.sh` | `./manage-integrated.sh run-integrated` |
| `./cleanup-environment.sh light` | `./manage-integrated.sh exec ./cleanup-environment.sh light` |
| `./start-dashboard-integrated.sh` | Incluido automáticamente en `run-integrated` |
| `./update-haproxy-ips.sh` | `./manage-integrated.sh update-ips` |
| `docker-compose up -d` | `./manage-integrated.sh start` |
| `docker-compose down` | `./manage-integrated.sh stop` |

## 🌐 URLs de Acceso

### URLs Principales

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| HAProxy Frontend | http://localhost:8080 | - |
| HAProxy Stats | http://localhost:8404/stats | admin/admin123 |
| Panel de Administración | http://localhost:8082 | - |
| Dashboard Profesional | http://localhost:8001 | - |
| WebLogic A Console | http://localhost:7001/console | weblogic/welcome1 |
| WebLogic B Console | http://localhost:7002/console | weblogic/welcome1 |
| Oracle Enterprise Manager | http://localhost:5500/em | system/welcome1 |

### Aplicaciones a través de HAProxy

| Aplicación | URL |
|------------|-----|
| Feature Flags | http://localhost:8080/feature-flags/ |
| Version A | http://localhost:8080/version-a/ |
| Version B | http://localhost:8080/version-b/ |
| WebLogic Features A | http://localhost:8080/weblogic-features-a/ |
| WebLogic Features B | http://localhost:8080/weblogic-features-b/ |

## 🔧 Configuración Avanzada

### Variables de Entorno

El archivo `.env.integrated` contiene configuraciones específicas:

```bash
# Cargar configuración integrada
source .env.integrated

# Ver configuración actual
./manage-integrated.sh exec env | grep -E "(HAPROXY|WEBLOGIC|ORACLE)"
```

### Personalización del Docker Compose

Para modificar la configuración:

1. Editar `config/docker-compose-integrated.yml`
2. Reiniciar servicios: `./manage-integrated.sh restart`

### Agregar Servicios Adicionales

```yaml
# Ejemplo: Agregar servicio de monitoreo
monitoring:
  image: prom/prometheus:latest
  container_name: prometheus
  ports:
    - "9090:9090"
  networks:
    weblogic-network:
      ipv4_address: 172.23.0.11
```

## 🐛 Solución de Problemas

### Problemas Comunes

#### Error: "Contenedor no encontrado"

```bash
# Verificar estado de contenedores
./manage-integrated.sh status

# Reiniciar servicios
./manage-integrated.sh restart
```

#### Error: "Puerto ya en uso"

```bash
# Verificar puertos ocupados
netstat -tulpn | grep -E "(8080|8404|7001|7002)"

# Detener servicios conflictivos
./manage-integrated.sh stop
```

#### Error: "Comando integrado falla"

```bash
# Ver logs detallados
./manage-integrated.sh logs integrated-manager

# Ejecutar limpieza completa
./manage-integrated.sh cleanup
./manage-integrated.sh start
```

### Logs y Debugging

```bash
# Ver logs de todos los servicios
./manage-integrated.sh logs

# Ver logs de un servicio específico
./manage-integrated.sh logs haproxy
./manage-integrated.sh logs weblogic-a

# Ejecutar comandos de debugging
./manage-integrated.sh exec ./scripts/check-urls.sh
./manage-integrated.sh exec docker ps
```

## 📊 Monitoreo y Métricas

### Dashboard Integrado

El dashboard profesional (http://localhost:8001) proporciona:

- Estado en tiempo real de todos los servicios
- Métricas de rendimiento
- Estadísticas de tráfico A/B y Canary
- Información de Feature Flags

### Métricas de HAProxy

Acceder a http://localhost:8404/stats para ver:

- Estado de backends (WebLogic A/B)
- Distribución de tráfico
- Tiempos de respuesta
- Errores y conexiones

## 🔄 Flujo de Trabajo Recomendado

### Desarrollo Diario

1. **Inicio del día:**
   ```bash
   ./quick-start-integrated.sh
   ```

2. **Durante el desarrollo:**
   ```bash
   # Desplegar nuevas aplicaciones
   ./manage-integrated.sh exec ./scripts/deploy/deploy-war.sh --all
   
   # Ver logs en tiempo real
   ./manage-integrated.sh logs haproxy
   ```

3. **Pruebas de despliegue:**
   ```bash
   # Configurar Canary Deployment
   ./manage-integrated.sh exec ./scripts/canary/manage-traffic.sh canary 20
   
   # Monitorear resultados
   ./manage-integrated.sh dashboard
   ```

4. **Final del día:**
   ```bash
   ./manage-integrated.sh stop
   ```

### Despliegue en Producción

1. **Preparación:**
   ```bash
   ./manage-integrated.sh cleanup
   ./manage-integrated.sh start
   ```

2. **Despliegue Canary:**
   ```bash
   ./manage-integrated.sh run-integrated
   ./manage-integrated.sh exec ./scripts/canary/manage-traffic.sh canary 5
   ```

3. **Monitoreo:**
   ```bash
   ./manage-integrated.sh dashboard
   # Monitorear métricas durante 30 minutos
   ```

4. **Escalado gradual:**
   ```bash
   ./manage-integrated.sh exec ./scripts/canary/manage-traffic.sh canary 20
   ./manage-integrated.sh exec ./scripts/canary/manage-traffic.sh canary 50
   ./manage-integrated.sh exec ./scripts/canary/manage-traffic.sh canary 100
   ```

## 🎯 Ventajas de la Solución Integrada

### Antes (Comando Manual)
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./run-integrated-command.sh
```

### Ahora (Gestión Integrada)
```bash
./manage-integrated.sh run-integrated
```

### Beneficios

1. **Simplicidad:** Un solo comando para toda la gestión
2. **Consistencia:** Mismo entorno en desarrollo y producción
3. **Escalabilidad:** Fácil agregar nuevos servicios
4. **Monitoreo:** Dashboard integrado y logs centralizados
5. **Automatización:** Scripts de inicio y limpieza automáticos
6. **Flexibilidad:** Comandos personalizados cuando sea necesario

## 📚 Referencias

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [HAProxy Configuration Guide](../haproxy/README.md)
- [WebLogic Deployment Guide](../docs/deployment-guide.md)
- [Feature Flags Documentation](../docs/feature-flags.md)

## 🤝 Contribución

Para contribuir a la solución integrada:

1. Modificar archivos en `config/` y `scripts/`
2. Probar con `./manage-integrated.sh`
3. Actualizar documentación
4. Crear pull request

---

**Nota:** Esta solución integrada reemplaza la necesidad de ejecutar comandos manuales complejos y proporciona una experiencia unificada para la gestión del entorno Oracle WebLogic con Docker Compose.
