# Contrato de las notificaciones push (backend → app móvil)

Lo usan `app/services/notificaciones.py` y `app/services/push_fcm.py` del backend, y en la app
`lib/funcionalidades/notificaciones/` (`ClavesPush`, `AgrupadorNotificaciones`, `ServicioPush`).

## Mensaje FCM

Cada push lleva `notification` (título y cuerpo genéricos, **nunca** el texto del mensaje ni de un
documento) y `data` con solo identificadores. En FCM todos los valores de `data` son texto.

| Clave de `data` | Obligatoria | Valor | Uso en la app |
|-----------------|-------------|-------|---------------|
| `tipo` | Sí | `MENSAJE_CHAT`, `DOCUMENTO_LISTO`, `DOCUMENTO_ERROR`, `SISTEMA`... | Decide la pantalla al tocar y si se agrupa como chat. |
| `id_chat` | Con `MENSAJE_CHAT` | id del chat (`"8"`) | Agrupa por chat, abre `/chats/{id_chat}` y no avisa si ese chat está en pantalla. |
| `id_traduccion_documento` | Con `DOCUMENTO_*` | id de la traducción del documento | Abre `/documentos`. |
| `id_notificacion` | Recomendada | id en la bandeja | Al tocar se marca como leída (`PATCH /notificaciones/{id}/leida`). |

Hoy el backend ya envía `tipo` e `id_notificacion` en `_datos_push()`, más `id_chat`/`id_mensaje`
(chats) e `id_documento`/`id_traduccion_documento` (documentos). Las claves de más se ignoran.

## Canal Android (lo debe enviar el backend)

| Campo | Valor |
|-------|-------|
| `android.notification.channel_id` | **`traducontext_mensajes`** |
| `android.priority` | `high` (ya se envía) |
| `android.notification.tag` | `chat_{id_chat}` en `MENSAJE_CHAT` (cada mensaje reemplaza la notificación de su chat); sin tag en el resto |
| `android.notification.default_sound` / `default_vibrate_timings` | `true` |

La app crea el canal `traducontext_mensajes` al iniciar (importancia alta, sonido predeterminado,
vibración) y borra el canal anterior `traducontext_general`. También es el canal por defecto del
`AndroidManifest.xml` (`default_notification_channel_id`), así que un push sin `channel_id` usa el
mismo canal. La importancia de un canal no se puede cambiar una vez creado: por eso es un id nuevo.

Cambio sugerido en `push_fcm.enviar_a_tokens()` (no aplicado desde el móvil):

```python
android=messaging.AndroidConfig(
    priority="high",
    notification=messaging.AndroidNotification(
        channel_id="traducontext_mensajes",
        tag=f"chat_{datos['id_chat']}" if datos.get("tipo") == "MENSAJE_CHAT" else None,
        default_sound=True,
        default_vibrate_timings=True,
    ),
),
```

## Comportamiento en la app

| Estado de la app | Quién muestra la notificación | Al tocarla |
|------------------|-------------------------------|------------|
| Primer plano | La app (notificación local). `MENSAJE_CHAT` se agrupa por `id_chat` en una sola notificación estilo mensajería (últimos 6 avisos); **no se muestra si ese chat está en pantalla**. Al abrir un chat se quita su notificación. | Abre la pantalla (`onDidReceiveNotificationResponse`). |
| Segundo plano | Android, con el canal y el `tag` del push. | `onMessageOpenedApp` → abre la pantalla. |
| Cerrada | Android, igual que en segundo plano. | `getInitialMessage` → abre la pantalla en cuanto hay sesión. |

En los tres casos, si el push trae `id_notificacion`, se marca como leída y se recarga la bandeja.

## Sin Firebase

Si falta `android/app/google-services.json` (o no corresponde a `com.traducontext.traducontextmovil`),
Gradle no aplica el plugin de Google Services, `Firebase.initializeApp()` falla de forma controlada y
la app arranca sin push: no pide permiso ni registra token. Ese archivo no se versiona.
