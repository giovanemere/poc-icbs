#!/bin/bash
# Script para reconstruir y reiniciar HAProxy con las nuevas configuraciones

echo "Deteniendo el contenedor HAProxy actual..."
docker stop haproxy
docker rm haproxy

echo "Reconstruyendo la imagen de HAProxy..."
docker-compose -f config/docker-compose.yml build haproxy

echo "Iniciando el nuevo contenedor HAProxy..."
docker-compose -f config/docker-compose.yml up -d haproxy

echo "Esperando a que HAProxy esté listo..."
sleep 5

echo "Verificando el estado de HAProxy..."
docker ps | grep haproxy

echo "Mostrando los logs de HAProxy..."
docker logs haproxy
