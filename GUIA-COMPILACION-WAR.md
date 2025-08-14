# Guía Completa de Compilación de Archivos WAR

## ✅ Estado: CONFIGURADO Y LISTO

Los archivos WAR han sido compilados exitosamente y están listos para despliegue automático en WebLogic.

## 🔨 Métodos de Compilación

### 1. **Método Principal (Recomendado)**
```bash
# Compilar todos los WAR y copiar automáticamente a autodeploy/
./scripts/build/build-wars.sh
```

### 2. **Método con Script Completo**
```bash
# Script completo con opciones avanzadas
./scripts/build-and-autodeploy.sh --all

# Con limpieza previa
./scripts/build-and-autodeploy.sh --clean --all
```

### 3. **Compilación Individual**
```bash
# Compilar WAR específico
./scripts/build/create-simple-wars.sh version-a
./scripts/build/create-simple-wars.sh version-b
./scripts/build/create-simple-wars.sh weblogic-features-a

# Luego copiar manualmente a autodeploy
cp deploy/*.war autodeploy/
```

## 📦 Archivos WAR Generados

### ✅ Estado Actual:

| Archivo WAR | Tamaño | Ubicación | Propósito |
|-------------|--------|-----------|-----------|
| `feature-flags.war` | 8.5K | ✅ deploy/ + autodeploy/ | Aplicación principal de Feature Flags |
| `ff4j-simple.war` | 2.7K | ✅ deploy/ + autodeploy/ | Aplicación FF4J simple |
| `version-a.war` | 2.7K | ✅ deploy/ + autodeploy/ | Versión A para Testing A/B |
| `version-b.war` | 2.7K | ✅ deploy/ + autodeploy/ | Versión B para Testing A/B |
| `weblogic-features-a.war` | 2.7K | ✅ deploy/ + autodeploy/ | Versión A para Canary Deployment |
| `weblogic-features-b.war` | 2.7K | ✅ deploy/ + autodeploy/ | Versión B para Canary Deployment |

## 📁 Estructura de Directorios

```
docker-for-oracle-weblogic/
├── deploy/                     # WAR compilados (backup)
│   ├── feature-flags.war       ✅
│   ├── ff4j-simple.war         ✅
│   ├── version-a.war           ✅
│   ├── version-b.war           ✅
│   ├── weblogic-features-a.war ✅
│   └── weblogic-features-b.war ✅
├── autodeploy/                 # WAR para despliegue automático
│   ├── feature-flags.war       ✅
│   ├── ff4j-simple.war         ✅
│   ├── version-a.war           ✅
│   ├── version-b.war           ✅
│   ├── weblogic-features-a.war ✅
│   └── weblogic-features-b.war ✅
└── scripts/
    ├── build/
    │   ├── build-wars.sh        # Script principal
    │   └── create-simple-wars.sh # Script individual
    └── build-and-autodeploy.sh  # Script completo
```

## 🔄 Proceso de Despliegue Automático

### Cómo Funciona:
1. **Compilación**: Los WAR se generan en `deploy/`
2. **Copia Automática**: Se copian a `autodeploy/`
3. **Despliegue WebLogic**: WebLogic detecta automáticamente los WAR en `autodeploy/`
4. **Disponibilidad**: Las aplicaciones quedan disponibles en las URLs configuradas

### Configuración en Docker Compose:
```yaml
volumes:
  - ../autodeploy:/u01/oracle/user_projects/domains/base_domain/autodeploy:rw
```

## 🚀 Próximos Pasos

### 1. Iniciar los Contenedores
```bash
./start-all.sh
```

### 2. Verificar Despliegue
- **WebLogic A Console**: http://localhost:7001/console
- **WebLogic B Console**: http://localhost:7002/console
- **Credenciales**: weblogic / welcome1

### 3. Acceder a las Aplicaciones
Una vez desplegadas, las aplicaciones estarán disponibles en:

| Aplicación | URL A | URL B |
|------------|-------|-------|
| Feature Flags | http://localhost:7001/feature-flags/ | http://localhost:7002/feature-flags/ |
| FF4J Simple | http://localhost:7001/ff4j-simple/ | http://localhost:7002/ff4j-simple/ |
| Version A | http://localhost:7001/version-a/ | - |
| Version B | - | http://localhost:7002/version-b/ |
| WebLogic Features A | http://localhost:7001/weblogic-features-a/ | - |
| WebLogic Features B | - | http://localhost:7002/weblogic-features-b/ |

### 4. Acceso a través de HAProxy
Una vez que HAProxy esté configurado:
- **Frontend Principal**: http://localhost:8080
- **Panel de Administración**: http://localhost:8082
- **Estadísticas HAProxy**: http://localhost:8404/stats

## 🛠️ Comandos Útiles

### Recompilar Todo
```bash
# Limpiar y recompilar
./scripts/build-and-autodeploy.sh --clean --all
```

### Verificar Estado
```bash
# Ver archivos en ambos directorios
ls -lh deploy/*.war
ls -lh autodeploy/*.war
```

### Limpiar Directorios
```bash
# Limpiar solo deploy (mantener .gitkeep)
find deploy/ -name "*.war" -delete

# Limpiar autodeploy
rm -f autodeploy/*.war
```

## 📋 Checklist de Verificación

- [x] Scripts de compilación creados y configurados
- [x] Archivos WAR compilados exitosamente
- [x] WAR copiados a autodeploy/ automáticamente
- [x] Estructura de directorios correcta
- [x] Volúmenes Docker configurados para autodeploy
- [x] Scripts de limpieza y recompilación disponibles

## 🔍 Solución de Problemas

### Error: "No se encontraron archivos WAR"
```bash
# Verificar que los scripts tienen permisos de ejecución
chmod +x scripts/build/*.sh
chmod +x scripts/build-and-autodeploy.sh
```

### Error: "Directorio no existe"
```bash
# Crear directorios si no existen
mkdir -p deploy autodeploy
```

### WAR no se despliegan automáticamente
1. Verificar que los contenedores estén corriendo
2. Verificar logs de WebLogic: `docker logs weblogic-a`
3. Verificar que los volúmenes estén montados correctamente

---

**Fecha de configuración**: $(date)
**Total de WAR compilados**: 6 archivos
**Tamaño total**: ~22KB
**Estado**: ✅ Listo para despliegue
