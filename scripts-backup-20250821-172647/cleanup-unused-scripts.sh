#!/bin/bash

# Script para limpiar scripts no utilizados

echo "🗑️ LIMPIEZA DE SCRIPTS NO UTILIZADOS"
echo "===================================="

# Crear directorio de backup
BACKUP_DIR="scripts-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📦 Creando backup en: $BACKUP_DIR"

# Scripts que SÍ se mantienen (esenciales)
KEEP_SCRIPTS=(
    "scripts/build/build-wars.sh"
    "build-latest.sh"
    "start-automatic.sh"
    "manage-admin-panel.sh"
)

echo
echo "✅ SCRIPTS QUE SE MANTIENEN:"
for script in "${KEEP_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "   ✅ $script"
    else
        echo "   ⚠️ $script (no encontrado)"
    fi
done

echo
echo "🗑️ MOVIENDO SCRIPTS NO UTILIZADOS AL BACKUP..."

# Contador
moved_count=0

# Mover scripts del directorio principal
for script in *.sh; do
    if [ -f "$script" ]; then
        # Verificar si está en la lista de scripts a mantener
        keep=false
        for keep_script in "${KEEP_SCRIPTS[@]}"; do
            if [[ "$script" == "$keep_script" ]]; then
                keep=true
                break
            fi
        done
        
        if [[ "$keep" == false ]]; then
            mv "$script" "$BACKUP_DIR/"
            echo "   📦 $script → $BACKUP_DIR/"
            ((moved_count++))
        fi
    fi
done

# Mover scripts de subdirectorios (excepto los que se mantienen)
echo
echo "🗑️ MOVIENDO SCRIPTS DE SUBDIRECTORIOS..."

# Scripts de build (excepto build-wars.sh)
if [ -d "scripts/build" ]; then
    for script in scripts/build/*.sh; do
        if [ -f "$script" ] && [[ "$script" != "scripts/build/build-wars.sh" ]]; then
            mkdir -p "$BACKUP_DIR/scripts/build"
            mv "$script" "$BACKUP_DIR/scripts/build/"
            echo "   📦 $script → $BACKUP_DIR/scripts/build/"
            ((moved_count++))
        fi
    done
fi

# Scripts de deploy (todos)
if [ -d "scripts/deploy" ]; then
    mkdir -p "$BACKUP_DIR/scripts/deploy"
    for script in scripts/deploy/*.sh; do
        if [ -f "$script" ]; then
            mv "$script" "$BACKUP_DIR/scripts/deploy/"
            echo "   📦 $script → $BACKUP_DIR/scripts/deploy/"
            ((moved_count++))
        fi
    done
fi

# Scripts de canary (todos)
if [ -d "scripts/canary" ]; then
    mkdir -p "$BACKUP_DIR/scripts/canary"
    for script in scripts/canary/*.sh; do
        if [ -f "$script" ]; then
            mv "$script" "$BACKUP_DIR/scripts/canary/"
            echo "   📦 $script → $BACKUP_DIR/scripts/canary/"
            ((moved_count++))
        fi
    done
fi

# Mover enlaces simbólicos también
echo
echo "🔗 MOVIENDO ENLACES SIMBÓLICOS..."
for link in *.sh; do
    if [ -L "$link" ]; then
        # Verificar si está en la lista de scripts a mantener
        keep=false
        for keep_script in "${KEEP_SCRIPTS[@]}"; do
            if [[ "$link" == "$keep_script" ]]; then
                keep=true
                break
            fi
        done
        
        if [[ "$keep" == false ]]; then
            mv "$link" "$BACKUP_DIR/"
            echo "   🔗 $link → $BACKUP_DIR/"
            ((moved_count++))
        fi
    fi
done

echo
echo "✅ LIMPIEZA COMPLETADA"
echo "====================="
echo "   📦 Scripts movidos al backup: $moved_count"
echo "   📁 Backup ubicado en: $BACKUP_DIR"

echo
echo "📋 SCRIPTS RESTANTES (ESENCIALES):"
echo "=================================="
remaining_count=0
for script in "${KEEP_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "   ✅ $script"
        ((remaining_count++))
    fi
done

echo
echo "📊 RESUMEN FINAL:"
echo "================"
echo "   📦 Scripts movidos al backup: $moved_count"
echo "   ✅ Scripts esenciales mantenidos: $remaining_count"
echo "   📁 Backup: $BACKUP_DIR"

echo
echo "🚀 COMANDOS QUE SIGUEN FUNCIONANDO:"
echo "=================================="
echo "   📦 Build WAR: ./scripts/build/build-wars.sh"
echo "   🐳 Build Images: ./build-latest.sh"
echo "   🚀 Subir servicios: ./start-automatic.sh"
echo "   🎛️ Gestión: ./manage-admin-panel.sh"

echo
echo "🔄 PARA RESTAURAR UN SCRIPT:"
echo "============================"
echo "   cp $BACKUP_DIR/nombre-del-script.sh ."
echo "   chmod +x nombre-del-script.sh"

echo
echo "🎉 ¡LIMPIEZA COMPLETADA EXITOSAMENTE!"
