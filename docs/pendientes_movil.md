# Módulos de la web pendientes en la app móvil

Cada módulo no portado tiene una pantalla `PantallaPendiente` / `PantallaPendienteContenido`
("Disponible próximamente") para que la navegación esté completa.

| Módulo web | Ruta móvil | Estado | Motivo |
|------------|-----------|--------|--------|
| Inicio | `/inicio` | Hecho (M2) | Bandeja de notificaciones. |
| Traducción | `/traducir` | Hecho (M2) | Configuración, detección, intercambio, copiar, alternativas. |
| Historial | `/historial` | Hecho (M2) | Búsqueda, solo favoritos, favorito, eliminar, copiar. |
| Perfil | `/perfil` | Hecho (M2, B7) | Editar nombre; foto de perfil (agregar, cambiar, quitar). |
| Documentos | `/documentos` | Hecho (M5) | Subir .docx/.xlsx/.pdf, traducir (origen automático o elegido), descargar/compartir, eliminar. |
| Conversaciones (intérprete) | `/conversaciones`, `/interprete/:id` | Hecho (M5, B1) | Crear (idiomas, entorno, contexto, glosario, descripción), elegir quién habla, dictado por voz y lectura en voz alta, reintentar, pausar/reanudar/finalizar, copiar. |
| Chats entre usuarios | `/conversaciones` (pestaña Chats), `/chats/:idChat` | Hecho (M5, B4) | Lista, nuevo chat por nombre (desde 3 letras, con espera), original + traducido, idioma de lectura, leído, refresco periódico con la pantalla abierta. |
| Glosarios | `/glosarios`, `/glosarios/:id` | Hecho (B3) | Crear, editar y eliminar glosarios y términos; duplicados validados como la web; selector en Traducir, Nueva conversación y Preferencias. Falta «Duplicar glosario» de la web. |
| Preferencias de traducción | `/preferencias` | Hecho (B2) | Idioma de destino, variante regional, contexto, tono, glosario predeterminado, explicar expresiones, alternativas; guardar, descartar y restablecer. Falta el aprendizaje de preferencias (HU-34). |
| Integraciones (Meet/Zoom) y sesiones externas | `/integraciones` | «Próximamente» (B7) | `POST /integraciones/{plataforma}/autorizar` exige OAuth en el navegador (y las sesiones externas, captura de audio de reuniones). |
| Foto de perfil | `/perfil` | Hecho (B7) | `GET/PUT/DELETE /perfil/foto`; JPG, PNG o WEBP de hasta 5 MB, elegida con el selector de archivos (sin cámara). |

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

## Administración (M4)

| Módulo web | Ruta móvil | Estado |
|------------|-----------|--------|
| Dashboard | `/administracion/dashboard` | Hecho: periodos, indicadores, idiomas/contextos más usados y actividad reciente (barras). |
| Usuarios | `/administracion/usuarios` (+ `/:id`) | Hecho: búsqueda, filtro por estado, paginación, detalle, suspender/reactivar, cambiar rol. |
| Reportes | `/administracion/reportes` | Hecho: periodo, tipo de servicio, totales, actividad paginada, exportar PDF/Excel (compartir). |
| Perfil | `/administracion/perfil` | Hecho (editar nombre). |
| Planes / Suscripciones | `/administracion/planes`, `/administracion/suscripciones` | "Próximamente": no existen en el backend. |
| Filtros por idioma/contexto en reportes | — | Pendiente: la web los tiene; en móvil solo periodo y servicio. |
| Gráficos de evolución | — | Se muestran como barras; sin librería de gráficos. |

## Pendiente dentro de M5

| Funcionalidad web | Motivo |
|-------------------|--------|
| Voz en el intérprete | Hecho en B1 con el reconocimiento y la síntesis del dispositivo (como la web). Depende del motor de voz instalado; sin él se avisa y se puede seguir escribiendo. |
| Asistencia conversacional (`POST /conversaciones/{id}/asistencia`) | No portada en móvil. |
| Renombrar participantes y editar la configuración de una conversación (`PATCH`) | No portado en móvil. |
| Tono al crear la conversación | No portado en móvil (contexto, glosario y descripción sí). |
| Chats en tiempo real | Sin WebSocket en el backend; se usa refresco periódico. |

## Bloques B1–B7

| Bloque | Estado | Notas |
|--------|--------|-------|
| B1 Voz en el intérprete (HU-25, HU-28) | Hecho | `speech_to_text` en el idioma del participante (región por tabla, como la web), texto parcial, reinicio tras silencios; `flutter_tts` en el idioma de destino; modo Manual/Automática en `shared_preferences` con la clave de la web `traducontext.reproduccionVoz`. Permiso `RECORD_AUDIO`. No probado en un dispositivo real (no se ejecutó `flutter run`). |
| B2 Preferencias | Hecho | Ver la tabla de arriba. |
| B3 Glosarios | Hecho | Ver la tabla de arriba. |
| B4 Búsqueda de usuarios | Hecho | El backend busca solo por nombre (pendientes_backend.md #16). |
| B5 Nombres de idioma | Hecho | `compartido/nombres_idioma.dart` por código. En Reportes el backend envía solo el nombre (sin código) y se muestra tal cual (pendientes_backend.md #18). |
| B6 Notificaciones | Hecho | Canal `traducontext_mensajes`, agrupación por chat estilo mensajería, sin aviso del chat en pantalla. Contrato: `docs/contrato_notificaciones.md`. El push sigue desactivado mientras `google-services.json` no corresponda al `applicationId`. |
| B7 Integraciones y foto | Foto hecha; integraciones «Próximamente» | OAuth externo. |
