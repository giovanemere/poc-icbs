# Arquitectura Mejorada del Proyecto Docker para Oracle WebLogic

## Diagrama de Arquitectura General

```mermaid
graph TD
    subgraph "Infraestructura Docker"
        Docker[Docker Engine]
        HAProxy[HAProxy Load Balancer]
        WebLogicA[Contenedor WebLogic A]
        WebLogicB[Contenedor WebLogic B]
    end

    subgraph "Scripts de Construccion"
        BuildSh[build.sh]
        BuildWarsSh[build-wars.sh]
        BuildFeatureFlagsSh[build-feature-flags.sh]
        CreateSimpleWarsSh[create-simple-wars.sh]
    end

    subgraph "Scripts de Despliegue"
        DeployWarSh[deploy-war.sh]
        SetupCanarySh[setup-canary.sh]
        CanaryControlSh[canary-control.sh]
        ManageTrafficSh[manage-traffic.sh]
        TestCanarySh[test-canary.sh]
    end

    subgraph "Aplicaciones Desplegadas"
        FeatureFlagsApp[feature-flags]
        FF4JConsoleApp[ff4j-simple]
        VersionAApp[weblogic-features-a]
        VersionBApp[weblogic-features-b]
        CanaryApp[weblogic-features]
    end

    User[Usuario] --> HAProxy
    HAProxy --> WebLogicA
    HAProxy --> WebLogicB
    
    HAProxy --> FeatureFlagsApp
    HAProxy --> FF4JConsoleApp
    HAProxy --> VersionAApp
    HAProxy --> VersionBApp
    HAProxy --> CanaryApp
    
    CanaryControlSh --> HAProxy
    
    classDef docker fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef scripts fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef apps fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    class Docker,HAProxy,WebLogicA,WebLogicB docker
    class BuildSh,BuildWarsSh,DeployWarSh,SetupCanarySh scripts
    class FeatureFlagsApp,FF4JConsoleApp,VersionAApp,VersionBApp,CanaryApp apps
```

## Componentes Principales

### 🐳 Infraestructura Docker
- **Docker Engine**: Motor de contenedores
- **HAProxy**: Load balancer y proxy reverso
- **WebLogic A/B**: Servidores de aplicaciones en contenedores

### 📜 Scripts de Construcción
- **build.sh**: Script principal de construcción
- **build-wars.sh**: Construcción de archivos WAR
- **build-feature-flags.sh**: Construcción específica para feature flags
- **create-simple-wars.sh**: Creación de WARs simples

### 🚀 Scripts de Despliegue
- **deploy-war.sh**: Despliegue de aplicaciones WAR
- **setup-canary.sh**: Configuración de despliegue canary
- **canary-control.sh**: Control del tráfico canary
- **manage-traffic.sh**: Gestión general del tráfico
- **test-canary.sh**: Pruebas del despliegue canary

## Diagrama de Flujo de Tráfico

```mermaid
flowchart TD
    User[Usuario] --> HAProxy[HAProxy Load Balancer]
    HAProxy --> Decision{Configuracion de Trafico}
    
    Decision -->|Normal| WebLogicA[WebLogic A]
    Decision -->|Normal| WebLogicB[WebLogic B]
    Decision -->|A/B Testing| ABLogic[Logica A/B]
    Decision -->|Canary| CanaryLogic[Logica Canary]
    
    ABLogic --> WebLogicA
    ABLogic --> WebLogicB
    
    CanaryLogic --> WebLogicA
    CanaryLogic --> WebLogicB
    
    WebLogicA --> Response[Respuesta al Usuario]
    WebLogicB --> Response
```

## Flujo de Despliegue

```mermaid
flowchart LR
    Start[Inicio] --> Build[Construccion]
    Build --> Test[Pruebas]
    Test --> Deploy[Despliegue]
    Deploy --> Monitor[Monitoreo]
    Monitor --> Success{Exito?}
    Success -->|Si| Complete[Completado]
    Success -->|No| Rollback[Rollback]
    Rollback --> Deploy
```

## Diagrama de Testing A/B (Cuando está activo)

