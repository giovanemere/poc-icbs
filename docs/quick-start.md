# 🚀 Guía de Inicio Rápido

Esta guía te ayudará a poner en funcionamiento el sistema WebLogic en pocos minutos.

## ⚡ Inicio Inmediato

### Comando Principal (Recomendado)

```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh
```

!!! success "Script Inteligente"
    Este comando utiliza **detección automática** para determinar el estado actual de los servicios y ejecutar la acción más eficiente:
    
    - **🚀 Inicio Completo**: Si no hay contenedores
    - **▶️ Inicio Normal**: Si hay contenedores parados  
    - **🔄 Reinicio Parcial**: Si algunos servicios están caídos
    - **⚡ Reinicio Rápido**: Si todos los servicios están corriendo

## 🎯 URLs Principales

Una vez iniciado el sistema, accede a estas URLs:

### Dashboard Principal
```
🎛️ http://localhost:8085/unified-dashboard-fixed.html
```
**El dashboard más completo con control total del sistema**

### Dashboard de Tráfico
```
📊 http://localhost:8084/
```
**Especializado en A/B Testing y Canary Deployment**

### Frontend Principal
```
🌐 http://localhost:8100/
```
**Punto de entrada principal del sistema**

## 📊 Verificar Estado

### Comando de Estado
```bash
./status.sh
```

Este comando muestra:
- 📦 Estado de contenedores Docker
- 🔌 Estado de puertos
- 🔍 Verificación de URLs
- 💾 Recursos del sistema
- 📋 Logs recientes

### Verificar URLs
```bash
./verify-updated-urls.sh
```

Verifica que todas las URLs del sistema estén respondiendo correctamente.

## 🛑 Parar el Sistema

```bash
./stop.sh
```

Para todos los servicios de manera segura.

## 🔄 Reinicio Forzado

Si hay problemas:

```bash
./force-restart.sh
```

Ejecuta un reinicio forzado completo (parada total + inicio limpio).

## 📋 Flujo de Trabajo Típico

### 1. Inicio del Día
```bash
# Iniciar sistema
./start.sh

# Verificar estado
./status.sh

# Acceder al dashboard
# http://localhost:8085/unified-dashboard-fixed.html
```

### 2. Durante el Desarrollo
```bash
# Ver logs en tiempo real
docker-compose -f config/docker-compose.yml logs -f

# Reiniciar un servicio específico
docker-compose -f config/docker-compose.yml restart haproxy

# Verificar URLs
./verify-updated-urls.sh
```

### 3. Final del Día
```bash
# Parar todo el sistema
./stop.sh
```

## 🚨 Solución Rápida de Problemas

### Si algo no funciona:

1. **Verificar estado:**
   ```bash
   ./status.sh
   ```

2. **Reinicio inteligente:**
   ```bash
   ./start.sh
   ```

3. **Reinicio forzado:**
   ```bash
   ./force-restart.sh
   ```

4. **Ver logs:**
   ```bash
   docker-compose -f config/docker-compose.yml logs -f
   ```

### URLs de Respaldo

Si HAProxy falla, estos dashboards independientes siguen funcionando:

- ✅ `http://localhost:8085/unified-dashboard-fixed.html`
- ✅ `http://localhost:8084/`
- ✅ `http://localhost:8092/index-functional.html`
- ✅ `http://localhost:8093/api/health`

## 🎮 Probar Funcionalidades

### A/B Testing
1. Accede al Dashboard de Tráfico: `http://localhost:8084/`
2. Configura porcentajes de tráfico
3. Observa la distribución en tiempo real

### Canary Deployment
1. Usa el Dashboard de Tráfico para configurar el porcentaje canary
2. Monitorea métricas antes de aumentar el tráfico
3. Rollback si es necesario

### Feature Flags
1. Accede a: `http://localhost:8100/feature-flags/`
2. Activa/desactiva funcionalidades
3. Observa cambios sin redesplegar

## 💡 Consejos Rápidos

!!! tip "Mejores Prácticas"
    
    - **Usa siempre `./start.sh`** para inicio diario
    - **Los dashboards independientes** son más confiables
    - **Verifica el estado** con `./status.sh` regularmente
    - **Usa `./force-restart.sh`** solo cuando hay problemas graves

!!! info "URLs Prioritarias"
    
    Guarda estos enlaces como favoritos:
    
    1. 🎛️ **Dashboard Principal**: `http://localhost:8085/unified-dashboard-fixed.html`
    2. 📊 **Dashboard de Tráfico**: `http://localhost:8084/`
    3. 🌐 **Frontend Principal**: `http://localhost:8100/`

## ✨ ¡Listo para Usar!

Con estos comandos básicos ya puedes usar todo el sistema. Para funcionalidades avanzadas, consulta la [documentación completa](index.md).

**¡El sistema está listo para producción!** 🎉
