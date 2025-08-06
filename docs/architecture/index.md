# Arquitectura del Sistema

Esta documentación describe la arquitectura completa del proyecto Docker Oracle WebLogic con soporte para despliegues canary, feature flags y balanceador de carga HAProxy.

## 🏗️ Vista General del Sistema

```mermaid
graph TB
    subgraph "Cliente"
        U[👤 Usuario]
        B[🌐 Browser]
    end
    
    subgraph "Load Balancer"
        H[HAProxy<br/>:8080]
        HS[HAProxy Stats<br/>:8404]
    end
    
    subgraph "WebLogic Cluster Principal"
        WA[WebLogic Admin<br/>:7001]
        WM1[WebLogic Managed-1<br/>:7003]
        WM2[WebLogic Managed-2<br/>:7005]
    end
    
    subgraph "WebLogic Cluster Canary"
        WC1[WebLogic Canary-1<br/>:7007]
        WC2[WebLogic Canary-2<br/>:7009]
    end
    
    subgraph "Base de Datos"
        DB[(Oracle Database<br/>:1521)]
        FF4J[(FF4J Database)]
    end
    
    subgraph "Monitoreo"
        FF4JC[FF4J Console<br/>:7001/ff4j]
        WLC[WebLogic Console<br/>:7001/console]
    end
    
    U --> B
    B --> H
    H --> WM1
    H --> WM2
    H -.-> WC1
    H -.-> WC2
    
    WA --> WM1
    WA --> WM2
    WA -.-> WC1
    WA -.-> WC2
    
    WM1 --> DB
    WM2 --> DB
    WC1 --> DB
    WC2 --> DB
    
    WM1 --> FF4J
    WM2 --> FF4J
    WC1 --> FF4J
    WC2 --> FF4J
    
    B --> HS
    B --> FF4JC
    B --> WLC
    
    style H fill:#e1f5fe
    style WA fill:#f3e5f5
    style DB fill:#e8f5e8
    style FF4J fill:#fff3e0
```

## 🔄 Flujo de Tráfico y Balanceado

### Modo Normal (Sin Canary)

```mermaid
graph LR
    subgraph "Tráfico 100%"
        C[Cliente] --> H[HAProxy]
        H --> |50%| WM1[WebLogic-1]
        H --> |50%| WM2[WebLogic-2]
        
        WC1[WebLogic Canary-1]
        WC2[WebLogic Canary-2]
        
        style WC1 fill:#ffebee,stroke:#f44336,stroke-dasharray: 5 5
        style WC2 fill:#ffebee,stroke:#f44336,stroke-dasharray: 5 5
    end
```

### Modo A/B Testing

```mermaid
graph LR
    subgraph "A/B Testing Activo"
        C[Cliente] --> H[HAProxy]
        H --> |40%| WM1[WebLogic-1<br/>Version A]
        H --> |40%| WM2[WebLogic-2<br/>Version A]
        H --> |20%| WC1[WebLogic Canary-1<br/>Version B]
        
        WC2[WebLogic Canary-2]
        
        style WM1 fill:#e8f5e8
        style WM2 fill:#e8f5e8
        style WC1 fill:#fff3e0
        style WC2 fill:#ffebee,stroke:#f44336,stroke-dasharray: 5 5
    end
```

### Modo Canary Deployment

```mermaid
graph LR
    subgraph "Canary Deployment"
        C[Cliente] --> H[HAProxy]
        H --> |30%| WM1[WebLogic-1<br/>Version Estable]
        H --> |30%| WM2[WebLogic-2<br/>Version Estable]
        H --> |20%| WC1[WebLogic Canary-1<br/>Version Nueva]
        H --> |20%| WC2[WebLogic Canary-2<br/>Version Nueva]
        
        style WM1 fill:#e8f5e8
        style WM2 fill:#e8f5e8
        style WC1 fill:#fff3e0
        style WC2 fill:#fff3e0
    end
```

## 🏛️ Arquitectura de Componentes

```mermaid
graph TD
    subgraph "Capa de Presentación"
        UI[Web UI]
        API[REST API]
    end
    
    subgraph "Capa de Aplicación"
        WLS[WebLogic Server]
        FF[Feature Flags]
        LB[Load Balancer]
    end
    
    subgraph "Capa de Datos"
        APP_DB[(App Database)]
        FF_DB[(FF4J Database)]
        CONFIG[(Configuration)]
    end
    
    subgraph "Capa de Infraestructura"
        DOCKER[Docker Engine]
        NETWORK[Docker Network]
        VOLUMES[Docker Volumes]
    end
    
    UI --> API
    API --> WLS
    WLS --> FF
    LB --> WLS
    
    WLS --> APP_DB
    FF --> FF_DB
    WLS --> CONFIG
    
    WLS --> DOCKER
    LB --> DOCKER
    DOCKER --> NETWORK
    DOCKER --> VOLUMES
```

## 📦 Estructura de Contenedores

