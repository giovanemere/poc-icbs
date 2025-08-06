#!/bin/bash
# Script de build para todas las aplicaciones

set -e

echo "🏗️  Building all applications..."

APPS=("weblogic-feature-flags" "haproxy-advanced" "mkdocs-server" "oracle-setup")
NAMESPACE="edissonz8809"

for app in "${APPS[@]}"; do
    if [[ -f "applications/$app/Dockerfile" ]]; then
        echo "📦 Building $app..."
        cd "applications/$app"
        docker build -t "$NAMESPACE/$app:latest" .
        cd "../.."
        echo "✅ $app built"
    else
        echo "⚠️  Dockerfile not found for $app"
    fi
done

echo "🎉 All applications built!"
