#!/bin/bash

# Script para encontrar un puerto libre dinámicamente
# Uso: ./find-free-port.sh [puerto_inicial] [puerto_final]

PUERTO_INICIAL=${1:-8080}
PUERTO_FINAL=${2:-8099}

# Modo silencioso si se pasa --quiet
QUIET=false
if [[ "$3" == "--quiet" ]]; then
    QUIET=true
fi

if [[ "$QUIET" == "false" ]]; then
    echo "🔍 Buscando puerto libre entre $PUERTO_INICIAL y $PUERTO_FINAL..." >&2
fi

for puerto in $(seq $PUERTO_INICIAL $PUERTO_FINAL); do
    # Verificar si el puerto está libre
    if ! netstat -tlnp 2>/dev/null | grep -q ":$puerto "; then
        if [[ "$QUIET" == "false" ]]; then
            echo "✅ Puerto libre encontrado: $puerto" >&2
        fi
        echo "$puerto"
        exit 0
    else
        if [[ "$QUIET" == "false" ]]; then
            echo "❌ Puerto $puerto ocupado" >&2
        fi
    fi
done

if [[ "$QUIET" == "false" ]]; then
    echo "⚠️  No se encontró ningún puerto libre en el rango $PUERTO_INICIAL-$PUERTO_FINAL" >&2
fi
exit 1
