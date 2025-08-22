# 🧠 Scripts Inteligentes - Sistema WebLogic

## ✅ **Scripts Creados**

He creado un sistema de scripts inteligentes que detectan automáticamente el estado de los servicios y ejecutan la acción más eficiente.

### **🚀 Scripts Principales**

#### **1. `./start.sh` - Inicio Inteligente (PRINCIPAL)**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh
```
- ⭐ **Script principal recomendado**
- 🧠 **Detección automática** del estado de servicios
- ⚡ **Acción optimizada** según el estado actual
- 📊 **Muestra URLs** al finalizar

#### **2. `./smart-start.sh` - Motor Inteligente**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./smart-start.sh
```
- 🧠 **Motor de detección inteligente**
- 🔍 **Analiza estado** de contenedores
- 🎯 **Decide acción** más eficiente
- 📋 **Logs detallados** del proceso

#### **3. `./force-restart.sh` - Reinicio Forzado**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./force-restart.sh
```
- 🔄 **Reinicio forzado completo**
- 🛑 **Para todos los servicios**
- 🧹 **Limpia recursos**
- 🚀 **Inicio limpio**

#### **4. `./status.sh` - Estado Detallado**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./status.sh
```
- 📊 **Estado completo** del sistema
- 🔍 **Verificación de URLs**
- 💾 **Recursos del sistema**
- 📋 **Logs recientes**

## 🧠 **Lógica de Detección Inteligente**

### **Estados Detectados:**

1. **🚀 Inicio Completo** (No hay contenedores)
   - Situación: Primera vez o sistema limpio
   - Acción: Inicio completo desde cero
   - Comando: `docker-compose up -d`

2. **▶️ Inicio Normal** (Contenedores parados)
   - Situación: Contenedores existen pero están parados
   - Acción: Inicio normal
   - Comando: `docker-compose up -d`

3. **🔄 Reinicio Parcial** (Algunos servicios caídos)
   - Situación: Algunos contenedores corriendo, otros no
   - Acción: Reinicio parcial
   - Comando: `docker-compose down && docker-compose up -d`

4. **⚡ Reinicio Rápido** (Todos corriendo)
   - Situación: Todos los servicios están corriendo
   - Acción: Reinicio rápido sin parar completamente
   - Comando: `docker-compose restart`

## 🎯 **Flujo de Trabajo Optimizado**

### **Uso Diario (Recomendado):**
```bash
# Siempre usar el script principal
./start.sh

# Ver estado cuando sea necesario
./status.sh

# Parar al final del día
./stop.sh
```

### **Desarrollo y Debugging:**
```bash
# Estado detallado
./status.sh

# Reinicio forzado si hay problemas
./force-restart.sh

# Verificar URLs
./verify-updated-urls.sh
```

### **Casos Específicos:**
```bash
# Solo reinicio rápido (si todo está corriendo)
./smart-start.sh

# Forzar reinicio completo (problemas graves)
./force-restart.sh

# Ver logs detallados
docker-compose -f config/docker-compose.yml logs -f
```

## 📊 **Información Mostrada**

### **Durante la Ejecución:**
- 🔍 **Estado actual** de contenedores
- 🎯 **Decisión tomada** y razón
- ⚡ **Acción ejecutada**
- ✅ **Resultado final**

### **Al Finalizar:**
- 📋 **URLs principales** del sistema
- 🔧 **Comandos útiles**
- 💡 **Tips y recomendaciones**
- 📊 **Estado de servicios**

## 🎯 **URLs Principales (Siempre Mostradas)**

```
🎛️ DASHBOARD PRINCIPAL:
=================================
   🎛️ http://localhost:8085/unified-dashboard-fixed.html  ⭐ Principal
   📊 http://localhost:8084/                              Dashboard de Tráfico

🌐 URLs del Sistema Completo:

🎛️ Dashboard Unificado (RECOMENDADO):
  http://localhost:8085/unified-dashboard-fixed.html  ⭐ Dashboard Principal
  📊 Control A/B Testing + Canary + URLs Activas + Métricas

📊 Dashboard de Tráfico WebLogic:
  http://localhost:8084/                    📊 Dashboard de Tráfico
  http://localhost:8084/api/stats            📊 API de Estadísticas
  http://localhost:8084/api/health           🔍 Health Check
  http://localhost:8084/api/ab/enable        🎯 A/B Testing API
  http://localhost:8084/api/canary/enable    🚀 Canary Deployment API
  http://localhost:8084/api/reset            🔄 Reset Stats API

🎛️ Panel de Administración HAProxy:
  http://localhost:8092/index-functional.html
  http://localhost:8092/

📡 API de Administración:
  http://localhost:8093/api/health
  http://localhost:8093/api/status

📈 Estadísticas HAProxy:
  http://localhost:8404/stats (admin/admin123)

🌐 Frontend Principal:
  http://localhost:8100/

🚀 Aplicaciones de Prueba:
  http://localhost:8100/version-a/
  http://localhost:8100/version-b/
  http://localhost:8100/feature-flags/

🔧 Consolas WebLogic:
  http://localhost:7001/console (weblogic/welcome1)
  http://localhost:7002/console (weblogic/welcome1)
```

## 💡 **Ventajas del Sistema Inteligente**

### **⚡ Eficiencia:**
- **Reinicio rápido** cuando todos los servicios están corriendo
- **Inicio optimizado** según el estado actual
- **Menos tiempo de espera** en reinicios

### **🧠 Inteligencia:**
- **Detección automática** del estado
- **Decisión optimizada** de la acción
- **Limpieza automática** de recursos

### **📊 Información:**
- **Estado detallado** de servicios
- **URLs verificadas** automáticamente
- **Logs y recursos** del sistema

### **🔧 Flexibilidad:**
- **Múltiples opciones** según necesidad
- **Forzar acciones** cuando sea necesario
- **Comandos específicos** para cada caso

## 🚀 **Comandos de Acceso Rápido**

```bash
# Inicio inteligente (PRINCIPAL)
./start.sh

# Estado del sistema
./status.sh

# Reinicio forzado
./force-restart.sh

# Parar todo
./stop.sh

# Verificar URLs
./verify-updated-urls.sh
```

## ✨ **¡Sistema Inteligente Listo!**

Los scripts inteligentes están configurados y listos para usar. El sistema ahora:

- ✅ **Detecta automáticamente** el estado de los servicios
- ✅ **Ejecuta la acción más eficiente** (inicio, reinicio parcial o completo)
- ✅ **Muestra información detallada** del proceso
- ✅ **Optimiza tiempos** de inicio y reinicio
- ✅ **Proporciona comandos específicos** para cada situación

**Comando principal recomendado:**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh
```

¡Ahora el sistema es mucho más eficiente y fácil de usar! 🎉
