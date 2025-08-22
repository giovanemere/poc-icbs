# 🧠 Scripts Inteligentes

El sistema incluye scripts inteligentes que detectan automáticamente el estado de los servicios y ejecutan la acción más eficiente.

## 🚀 Scripts Principales

### 1. `./start.sh` - Inicio Inteligente (PRINCIPAL)

```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh
```

!!! success "Script Recomendado"
    **Este es el script principal que debes usar para el día a día.**
    
    - ⭐ **Script principal recomendado**
    - 🧠 **Detección automática** del estado de servicios
    - ⚡ **Acción optimizada** según el estado actual
    - 📊 **Muestra URLs** al finalizar

### 2. `./smart-start.sh` - Motor Inteligente

```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./smart-start.sh
```

- 🧠 **Motor de detección inteligente**
- 🔍 **Analiza estado** de contenedores
- 🎯 **Decide acción** más eficiente
- 📋 **Logs detallados** del proceso

### 3. `./force-restart.sh` - Reinicio Forzado

```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./force-restart.sh
```

- 🔄 **Reinicio forzado completo**
- 🛑 **Para todos los servicios**
- 🧹 **Limpia recursos**
- 🚀 **Inicio limpio**

### 4. `./status.sh` - Estado Detallado

```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./status.sh
```

- 📊 **Estado completo** del sistema
- 🔍 **Verificación de URLs**
- 💾 **Recursos del sistema**
- 📋 **Logs recientes**

## 🧠 Lógica de Detección Inteligente

### Estados Detectados

El sistema detecta automáticamente el estado actual y decide la mejor acción:

=== "🚀 Inicio Completo"
    **Situación:** No hay contenedores existentes
    
    **Acción:** Inicio completo desde cero
    
    **Comando:** `docker-compose up -d`
    
    ```bash
    # Ejemplo de salida
    DECISIÓN: Inicio completo (no hay contenedores existentes)
    🚀 Iniciando sistema desde cero...
    ```

=== "▶️ Inicio Normal"
    **Situación:** Contenedores existen pero están parados
    
    **Acción:** Inicio normal
    
    **Comando:** `docker-compose up -d`
    
    ```bash
    # Ejemplo de salida
    DECISIÓN: Inicio normal (contenedores parados)
    ▶️ Iniciando contenedores parados...
    ```

=== "🔄 Reinicio Parcial"
    **Situación:** Algunos contenedores corriendo, otros no
    
    **Acción:** Reinicio parcial
    
    **Comando:** `docker-compose down && docker-compose up -d`
    
    ```bash
    # Ejemplo de salida
    DECISIÓN: Reinicio parcial (algunos servicios caídos: 5/8)
    🔄 Reiniciando servicios parcialmente...
    ```

=== "⚡ Reinicio Rápido"
    **Situación:** Todos los servicios están corriendo
    
    **Acción:** Reinicio rápido sin parar completamente
    
    **Comando:** `docker-compose restart`
    
    ```bash
    # Ejemplo de salida
    DECISIÓN: Reinicio rápido (todos los servicios corriendo: 8/8)
    ⚡ Reiniciando servicios (modo rápido)...
    ```

## 📊 Información Mostrada

### Durante la Ejecución

Los scripts muestran información detallada durante el proceso:

```bash
🧠 INICIO INTELIGENTE - SISTEMA WEBLOGIC
=============================================

[2025-08-21 19:57:48] FASE 1: Detectando estado de los servicios...
[2025-08-21 19:57:49] Contenedores totales definidos: 8
[2025-08-21 19:57:49] Contenedores corriendo: 8
✅ DECISIÓN: Reinicio rápido (todos los servicios corriendo: 8/8)

[2025-08-21 19:57:49] FASE 3: Ejecutando reinicio rápido...
⚡ Reiniciando servicios (modo rápido)...

[2025-08-21 19:58:01] FASE 4: Verificando estado final...
✅ Todos los servicios están corriendo (8/8)
```

### Al Finalizar

Al completar la ejecución, se muestran:

- 📋 **URLs principales** del sistema
- 🔧 **Comandos útiles**
- 💡 **Tips y recomendaciones**
- 📊 **Estado de servicios**

## 🎯 Flujo de Trabajo Optimizado

### Uso Diario (Recomendado)

```bash
# Siempre usar el script principal
./start.sh

# Ver estado cuando sea necesario
./status.sh

# Parar al final del día
./stop.sh
```

### Desarrollo y Debugging

```bash
# Estado detallado
./status.sh

# Reinicio forzado si hay problemas
./force-restart.sh

# Verificar URLs
./verify-updated-urls.sh
```

