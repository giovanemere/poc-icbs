# 🎯 Guía Completa de Canary Deployment

Esta guía proporciona instrucciones detalladas para implementar canary deployments en el sistema WebLogic con HAProxy.

## 📋 Tabla de Contenidos

- [🎯 ¿Qué es Canary Deployment?](#-qué-es-canary-deployment)
- [🏗️ Arquitectura](#️-arquitectura)
- [🚀 Configuración Inicial](#-configuración-inicial)
- [📊 Gestión de Tráfico](#-gestión-de-tráfico)
- [🧪 Testing de Canary](#-testing-de-canary)
- [📈 Monitoreo y Métricas](#-monitoreo-y-métricas)
- [🔄 Estrategias de Deployment](#-estrategias-de-deployment)
- [🛠️ Troubleshooting](#️-troubleshooting)

## 🎯 ¿Qué es Canary Deployment?

### 📖 Definición

Canary Deployment es una técnica de deployment que reduce el riesgo de introducir una nueva versión de software dirigiendo una pequeña porción del tráfico a la nueva versión, mientras que la mayoría del tráfico continúa siendo servido por la versión estable.

### 🎯 Beneficios

- **🔒 Reducción de Riesgo**: Limita el impacto de bugs a un pequeño porcentaje de usuarios
- **📊 Validación Real**: Testing con tráfico real de producción
- **🔄 Rollback Rápido**: Capacidad de revertir cambios instantáneamente
- **📈 Monitoreo Gradual**: Observar métricas antes de deployment completo
- **👥 Feedback Temprano**: Obtener feedback de usuarios reales

### 🏗️ Casos de Uso

- **🆕 Nuevas Funcionalidades**: Testing de features antes del lanzamiento completo
- **🔧 Cambios Críticos**: Validación de cambios que afectan funcionalidad core
- **⚡ Optimizaciones**: Verificación de mejoras de performance
- **🔒 Actualizaciones de Seguridad**: Deployment seguro de patches críticos

## 🏗️ Arquitectura

### 🔄 Flujo de Tráfico

```
                    USUARIOS
                       │
                       ▼
                 ┌─────────────┐
                 │   HAProxy   │
                 │ Load Balancer│
                 └─────┬───────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
   ┌─────────┐    ┌─────────┐    ┌─────────┐
   │ 80% →   │    │ 20% →   │    │ Stats & │
   │WebLogic │    │WebLogic │    │ Control │
   │    A    │    │    B    │    │   API   │
   │(Stable) │    │(Canary) │    │         │
   └─────────┘    └─────────┘    └─────────┘
```

### 🎛️ Componentes

| Componente | Función | Puerto |
|------------|---------|--------|
| **HAProxy** | Balanceador y controlador de tráfico | 8083 |
| **WebLogic A** | Versión estable (producción) | 7001 |
| **WebLogic B** | Versión canary (nueva) | 7002 |
| **HAProxy Stats** | Dashboard de métricas | 8404 |
| **HAProxy API** | Control programático | 8081 |

## 🚀 Configuración Inicial

### 📋 Prerrequisitos

```bash
# Verificar que todos los servicios estén corriendo
./manage-services.sh status

# Verificar conectividad
./scripts/check-urls.sh --quick

# Validar configuración
./scripts/validate-config-consistency.sh
```

### ⚙️ Configuración Base

```bash
# Resetear a configuración 50/50
./scripts/canary/manage-traffic.sh reset

# Verificar estado inicial
./scripts/canary/manage-traffic.sh status
```

### 🔧 Variables de Configuración

En el archivo `.env`:

```bash
# Configuración de Canary
CANARY_DEFAULT_PERCENTAGE=10
CANARY_INCREMENT_STEP=25
CANARY_MONITORING_INTERVAL=60
CANARY_ROLLBACK_THRESHOLD=5
CANARY_SUCCESS_THRESHOLD=95
```

## 📊 Gestión de Tráfico

### 🎛️ Script Principal: manage-traffic.sh

```bash
# Ver ayuda completa
./scripts/canary/manage-traffic.sh --help
```

### 🚦 Comandos Básicos

#### Configurar Canary
```bash
# Configurar 10% canary
./scripts/canary/manage-traffic.sh canary 10

# Configurar 25% canary
./scripts/canary/manage-traffic.sh canary 25

# Configurar 50% canary
./scripts/canary/manage-traffic.sh canary 50
```

#### Ver Estado
```bash
# Estado actual de distribución
./scripts/canary/manage-traffic.sh status

# Estado detallado con métricas
./scripts/canary/manage-traffic.sh status --detailed
```

#### Operaciones de Control
```bash
# Completar canary (100% a nueva versión)
./scripts/canary/manage-traffic.sh complete

# Rollback (100% a versión estable)
./scripts/canary/manage-traffic.sh rollback

# Reset a 50/50
./scripts/canary/manage-traffic.sh reset
```

### 📈 Incremento Gradual

```bash
#!/bin/bash
# Script de incremento gradual

PERCENTAGES=(10 25 50 75 100)

for percentage in "${PERCENTAGES[@]}"; do
    echo "Configurando $percentage% canary"
    ./scripts/canary/manage-traffic.sh canary $percentage
    
    # Esperar y monitorear
    sleep 300  # 5 minutos
    
    # Verificar métricas
    if ! ./scripts/canary/test-canary.sh 20; then
        echo "Métricas no satisfactorias - ejecutando rollback"
        ./scripts/canary/manage-traffic.sh rollback
        exit 1
    fi
done
```

## 🧪 Testing de Canary

### 🔍 Script de Testing: test-canary.sh

```bash
# Test básico con 10 requests
./scripts/canary/test-canary.sh

# Test con número específico de requests
./scripts/canary/test-canary.sh 50

# Test detallado con análisis
./scripts/canary/test-canary.sh --detailed

# Test continuo
./scripts/canary/test-canary.sh --continuous
```

### 📊 Simulación de Tráfico

```bash
# Simulación básica
./scripts/canary/simulate-traffic.sh

# Simulación con parámetros específicos
./scripts/canary/simulate-traffic.sh \
    --duration 300 \
    --rate 10 \
    --concurrent 5

# Simulación con patrones de tráfico
./scripts/canary/simulate-traffic.sh \
    --pattern spike \
    --duration 600
```

### 🧪 Testing Automatizado

```bash
#!/bin/bash
# Script de testing automatizado para canary

set -e

CANARY_PERCENTAGE="$1"
TEST_DURATION=300
SUCCESS_THRESHOLD=95

echo "Iniciando testing de canary al $CANARY_PERCENTAGE%"

# Configurar canary
./scripts/canary/manage-traffic.sh canary "$CANARY_PERCENTAGE"

# Ejecutar tests
echo "Ejecutando tests durante $TEST_DURATION segundos..."

# Test de carga
if ! ./scripts/canary/simulate-traffic.sh --duration "$TEST_DURATION" --rate 5; then
    echo "Test de carga falló"
    ./scripts/canary/manage-traffic.sh rollback
    exit 1
fi

# Verificar métricas
SUCCESS_RATE=$(./scripts/canary/test-canary.sh 50 | grep "Success Rate" | awk '{print $3}' | sed 's/%//')

if (( $(echo "$SUCCESS_RATE < $SUCCESS_THRESHOLD" | bc -l) )); then
    echo "Tasa de éxito ($SUCCESS_RATE%) por debajo del umbral ($SUCCESS_THRESHOLD%)"
    ./scripts/canary/manage-traffic.sh rollback
    exit 1
fi

echo "Testing de canary exitoso - tasa de éxito: $SUCCESS_RATE%"
```

## 📈 Monitoreo y Métricas

### 📊 Dashboard HAProxy

Accede al dashboard en: http://localhost:8404/stats

#### Métricas Clave
- **Request Rate**: Requests por segundo por backend
- **Response Time**: Tiempo de respuesta promedio
- **Error Rate**: Porcentaje de errores
- **Active Sessions**: Sesiones activas por backend
- **Health Status**: Estado de health checks

### 📈 Métricas de Canary

```bash
# Obtener métricas en formato CSV
curl -s "http://localhost:8404/stats;csv" | grep -E 'weblogic-[ab]'

# Métricas específicas de canary
./scripts/canary/manage-traffic.sh metrics

# Monitoreo continuo
watch -n 10 './scripts/canary/manage-traffic.sh status'
```

### 📊 Script de Monitoreo Personalizado

```bash
#!/bin/bash
# monitor-canary.sh

while true; do
    clear
    echo "=== CANARY DEPLOYMENT MONITORING ==="
    echo "Timestamp: $(date)"
    echo ""
    
    # Estado de distribución
    ./scripts/canary/manage-traffic.sh status
    echo ""
    
    # Métricas de HAProxy
    echo "=== HAPROXY METRICS ==="
    curl -s "http://localhost:8404/stats;csv" | \
        grep -E 'weblogic-[ab]' | \
        awk -F',' '{print $1 ": " $8 " req/s, " $9 " errors"}'
    echo ""
    
    # Health checks
    echo "=== HEALTH STATUS ==="
    ./scripts/check-urls.sh --quick
    
    sleep 30
done
```

### 🚨 Alertas Automáticas

```bash
#!/bin/bash
# canary-alerts.sh

ERROR_THRESHOLD=5
RESPONSE_TIME_THRESHOLD=2000

# Verificar tasa de errores
ERROR_RATE=$(curl -s "http://localhost:8404/stats;csv" | \
    grep "weblogic-b" | \
    awk -F',' '{print $13}')

if (( $(echo "$ERROR_RATE > $ERROR_THRESHOLD" | bc -l) )); then
    echo "ALERT: Error rate too high: $ERROR_RATE%"
    ./scripts/canary/manage-traffic.sh rollback
    # Enviar notificación (email, Slack, etc.)
fi

# Verificar tiempo de respuesta
RESPONSE_TIME=$(curl -s "http://localhost:8404/stats;csv" | \
    grep "weblogic-b" | \
    awk -F',' '{print $11}')

if (( $(echo "$RESPONSE_TIME > $RESPONSE_TIME_THRESHOLD" | bc -l) )); then
    echo "ALERT: Response time too high: ${RESPONSE_TIME}ms"
    ./scripts/canary/manage-traffic.sh rollback
fi
```

## 🔄 Estrategias de Deployment

### 🎯 Estrategia Conservadora

```bash
#!/bin/bash
# conservative-canary.sh

PERCENTAGES=(5 10 20 30 50 75 100)
WAIT_TIME=600  # 10 minutos entre incrementos

for percentage in "${PERCENTAGES[@]}"; do
    echo "Configurando $percentage% canary"
    ./scripts/canary/manage-traffic.sh canary $percentage
    
    # Monitoreo extendido
    for i in {1..10}; do
        if ! ./scripts/canary/test-canary.sh 10; then
            echo "Test falló en intento $i - rollback"
            ./scripts/canary/manage-traffic.sh rollback
            exit 1
        fi
        sleep 60
    done
    
    if [ $percentage -lt 100 ]; then
        echo "Esperando $WAIT_TIME segundos..."
        sleep $WAIT_TIME
    fi
done
```

### ⚡ Estrategia Agresiva

```bash
#!/bin/bash
# aggressive-canary.sh

PERCENTAGES=(25 50 100)
WAIT_TIME=180  # 3 minutos entre incrementos

for percentage in "${PERCENTAGES[@]}"; do
    echo "Configurando $percentage% canary"
    ./scripts/canary/manage-traffic.sh canary $percentage
    
    # Testing rápido
    if ! ./scripts/canary/test-canary.sh 20; then
        echo "Test falló - rollback inmediato"
        ./scripts/canary/manage-traffic.sh rollback
        exit 1
    fi
    
    if [ $percentage -lt 100 ]; then
        sleep $WAIT_TIME
    fi
done
```

### 🎯 Estrategia Basada en Métricas

```bash
#!/bin/bash
# metrics-based-canary.sh

SUCCESS_THRESHOLD=98
ERROR_THRESHOLD=1
RESPONSE_TIME_THRESHOLD=1000

increment_canary() {
    local current_percentage="$1"
    local next_percentage="$2"
    
    echo "Incrementando de $current_percentage% a $next_percentage%"
    ./scripts/canary/manage-traffic.sh canary $next_percentage
    
    # Esperar estabilización
    sleep 120
    
    # Verificar métricas
    local success_rate=$(get_success_rate)
    local error_rate=$(get_error_rate)
    local response_time=$(get_response_time)
    
    if (( $(echo "$success_rate < $SUCCESS_THRESHOLD" | bc -l) )) || \
       (( $(echo "$error_rate > $ERROR_THRESHOLD" | bc -l) )) || \
       (( $(echo "$response_time > $RESPONSE_TIME_THRESHOLD" | bc -l) )); then
        echo "Métricas no satisfactorias - rollback"
        ./scripts/canary/manage-traffic.sh rollback
        return 1
    fi
    
    return 0
}

# Incremento basado en métricas
PERCENTAGES=(10 25 50 75 100)
current=0

for percentage in "${PERCENTAGES[@]}"; do
    if ! increment_canary $current $percentage; then
        exit 1
    fi
    current=$percentage
done
```

## 🛠️ Troubleshooting

### 🚨 Problemas Comunes

#### Canary No Recibe Tráfico

```bash
# Verificar configuración HAProxy
curl -s "http://localhost:8404/stats;csv" | grep weblogic-b

# Verificar configuración de tráfico
./scripts/canary/manage-traffic.sh status

# Verificar logs HAProxy
./manage-services.sh logs haproxy | tail -50
```

#### Distribución de Tráfico Incorrecta

```bash
# Resetear configuración
./scripts/canary/manage-traffic.sh reset

# Verificar configuración HAProxy
docker exec haproxy cat /usr/local/etc/haproxy/haproxy.cfg | grep -A 10 -B 10 weight

# Recargar configuración HAProxy
docker exec haproxy kill -USR2 1
```

#### Métricas Inconsistentes

```bash
# Verificar conectividad a stats
curl -f "http://localhost:8404/stats"

# Verificar API HAProxy
curl -f "http://localhost:8081/stats"

# Reiniciar HAProxy si es necesario
./manage-services.sh restart haproxy
```

### 🔧 Comandos de Diagnóstico

```bash
# Estado completo del sistema
./scripts/validate-complete-system.sh

# Testing de integración específico para canary
./scripts/test-integration.sh --canary

# Verificar configuración de canary
./scripts/validate-config-consistency.sh --haproxy-only
```

### 🔄 Recuperación de Emergencia

```bash
# Rollback inmediato
./scripts/canary/manage-traffic.sh rollback

# Verificar que el rollback funcionó
./scripts/check-urls.sh --timing

# Si persisten problemas, resetear completamente
./scripts/canary/manage-traffic.sh reset
./manage-services.sh restart haproxy
```

## 📋 Checklist de Canary Deployment

### ✅ Pre-Deployment
- [ ] Backup de versión actual
- [ ] Verificar métricas baseline
- [ ] Preparar plan de rollback
- [ ] Configurar alertas
- [ ] Validar nueva versión en staging

### ✅ Durante Canary
- [ ] Monitorear métricas en tiempo real
- [ ] Verificar logs de errores
- [ ] Validar funcionalidad crítica
- [ ] Monitorear feedback de usuarios
- [ ] Documentar observaciones

### ✅ Post-Canary
- [ ] Analizar métricas completas
- [ ] Verificar que no hay regresiones
- [ ] Actualizar documentación
- [ ] Comunicar resultados al equipo
- [ ] Planificar próximos deployments

## 📚 Referencias

- [Scripts de Canary](../scripts/canary/)
- [Guía de Deployment](DEPLOYMENT_GUIDE.md)
- [Guía de Monitoreo](MONITORING_GUIDE.md)
- [HAProxy Documentation](http://www.haproxy.org/download/2.4/doc/configuration.txt)
- [README Principal](../README.md)

---

**Última actualización**: 2025-01-31
