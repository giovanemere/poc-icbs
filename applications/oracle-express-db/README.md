# oracle-setup

## Descripción
Configuración Oracle Database

## Estructura
```
applications/oracle-setup/
├── src/                 # Código fuente
├── config/             # Configuraciones
├── scripts/            # Scripts específicos
├── deploy/             # Deployment files
├── docs/               # Documentación
├── tests/              # Tests
├── Dockerfile          # Dockerfile principal
└── README.md          # Esta documentación
```

## Build
```bash
docker build -t edissonz8809/oracle-setup:latest .
```

## Variables
Las variables están centralizadas en `scripts/.env`

---
Generado: 2025-07-31 22:46:27
