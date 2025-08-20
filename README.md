# 🦋 Mariposario RA

Aplicación Flutter multiplataforma (Android & iOS) para explorar mariposas en Realidad Aumentada con un diseño minimalista y soporte para dark mode.

---

## 🚀 Instalación Rápida

1. **Instala Flutter** ([Guía oficial](https://docs.flutter.dev/get-started/install))
2. Clona el repositorio y entra a la carpeta:

   ```bash
   git clone <URL_DE_TU_REPO>
   cd mariposario_ra
   ```

3. Instala dependencias:

   ```bash
   flutter pub get
   ```

---

## ▶️ Cómo Correr la App

### Android

- Conecta un dispositivo o abre un emulador.
- Ejecuta:

  ```bash
  flutter run -d android
  ```

### iOS

- Requiere Mac + Xcode + dispositivo físico o simulador.
- Ejecuta:

  ```bash
  flutter run -d ios
  ```

- Si es la primera vez: abre el proyecto en Xcode, configura tu Team y acepta permisos.

---

## 🧩 Paquetes Necesarios

- `flutter` (SDK principal)
- `provider` (gestión de estado y tema)
- `ar_flutter_plugin` (Realidad Aumentada)  
  **Para habilitar RA:**

    1. En `pubspec.yaml`, descomenta la línea:

       ```yaml
       ar_flutter_plugin: ^0.7.3
       ```

    2. Ejecuta:

       ```bash
       flutter pub get
       ```

---

## 🦋 Cómo Importar Mariposas (Estructura Modular)

Desde ahora, **no necesitas modificar el código** para agregar nuevas especies. Solo sigue estos pasos usando el directorio `species/`:

### ¿Qué es `species/`?

Es una carpeta donde cada subcarpeta representa una mariposa. Dentro de cada subcarpeta hay un archivo `metadata.json` con la información y rutas de assets de la especie.

### Ejemplo visual

```
mariposario_ra/
├── species/
│   ├── monarca/
│   │   └── metadata.json
│   ├── morpho/
│   │   └── metadata.json
│   └── ...
```

### Ejemplo de `metadata.json`

```json
{
  "name": "Mariposa Monarca",
  "scientificName": "Danaus plexippus",
  "imageAsset": "assets/images/monarca.png",
  "modelAsset": "assets/models/mariposa.glb"
}
```

### ¿Cómo agregar una mariposa?

1. Crea una carpeta dentro de `species/` con el nombre de la mariposa (ejemplo: `species/morpho/`).
2. Dentro, crea el archivo `metadata.json` como el ejemplo de arriba.
3. Coloca la imagen en `assets/images/` y el modelo `.glb` en `assets/models/`.
4. ¡Listo! La app los detectará automáticamente.

---

## 🟦 Integración QR por área

Puedes asociar cada área del sendero a una especie usando códigos QR. Así, el usuario escanea el QR en el área y la app muestra directamente la mariposa correspondiente en AR.

### ¿Cómo funciona?

- Imprime un QR para cada área, codificando el nombre o ID de la especie (ejemplo: `monarca`, `morpho`, `azulreal`).
- El usuario escanea el QR desde la app.
- La app detecta el código y carga automáticamente la experiencia AR de la mariposa asociada.

### ¿Cómo implementarlo en la app?

1. Agrega un botón "Escanear QR" en la pantalla principal o de selección.
2. Al escanear, busca la especie cuyo nombre coincida con el QR y navega directo a la experiencia AR.
3. Puedes generar QRs fácilmente en línea (por ejemplo, [https://www.qr-code-generator.com/](https://www.qr-code-generator.com/)).

### Ejemplo de flujo QR

1. El QR de la zona 1 contiene el texto: `monarca`.
2. El usuario escanea el QR.
3. La app busca la especie `monarca` y muestra la mariposa en RA.

---

## 🛠️ Integración de Realidad Aumentada

- **Permisos:**

    - iOS: Agrega a `ios/Runner/Info.plist`:

      ```xml
      <key>NSCameraUsageDescription</key>
      <string>Necesitamos acceso a la cámara para mostrar RA</string>
      ```

    - Android: Agrega a `android/app/src/main/AndroidManifest.xml`:

      ```xml
      <uses-permission android:name="android.permission.CAMERA"/>
      ```

- **Uso básico en código:**

    - Usa el widget `ARView` de `ar_flutter_plugin` para mostrar el modelo 3D.
    - Ejemplo mínimo en `ARExperienceScreen`:

      ```dart
      ARView(
        onARViewCreated: (controller) {
          controller.onAddNode(
            ARNode(
              type: NodeType.localGLTF2,
              uri: "assets/models/mariposa_monarca.glb",
              scale: Vector3(0.5, 0.5, 0.5),
            ),
          );
        },
      )
      ```

---

## 📁 Estructura Recomendada

```
mariposario_ra/
├── lib/
│   ├── screens/...
│   ├── models/butterfly_example.dart
│   └── ...
├── assets/
│   ├── images/monarca.png
│   └── models/mariposa_monarca.glb
│   └── sounds/ambiente_bosque.mp3
├── pubspec.yaml
```

---

## ❓ Troubleshooting y Consejos

- Si no ves el modelo en RA:
    - Verifica permisos de cámara.
    - El modelo `.glb` debe estar bien exportado y referenciado.
    - Usa dispositivos compatibles con ARCore (Android) o ARKit (iOS).
- Para agregar más mariposas, repite el flujo de assets y modelo en el código.
- Mantén los modelos optimizados para evitar caídas de rendimiento.

---

## 📚 Recursos Útiles

- [Documentación Flutter](https://docs.flutter.dev/)
- [ar_flutter_plugin](https://pub.dev/packages/ar_flutter_plugin)
- [Optimización de modelos glTF](https://github.com/KhronosGroup/glTF-Tutorials)

---

Desarrollado con ❤️ siguiendo el plan visual y de experiencia de usuario para el Mariposario RA.
