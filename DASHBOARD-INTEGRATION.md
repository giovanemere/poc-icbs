# Integración del Dashboard en Docker Compose Multi-Env

## Resumen de la Integración

Se ha integrado completamente el servicio del dashboard profesional en el archivo `config/docker-compose-multi-env.yml`, permitiendo levantar todos los servicios, incluyendo el dashboard, desde un solo lugar.

## Archivos Modificados

### 1. `config/docker-compose-multi-env.yml`
Se agregó el servicio `dashboard` con:
- Build context: `../haproxy/dashboard`
- Imagen: `dashboard-professional:${BUILD_VERSION:-latest}`
- IP: `172.23.0.7`
- Puerto externo: `8001`
- Dependencias: `haproxy`
- Health checks configurados
- Límites de recursos configurables

### 2. `.env`
Se agregaron las siguientes variables:
```bash
# Configuración del Dashboard Profesional
DASHBOARD_HOST=172.23.0.7
DASHBOARD_PORT=8000
EXTERNAL_DASHBOARD_PORT=8001
DASHBOARD_REFRESH_INTERVAL=5
DASHBOARD_API_TIMEOUT=10
DASHBOARD_MEMORY_LIMIT=256m
DASHBOARD_CPU_LIMIT=0.5
```

### 3. Scripts Creados

#### `start-multi-env.sh`
Script principal para gestionar el entorno multi-env:
- Soporte para servicios específicos
- Comando `full` para iniciar todo + verificar dashboard
- Comando `dashboard` para iniciar solo el dashboard
- Gestión completa de logs, estado, build, etc.

#### `start-dashboard-integrated.sh`
Script simple que ejecuta el comando integrado equivalente a tu solicitud original.

## Comandos de Uso

### Comando Integrado con Limpieza Automática (Tu Solicitud Original)
```bash
# Equivale a: cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start-with-images.sh start && ./start-with-images.sh start dashboard
# Ahora incluye limpieza automática en caso de falla
./start-dashboard-integrated.sh
```

**Características del comando integrado:**
- ✅ Limpieza automática si detecta errores
- ✅ Segundo intento automático después de limpieza
- ✅ Verificación de servicios críticos
- ✅ Diagnóstico detallado en caso de falla persistente
- ✅ URLs y comandos útiles al finalizar

### Scripts de Limpieza

#### Limpieza Automática
El script integrado incluye limpieza automática, pero también puedes usar:

```bash
# Limpieza ligera (recomendada para problemas comunes)
./cleanup-environment.sh light

# Limpieza completa (más agresiva)
./cleanup-environment.sh full

# Limpieza profunda (⚠️ elimina datos)
./cleanup-environment.sh deep

# Solo ver estado actual
./cleanup-environment.sh status
```

### Comandos Individuales
```bash
# Cambiar al directorio del proyecto
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic

# Iniciar todos los servicios incluyendo dashboard
./start-multi-env.sh full

# Iniciar solo el dashboard
./start-multi-env.sh dashboard

# Iniciar servicios específicos
./start-multi-env.sh start haproxy dashboard

# Ver estado de todos los servicios
./start-multi-env.sh status

# Ver logs del dashboard
./start-multi-env.sh logs dashboard

# Construir todas las imágenes
./start-multi-env.sh build

# Detener todos los servicios
./start-multi-env.sh stop
```

### Usando Docker Compose Directamente
```bash
# Iniciar todos los servicios
docker-compose -f config/docker-compose-multi-env.yml up -d

# Iniciar solo el dashboard
docker-compose -f config/docker-compose-multi-env.yml up -d dashboard

# Ver estado
docker-compose -f config/docker-compose-multi-env.yml ps

# Ver logs del dashboard
docker-compose -f config/docker-compose-multi-env.yml logs -f dashboard

# Detener todo
docker-compose -f config/docker-compose-multi-env.yml down
```

## URLs de Acceso

Una vez iniciados los servicios, tendrás acceso a:

| Servicio | URL | Descripción |
|----------|-----|-------------|
| **Dashboard vía HAProxy** | `http://localhost:8080/dashboard/` | Acceso recomendado |
| **Dashboard Directo** | `http://localhost:8001/` | Acceso directo al contenedor |
| **HAProxy Frontend** | `http://localhost:8080` | Load balancer principal |
| **HAProxy Stats** | `http://localhost:8404/stats` | Estadísticas de HAProxy |
| **HAProxy Admin UI** | `http://localhost:8082` | Panel de administración |
| **WebLogic A** | `http://localhost:7001/console` | Consola WebLogic A |
| **WebLogic B** | `http://localhost:7002/console` | Consola WebLogic B |
| **WebLogic FF** | `http://localhost:7003/console` | Consola WebLogic Feature Flags |
| **Oracle DB** | `localhost:1521` | Base de datos Oracle |
| **Oracle EM** | `http://localhost:5500/em` | Enterprise Manager |

## Verificación

Para verificar que todo funciona correctamente:

```bash
# Probar el dashboard completo
./scripts/test-dashboard.sh

# Verificar conectividad básica
curl -s http://localhost:8001/api/health | jq .
curl -s http://localhost:8080/dashboard/api/health | jq .

# Ver estado de todos los contenedores
docker ps

# Ver logs en tiempo real
./start-multi-env.sh logs dashboard
```

## Ventajas de esta Integración

1. **Un Solo Comando**: Levantar todo el entorno con un solo comando
2. **Configuración Centralizada**: Todas las variables en `.env`
3. **Gestión Unificada**: Un script para gestionar todos los servicios
4. **Escalabilidad**: Fácil agregar más servicios
5. **Flexibilidad**: Iniciar servicios específicos según necesidad
6. **Monitoreo**: Dashboard integrado desde el inicio

## Solución de Problemas

Si el dashboard no está accesible:

```bash
# Verificar que el contenedor esté ejecutándose
docker ps | grep dashboard

# Ver logs del dashboard
./start-multi-env.sh logs dashboard

# Reiniciar solo el dashboard
./start-multi-env.sh restart dashboard

# Verificar conectividad interna
docker exec haproxy curl -s http://dashboard:8000/api/health
```

## Próximos Pasos

1. Ejecutar `./start-dashboard-integrated.sh` para probar la integración completa
2. Verificar que todas las URLs estén accesibles
3. Probar las funcionalidades del dashboard
4. Configurar monitoreo adicional si es necesario
