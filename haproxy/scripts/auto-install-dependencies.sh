#!/bin/bash

# Script de inicialización automática para HAProxy
# Instala dependencias necesarias automáticamente

set -e

echo "🚀 Inicializando dependencias de HAProxy..."

# Función para instalar socat
install_socat() {
    echo "📦 Verificando socat..."
    
    if command -v socat >/dev/null 2>&1; then
        echo "✅ socat ya está instalado"
        return 0
    fi
    
    echo "⚠️  socat no encontrado, instalando..."
    
    # Detectar el sistema operativo
    if command -v apk >/dev/null 2>&1; then
        # Alpine Linux
        echo "🐧 Detectado Alpine Linux"
        apk add --no-cache socat
    elif command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu
        echo "🐧 Detectado Debian/Ubuntu"
        apt-get update -qq
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq socat
    elif command -v yum >/dev/null 2>&1; then
        # CentOS/RHEL
        echo "🐧 Detectado CentOS/RHEL"
        yum install -y socat
    else
        echo "❌ Sistema operativo no soportado para instalación automática"
        return 1
    fi
    
    echo "✅ socat instalado correctamente"
}

# Función para verificar otras dependencias
check_dependencies() {
    echo "🔍 Verificando otras dependencias..."
    
    # Verificar curl
    if ! command -v curl >/dev/null 2>&1; then
        echo "⚠️  curl no encontrado"
        if command -v apk >/dev/null 2>&1; then
            apk add --no-cache curl
        elif command -v apt-get >/dev/null 2>&1; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl
        fi
    fi
    
    # Verificar python3 (para APIs)
    if ! command -v python3 >/dev/null 2>&1; then
        echo "⚠️  python3 no encontrado"
        if command -v apk >/dev/null 2>&1; then
            apk add --no-cache python3 py3-pip
        elif command -v apt-get >/dev/null 2>&1; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3 python3-pip
        fi
    fi
    
    echo "✅ Dependencias verificadas"
}

# Función principal
main() {
    echo "🎯 Iniciando instalación automática de dependencias..."
    
    # Instalar socat (crítico para HAProxy stats)
    install_socat
    
    # Verificar otras dependencias
    check_dependencies
    
    echo "🎉 Inicialización de dependencias completada"
    echo "📊 HAProxy listo para funcionar con todas las APIs"
}

# Ejecutar solo si se llama directamente
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
