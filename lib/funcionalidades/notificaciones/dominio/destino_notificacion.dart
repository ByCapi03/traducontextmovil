import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/notificacion.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';

/// Pantalla a la que lleva una notificación (al tocarla en la bandeja o en el
/// push). Se usa el mismo mapa en ambos sitios.
///
/// Claves de `datos` esperadas (solo identificadores): `id_chat` para
/// MENSAJE_CHAT y `id_traduccion_documento` para DOCUMENTO_*. Hoy el backend
/// aún no genera notificaciones (ver docs/pendientes_backend.md).
String? rutaParaNotificacion(String tipo, Map<String, String> datos) => switch (tipo) {
      TiposNotificacion.documentoListo || TiposNotificacion.documentoError => Rutas.documentos,
      TiposNotificacion.mensajeChat => switch (int.tryParse(datos['id_chat'] ?? '')) {
          final int idChat => Rutas.chat(idChat),
          null => Rutas.chats,
        },
      _ => null,
    };
