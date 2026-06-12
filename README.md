# Dicom Visual

**Visor de imágenes DICOM para dispositivos móviles** — Compatible con archivos DICOM locales y servidores Orthanc (PACS). Desarrollado con Flutter.

<p align="center">
  <img src="assets/logo.png" alt="Dicom Visual Logo" width="120" height="120">
</p>

## ✨ Características

### 📂 Carga Local
- Selección de archivos `.dcm` individuales o directorios completos mediante selector de archivos nativo
- Visualización inmediata con galería deslizable

### ☁️ Conexión Orthanc (PACS)
- Navegación completa: Pacientes → Estudios → Series → Instancias
- **Búsqueda por nombre o ID** con filtrado en tiempo real
- **Ordenamiento por fecha** (más reciente primero)
- Múltiples servidores guardados con persistencia local
- Log de diagnóstico de conexión
- Soporte para conexiones autenticadas

### 🖼️ Visor de Imágenes
| Funcionalidad | Descripción |
|---|---|
| **Modo WW/WL** | Arrastre horizontal para ajustar contraste (WW), vertical para brillo (WL) |
| **📊 HUD en vivo** | Overlay animado con valores numéricos y barras de progreso mientras arrastra |
| **🔍 Modo Zoom** | Pellizco con 2 dedos para acercar/alejar. Arrastre para navegar la imagen ampliada |
| **🔄 Cambio de modo** | Botón toggle en la imagen y en la barra inferior: WW/WL ↔ Zoom |
| **↩️ Doble tap** | Doble toque para reset rápido de WW/WL a valores por defecto |
| **↔️ Galería** | Deslice entre múltiples imágenes con navegación por miniaturas |

### 👤 Overlay de Paciente
- Nombre, ID, modalidad, fecha y descripción del estudio superpuestos en la imagen
- Gradiente semitransparente que no interfiere con gestos (`IgnorePointer`)
- Misma información en el AppBar del visor

### 📋 Metadatos DICOM
- Panel modal con **40+ tags importantes** organizados por categoría
- Tags clave: Paciente, Estudio, Serie, Equipo, Parámetros de imagen
- Valores resaltados visualmente para fácil lectura

### �� Temas
- Soporte nativo para tema claro/oscuro
- Se adapta automáticamente a la configuración del sistema

## 📸 Capturas de Pantalla

> _(Agregar capturas de pantalla aquí)_

| Lista Orthanc | Visor con HUD | Metadatos |
|---|---|---|
| Pacientes con iniciales y búsqueda | Imagen con overlay y HUD de WW/WL | Panel de tags DICOM |

## 🚀 Instalación

### Requisitos
- Flutter SDK `^3.12.1`
- Dispositivo Android (API 21+) o iOS

