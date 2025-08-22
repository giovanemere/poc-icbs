# Docker para Oracle WebLogic con Testing A/B, Canary Deployment y Feature Flags

Este proyecto proporciona un entorno Docker para Oracle WebLogic con soporte para estrategias avanzadas de despliegue como Testing A/B, Canary Deployment y Feature Flags utilizando HAProxy. Incluye modo oscuro en las interfaces de usuario, herramientas para build local y sistema unificado de gestión.

## 🚀 Inicio Rápido

### **Comando Principal (Recomendado)**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh
```

### **Parar Todo el Sistema**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./stop.sh
```

### **Verificar URLs del Sistema**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./verify-updated-urls.sh
```

## 🎯 **URLs Principales del Sistema**

### **🎛️ DASHBOARD PRINCIPAL:**
```
🎛️ http://localhost:8085/unified-dashboard-fixed.html  ⭐ Principal
📊 http://localhost:8084/                              Dashboard de Tráfico
```

### **🌐 URLs del Sistema Completo**

#### **🎛️ Dashboard Unificado (RECOMENDADO):**
- `http://localhost:8085/unified-dashboard-fixed.html` ⭐ **Dashboard Principal**
- 📊 Control A/B Testing + Canary + URLs Activas + Métricas

#### **📊 Dashboard de Tráfico WebLogic:**
- `http://localhost:8084/` - 📊 Dashboard de Tráfico
- `http://localhost:8084/api/stats` - 📊 API de Estadísticas
- `http://localhost:8084/api/health` - 🔍 Health Check
- `http://localhost:8084/api/ab/enable` - 🎯 A/B Testing API
- `http://localhost:8084/api/canary/enable` - 🚀 Canary Deployment API
- `http://localhost:8084/api/reset` - 🔄 Reset Stats API

#### **🎛️ Panel de Administración HAProxy:**
- `http://localhost:8092/index-functional.html`
- `http://localhost:8092/`

#### **📡 API de Administración:**
- `http://localhost:8093/api/health`
- `http://localhost:8093/api/status`

#### **📈 Estadísticas HAProxy:**
- `http://localhost:8404/stats` (admin/admin123)

#### **🌐 Frontend Principal:**
- `http://localhost:8100/`

#### **🚀 Aplicaciones de Prueba:**
- `http://localhost:8100/version-a/`
- `http://localhost:8100/version-b/`
- `http://localhost:8100/feature-flags/`

#### **🔧 Consolas WebLogic:**
- `http://localhost:7001/console` (weblogic/welcome1)
- `http://localhost:7002/console` (weblogic/welcome1)

## 🔧 Comandos de Desarrollo

### **Build WAR Files**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./scripts/build/build-wars.sh
```

### **Build Docker Images**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./build-latest.sh
```

### **Subir MkDocs para Desarrollo**
```bash
# Opción 1: Navegar al directorio del proyecto de documentación
cd /path/to/mkdocs-project

# Iniciar servidor de desarrollo MkDocs
mkdocs serve --dev-addr=0.0.0.0:8000

# Opción 2: Si tienes un script específico
./start-mkdocs-dev.sh

# Opción 3: Con Docker (si tienes imagen de MkDocs)
docker run --rm -it -p 8000:8000 -v ${PWD}:/docs squidfunk/mkdocs-material

# Opción 4: MkDocs con auto-reload
mkdocs serve --dev-addr=0.0.0.0:8000 --livereload
```

**URLs de MkDocs:**
- **Documentación Local**: `http://localhost:8000`
- **Auto-reload**: Se actualiza automáticamente al guardar cambios
- **Puerto por defecto**: 8000 (evita conflictos con WebLogic)

## 📋 Scripts Disponibles

| Script | Descripción | Uso |
|--------|-------------|-----|
| **`./start.sh`** | ⭐ **PRINCIPAL** - Inicia todo el sistema | Uso diario |
| **`./stop.sh`** | Para todo el sistema completamente | Cuando termines |
| **`./verify-updated-urls.sh`** | Verifica todas las URLs del sistema | Verificación |
| `./start-unified-system.sh` | Script completo con logs detallados | Debugging |
| `./check-images.sh` | Verifica imágenes Docker disponibles | Troubleshooting |
| `./scripts/build/build-wars.sh` | Construye archivos WAR | Desarrollo |
| `./build-latest.sh` | Construye imágenes Docker | Desarrollo |

## 🎯 Flujo de Trabajo Recomendado

### **1. Desarrollo Completo**
```bash
# 1. Construir WAR files
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./scripts/build/build-wars.sh

# 2. Construir imágenes Docker
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./build-latest.sh

# 3. Iniciar todo el sistema
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh
```

### **2. Uso Diario**
```bash
# Iniciar sistema
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh

# Verificar que todo funciona
# - Abrir: http://localhost:8085/unified-dashboard-fixed.html
# - Probar: http://localhost:8100/

# Parar sistema al final del día
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./stop.sh
```

