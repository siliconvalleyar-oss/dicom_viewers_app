# Changelog

## [1.0.6] - 2026-06-12

### Added
- 👆 **Doble tap** para reset rápido de WW/WL sobre la imagen
- 💡 **Confirmación visual** — HUD aparece brevemente (600ms) mostrando los valores reseteados

### Changed
- Versión actualizada a `1.0.6`
- README profesional con tablas de gestos, estructura del proyecto e historial de versiones

---

## [1.0.5] - 2026-06-12

### Added
- 📊 **HUD flotante de WW/WL** — overlay animado que muestra valores de contraste (WW) y brillo (WL) en tiempo real al arrastrar sobre la imagen
- 🎨 **Barras de progreso** visuales con degradado azul (WW) y naranja (WL)

### Changed
- Versión actualizada a `1.0.5`
- Gestos de WW/WL mejorados con `onPanStart`/`onPanEnd` para mostrar/ocultar el HUD
- HUD usa `AnimatedOpacity` con fade de 200ms y `IgnorePointer` para no bloquear gestos

---

## [1.0.4] - 2026-06-12

### Added
- 🧭 **Botones de navegación (prev/next)** en el visor de archivos locales

### Changed
- Versión actualizada a `1.0.4`
- **Padding inferior aumentado** de `+16` a `+24` en botones nav de ambos visores (local y Orthanc) para mejor separación de la barra Android

### Fixed
- Botones de navegación ahora usan `MediaQuery.padding.bottom` para no quedar ocultos detrás de la barra de navegación del sistema

---

## [1.0.3] - 2026-06-12

### Added
- 🔍 **Búsqueda y filtros** en el navegador Orthanc (por nombre o ID de paciente)
- 📅 **Ordenamiento por fecha** — estudios ordenados del más reciente al más antiguo
- 👤 **Iniciales del paciente** en el avatar en lugar de "?"

### Changed
- Versión actualizada a `1.0.3`
- Tiles de estudio rediseñados con iconos (calendario, series, accession number)
- Fecha formateada como YYYY-MM-DD

### Fixed
- **Nombres de pacientes mostraban "Unknown"** — Orthanc devuelve datos en `MainDicomTags`, no `PatientMainDicomTags`
- Búsqueda ahora filtra correctamente sin duplicar llamadas a setState

---

## [1.0.2] - 2026-06-12

### Added
- 👤 **Overlay de datos del paciente** sobre la imagen (nombre, ID, modalidad, fecha, descripción)
- 🔍 **Modo Zoom** dedicado — deslizador modo WW/WL vs Zoom. Pinza para acercar/alejar
- 🔄 **Modo WW/WL** mejorado — arrastra con 1 dedo para ajustar contraste/brillo

### Changed
- Versión actualizada a `1.0.2`
- Visor de imágenes rediseñado: gestos sin conflictos entre zoom y WW/WL
- Los datos del paciente ahora se buscan por código hex en lugar de descripción (más robusto)
- Panel de metadatos ahora muestra 40 tags importantes con resaltado visual

### Fixed
- **Paciente mostraba "Unknown"** — búsqueda de tags por código hex en `flattenTags`
- **Zoom no funcionaba** — `GestureDetector` bloqueaba `InteractiveViewer`. Ahora con modo toggle
- Conflicto de gestos entre PageView, InteractiveViewer y ajuste de ventana resuelto

---

## [1.0.1] - 2026-06-12

### Added
- 🖼️ **Galería de imágenes** — Vista con PageView y miniaturas para deslizar entre múltiples imágenes
- 👤 **Información del paciente** visible en el visor (nombre, ID, fecha, modalidad)
- 📋 **Metadatos importantes** — Panel rediseñado mostrando solo tags relevantes
- 📚 **Documentación completa** — README actualizado con instrucciones de instalación y uso

### Changed
- Versión actualizada a `1.0.1`
- Metadata panel simplificado: solo muestra tags importantes (Paciente, Estudio, Serie, Equipo)
- Visor de Orthanc ahora incluye galería de miniaturas para navegar instancias

### Fixed
- Configuración de firma release en Android (keystore + build.gradle.kts)
- Permiso INTERNET y `usesCleartextTraffic` en AndroidManifest.xml
- `.gitignore` completo para el proyecto Flutter

---

## [1.0.0] - 2026-06-01

### Added
- Visor de imágenes DICOM básico
- Carga de archivos `.dcm` locales
- Conexión a servidor Orthanc
- Ajuste de ventana (Window Width/Level)
- Zoom interactivo
- Panel de metadatos con todos los tags DICOM
- Soporte de temas claro/oscuro
- Múltiples servidores guardados
- Log de diagnóstico de conexión
