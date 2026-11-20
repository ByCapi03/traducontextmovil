# traducontextmovil

App móvil de TraduContext (Flutter, Android). Consume la API de `traducontextback`.

Antes de arrancar la app, el backend tiene que estar corriendo en el puerto 8000 (ver el README
de `traducontextback`).

## Stack

Riverpod (estado) · go_router (rutas + redirect por permisos) · dio (interceptor Bearer, 401 → /login) ·
flutter_secure_storage (token) · firebase_messaging + flutter_local_notifications (push).

## Requisitos

- Flutter estable con Dart 3.11.5 o superior (probado con Flutter 3.41.7). Compruébalo con `flutter doctor`.
- Android SDK con `platform-tools` (`adb`). Si `adb` no está en el PATH, está en
  `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.
- Para un teléfono físico: opciones de desarrollador y **depuración USB** activadas. Al conectar el
  teléfono, acepta la huella del PC.

## 1. Instalación

```powershell
cd traducontextmovil
flutter pub get
```

## 2. Firebase (notificaciones push)

- La app usa la configuración nativa de Android: basta con `android/app/google-services.json`, que
  no se versiona. No hace falta `firebase_options.dart`.
- El `applicationId` es `com.atemporal`, porque reutiliza el registro Android que ya existe en el
  proyecto Firebase `atemporal-f0125`. Descarga su `google-services.json` (Firebase → Configuración
  del proyecto → Tus apps → Android `com.atemporal`) y cópialo en `android/app/`.
- Si el archivo falta o no corresponde a `com.atemporal`, la app compila y funciona igual, pero sin
  push (Gradle muestra un aviso).
- El backend necesita `FIREBASE_CREDENCIALES` para enviar los push.
- Al iniciar sesión, la app pide permiso de notificaciones (Android 13+) y registra el teléfono
  en el backend.

## 3. Ejecutar contra el backend local

La app elige la URL del backend con `--dart-define` (`config/*.json`):

| Destino | Cómo | URL que usa la app | Backend |
|---------|------|--------------------|---------|
| **Teléfono por USB** (recomendado) | `.\scripts\movil_usb.ps1` | `http://127.0.0.1:8000/api/v1` | `uvicorn app.main:app --port 8000` |
| Teléfono por Wi-Fi | `flutter run --dart-define-from-file=config/api_wifi.json` | IP Wi-Fi del PC (`config/api_wifi.json`) | `uvicorn app.main:app --host 0.0.0.0 --port 8000` + puerto 8000 abierto en el firewall de Windows (red privada) |
| Emulador | `flutter run` | `http://10.0.2.2:8000/api/v1` (por defecto) | `uvicorn app.main:app --port 8000` |

- `scripts/movil_usb.ps1` ejecuta `adb reverse tcp:8000 tcp:8000` y luego
  `flutter run --dart-define-from-file=config/api_usb.json`. Así el `127.0.0.1:8000` del teléfono
  llega al del PC, sin IP ni firewall.
- `adb reverse` se pierde al desconectar el cable o reiniciar adb: vuelve a ejecutar el script o
  `adb reverse tcp:8000 tcp:8000`. Compruébalo con `adb reverse --list`.
- La IP Wi-Fi la asigna el router y puede cambiar: mírala con `ipconfig` (adaptador Wi-Fi) y
  actualiza `config/api_wifi.json`. El teléfono y el PC tienen que estar en la misma red.
- En VS Code las tres opciones están en `.vscode/launch.json`.
- La app permite HTTP sin TLS (`usesCleartextTraffic`) para el backend local.

## 4. Instalar un APK en el teléfono

```powershell
flutter build apk --debug --dart-define-from-file=config/api_usb.json
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb reverse tcp:8000 tcp:8000
```

Usa el mismo `--dart-define` que vayas a usar al conectar: un APK compilado sin él apunta a
`10.0.2.2`, que solo funciona en el emulador.

## Verificación

`flutter analyze` y `flutter test` tienen que pasar antes de cada commit.

## Estructura (`lib/`)

| Carpeta | Contenido |
|---------|-----------|
| `nucleo/` | Configuración (URL de la API), almacenamiento, red, rutas, tema, permisos. |
| `navegacion/` | Rutas (go_router), enrutador y carcasas de usuario y administración. |
| `funcionalidades/` | Un módulo por funcionalidad (autenticación, traducción, chats, documentos, notificaciones, administración...). |
| `compartido/` | Widgets y utilidades comunes. |

## Documentación

- `docs/pendientes_movil.md`: qué módulos de la web están portados y qué falta.
- `docs/pendientes_backend.md`: cambios sugeridos al backend detectados desde el móvil.
- `docs/contrato_notificaciones.md`: formato de los push que envía el backend.

## Credenciales

`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`, `firebase.json`,
`key.properties` y `*.jks` están en `.gitignore`: no se versionan nunca. En `CREDENCIALES.md`
del repo `traducontextback` se explica el detalle de todas las credenciales del sistema y cómo
circulan.