### Casos Específicos

```bash
# Solo reinicio rápido (si todo está corriendo)
./smart-start.sh

# Forzar reinicio completo (problemas graves)
./force-restart.sh

# Ver logs detallados
docker-compose -f config/docker-compose.yml logs -f
```

## 📋 Comparación de Scripts

| Script | Detección | Velocidad | Uso Recomendado |
|--------|-----------|-----------|-----------------|
| `./start.sh` | ✅ Automática | ⚡ Optimizada | 🌟 Uso diario |
| `./smart-start.sh` | ✅ Automática | ⚡ Optimizada | 🔧 Uso avanzado |
| `./force-restart.sh` | ❌ Manual | 🐌 Completa | 🚨 Problemas graves |
| `./status.sh` | ✅ Solo lectura | ⚡ Rápida | 📊 Monitoreo |
| `./stop.sh` | ❌ Manual | ⚡ Rápida | 🛑 Parar sistema |

## 💡 Ventajas del Sistema Inteligente

### ⚡ Eficiencia

- **Reinicio rápido** cuando todos los servicios están corriendo
- **Inicio optimizado** según el estado actual
- **Menos tiempo de espera** en reinicios
- **Detección automática** evita comandos innecesarios

### 🧠 Inteligencia

- **Análisis automático** del estado del sistema
- **Decisión optimizada** de la acción a ejecutar
- **Limpieza automática** de recursos cuando es necesario
- **Adaptación** a diferentes escenarios

### 📊 Información

- **Estado detallado** de todos los servicios
- **URLs verificadas** automáticamente
- **Logs y recursos** del sistema en tiempo real
- **Recomendaciones** basadas en el estado actual

### 🔧 Flexibilidad

- **Múltiples opciones** según la necesidad
- **Forzar acciones** específicas cuando sea necesario
- **Comandos especializados** para cada caso de uso
- **Compatibilidad** con flujos de trabajo existentes

## 🚀 Ejemplos de Uso

### Escenario 1: Primera Vez

```bash
# Sistema limpio, primera ejecución
./start.sh

# Salida esperada:
# DECISIÓN: Inicio completo (no hay contenedores existentes)
# 🚀 Iniciando sistema desde cero...
```

### Escenario 2: Después de Parar

```bash
# Después de ejecutar ./stop.sh
./start.sh

# Salida esperada:
# DECISIÓN: Inicio normal (contenedores parados)
# ▶️ Iniciando contenedores parados...
```

### Escenario 3: Sistema Corriendo

```bash
# Todos los servicios ya están corriendo
./start.sh

# Salida esperada:
# DECISIÓN: Reinicio rápido (todos los servicios corriendo: 8/8)
# ⚡ Reiniciando servicios (modo rápido)...
```

### Escenario 4: Problemas Parciales

```bash
# Algunos servicios caídos
./start.sh

# Salida esperada:
# DECISIÓN: Reinicio parcial (algunos servicios caídos: 5/8)
# 🔄 Reiniciando servicios parcialmente...
```

## 🔧 Personalización

### Variables de Entorno

Puedes personalizar el comportamiento con variables de entorno:

```bash
# Forzar un tipo específico de inicio
FORCE_ACTION=restart ./start.sh

# Modo silencioso (menos output)
QUIET_MODE=true ./start.sh

# Modo debug (más información)
DEBUG_MODE=true ./start.sh
```

### Configuración Avanzada

Los scripts leen configuración desde:

- `.env` - Variables de entorno principales
- `config/docker-compose.yml` - Configuración de servicios
- Scripts personalizados en `scripts/`

## 🚨 Troubleshooting

### Si la Detección Falla

```bash
# Forzar reinicio completo
./force-restart.sh

# Ver estado detallado
./status.sh

# Verificar manualmente
docker-compose -f config/docker-compose.yml ps
```

### Si los Scripts No Funcionan

```bash
# Verificar permisos
chmod +x *.sh

# Verificar dependencias
docker --version
docker-compose --version

# Ver logs de error
./start.sh 2>&1 | tee start.log
```

## ✨ Scripts Inteligentes Listos

Los scripts inteligentes están configurados y optimizados para:

- ✅ **Detectar automáticamente** el estado de los servicios
- ✅ **Ejecutar la acción más eficiente** según el estado
- ✅ **Mostrar información detallada** del proceso
- ✅ **Optimizar tiempos** de inicio y reinicio
- ✅ **Proporcionar comandos específicos** para cada situación

**Comando principal recomendado:**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh
```

¡El sistema es ahora mucho más eficiente y fácil de usar! 🎉
