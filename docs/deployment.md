# Despliegue

## 🚀 Despliegue Local

```bash
# Clonar repositorio
git clone https://github.com/giovanemere/POC ICBS.git
cd POC ICBS

# Instalar dependencias
npm install

# Ejecutar en desarrollo
npm run dev
```

## 🐳 Docker

```bash
# Construir imagen
docker build -t POC ICBS .

# Ejecutar contenedor
docker run -p 8080:8080 POC ICBS
```

## ☁️ Producción

Pasos para despliegue en producción.
