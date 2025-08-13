# Flujo de Despliegue Canary

```mermaid
flowchart TD
    Start[Inicio] --> BuildImages[Construir Imágenes]
    BuildImages --> BuildWars[Construir WARs]
    BuildWars --> DeployWars[Desplegar WARs]
    DeployWars --> SetupCanary[Configurar Canary]
    
    SetupCanary --> CanaryTest{Pruebas OK?}
    CanaryTest -->|No| AdjustTraffic[Ajustar Tráfico]
    AdjustTraffic --> CanaryTest
    
    CanaryTest -->|Sí| IncreaseTraffic[Aumentar Tráfico a Versión B]
    IncreaseTraffic --> FullDeployment[Despliegue Completo]
    FullDeployment --> End[Fin]
    
    subgraph "Construcción"
        BuildImages
        BuildWars
    end
    
    subgraph "Despliegue"
        DeployWars
        SetupCanary
    end
    
    subgraph "Pruebas y Ajustes"
        CanaryTest
        AdjustTraffic
        IncreaseTraffic
    end
    
    subgraph "Scripts Utilizados"
        Script1[build.sh]
        Script2[build-wars.sh]
        Script3[deploy-war.sh]
        Script4[setup-canary.sh]
        Script5[test-canary.sh]
        Script6[canary-control.sh]
    end
    
    BuildImages -.-> Script1
    BuildWars -.-> Script2
    DeployWars -.-> Script3
    SetupCanary -.-> Script4
    CanaryTest -.-> Script5
    AdjustTraffic -.-> Script6
    IncreaseTraffic -.-> Script6
```

## Descripción del Flujo de Despliegue Canary

El diagrama muestra el flujo completo del proceso de despliegue canary en el proyecto Docker para Oracle WebLogic.

### Etapas del Proceso

1. **Construcción**
   - Construir Imágenes: Se crea la imagen Docker de WebLogic utilizando build.sh
   - Construir WARs: Se compilan los archivos WAR para las versiones A y B utilizando build-wars.sh

2. **Despliegue**
   - Desplegar WARs: Se despliegan los archivos WAR en WebLogic utilizando deploy-war.sh
   - Configurar Canary: Se configura el despliegue canary utilizando setup-canary.sh

3. **Pruebas y Ajustes**
   - Pruebas: Se realizan pruebas para verificar el funcionamiento del despliegue canary utilizando test-canary.sh
   - Ajustar Tráfico: Si las pruebas no son satisfactorias se ajusta el porcentaje de tráfico utilizando canary-control.sh
   - Aumentar Tráfico: Si las pruebas son satisfactorias se aumenta gradualmente el tráfico hacia la versión B

4. **Despliegue Completo**
   - Una vez que la versión B ha sido probada completamente se realiza el despliegue completo

### Scripts Utilizados

- build.sh: Construye la imagen Docker de WebLogic
- build-wars.sh: Compila los archivos WAR para WebLogic Features
- deploy-war.sh: Script unificado para desplegar archivos WAR
- setup-canary.sh: Configura el despliegue canary
- test-canary.sh: Prueba el despliegue canary
- canary-control.sh: Controla el porcentaje de tráfico entre versiones
