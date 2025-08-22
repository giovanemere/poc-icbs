# 🧪 Prueba de Diagramas Mermaid

Esta página contiene diagramas de prueba para verificar que Mermaid 9.4.3 funciona correctamente.

## Diagrama Simple

```mermaid
graph LR
    A[Inicio] --> B[Proceso]
    B --> C[Fin]
```

## Diagrama de Flujo

```mermaid
flowchart TD
    Start([Inicio]) --> Decision{Decision?}
    Decision -->|Si| ProcessA[Proceso A]
    Decision -->|No| ProcessB[Proceso B]
    ProcessA --> End([Fin])
    ProcessB --> End
```

## Arquitectura del Sistema (Compatible)

```mermaid
graph TB
    Cliente --> HAProxy
    HAProxy --> WebLogicA[WebLogic A]
    HAProxy --> WebLogicB[WebLogic B]
    WebLogicA --> Oracle[Oracle DB]
    WebLogicB --> Oracle
    
    classDef default fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef database fill:#fff3e0,stroke:#ff9800,stroke-width:2px
    
    class Oracle database
```

## Diagrama de Secuencia Simple

```mermaid
sequenceDiagram
    participant U as Usuario
    participant H as HAProxy
    participant W as WebLogic
    participant D as Database
    
    U->>H: Request
    H->>W: Forward
    W->>D: Query
    D-->>W: Data
    W-->>H: Response
    H-->>U: Result
```

## Diagrama de Estados Simple

```mermaid
stateDiagram-v2
    [*] --> Stopped
    Stopped --> Starting
    Starting --> Running
    Running --> Stopped
    Starting --> Error
    Error --> Stopped
```

## Diagrama con Subgrafos

```mermaid
graph TB
    subgraph Frontend
        A[Cliente]
        B[HAProxy]
    end
    
    subgraph Backend
        C[WebLogic A]
        D[WebLogic B]
    end
    
    subgraph Database
        E[Oracle DB]
    end
    
    A --> B
    B --> C
    B --> D
    C --> E
    D --> E
```

## Diagrama de Red Simple

```mermaid
graph LR
    Internet --> Firewall
    Firewall --> LoadBalancer
    LoadBalancer --> Server1
    LoadBalancer --> Server2
    Server1 --> Database
    Server2 --> Database
```

Si ves estos diagramas correctamente, Mermaid 9.4.3 está funcionando! ✅

## Notas de Compatibilidad

Para Mermaid 9.4.3:
- ✅ Evitar emojis en los nodos
- ✅ Usar texto simple en las etiquetas
- ✅ Evitar `<br/>` en los nodos
- ✅ Usar sintaxis de estilos completa
- ✅ Mantener nombres de nodos simples
