# Arquitectura del Proyecto Docker para Oracle WebLogic

```mermaid
graph TD
    subgraph "Infraestructura Docker"
        Docker[Docker Engine]
        WebLogicContainer[Contenedor WebLogic]
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
        TestCanarySh[test-canary.sh]
    end

    subgraph "Scripts del Contenedor"
        ContainerCanaryControlSh[canary-control.sh]
        SetupMonitoringSh[setup-monitoring.sh]
        StartSampleSh[startSample.sh]
    end

    subgraph "Archivos WAR"
        FeatureFlagsWar[feature-flags.war]
        FF4JSimpleWar[ff4j-simple.war]
        WebLogicFeaturesAWar[weblogic-features-a.war]
        WebLogicFeaturesBWar[weblogic-features-b.war]
    end

    subgraph "Codigo Fuente"
        FeatureFlagsProject[feature-flags]
        VersionAProject[version-a]
        VersionBProject[version-b]
    end

    BuildSh --> Docker
    BuildWarsSh --> WebLogicFeaturesAWar
    BuildWarsSh --> WebLogicFeaturesBWar
    BuildFeatureFlagsSh --> FeatureFlagsWar
    CreateSimpleWarsSh --> WebLogicFeaturesAWar
    CreateSimpleWarsSh --> WebLogicFeaturesBWar
    CreateSimpleWarsSh --> FF4JSimpleWar

    FeatureFlagsProject --> BuildFeatureFlagsSh
    VersionAProject --> BuildWarsSh
    VersionBProject --> BuildWarsSh

    DeployWarSh --> WebLogicContainer
    FeatureFlagsWar --> DeployWarSh
    FF4JSimpleWar --> DeployWarSh
    WebLogicFeaturesAWar --> DeployWarSh
    WebLogicFeaturesBWar --> DeployWarSh
    
    classDef docker fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef build fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef deploy fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef container fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef war fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    classDef source fill:#e0f2f1,stroke:#00695c,stroke-width:2px
    
    class Docker,WebLogicContainer docker
    class BuildSh,BuildWarsSh,BuildFeatureFlagsSh,CreateSimpleWarsSh build
    class DeployWarSh,SetupCanarySh,CanaryControlSh,TestCanarySh deploy
    class ContainerCanaryControlSh,SetupMonitoringSh,StartSampleSh container
    class FeatureFlagsWar,FF4JSimpleWar,WebLogicFeaturesAWar,WebLogicFeaturesBWar war
    class FeatureFlagsProject,VersionAProject,VersionBProject source
```
    WebLogicFeaturesAWar --> DeployWarSh
    WebLogicFeaturesBWar --> DeployWarSh

    %% Relaciones de Canary
    SetupCanarySh --> WebLogicContainer
    CanaryControlSh --> WebLogicContainer
    TestCanarySh --> WebLogicContainer

    %% Relaciones de scripts del contenedor
    ContainerCanaryControlSh --> WebLogicContainer
    SetupMonitoringSh --> WebLogicContainer
    StartSampleSh --> WebLogicContainer

    %% Flujo de usuario
    User[Usuario] --> DeployWarSh
    User --> SetupCanarySh
    User --> CanaryControlSh
    User --> TestCanarySh
    User --> BuildSh
    User --> BuildWarsSh
    User --> BuildFeatureFlagsSh
    User --> CreateSimpleWarsSh

    %% Acceso a aplicaciones
    WebLogicContainer --> FeatureFlagsApp["/feature-flags"]
    WebLogicContainer --> FF4JConsoleApp["/ff4j-simple"]
    WebLogicContainer --> VersionAApp["/weblogic-features-a"]
    WebLogicContainer --> VersionBApp["/weblogic-features-b"]
    WebLogicContainer --> CanaryApp["/weblogic-features"]
```

## Descripción de la Arquitectura

El diagrama muestra la arquitectura completa del proyecto Docker para Oracle WebLogic con soporte para Feature Flags y despliegue Canary.

### Componentes Principales

1. **Infraestructura Docker**
   - Docker Engine: Motor de contenedores que ejecuta WebLogic
   - Contenedor WebLogic: Instancia de Oracle WebLogic Server

2. **Scripts de Construcción**
   - build.sh: Construye la imagen Docker de WebLogic
   - build-wars.sh: Compila los archivos WAR para WebLogic Features
   - build-feature-flags.sh: Compila la aplicación de Feature Flags
   - create-simple-wars.sh: Crea archivos WAR simples

3. **Scripts de Despliegue**
   - deploy-war.sh: Script unificado para desplegar archivos WAR
   - setup-canary.sh: Configura el despliegue canary
   - canary-control.sh: Controla el porcentaje de tráfico entre versiones
   - test-canary.sh: Prueba el despliegue canary

4. **Scripts del Contenedor**
   - canary-control.sh: Control de canary dentro del contenedor
   - setup-monitoring.sh: Configura la exposición de logs
   - startSample.sh: Script de inicio para el contenedor

5. **Archivos WAR**
   - feature-flags.war: Aplicación de Feature Flags
   - ff4j-simple.war: Consola simulada de FF4J
   - weblogic-features-a.war: Versión A para despliegue canary
   - weblogic-features-b.war: Versión B para despliegue canary

6. **Código Fuente**
   - feature-flags: Proyecto de Feature Flags
   - version-a: Versión A para despliegue canary
   - version-b: Versión B para despliegue canary

7. **Aplicaciones Desplegadas**
   - /feature-flags: Aplicación de Feature Flags
   - /ff4j-simple: Consola simulada de FF4J
   - /weblogic-features-a: Versión A para despliegue canary
   - /weblogic-features-b: Versión B para despliegue canary
   - /weblogic-features: Punto de entrada para despliegue canary



Tráfico por Backend solo deberia mostrarme testing A/b y canary

uando se tiene testing a/b, canary inactivo deberia estar desactivado el tafico a weblogic-b, version-b -backend y weblogic-feature-b
