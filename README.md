# traducontextmovil

App movil (Flutter) de TraduContext. Consume la API de `traducontextback`.

## Stack
Riverpod (estado) · go_router (rutas + redirect por permisos) · dio (interceptor Bearer, 401 -> /login) · flutter_secure_storage (token).

## Ejecutar contra el backend local
- Emulador Android: usa `http://10.0.2.2:8000/api/v1` por defecto.
- Otro destino (dispositivo fisico, otra IP):
  `flutter run --dart-define=API_URL=http://<IP-del-PC>:8000/api/v1`
  (el backend debe escuchar en `0.0.0.0`).

## Estructura (lib/)
- `nucleo/` configuracion, almacenamiento, red, rutas, tema, permisos
- `datos/` modelos, servicios_api, repositorios
- `presentacion/` autenticacion, carcasas, inicio, perfil, administracion
- `compartido/widgets/`

## Credenciales
`google-services.json`, `GoogleService-Info.plist` y cualquier credencial de Firebase estan en `.gitignore`. No se versionan.
