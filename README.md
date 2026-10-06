# AppsLine Reader

Lector minimalista de documentos **PDF** y **Word (.docx)** hecho con Flutter.
MVP funcional para **Android** e **iOS**.

## Funcionalidad

- **Abrir documentos** PDF y DOCX con el selector nativo de archivos
  (Storage Access Framework en Android, UIDocumentPicker en iOS).
- **Visor de PDF**: desplazamiento continuo, zoom, indicador de página,
  salto de página y **búsqueda de texto** con navegación entre resultados.
- **Visor de DOCX**: extracción del texto del documento (se parsea
  `word/document.xml` en un isolate para no bloquear la UI), texto
  seleccionable y tamaño de letra ajustable.
- **Recientes**: los documentos abiertos se copian al almacenamiento de la
  app y quedan en una lista de recientes persistente (deslizar para borrar).
- **Estilo minimalista**: blanco/negro, Material 3, modo claro y oscuro
  automático según el sistema.

## Estructura

```
lib/
├── main.dart                        # Punto de entrada
└── src/
    ├── theme.dart                   # Tema minimalista (claro/oscuro)
    ├── models/
    │   └── recent_document.dart     # Modelo de documento reciente
    ├── services/
    │   ├── recent_documents_service.dart  # Recientes + copia local
    │   └── docx_extractor.dart      # Extracción de texto de DOCX
    ├── screens/
    │   ├── home_screen.dart         # Inicio: abrir + recientes
    │   ├── pdf_viewer_screen.dart   # Visor PDF (búsqueda, páginas)
    │   └── docx_viewer_screen.dart  # Visor DOCX (texto)
    └── widgets/
        └── recent_document_tile.dart
```

## Requisitos

- Flutter **3.27 o superior** (canal stable).
- Android: SDK 36 instalado (lo gestiona Android Studio automáticamente).
- iOS: Xcode y CocoaPods.

## Ejecutar

```bash
flutter pub get

# Android
flutter run

# iOS (desde macOS)
cd ios && pod install && cd ..
flutter run
```

> Nota: el archivo `android/gradle/wrapper/gradle-wrapper.jar` y
> `ios/Podfile` los genera la herramienta de Flutter automáticamente en el
> primer build; no van versionados en el repositorio.

## Dependencias principales

| Paquete | Uso |
| --- | --- |
| `file_picker` | Selector nativo de archivos |
| `syncfusion_flutter_pdfviewer` | Renderizado de PDF |
| `archive` + `xml` | Lectura de DOCX (ZIP + WordprocessingML) |
| `shared_preferences` | Persistencia de la lista de recientes |
| `path_provider` | Directorio de documentos de la app |
