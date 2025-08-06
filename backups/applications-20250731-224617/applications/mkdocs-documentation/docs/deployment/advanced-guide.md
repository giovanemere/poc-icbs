# 🚀 Guía Completa de Deployment

Esta guía proporciona instrucciones detalladas para el deployment de aplicaciones en el sistema WebLogic con HAProxy.

## 📋 Tabla de Contenidos

- [🎯 Tipos de Deployment](#-tipos-de-deployment)
- [📦 Deployment Básico](#-deployment-básico)
- [🔄 Deployment Completo](#-deployment-completo)
- [🎯 Canary Deployment](#-canary-deployment)
- [🔧 Configuración Avanzada](#-configuración-avanzada)
- [🧪 Testing y Validación](#-testing-y-validación)
- [🛠️ Troubleshooting](#️-troubleshooting)

## 🎯 Tipos de Deployment

### 1. 📦 Deployment Básico
Deployment en una sola instancia WebLogic.

### 2. 🔄 Deployment Completo
Deployment simultáneo en ambas instancias WebLogic.

### 3. 🎯 Canary Deployment
Deployment gradual con control de tráfico.

### 4. 🔄 Rolling Deployment
Deployment secuencial sin downtime.

## 📦 Deployment Básico

### 🚀 Deployment Simple

```bash
# Deployment básico de una aplicación WAR
./scripts/deploy/deploy-war.sh /path/to/application.war

# Deployment con contexto específico
./scripts/deploy/deploy-war.sh /path/to/app.war --context myapp

# Deployment en instancia específica
./scripts/deploy/deploy-war.sh /path/to/app.war --target weblogic-a
```

### ⚙️ Opciones Disponibles

```bash
# Ver todas las opciones
./scripts/deploy/deploy-war.sh --help

# Opciones principales:
--target INSTANCE     # weblogic-a o weblogic-b
--context CONTEXT     # Contexto de la aplicación
--clean               # Limpiar cachés antes del deployment
--verify-only         # Solo verificar URLs sin deployar
--timeout SECONDS     # Timeout para operaciones
--verbose             # Salida detallada
```

### 📋 Ejemplo Completo

```bash
# Deployment con todas las opciones
./scripts/deploy/deploy-war.sh \
    /path/to/myapp.war \
    --target weblogic-a \
    --context myapp \
    --clean \
    --timeout 300 \
    --verbose
```

## 🔄 Deployment Completo

### 🎯 Deployment en Ambas Instancias

```bash
# Deployment completo básico
./scripts/deploy/deploy-complete.sh /path/to/application.war

# Deployment con validación
./scripts/deploy/deploy-complete.sh /path/to/app.war --validate

# Deployment con rollback automático
./scripts/deploy/deploy-complete.sh /path/to/app.war --auto-rollback
```

### 🔧 Configuración Avanzada

```bash
# Deployment con configuración personalizada
./scripts/deploy/deploy-complete.sh \
    /path/to/app.war \
    --context myapp \
    --validate \
    --auto-rollback \
    --timeout 600 \
    --parallel
```

### 📊 Monitoreo del Deployment

```bash
# Verificar estado durante deployment
watch -n 5 './scripts/check-urls.sh --quick'

# Monitorear logs
./manage-services.sh logs --follow
```

## 🎯 Canary Deployment

### 🚦 Proceso de Canary Deployment

#### Paso 1: Preparación
```bash
# Verificar estado inicial
./scripts/canary/manage-traffic.sh status

# Resetear distribución a 50/50
./scripts/canary/manage-traffic.sh reset
```

#### Paso 2: Deployment en Canary
```bash
# Deployar nueva versión en weblogic-b (canary)
./scripts/deploy/deploy-war.sh /path/to/new-version.war --target weblogic-b
```

#### Paso 3: Configurar Tráfico Canary
```bash
# Enviar 10% del tráfico al canary
./scripts/canary/manage-traffic.sh canary 10

# Verificar distribución
./scripts/canary/manage-traffic.sh status
```

#### Paso 4: Testing y Monitoreo
```bash
# Ejecutar tests de canary
./scripts/canary/test-canary.sh 50

# Simular tráfico
./scripts/canary/simulate-traffic.sh --duration 300 --rate 5
```

#### Paso 5: Incremento Gradual
```bash
# Incrementar gradualmente si todo va bien
./scripts/canary/manage-traffic.sh canary 25
./scripts/canary/manage-traffic.sh canary 50
./scripts/canary/manage-traffic.sh canary 75
```

#### Paso 6: Completar o Rollback
```bash
# Si todo va bien - completar canary
./scripts/canary/manage-traffic.sh complete

# Si hay problemas - rollback
./scripts/canary/manage-traffic.sh rollback
```

### 🔄 Canary Deployment Automatizado

```bash
# Script de canary automatizado (ejemplo)
#!/bin/bash
set -e

APP_WAR="$1"
CANARY_PERCENTAGES=(10 25 50 75 100)

echo "Iniciando Canary Deployment para $APP_WAR"

# Deployment en canary
./scripts/deploy/deploy-war.sh "$APP_WAR" --target weblogic-b

# Incremento gradual
for percentage in "${CANARY_PERCENTAGES[@]}"; do
    echo "Configurando $percentage% de tráfico canary"
    ./scripts/canary/manage-traffic.sh canary $percentage
    
    # Testing
    if ! ./scripts/canary/test-canary.sh 20; then
        echo "Test falló - ejecutando rollback"
        ./scripts/canary/manage-traffic.sh rollback
        exit 1
    fi
    
    # Esperar antes del siguiente incremento
    if [ $percentage -lt 100 ]; then
        echo "Esperando 60 segundos antes del siguiente incremento..."
        sleep 60
    fi
done

echo "Canary Deployment completado exitosamente"
```

## 🔧 Configuración Avanzada

### 📁 Estructura de Aplicaciones

```
applications/
├── myapp-v1.0.0.war
├── myapp-v1.1.0.war
└── configs/
    ├── myapp-dev.properties
    ├── myapp-staging.properties
    └── myapp-prod.properties
```

### ⚙️ Variables de Entorno para Deployment

```bash
# Configuración en .env
DEPLOYMENT_TIMEOUT=300
DEPLOYMENT_RETRIES=3
DEPLOYMENT_PARALLEL=true
DEPLOYMENT_VALIDATE=true
DEPLOYMENT_AUTO_ROLLBACK=true

# URLs de verificación
HEALTH_CHECK_URL=/health
READINESS_CHECK_URL=/ready
```

### 🔄 Deployment con Configuración Externa

```bash
# Deployment con archivo de configuración
./scripts/deploy/deploy-war.sh \
    /path/to/app.war \
    --config /path/to/deployment.conf \
    --environment production
```

### 📋 Archivo de Configuración de Deployment

```bash
# deployment.conf
DEPLOYMENT_TARGET=both
DEPLOYMENT_CONTEXT=myapp
DEPLOYMENT_TIMEOUT=600
DEPLOYMENT_VALIDATE=true
DEPLOYMENT_HEALTH_CHECK_URL=/actuator/health
DEPLOYMENT_READINESS_CHECK_URL=/actuator/ready
DEPLOYMENT_ROLLBACK_ON_FAILURE=true
```

## 🧪 Testing y Validación

### 🔍 Pre-Deployment Testing

```bash
# Validar aplicación WAR
jar -tf /path/to/app.war | head -20

# Verificar estructura
unzip -l /path/to/app.war | grep -E '\.(xml|properties)$'

# Validar configuración del sistema
./scripts/validate-complete-system.sh --quick
```

### 🧪 Post-Deployment Testing

```bash
# Verificar deployment
./scripts/check-urls.sh

# Tests de integración
./scripts/test-integration.sh --deployment

# Tests de performance
./scripts/test-performance.sh --light
```

### 📊 Validación de Health Checks

```bash
# Verificar health checks personalizados
curl -f http://localhost:8083/myapp/health
curl -f http://localhost:8083/myapp/ready

# Verificar métricas de aplicación
curl -s http://localhost:8083/myapp/metrics | jq .
```

### 🔄 Testing de Rollback

```bash
# Simular fallo y probar rollback
./scripts/canary/manage-traffic.sh canary 50

# Simular error en canary
docker exec weblogic-b /opt/oracle/wlserver/server/bin/setDomainEnv.sh

# Ejecutar rollback
./scripts/canary/manage-traffic.sh rollback

# Verificar que el rollback funcionó
./scripts/check-urls.sh --timing
```

## 🛠️ Troubleshooting

### 🚨 Problemas Comunes

#### Deployment Falla

```bash
# Verificar logs de WebLogic
./manage-services.sh logs weblogic-a | tail -50
./manage-services.sh logs weblogic-b | tail -50

# Verificar espacio en disco
df -h

# Verificar memoria disponible
free -h
docker stats
```

#### Aplicación No Responde

```bash
# Verificar estado de la aplicación
curl -I http://localhost:8083/myapp/

# Verificar configuración HAProxy
curl -s http://localhost:8404/stats | grep myapp

# Verificar logs de aplicación
./manage-services.sh logs weblogic-a | grep -i myapp
```

#### Canary No Funciona Correctamente

```bash
# Verificar configuración de tráfico
./scripts/canary/manage-traffic.sh status

# Verificar configuración HAProxy
curl -s http://localhost:8404/stats;csv | grep -E 'weblogic-[ab]'

# Resetear configuración
./scripts/canary/manage-traffic.sh reset
```

### 🔧 Comandos de Diagnóstico

```bash
# Estado completo del sistema
./scripts/validate-complete-system.sh

# Verificar conectividad
./scripts/check-urls.sh --verbose

# Verificar configuración
./scripts/validate-config-consistency.sh

# Logs detallados
./manage-services.sh logs --timestamps --follow
```

### 🔄 Recuperación de Emergencia

```bash
# Parar todos los servicios
./manage-services.sh stop

# Limpiar recursos
./manage-services.sh clean

# Reiniciar desde cero
./start-all.sh

# Verificar recuperación
./scripts/validate-complete-system.sh --quick
```

## 📋 Checklist de Deployment

### ✅ Pre-Deployment
- [ ] Backup de aplicación actual
- [ ] Verificar recursos del sistema
- [ ] Validar archivo WAR
- [ ] Verificar configuración del sistema
- [ ] Preparar plan de rollback

### ✅ Durante Deployment
- [ ] Monitorear logs en tiempo real
- [ ] Verificar health checks
- [ ] Monitorear métricas de performance
- [ ] Verificar distribución de tráfico

### ✅ Post-Deployment
- [ ] Ejecutar tests de integración
- [ ] Verificar funcionalidad completa
- [ ] Monitorear por período extendido
- [ ] Documentar cambios realizados
- [ ] Actualizar documentación de aplicación

## 📚 Referencias

- [Scripts de Deployment](../scripts/deploy/)
- [Scripts de Canary](../scripts/canary/)
- [Guía de Monitoreo](MONITORING_GUIDE.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [README Principal](../README.md)

---

**Última actualización**: 2025-01-31
