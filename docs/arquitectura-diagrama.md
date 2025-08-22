# 🏗️ Diagramas de Arquitectura

## Arquitectura Principal - Versión Simple

```mermaid
graph TB
    Cliente --> HAProxy
    HAProxy --> WebLogicA
    HAProxy --> WebLogicB
    WebLogicA --> Oracle
    WebLogicB --> Oracle
    HAProxy --> Dashboards
    
    classDef haproxy fill:#e1f5fe,stroke:#1976d2,stroke-width:3px
    classDef weblogic fill:#f3e5f5,stroke:#9c27b0,stroke-width:2px
    classDef oracle fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    classDef dashboards fill:#e8f5e8,stroke:#4caf50,stroke-width:2px
    
    class HAProxy haproxy
    class WebLogicA,WebLogicB weblogic
    class Oracle oracle
    class Dashboards dashboards
```

## Arquitectura Detallada - Con Puertos

```mermaid
graph TB
    subgraph "Frontend Layer"
        Cliente[Cliente Web]
        HAProxy[HAProxy Load Balancer]
    end
    
    subgraph "Application Layer"
        WLA[WebLogic A Port 7001]
        WLB[WebLogic B Port 7002]
    end
    
    subgraph "Data Layer"
        Oracle[Oracle Database Port 1521]
    end
    
    subgraph "Monitoring Layer"
        Dashboard1[Dashboard Unificado Port 8085]
        Dashboard2[Dashboard Trafico Port 8084]
        Dashboard3[Panel HAProxy Port 8092]
    end
    
    Cliente --> HAProxy
    HAProxy --> WLA
    HAProxy --> WLB
    WLA --> Oracle
    WLB --> Oracle
    HAProxy --> Dashboard1
    HAProxy --> Dashboard2
    HAProxy --> Dashboard3
```

## Flujo de Datos

```mermaid
flowchart LR
    User[Usuario] --> Browser[Navegador]
    Browser --> HAProxy[HAProxy Port 8100]
    HAProxy --> Decision{Load Balance}
    Decision --> WLA[WebLogic A]
    Decision --> WLB[WebLogic B]
    WLA --> DB[(Oracle DB)]
    WLB --> DB
    DB --> WLA
    DB --> WLB
    WLA --> HAProxy
    WLB --> HAProxy
    HAProxy --> Browser
    Browser --> User
```

## Arquitectura de Red

```mermaid
graph TB
    Internet[Internet] --> Firewall[Firewall]
    Firewall --> HAProxy[HAProxy Load Balancer]
    
    HAProxy --> WebLogic1[WebLogic Server A]
    HAProxy --> WebLogic2[WebLogic Server B]
    
    WebLogic1 --> Database[Oracle Database]
    WebLogic2 --> Database
    
    HAProxy --> Monitoring[Monitoring Dashboards]
    
    classDef internet fill:#ffebee,stroke:#f44336
    classDef haproxy fill:#e3f2fd,stroke:#2196f3
    classDef weblogic fill:#f3e5f5,stroke:#9c27b0
    classDef database fill:#fff8e1,stroke:#ffc107
    classDef monitoring fill:#e8f5e8,stroke:#4caf50
    
    class Internet internet
    class HAProxy haproxy
    class WebLogic1,WebLogic2 weblogic
    class Database database
    class Monitoring monitoring
```

## Diagrama de Componentes

```mermaid
graph LR
    subgraph "Docker Containers"
        C1[HAProxy Container]
        C2[WebLogic A Container]
        C3[WebLogic B Container]
        C4[Oracle Container]
        C5[Dashboard Containers]
    end
    
    subgraph "Host System"
        H1[Docker Engine]
        H2[Host Network]
        H3[Host Storage]
    end
    
    C1 --> H2
    C2 --> H2
    C3 --> H2
    C4 --> H2
    C5 --> H2
    
    C2 --> H3
    C3 --> H3
    C4 --> H3
    
    H1 --> C1
    H1 --> C2
    H1 --> C3
    H1 --> C4
    H1 --> C5
```

## Puertos y Servicios

```mermaid
graph TB
    subgraph "Puerto 8100"
        Frontend[Frontend Principal]
    end
    
    subgraph "Puertos 8084-8093"
        D1[Dashboard 8085]
        D2[Trafico 8084]
        D3[HAProxy 8092]
        D4[API 8093]
    end
    
    subgraph "Puertos 7001-7002"
        W1[WebLogic A 7001]
        W2[WebLogic B 7002]
    end
    
    subgraph "Puerto 1521"
        DB[Oracle Database]
    end
    
    Frontend --> D1
    Frontend --> D2
    Frontend --> D3
    Frontend --> D4
    Frontend --> W1
    Frontend --> W2
    W1 --> DB
    W2 --> DB
```
