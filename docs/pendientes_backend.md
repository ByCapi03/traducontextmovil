# Pendientes detectados en el backend (no modificado desde el móvil)

Revisado contra `traducontextback/app/api/routes/{autenticacion,usuarios}.py` y
`app/services/{autenticacion,usuarios}.py`.

| # | Endpoint | Situación actual | Efecto en la app | Cambio sugerido |
|---|----------|------------------|------------------|-----------------|
| 1 | `POST /autenticacion/iniciar-sesion` | Cuenta sin verificar y cuenta suspendida devuelven ambas **403**; solo cambia el texto del `detail`. | El login muestra «Tu cuenta no está activa.» y el enlace «¿Aún no verificaste tu correo?». Si estaba suspendida, la verificación responde 403 y se muestra «Tu cuenta está suspendida…». | Devolver un código de error estable (p. ej. `{"codigo": "CUENTA_NO_VERIFICADA"}`) o un HTTP distinto. |
| 2 | `verificar-codigo`, `validar-codigo-recuperacion`, `restablecer-contrasena` | Sin límite de intentos. El código es de 6 dígitos y vale 10 min. | Ninguno visible. | Limitar intentos por código/correo (p. ej. 5) e invalidar el código al superarlo. |
| 3 | `reenviar-codigo`, `solicitar-recuperacion` | Sin límite de frecuencia; nunca devuelve **429**. | La app aplica 60 s de espera en cliente y ya tiene texto propio para 429. | Rate limit por correo/IP con 429. |
| 4 | `POST /usuarios/reenviar-codigo` | **404** «No existe un usuario con ese correo.» revela si el correo está registrado. | Se muestra «No encontramos una cuenta con ese correo.» | Responder 200 neutro como en recuperación. |
| 5 | `POST /autenticacion/solicitar-recuperacion` | Respuesta neutra (bien), pero el **502** solo puede ocurrir si la cuenta existe y está activa. | Paso 1 muestra mensaje neutro; con 502, «No pudimos enviar el correo…». | Enviar el correo en segundo plano o responder 200 también ante fallo SMTP (y registrarlo en logs). |
| 6 | `POST /usuarios/verificar-codigo` | **400** agrupa código inválido, expirado y cuenta ya activa. | Un único texto que cubre los tres casos. | Código de error estable por caso. |
| 7 | Todos | Los `detail` llegan sin tildes («contrasena», «sesion»). | La app nunca los muestra en autenticación: usa textos propios por código HTTP. | Corregir textos del backend. |

## Detectados en M2 (usuario)

| # | Endpoint | Situación actual | Efecto en la app | Cambio sugerido |
|---|----------|------------------|------------------|-----------------|
| 8 | `notificar()` en `app/services/notificaciones.py` | Ningún flujo la llama: ni la traducción de documentos ni los chats generan notificaciones. | La bandeja de Inicio funciona pero, por ahora, siempre estará vacía (salvo datos sembrados). | Llamar a `notificar()` al terminar `POST /documentos/traducir` (`DOCUMENTO_LISTO` / `DOCUMENTO_ERROR`) y al recibir un mensaje de chat (`MENSAJE_CHAT`). |
| 9 | `datos` de las notificaciones | No hay contrato de claves. | La app asume `id_traduccion_documento` (documentos) e `id_chat` (chats) para navegar al tocar. | Documentar y usar esas claves al llamar a `notificar()`. |
| 10 | `GET /configuracion-traduccion` | Si no existe responde 404 y no hay endpoint "crear por defecto". | La app usa `DELETE /configuracion-traduccion` (restablecer), que crea la configuración por defecto si no existe. Solo se llama tras un 404. | Opcional: `POST /configuracion-traduccion/por-defecto` explícito, o que el GET la cree. |

## Detectados en M4 (administración)

| # | Endpoint | Situación actual | Efecto en la app | Cambio sugerido |
|---|----------|------------------|------------------|-----------------|
| 11 | Planes y suscripciones | No existen modelos ni endpoints. | Perfil del administrador muestra "Planes" y "Suscripciones" como "Próximamente". | `GET/POST /planes`, `PATCH/DELETE /planes/{id}`, `GET /suscripciones?estado=&pagina=`, `PATCH /suscripciones/{id}` (permiso `administrar_planes`, ya sembrado). |
| 12 | `GET /dashboard`, `GET /reportes/actividad` | Exigen zona horaria IANA. | La app envía `UTC` (Dart no expone la zona IANA sin plugin): los cortes por día pueden desplazarse unas horas. | Opcional: aceptar un desplazamiento (`+-HH:MM`) además de la zona IANA. |

## Detectados en M5 (documentos, intérprete y chats)

| # | Endpoint | Situación actual | Efecto en la app | Cambio sugerido |
|---|----------|------------------|------------------|-----------------|
| 13 | WebSocket de chats (Etapa 2) | No existe ningún WebSocket en el backend. | El chat abierto consulta `GET /chats/{id}/mensajes?despues_de=` cada 4 s, solo con la pantalla abierta y la app en primer plano. | `WS /chats/ws?token=...` con eventos `mensaje_nuevo`, `mensaje_traducido` y `leido` por `id_chat`. |
| 14 | Voz en la conversación con intérprete | No hay endpoint de audio para `/conversaciones` (solo `POST /sesiones-externas/{id}/audio`). La web usa el reconocimiento y la síntesis de voz del navegador. | La app móvil solo admite texto. | `POST /conversaciones/{id}/intervenciones/audio` (multipart, `id_participante`) que transcriba y traduzca. Alternativa sin backend: reconocimiento en el dispositivo (`speech_to_text`), igual que hace la web. |
| 15 | `POST /documentos/traducir` | Síncrono: la respuesta llega al terminar la traducción. | La app amplía el tiempo de espera a 10 min para esa petición; si la conexión se corta, el resultado se ve al recargar. | Procesar en segundo plano (estado `PENDIENTE`) y avisar con `notificar(DOCUMENTO_LISTO)`. |
| 16 | `GET /chats/usuarios` | Busca a cualquier usuario activo por nombre. | Se muestra solo id y nombre (el backend no devuelve correo). | Valorar limitar la búsqueda (privacidad). |