| Contenedor | Puerto | Función | Estado |
|------------|--------|---------|--------|
| `weblogic-admin` | 7001 | Servidor de administración | Siempre activo |
| `weblogic-managed-1` | 7003 | Servidor principal 1 | Siempre activo |
| `weblogic-managed-2` | 7005 | Servidor principal 2 | Siempre activo |
| `weblogic-canary-1` | 7007 | Servidor canary 1 | Condicional |
| `weblogic-canary-2` | 7009 | Servidor canary 2 | Condicional |
| `haproxy-lb` | 8080, 8404 | Load balancer | Siempre activo |
| `oracle-db` | 1521 | Base de datos | Siempre activo |

## 🔧 Configuración de HAProxy

### Algoritmos de Balanceado

```haproxy
backend weblogic_main
    balance roundrobin
    option httpchk GET /health
    server weblogic-1 weblogic-managed-1:7003 check
    server weblogic-2 weblogic-managed-2:7005 check

backend weblogic_canary
    balance roundrobin
    option httpchk GET /health
    server canary-1 weblogic-canary-1:7007 check
    server canary-2 weblogic-canary-2:7009 check
```

### Reglas de Enrutamiento

```haproxy
frontend weblogic_frontend
    bind *:8080
    
    # A/B Testing basado en cookies
    acl is_beta_user hdr_sub(cookie) beta=true
    use_backend weblogic_canary if is_beta_user
    
    # Canary deployment basado en porcentaje
    acl canary_traffic rand(100) lt 20
    use_backend weblogic_canary if canary_traffic
    
    default_backend weblogic_main
```

## 🚀 Scripts de Automatización

### Scripts de Construcción

```mermaid
graph LR
    subgraph "Build Pipeline"
        BS[build.sh] --> DI[Docker Image]
        BWS[build-wars.sh] --> WAR[WAR Files]
        BFS[build-feature-flags.sh] --> FF[Feature Flags WAR]
        CSW[create-simple-wars.sh] --> SW[Simple WARs]
    end
    
    DI --> DC[Docker Container]
    WAR --> DC
    FF --> DC
    SW --> DC
```

### Scripts de Despliegue

```mermaid
graph LR
    subgraph "Deployment Pipeline"
        DW[deploy-war.sh] --> WLS[WebLogic Server]
        SC[setup-canary.sh] --> CC[Canary Config]
        CCT[canary-control.sh] --> TC[Traffic Control]
        TC_TEST[test-canary.sh] --> VER[Verification]
    end
```

## 🔍 Feature Flags con FF4J

### Arquitectura FF4J

```mermaid
graph TB
    subgraph "FF4J Components"
        FC[FF4J Core]
        FW[FF4J Web Console]
        FS[FF4J Store]
        FA[FF4J Audit]
    end
    
    subgraph "Application"
        APP[WebLogic App]
        FEAT[Feature Code]
    end
    
    subgraph "Storage"
        DB[(Database)]
        CACHE[(Cache)]
    end
    
    APP --> FC
    FC --> FEAT
    FC --> FS
    FS --> DB
    FS --> CACHE
    FC --> FA
    FA --> DB
    FW --> FC
```

### Estados de Feature Flags

| Estado | Descripción | Tráfico |
|--------|-------------|---------|
| `ENABLED` | Feature activo para todos | 100% |
| `DISABLED` | Feature desactivado | 0% |
| `CANARY` | Feature en pruebas | Configurable |
| `A_B_TEST` | Pruebas A/B activas | Split configurable |

## 📊 Monitoreo y Observabilidad

### Métricas Disponibles

- **HAProxy Stats**: Estadísticas de balanceado en tiempo real
- **WebLogic Metrics**: JVM, threads, conexiones
- **FF4J Audit**: Uso de feature flags
- **Application Logs**: Logs centralizados

### Dashboards

1. **HAProxy Dashboard** (`http://localhost:8404/stats`)
   - Estado de backends
   - Distribución de tráfico
   - Health checks

2. **WebLogic Console** (`http://localhost:7001/console`)
   - Estado del cluster
   - Aplicaciones desplegadas
   - Configuración del dominio

3. **FF4J Console** (`http://localhost:7001/ff4j-web-console`)
   - Gestión de feature flags
   - Auditoría de uso
   - Configuración de estrategias

## 🔐 Seguridad

### Configuración de Seguridad

- **WebLogic Security**: Autenticación y autorización
- **HAProxy SSL**: Terminación SSL/TLS
- **Database Security**: Conexiones cifradas
- **Network Security**: Redes Docker aisladas

### Credenciales por Defecto

!!! warning "Cambiar en Producción"
    Estas credenciales deben cambiarse antes del despliegue en producción.

| Servicio | Usuario | Contraseña |
|----------|---------|------------|
| WebLogic Admin | `weblogic` | `welcome1` |
| HAProxy Stats | `admin` | `admin` |
| Oracle DB | `system` | `oracle` |

## 🔄 Flujos de Despliegue

### Despliegue Normal

1. Build de la aplicación
2. Creación del WAR
3. Despliegue en cluster principal
4. Verificación de health checks
5. Activación del tráfico

### Despliegue Canary

1. Build de la nueva versión
2. Despliegue en cluster canary
3. Configuración de porcentaje de tráfico
4. Monitoreo de métricas
5. Promoción o rollback

### A/B Testing

1. Configuración de feature flags
2. Definición de criterios de segmentación
3. Activación de pruebas
4. Recolección de métricas
5. Análisis de resultados
