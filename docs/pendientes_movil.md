# Módulos de la web pendientes en la app móvil

Cada módulo no portado tiene una pantalla `PantallaPendiente` / `PantallaPendienteContenido`
("Disponible próximamente") para que la navegación esté completa.

| Módulo web | Ruta móvil | Estado | Motivo |
|------------|-----------|--------|--------|
| Inicio | `/inicio` | Hecho (M2) | Bandeja de notificaciones. |
| Traducción | `/traducir` | Hecho (M2) | Configuración, detección, intercambio, copiar, alternativas. |
| Historial | `/historial` | Hecho (M2) | Búsqueda, solo favoritos, favorito, eliminar, copiar. |
| Perfil | `/perfil` | Hecho (M2) | Editar nombre. Foto de perfil pendiente. |
| Documentos | `/documentos` | Pendiente (M5) | |
| Conversaciones (intérprete) | `/conversaciones` | Pendiente (M5) | |
| Chats entre usuarios | `/chats/:idChat` | Pendiente (M5) | |
| Glosarios | `/glosarios` | Pendiente | CRUD extenso de glosarios y términos; se usa desde la web. |
| Preferencias de traducción | `/preferencias` | Pendiente | Contexto, tono, variante, glosario por defecto; se usa desde la web. |
| Integraciones (Meet/Zoom) y sesiones externas | `/integraciones` | Pendiente | Requiere OAuth en navegador y captura de audio de reuniones. |
| Foto de perfil | — | Pendiente | `PUT/DELETE /perfil/foto` existen; falta selector de imagen. |

## Notificaciones push (M3)

- Implementado: registro del token FCM en `POST /dispositivos` con plataforma `android` al iniciar
  sesión y cuando FCM lo renueva; `DELETE /dispositivos/{token}` antes de cerrar sesión; permiso
  de notificaciones (Android 13+); notificación local en primer plano; navegación al tocar
  (primer plano, segundo plano y app cerrada).
- **Configuración pendiente (no es del backend):** el `android/app/google-services.json` actual
  pertenece al paquete `com.atemporal`, no a `com.traducontext.traducontextmovil`. Con él, Gradle
  omite el plugin de Google Services (aviso en la compilación) y la app arranca sin push.
  Para activarlo: registrar la app Android `com.traducontext.traducontextmovil` en el proyecto
  Firebase y reemplazar `google-services.json` (no se versiona). No hace falta
  `firebase_options.dart`: en Android se usa la configuración nativa.
- iOS no está configurado (sin `GoogleService-Info.plist` ni APNs).
- Se usa `getToken`/`onTokenRefresh` (obsoletos en firebase_messaging 17) porque el backend envía
  a tokens de registro (`MulticastMessage(tokens=...)`); `register()` devuelve un Installation ID.