### **3. Desarrollo con MkDocs**
```bash
# En terminal separada para documentación
cd /path/to/mkdocs-project
mkdocs serve --dev-addr=0.0.0.0:8000

# Acceder a documentación en: http://localhost:8000
```

## 🚨 Solución de Problemas Comunes

### **Si algo no funciona:**

1. **Parar todo y reiniciar:**
   ```bash
   ./stop.sh
   ./start.sh
   ```

2. **Ver logs detallados:**
   ```bash
   ./start-unified-system.sh
   ```

3. **Verificar imágenes:**
   ```bash
   ./check-images.sh
   ```

4. **Verificar URLs:**
   ```bash
   ./verify-updated-urls.sh
   ```

### **URLs de Respaldo (Siempre Funcionan)**
Si HAProxy falla, estos dashboards independientes siguen funcionando:
- `http://localhost:8085/unified-dashboard-fixed.html`
- `http://localhost:8084/`
- `http://localhost:8092/index-functional.html`
- `http://localhost:8093/api/health`

### **URLs Prioritarias para Acceso Rápido**

1. **🎛️ Dashboard Principal**: `http://localhost:8085/unified-dashboard-fixed.html` ⭐
2. **📊 Dashboard de Tráfico**: `http://localhost:8084/`
3. **🌐 Frontend Principal**: `http://localhost:8100/`

## 💡 Consejos y Mejores Prácticas

- **Los dashboards independientes** (8084, 8085, 8092, 8093) son más confiables que las URLs que dependen de HAProxy
- **El Frontend Principal** (8100) depende de que HAProxy esté funcionando correctamente
- **Usa el Dashboard de Tráfico** (8084) para A/B Testing y Canary Deployment
- **El Dashboard Unificado** (8085) es el más completo para monitoreo general
- **Construye las imágenes localmente** para mejor rendimiento y control de versiones

## 🎮 Testing A/B, Canary Deployment y Feature Flags

### 1. Testing A/B
- Accede al Dashboard de Tráfico: `http://localhost:8084`
- Configura porcentajes de tráfico entre versiones A y B
- Monitorea resultados en tiempo real

### 2. Canary Deployment
- Usa el Dashboard de Tráfico para configurar despliegues graduales
- Inicia con 5% de tráfico, aumenta gradualmente
- Monitorea métricas antes de aumentar el porcentaje

### 3. Feature Flags
- Accede a: `http://localhost:8100/feature-flags/`
- Activa/desactiva funcionalidades sin redesplegar
- Controla el rollout de nuevas características

## 🔧 Comandos Útiles

### **Gestión de Contenedores**
```bash
# Ver logs en tiempo real
docker-compose -f config/docker-compose.yml logs -f

# Ver estado de contenedores
docker-compose -f config/docker-compose.yml ps

# Reiniciar solo un servicio
docker-compose -f config/docker-compose.yml restart haproxy
```

### **Verificación y Debugging**
```bash
# Verificar imágenes disponibles
./check-images.sh

# Verificar configuración de URLs
./verify-updated-urls.sh

# Inicio con logs detallados
./start-unified-system.sh
```

## Arquitectura del Sistema

```
                                  ┌─────────────┐
                                  │   Cliente   │
                                  └──────┬──────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                            HAProxy                                  │
│                         (Puerto 8100)                              │
└───┬─────────────────────────────────┬───────────────────────────┬───┘
    │                                 │                           │
    ▼                                 ▼                           ▼
┌─────────────┐                 ┌─────────────┐             ┌─────────────┐
│ WebLogic A  │                 │ WebLogic B  │             │ Dashboards  │
│  (7001)     │                 │  (7002)     │             │Independientes│
└──────┬──────┘                 └──────┬──────┘             └─────────────┘
       │                               │
       └───────────────┬───────────────┘
                       │
                       ▼
               ┌───────────────┐
               │  Oracle DB    │
               │ (1521/5500)   │
               └───────────────┘
```

## ✨ ¡Listo para Usar!

Ejecuta el comando principal para comenzar:

```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic && ./start.sh
```

Luego ve a: `http://localhost:8085/unified-dashboard-fixed.html` para acceder al dashboard principal.

---

## 📚 Documentación Adicional

- [README Principal](../README.md) - Documentación completa del proyecto
- [Instrucciones Unificadas](../INSTRUCCIONES-UNIFICADAS.md) - Guía rápida de uso
- [URLs Corregidas](../URLS-CORREGIDAS-FINAL.md) - Lista completa de URLs actualizadas

## Licencias

- Oracle WebLogic Server: Requiere aceptar los términos de licencia de Oracle
- Oracle Database: Requiere aceptar los términos de licencia de Oracle
- HAProxy: Licencia GPL v2
- Scripts y configuraciones personalizadas: MIT License
