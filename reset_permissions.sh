#!/bin/bash

echo "🧹 Limpieza completa de permisos iOS..."

# 1. Detener cualquier proceso de Flutter
echo "⏹️  Deteniendo procesos Flutter..."
pkill -f flutter
pkill -f dart

# 2. Limpiar proyecto Flutter
echo "🗑️  Limpiando proyecto Flutter..."
flutter clean

# 3. Limpiar iOS específicamente
echo "🍎 Limpiando configuración iOS..."
cd ios
rm -rf build/
rm -rf Pods/
rm -rf .symlinks/
rm -f Podfile.lock

# 4. Reinstalar pods
echo "📦 Reinstalando CocoaPods..."
pod deintegrate
pod install

cd ..

# 5. Resetear permisos del simulador (si está corriendo)
echo "🔄 Reseteando permisos del simulador..."
xcrun simctl privacy booted reset all 2>/dev/null || echo "No se pudo resetear simulador (puede que no esté corriendo)"

# 6. Limpiar caché de Flutter
echo "🧼 Limpiando caché Flutter..."
flutter pub cache clean
flutter pub get

echo "✅ Limpieza completa terminada!"
echo ""
echo "🚀 Ahora ejecuta:"
echo "   flutter run"
echo ""
echo "📱 Y ASEGÚRATE de:"
echo "   1. Eliminar manualmente la app del dispositivo/simulador"
echo "   2. Cuando aparezca el diálogo de permisos, tocar 'Permitir'"
