# 🚀 Sistema WebLogic Unificado - Instrucciones

## ⚡ **Inicio Rápido**

### **Para Iniciar Todo el Sistema:**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./start.sh
```

### **Para Parar Todo el Sistema:**
```bash
cd /home/giovanemere/periferia/icbs/docker-for-oracle-weblogic
./stop.sh
```

## 📋 **Scripts Disponibles**

| Script | Descripción | Uso |
|--------|-------------|-----|
| **`./start.sh`** | ⭐ **PRINCIPAL** - Inicia todo | Uso diario |
| **`./stop.sh`** | Para todo el sistema | Cuando termines |
| `./start-unified-system.sh` | Script completo con logs detallados | Debugging |
| `./verify-urls.sh` | Verifica configuración de URLs | Verificación |
| `./check-images.sh` | Verifica imágenes Docker | Troubleshooting |

## 🌐 **URLs del Sistema**

### **🎛️ Dashboards Principales (Más Confiables)**
- **Dashboard Unificado**: `http://localhost:8085/unified-dashboard-fixed.html` ⭐
- **Dashboard de Tráfico**: `http://localhost:8084/`
- **Panel HAProxy**: `http://localhost:8092/`
- **API Admin**: `http://localhost:8093/api/health`

### **🌐 Frontend Principal (Puerto 8100)**
- **Frontend Principal**: `http://localhost:8100/`
- **Version A**: `http://localhost:8100/version-a/`
- **Version B**: `http://localhost:8100/version-b/`
- **Feature Flags**: `http://localhost:8100/feature-flags/`
- **FF4J Simple**: `http://localhost:8100/ff4j-simple/`

### **📈 Administración**
- **HAProxy Stats**: `http://localhost:8404/stats` (admin/admin123)
- **WebLogic A Console**: `http://localhost:7001/console` (weblogic/welcome1)
- **WebLogic B Console**: `http://localhost:7002/console` (weblogic/welcome1)
- **Oracle Enterprise Manager**: `http://localhost:5500/em`

## 🔧 **Comandos Útiles**

```bash
# Ver logs en tiempo real
docker-compose -f config/docker-compose.yml logs -f

# Ver estado de contenedores
docker-compose -f config/docker-compose.yml ps

# Reiniciar solo un servicio
docker-compose -f config/docker-compose.yml restart haproxy

# Ver logs de un servicio específico
docker-compose -f config/docker-compose.yml logs -f haproxy
```

## 🎯 **Flujo de Trabajo Recomendado**

### **1. Inicio del Día**
```bash
./start.sh
```

### **2. Verificar que Todo Funciona**
- Abrir: `http://localhost:8085/unified-dashboard-fixed.html`
- Verificar: `http://localhost:8084/` (Dashboard de Tráfico)
- Probar: `http://localhost:8100/` (Frontend Principal)

### **3. Para A/B Testing y Canary**
- Usar: `http://localhost:8084/` (Dashboard de Tráfico)
- APIs disponibles:
  - `http://localhost:8084/api/ab/enable`
  - `http://localhost:8084/api/canary/enable`
  - `http://localhost:8084/api/reset`

### **4. Final del Día**
```bash
./stop.sh
```

## 🚨 **Solución de Problemas**

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
   ./verify-urls.sh
   ```

### **URLs de Respaldo (Siempre Funcionan)**
Si HAProxy falla, estos dashboards independientes siguen funcionando:
- `http://localhost:8085/unified-dashboard-fixed.html`
- `http://localhost:8084/`
- `http://localhost:8092/`
- `http://localhost:8093/api/health`

## 💡 **Consejos**

- **Los dashboards independientes** (8084, 8085, 8092, 8093) son más confiables
- **El Frontend Principal** (8100) depende de HAProxy
- **Usa el Dashboard de Tráfico** (8084) para A/B Testing y Canary
- **El Dashboard Unificado** (8085) es el más completo

## ✨ **¡Listo para Usar!**

Ejecuta `./start.sh` y ve a `http://localhost:8085/unified-dashboard-fixed.html` para comenzar.
