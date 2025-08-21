# 🐳 Docker para Oracle WebLogic - Versión Limpia

Este directorio contiene la configuración esencial para ejecutar Oracle WebLogic con Docker.

## 🚀 Inicio Rápido

### **Comando Principal:**
```bash
docker-compose -f config/docker-compose.yml up -d
```

### **Verificar Estado:**
```bash
docker-compose -f config/docker-compose.yml ps
```

### **Detener Servicios:**
```bash
docker-compose -f config/docker-compose.yml down
```

## 📁 Estructura del Directorio

```
📁 docker-for-oracle-weblogic/
├── 📁 config/
│   └── 🐳 docker-compose.yml          # Configuración principal de Docker
├── 📁 .git/                           # Repositorio Git
├── 📄 .env                            # Variables de entorno
├── 📄 README.md                       # Documentación original
├── 📄 README-SIMPLE.md                # Esta documentación
└── 📦 backup-20250821-165925/         # Backup de archivos anteriores
```

## 🌐 Servicios Incluidos

El `docker-compose.yml` incluye los siguientes servicios:

- **🖥️ weblogic-a** - Servidor WebLogic A
- **🖥️ weblogic-b** - Servidor WebLogic B  
- **⚖️ haproxy** - Load Balancer HAProxy
- **🗄️ orcldb** - Base de datos Oracle

## 🔧 Configuración

### **Variables de Entorno:**
Las variables están definidas en el archivo `.env`:
- Configuración de Oracle Database
- Configuración de WebLogic
- Puertos y networking

### **Puertos Expuestos:**
- **8080** - HAProxy Frontend
- **8404** - HAProxy Stats
- **7001** - WebLogic A Console
- **7002** - WebLogic B Console
- **1521** - Oracle Database
- **5500** - Oracle Enterprise Manager

## 📦 Backup

Todos los archivos adicionales (scripts, dashboards, documentación extendida) han sido movidos a:
```
📦 backup-20250821-165925/
```

### **Archivos importantes en el backup:**
- `unified-dashboard-fixed.html` - Dashboard Unificado funcional
- `manage-admin-panel.sh` - Script de gestión completo
- `scripts/` - Scripts de build y deploy
- `README-ACTUALIZADO.md` - Documentación completa

## 🔄 Para Restaurar Funcionalidad Completa

Si necesitas restaurar el Dashboard Unificado y scripts de gestión:

```bash
# Restaurar archivos específicos del backup
cp backup-20250821-165925/unified-dashboard-fixed.html .
cp backup-20250821-165925/manage-admin-panel.sh .
chmod +x manage-admin-panel.sh

# Restaurar scripts de build
cp -r backup-20250821-165925/scripts .

# Usar el dashboard
python3 -m http.server 8085 &
# Abrir: http://localhost:8085/unified-dashboard-fixed.html
```

## 🎯 URLs Principales (después de iniciar)

- **HAProxy Frontend**: `http://localhost:8080`
- **HAProxy Stats**: `http://localhost:8404/stats` (admin/admin123)
- **WebLogic A Console**: `http://localhost:7001/console`
- **WebLogic B Console**: `http://localhost:7002/console`
- **Oracle EM**: `http://localhost:5500/em`

## 🆘 Solución de Problemas

### **Verificar logs:**
```bash
docker-compose -f config/docker-compose.yml logs [servicio]
```

### **Reiniciar servicios:**
```bash
docker-compose -f config/docker-compose.yml restart
```

### **Limpiar y reiniciar:**
```bash
docker-compose -f config/docker-compose.yml down
docker system prune -f
docker-compose -f config/docker-compose.yml up -d
```

## 📋 Información Adicional

- **Documentación completa**: Ver `backup-20250821-165925/README-ACTUALIZADO.md`
- **Dashboard funcional**: Ver `backup-20250821-165925/unified-dashboard-fixed.html`
- **Scripts de gestión**: Ver `backup-20250821-165925/manage-admin-panel.sh`

---

**🐳 Configuración Docker Limpia para Oracle WebLogic**

**Comando principal**: `docker-compose -f config/docker-compose.yml up -d`

**Estado**: ✅ **CONFIGURACIÓN ESENCIAL LISTA PARA USO**
