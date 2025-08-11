# Despliegue - poc-icbs

## 🚀 Estrategias de Despliegue

### Desarrollo Local

```bash
# Clonar repositorio
git clone https://github.com/giovanemere/poc-icbs.git
cd poc-icbs

# Instalar dependencias
npm install

# Configurar variables de entorno
cp .env.example .env

# Iniciar en modo desarrollo
npm run dev
```

### Docker

#### Dockerfile
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

#### Docker Compose
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    depends_on:
      - db
  
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: poc-icbs
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Kubernetes

#### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: poc-icbs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: poc-icbs
  template:
    metadata:
      labels:
        app: poc-icbs
    spec:
      containers:
      - name: poc-icbs
        image: poc-icbs:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
```

#### Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: poc-icbs-service
spec:
  selector:
    app: poc-icbs
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer
```

## 🔄 CI/CD Pipeline

### GitHub Actions
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
    - run: npm ci
    - run: npm test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Build Docker image
      run: docker build -t poc-icbs .
    - name: Push to registry
      run: docker push poc-icbs
```

## 🌍 Ambientes

### Desarrollo
- **URL**: http://localhost:3000
- **Base de Datos**: Local PostgreSQL
- **Logs**: Console

### Staging
- **URL**: https://staging-poc-icbs.example.com
- **Base de Datos**: Staging PostgreSQL
- **Logs**: ELK Stack

### Producción
- **URL**: https://poc-icbs.example.com
- **Base de Datos**: Production PostgreSQL (HA)
- **Logs**: ELK Stack + Alerting

## 📊 Monitoreo Post-Despliegue

### Health Checks
```bash
curl https://poc-icbs.example.com/health
```

### Métricas
- **CPU**: < 70%
- **Memoria**: < 80%
- **Response Time**: < 200ms
- **Error Rate**: < 1%

### Alertas
- **Downtime**: > 1 minuto
- **High CPU**: > 80%
- **High Memory**: > 90%
- **Error Rate**: > 5%