### APK Release Firmado
```bash
cd dicom_visual
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Desde código fuente (debug)
```bash
git clone <repo-url>
cd dicom_visual
flutter pub get
flutter run
```

### Instalación directa al teléfono
```bash
flutter install --release
```

## 🎮 Guía de Uso

### Carga Local
1. Abra la app
2. Toque **+** para seleccionar archivos `.dcm` individuales
3. Toque 📁 para cargar un directorio completo
4. Toque un estudio para abrir el visor
5. Navegue entre imágenes usando las miniaturas o botones `< anterior / siguiente >`

### Conexión Orthanc
1. Toque el ícono ☁️ en la pantalla principal
2. Seleccione un servidor existente o agregue uno nuevo
3. Verifique la conexión (toque el servidor para probar)
4. Si es exitosa, toque **Connect**
5. Use la **barra de búsqueda** para filtrar pacientes por nombre o ID

### Control del Visor

#### Modo WW/WL (por defecto)
| Gesto | Efecto |
|---|---|
| Arrastrar → Derecha/Izquierda | Aumenta/Reduce **Contraste** (WW) |
| Arrastrar ↑ Abajo/Arriba | Aumenta/Reduce **Brillo** (WL) |
| **Doble tap** | Resetea WW/WL a valores por defecto (255/128) |

> 💡 Durante el arrastre, aparece un **HUD flotante** con los valores actuales y barras de progreso.

#### Modo Zoom
| Gesto | Efecto |
|---|---|
| Pellizcar (2 dedos) | Acercar / Alejar |
| Arrastrar (1 dedo) | Navegar por la imagen ampliada |

#### Controles inferiores
| Botón | Acción |
|---|---|
| **WW/WL** | Resetea contraste/brillo a valores iniciales |
| **Reset Zoom** | Vuelve al zoom 1:1 |
| **Zoom mode / WW/WL mode** | Cambia entre modo de ajuste y modo de zoom |

## 🏗️ Estructura del Proyecto

```
dicom_visual/
├── lib/
│   ├── main.dart                          # Punto de entrada
│   ├── screens/
│   │   ├── home_screen.dart               # Pantalla principal
│   │   ├── viewer_screen.dart             # Visor de imágenes con overlay y navegación
│   │   ├── server_list_screen.dart        # Gestión de servidores Orthanc
│   │   └── orthanc_browser.dart           # Navegador con búsqueda y filtros
│   ├── widgets/
│   │   ├── dicom_image_viewer.dart        # Visor principal: WW/WL, zoom, HUD, modo toggle
│   │   ├── metadata_panel.dart            # Panel de 40+ tags DICOM
│   │   ├── connection_log_view.dart       # Log de diagnóstico
│   │   ├── edit_server_dialog.dart        # Diálogo de edición de servidor
│   │   └── orthanc_config_dialog.dart     # Configuración de conexión
│   └── services/
│       ├── dicom_loader.dart              # Carga de archivos DICOM locales
│       ├── orthanc_service.dart           # API REST de Orthanc
│       ├── server_manager.dart            # Persistencia de servidores
│       └── connection_monitor.dart        # Monitoreo de conectividad
├── .codebuff/
│   └── skills/                            # Skills reutilizables del proyecto
│       ├── dicom-image-viewer.md
│       ├── flutter-dicom-setup.md
│       ├── flutter-gesture-handling.md
│       └── orthanc-api-integration.md
├── android/                               # Configuración nativa Android
├── ios/                                   # Configuración nativa iOS
├── assets/
│   └── logo.png                           # Logo de la aplicación
├── pubspec.yaml                           # Dependencias y configuración
└── CHANGELOG.md                           # Historial de versiones
```

## 🔧 Configuración de Red

### Emulador Android
```dart
Host: 10.0.2.2        // Localhost de la máquina host
Puerto: 8042           // Puerto por defecto de Orthanc
```

### Dispositivo Físico
```dart
Host: 192.168.1.XX     // IP local del servidor Orthanc
Puerto: 8042
```

### Solución de Problemas de Conexión
- **AP Isolation** — Desactivar en la configuración WiFi del router
- **Firewall** — Verificar que el puerto 8042 esté abierto
- **Red diferente** — Asegurar que el teléfono y el servidor estén en la misma red
- **Credenciales** — Orthanc por defecto usa `orthanc`/`orthanc`

## 🔐 Firma y Distribución

### Generar Keystore
```bash
keytool -genkey -v -keystore release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias release
```

### Configurar Firma
Archivo `android/key.properties`:
```properties
storePassword=tu_contraseña
keyPassword=tu_contraseña
keyAlias=release
storeFile=../../release-keystore.jks
```

### Generar APK Release
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## 🆕 Historial de Versiones

Ver [CHANGELOG.md](CHANGELOG.md) para el detalle completo.

| Versión | Novedades |
|---|---|
| **1.0.5** | HUD flotante de WW/WL con animación, gestos mejorados |
| **1.0.4** | Botones de navegación, padding corregido, imagen a ancho completo |
| **1.0.3** | Búsqueda Orthanc, orden por fecha, fix nombres "Unknown" |
| **1.0.2** | Overlay paciente, modo zoom, modo WW/WL sin conflictos |
| **1.0.1** | Galería con miniaturas, metadatos importantes, firma release |
| **1.0.0** | Lanzamiento inicial con visor básico y conexión Orthanc |

## 📄 Licencia

Uso privado. No redistribuir sin autorización.

---

<p align="center">
  <i>Desarrollado con Flutter · DICOM · 💙</i>
</p>
