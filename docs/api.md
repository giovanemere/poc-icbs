# API Documentation - poc-icbs

## 📋 Descripción de la API

API RESTful para ICBS integration service

## 🔗 Base URL

```
https://api.example.com/v1
```

## 🔐 Autenticación

```bash
Authorization: Bearer <token>
```

## 📚 Endpoints

### Health Check

```http
GET /health
```

**Respuesta:**
```json
{
  "status": "ok",
  "timestamp": "2025-08-11T05:00:00Z",
  "version": "1.0.0"
}
```

### API Info

```http
GET /api/v1
```

**Respuesta:**
```json
{
  "name": "poc-icbs",
  "version": "1.0.0",
  "description": "ICBS integration service"
}
```

## 📊 Códigos de Estado

| Código | Descripción |
|--------|-------------|
| 200    | OK |
| 201    | Created |
| 400    | Bad Request |
| 401    | Unauthorized |
| 404    | Not Found |
| 500    | Internal Server Error |

## 🧪 Ejemplos

### cURL
```bash
curl -X GET https://api.example.com/v1/health
```

### JavaScript
```javascript
fetch('https://api.example.com/v1/health')
  .then(response => response.json())
  .then(data => console.log(data));
```
