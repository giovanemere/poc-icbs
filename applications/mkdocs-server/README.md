# mkdocs-server

## Descripción
Servidor de documentación MkDocs

## Estructura
```
applications/mkdocs-server/
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
docker build -t edissonz8809/mkdocs-server:latest .
```

## Variables
Las variables están centralizadas en `scripts/.env`

---
Generado: 2025-07-31 22:46:27