```mermaid
flowchart LR
    User[Usuario] --> HAProxy[HAProxy]
    HAProxy --> ABDecision{A/B Testing}
    ABDecision -->|50%| WebLogicA[WebLogic A Version A]
    ABDecision -->|50%| WebLogicB[WebLogic B Version B]
    WebLogicA --> ResponseA[Respuesta Version A]
    WebLogicB --> ResponseB[Respuesta Version B]
```

### Características del Testing A/B Activo:
- **Distribución**: 50% del tráfico a cada versión
- **Métricas**: Recolección de datos de rendimiento
- **Comparación**: Análisis de resultados entre versiones

## Diagrama de Testing A/B (Cuando está inactivo)

```mermaid
flowchart LR
    User[Usuario] --> HAProxy[HAProxy]
    HAProxy --> WebLogicA[WebLogic A Version Estable]
    HAProxy --> WebLogicB[WebLogic B Version Estable]
    WebLogicA --> Response[Respuesta Uniforme]
    WebLogicB --> Response
```

### Características del Testing A/B Inactivo:
- **Distribución**: Tráfico normal balanceado
- **Versiones**: Ambas instancias ejecutan la misma versión
- **Estabilidad**: Comportamiento predecible y uniforme

## Diagrama de Canary Deployment (Cuando está activo)

```mermaid
flowchart LR
    User[Usuario] --> HAProxy[HAProxy]
    HAProxy --> CanaryDecision{Canary Deployment}
    CanaryDecision -->|90%| WebLogicA[WebLogic A Version Estable]
    CanaryDecision -->|10%| WebLogicB[WebLogic B Version Canary]
    WebLogicA --> ResponseStable[Respuesta Version Estable]
    WebLogicB --> ResponseCanary[Respuesta Version Canary]
```

### Características del Canary Deployment Activo:
- **Distribución**: 90% tráfico estable, 10% canary
- **Riesgo**: Minimizado al exponer solo una pequeña porción
- **Monitoreo**: Vigilancia intensiva de la versión canary

## Diagrama de Canary Deployment (Cuando está inactivo)

```mermaid
flowchart LR
    User[Usuario] --> HAProxy[HAProxy]
    HAProxy --> WebLogicA[WebLogic A Version Estable]
    HAProxy --> WebLogicB[WebLogic B Version Estable]
    WebLogicA --> Response[Respuesta Uniforme]
    WebLogicB --> Response
```

### Características del Canary Deployment Inactivo:
- **Distribución**: Tráfico normal balanceado
- **Versiones**: Ambas instancias ejecutan la versión estable
- **Operación**: Funcionamiento normal sin experimentación

## Arquitectura de Red

```mermaid
graph TB
    Internet[Internet] --> Firewall[Firewall]
    Firewall --> LoadBalancer[HAProxy Load Balancer]
    
    LoadBalancer --> WebLogic1[WebLogic Container A]
    LoadBalancer --> WebLogic2[WebLogic Container B]
    
    WebLogic1 --> Database[Oracle Database]
    WebLogic2 --> Database
    
    LoadBalancer --> Monitoring[Dashboards de Monitoreo]
    
    classDef network fill:#ffebee,stroke:#f44336,stroke-width:2px
    classDef compute fill:#e3f2fd,stroke:#2196f3,stroke-width:2px
    classDef storage fill:#fff8e1,stroke:#ffc107,stroke-width:2px
    classDef monitor fill:#e8f5e8,stroke:#4caf50,stroke-width:2px
    
    class Internet,Firewall network
    class LoadBalancer,WebLogic1,WebLogic2 compute
    class Database storage
    class Monitoring monitor
```

## Beneficios de esta Arquitectura

### 🎯 Flexibilidad
- **Despliegues graduales**: Canary deployment para reducir riesgos
- **Testing A/B**: Comparación de versiones en producción
- **Feature flags**: Control granular de funcionalidades

### 🛡️ Confiabilidad
- **Load balancing**: Distribución de carga entre instancias
- **Rollback rápido**: Capacidad de revertir cambios problemáticos
- **Monitoreo**: Supervisión continua del rendimiento

### 🚀 Escalabilidad
- **Contenedores**: Fácil escalado horizontal
- **Microservicios**: Arquitectura preparada para crecimiento
- **Automatización**: Scripts para operaciones repetitivas

Esta arquitectura mejorada proporciona una base sólida para el desarrollo, testing y despliegue de aplicaciones empresariales con Oracle WebLogic.
