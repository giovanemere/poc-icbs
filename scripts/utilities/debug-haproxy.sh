#!/bin/bash

# Script de debug para HAProxy

HAPROXY_CONFIG="/home/giovanemere/periferia/icbs/docker-for-oracle-weblogic/haproxy/config/haproxy.cfg"
HAPROXY_CONTAINER="haproxy"

echo "=== Configuración actual ==="
cat "$HAPROXY_CONFIG"

echo ""
echo "=== Validando configuración actual ==="
docker exec "$HAPROXY_CONTAINER" haproxy -f /usr/local/etc/haproxy/haproxy.cfg -c

echo ""
echo "=== IPs de contenedores ==="
weblogic_a_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "weblogic-a" 2>/dev/null)
weblogic_b_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "weblogic-b" 2>/dev/null)

echo "weblogic-a: $weblogic_a_ip"
echo "weblogic-b: $weblogic_b_ip"

echo ""
echo "=== Creando configuración temporal ==="
temp_config="/tmp/haproxy_debug.cfg"
cp "$HAPROXY_CONFIG" "$temp_config"

# Actualizar las IPs
sed -i "s/server weblogic-a [0-9.]*:7001/server weblogic-a $weblogic_a_ip:7001/g" "$temp_config"
sed -i "s/server weblogic-b [0-9.]*:7001/server weblogic-b $weblogic_b_ip:7001/g" "$temp_config"

echo "=== Configuración temporal ==="
cat "$temp_config"

echo ""
echo "=== Validando configuración temporal ==="
docker exec "$HAPROXY_CONTAINER" haproxy -f /dev/stdin -c < "$temp_config"

rm -f "$temp_config"
