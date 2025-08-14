# Configuración con Imágenes Existentes

## ✅ Estado: CONFIGURADO CON IMÁGENES LOCALES

El proyecto ha sido configurado para usar las imágenes Docker existentes, evitando problemas de conectividad y builds largos.

## 🐳 Imágenes Docker Utilizadas

### ✅ Imágenes Disponibles Localmente:

| Servicio | Imagen | Tag | Tamaño | Estado |
|----------|--------|-----|--------|--------|
| **WebLogic A/B** | `edissonz8809/weblogic-feature-flags` | v1.1.0 | 1.64GB | ✅ Disponible |
| **HAProxy** | `edissonz8809/haproxy-advanced` | v1.1.0 | 87.9MB | ✅ Disponible |
| **Oracle DB** | `edissonz8809/oracle-express-db` | v1.1.0 | 11.7GB | ✅ Disponible |

## 🔧 Configuración de Servicios

### 1. **WebLogic Servers**
```yaml
weblogic-a:
  image: edissonz8809/weblogic-feature-flags:v1.1.0
  container_name: weblogic-a
  ports: ["7001:7001"]
  ip: 172.23.0.4

weblogic-b:
  image: edissonz8809/weblogic-feature-flags:v1.1.0
  container_name: weblogic-b
  ports: ["7002:7001"]
  ip: 172.23.0.3
```

### 2. **HAProxy Load Balancer**
```yaml
haproxy:
  image: edissonz8809/haproxy-advanced:v1.1.0
  container_name: haproxy
  ports: 
    - "8080:80"   # HTTP Frontend
    - "8443:443"  # HTTPS Frontend
    - "8404:8404" # Stats
    - "8081:8081" # API
    - "8082:8082" # UI
  ip: 172.23.0.5
```

### 3. **Oracle Database**
```yaml
orcldb:
  image: edissonz8809/oracle-express-db:v1.1.0
  container_name: orcldb
  ports: 
    - "1521:1521" # Database
    - "5500:5500" # Enterprise Manager
  ip: 172.23.0.2
```

## 🌐 Configuración de Red

### Red Docker: `weblogic-network`
- **Subnet**: 172.23.0.0/16
- **Driver**: bridge
- **IPs Fijas**: Configuradas para cada servicio

### Mapeo de IPs:
| Servicio | IP Interna | Puerto Interno | Puerto Externo |
|----------|------------|----------------|----------------|
| Oracle DB | 172.23.0.2 | 1521, 5500 | 1521, 5500 |
| WebLogic B | 172.23.0.3 | 7001 | 7002 |
| WebLogic A | 172.23.0.4 | 7001 | 7001 |
| HAProxy | 172.23.0.5 | 80, 443, 8404, 8081, 8082 | 8080, 8443, 8404, 8081, 8082 |

## 📁 Volúmenes Configurados

### Volúmenes Persistentes:
- `db-oracle`: Datos de Oracle Database
- `weblogic-a-logs`: Logs de WebLogic A
- `weblogic-b-logs`: Logs de WebLogic B
- `weblogic-a-monitoring`: Monitoreo WebLogic A
- `weblogic-b-monitoring`: Monitoreo WebLogic B

### Volúmenes de Bind Mount:
- `../autodeploy` → `/u01/oracle/user_projects/domains/base_domain/autodeploy`
- `../deploy` → `/u01/oracle/deploy`
- `../container-scripts` → `/u01/oracle/container-scripts`
- `../haproxy/config` → `/usr/local/etc/haproxy`
- `../oracle/scripts/setup` → `/opt/oracle/scripts/setup`

## 🚀 Ventajas de Usar Imágenes Existentes

### ✅ Beneficios:
1. **Sin Build**: No necesita compilar imágenes
2. **Sin Descarga**: No requiere conectividad a Docker Hub
3. **Inicio Rápido**: Contenedores listos inmediatamente
4. **Configuración Previa**: Imágenes ya optimizadas
5. **Consistencia**: Versiones controladas y probadas

### ⚡ Rendimiento:
- **Tiempo de inicio**: ~30-60 segundos vs 10-15 minutos
- **Ancho de banda**: 0 MB vs ~2-3 GB de descarga
- **Espacio en disco**: Reutiliza imágenes existentes

## 🔄 Comandos de Gestión

### Iniciar Servicios:
```bash
# Iniciar todos los servicios
./start-all.sh

# O manualmente
docker-compose -f config/docker-compose.yml up -d
```

### Verificar Estado:
```bash
# Ver contenedores corriendo
docker-compose -f config/docker-compose.yml ps

# Ver logs
docker-compose -f config/docker-compose.yml logs -f
```

### Detener Servicios:
```bash
# Detener todos los servicios
docker-compose -f config/docker-compose.yml down

# Detener y limpiar volúmenes
docker-compose -f config/docker-compose.yml down -v
```

## 🌍 URLs de Acceso

### Servicios Principales:
| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **HAProxy Frontend** | http://localhost:8080 | - |
| **HAProxy Stats** | http://localhost:8404/stats | admin/admin123 |
| **HAProxy Admin UI** | http://localhost:8082 | - |
| **WebLogic A Console** | http://localhost:7001/console | weblogic/welcome1 |
| **WebLogic B Console** | http://localhost:7002/console | weblogic/welcome1 |
| **Oracle EM** | http://localhost:5500/em | system/welcome1 |

### Aplicaciones (después del despliegue):
| Aplicación | URL A | URL B |
|------------|-------|-------|
| Feature Flags | http://localhost:7001/feature-flags/ | http://localhost:7002/feature-flags/ |
| FF4J Simple | http://localhost:7001/ff4j-simple/ | http://localhost:7002/ff4j-simple/ |
| Version A | http://localhost:7001/version-a/ | - |
| Version B | - | http://localhost:7002/version-b/ |

## 📋 Checklist de Verificación

- [x] Imágenes Docker verificadas y disponibles
- [x] Docker-compose.yml actualizado con imágenes existentes
- [x] Configuración de red con IPs fijas
- [x] Volúmenes configurados correctamente
- [x] Puertos mapeados sin conflictos
- [x] Variables de entorno configuradas
- [x] Archivos WAR compilados y en autodeploy/
- [x] Scripts de gestión actualizados

## 🎯 Próximos Pasos

1. **Iniciar servicios**: `./start-all.sh`
2. **Verificar despliegue**: Acceder a las consolas
3. **Probar aplicaciones**: Verificar URLs de aplicaciones
4. **Configurar HAProxy**: Ajustar balanceeo de carga

---

**Configuración completada**: $(date)
**Imágenes utilizadas**: 3 imágenes locales (edissonz8809/*)
**Tiempo estimado de inicio**: 30-60 segundos
**Estado**: ✅ Listo para despliegue
