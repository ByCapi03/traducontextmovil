import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/notificacion.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/push.dart';

/// Claves del push acordadas con el backend (docs/contrato_notificaciones.md).
abstract final class ClavesPush {
  static const String tipo = 'tipo';
  static const String idChat = 'id_chat';
  static const String idTraduccionDocumento = 'id_traduccion_documento';
  static const String idNotificacion = 'id_notificacion';

  /// Canal Android de los avisos tipo mensajería (importancia alta, sonido y
  /// vibración). El backend lo envía en `android.notification.channel_id`.
  static const String canalMensajes = 'traducontext_mensajes';

  /// Canal anterior (importancia por defecto); se borra al iniciar.
  static const String canalAnterior = 'traducontext_general';
}

/// Una línea de una conversación en la notificación agrupada.
class LineaNotificacion {
  const LineaNotificacion({required this.remitente, required this.texto, required this.fecha});

  final String remitente;
  final String texto;
  final DateTime fecha;
}

/// Notificación local lista para mostrar.
class NotificacionLocal {
  const NotificacionLocal({
    required this.id,
    required this.datos,
    this.titulo,
    this.cuerpo,
    this.grupo,
    this.lineas = const [],
  });

  /// Fijo por chat: un mensaje nuevo actualiza la notificación de su chat.
  final int id;
  final String? titulo;
  final String? cuerpo;
  final Map<String, String> datos;

  /// Clave de agrupación de Android (una por chat).
  final String? grupo;

  /// Mensajes acumulados del chat, del más antiguo al más reciente.
  final List<LineaNotificacion> lineas;
}

/// Decide qué notificación local mostrar con la app abierta: agrupa por
/// `id_chat` (estilo mensajería, últimos [maximoLineas] mensajes) y no
/// muestra nada si el chat que llega es el que está en pantalla.
class AgrupadorNotificaciones {
  AgrupadorNotificaciones({DateTime Function()? reloj}) : _reloj = reloj ?? DateTime.now;

  static const int maximoLineas = 6;
  static const int _baseChats = 1000000;

  final DateTime Function() _reloj;
  final Map<int, List<LineaNotificacion>> _lineasPorChat = {};
  int _siguienteId = 1;
  int? _chatEnPantalla;

  int? get chatEnPantalla => _chatEnPantalla;

  static int? idChatDe(Map<String, String> datos) =>
      datos[ClavesPush.tipo] == TiposNotificacion.mensajeChat ? int.tryParse(datos[ClavesPush.idChat] ?? '') : null;

  /// Id de la notificación local de un chat.
  static int idNotificacionChat(int idChat) => _baseChats + idChat;

  /// El chat abierto deja de acumular y su notificación se puede quitar.
  void abrirChat(int idChat) {
    _chatEnPantalla = idChat;
    _lineasPorChat.remove(idChat);
  }

  void cerrarChat(int idChat) {
    if (_chatEnPantalla == idChat) _chatEnPantalla = null;
  }

  /// null: no se muestra (sin texto o es el chat en pantalla).
  NotificacionLocal? preparar(MensajePush mensaje) {
    if (mensaje.titulo == null && mensaje.cuerpo == null) return null;
    final idChat = idChatDe(mensaje.datos);
    if (idChat == null) {
      final id = _siguienteId;
      _siguienteId = _siguienteId % (_baseChats - 1) + 1;
      return NotificacionLocal(id: id, titulo: mensaje.titulo, cuerpo: mensaje.cuerpo, datos: mensaje.datos);
    }
    if (idChat == _chatEnPantalla) return null;
    final lineas = [
      ...?_lineasPorChat[idChat],
      LineaNotificacion(
        remitente: mensaje.titulo ?? 'Mensaje nuevo',
        texto: mensaje.cuerpo ?? '',
        fecha: _reloj(),
      ),
    ];
    final recientes = lineas.length > maximoLineas ? lineas.sublist(lineas.length - maximoLineas) : lineas;
    _lineasPorChat[idChat] = recientes;
    return NotificacionLocal(
      id: idNotificacionChat(idChat),
      titulo: mensaje.titulo,
      cuerpo: recientes.length == 1 ? mensaje.cuerpo : '${recientes.length} mensajes nuevos',
      datos: mensaje.datos,
      grupo: 'traducontext.chat.$idChat',
      lineas: recientes,
    );
  }
}
