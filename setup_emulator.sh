#!/bin/bash
# Script para crear un emulador Android para DICOM Visual
# Ejecutar: bash setup_emulator.sh

set -e

echo "🚀 Creando emulador Android..."

# Detectar ruta del SDK
if [ -d "$HOME/Android/Sdk" ]; then
  SDK="$HOME/Android/Sdk"
elif [ -d "$HOME/Library/Android/sdk" ]; then
  SDK="$HOME/Library/Android/sdk"
else
  echo "❌ No se encontró Android SDK en las rutas habituales"
  echo "   Busca tu SDK con: flutter config --android-sdk"
  exit 1
fi

CMDTOOLS="$SDK/cmdline-tools/latest/bin"
if [ ! -f "$CMDTOOLS/sdkmanager" ]; then
  CMDTOOLS="$SDK/cmdline-tools/12.0/bin"
fi
if [ ! -f "$CMDTOOLS/sdkmanager" ]; then
  CMDTOOLS="$SDK/cmdline-tools/11.0/bin"
fi

echo "📦 SDK detectado en: $SDK"
echo "🔧 Usando sdkmanager en: $CMDTOOLS"

# 1. Aceptar licencias
echo ""
echo "📜 Aceptando licencias..."
"$CMDTOOLS/sdkmanager" --licenses 2>&1 || true

# 2. Instalar imagen de sistema (API 34)
echo ""
echo "📥 Instalando imagen de sistema Android 14 (API 34)..."
"$CMDTOOLS/sdkmanager" "system-images;android-34;default;x86_64" 2>&1

# 3. Instalar emulator si no está
echo ""
echo "📥 Instalando emulator..."
"$CMDTOOLS/sdkmanager" "emulator" 2>&1

# 4. Crear el emulador
echo ""
echo "🖥️  Creando emulador 'DicomEmulator'..."
echo "no" | "$CMDTOOLS/avdmanager" create avd \
  -n "DicomEmulator" \
  -k "system-images;android-34;default;x86_64" \
  -d "pixel_6" \
  -f 2>&1

echo ""
echo "✅ ¡Emulador 'DicomEmulator' creado!"
echo ""
echo "Para iniciarlo:"
echo "  cd $SDK/emulator && ./emulator -avd DicomEmulator &"
echo ""
echo "Para ejecutar la app:"
echo "  cd /home/optimus/Documentos/freebuff/src/flutter/dicom_visual"
echo "  flutter run"
echo ""
