#!/bin/bash
# Script para arreglar todas las referencias a scripts movidos

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔧 Arreglando referencias a scripts..."

# Buscar y reemplazar referencias en todos los scripts
find "$PROJECT_ROOT" -name "*.sh" -type f -exec grep -l "scripts/core/load-env.sh" {} \; | while read -r file; do
    echo "Actualizando: $file"
    sed -i 's|scripts/core/load-env.sh|scripts/core/load-env.sh|g' "$file"
done

find "$PROJECT_ROOT" -name "*.sh" -type f -exec grep -l "scripts/core/docker-compose-wrapper.sh" {} \; | while read -r file; do
    echo "Actualizando: $file"
    sed -i 's|scripts/core/docker-compose-wrapper.sh|scripts/core/docker-compose-wrapper.sh|g' "$file"
done

find "$PROJECT_ROOT" -name "*.sh" -type f -exec grep -l "scripts/maintenance/auto-update-haproxy.sh" {} \; | while read -r file; do
    echo "Actualizando: $file"
    sed -i 's|scripts/maintenance/auto-update-haproxy.sh|scripts/maintenance/auto-update-haproxy.sh|g' "$file"
done

find "$PROJECT_ROOT" -name "*.sh" -type f -exec grep -l "scripts/services/minikube-port-forwards.sh" {} \; | while read -r file; do
    echo "Actualizando: $file"
    sed -i 's|scripts/services/minikube-port-forwards.sh|scripts/services/minikube-port-forwards.sh|g' "$file"
done

echo "✅ Referencias actualizadas"
