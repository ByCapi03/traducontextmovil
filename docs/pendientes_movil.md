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
