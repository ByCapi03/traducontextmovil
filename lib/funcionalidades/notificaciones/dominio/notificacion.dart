/// Tipos que define el backend (app/models/notificacion/notificacion.py).
abstract final class TiposNotificacion {
  static const String documentoListo = 'DOCUMENTO_LISTO';
  static const String documentoError = 'DOCUMENTO_ERROR';
  static const String sistema = 'SISTEMA';
  static const String mensajeChat = 'MENSAJE_CHAT';
}

/// Notificación de la bandeja. `datos` solo lleva identificadores, nunca contenido.
class Notificacion {
  const Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.cuerpo,
    required this.leida,
    required this.fecha,
    this.datos = const {},
  });

  final int id;
  final String tipo;
  final String titulo;
  final String cuerpo;
  final bool leida;
  final DateTime fecha;
  final Map<String, String> datos;

  Notificacion marcadaLeida() => Notificacion(
        id: id,
        tipo: tipo,
        titulo: titulo,
        cuerpo: cuerpo,
        leida: true,
        fecha: fecha,
        datos: datos,
      );
}

class PaginaNotificaciones {
  const PaginaNotificaciones({
    required this.elementos,
    required this.noLeidas,
    required this.pagina,
    required this.totalPaginas,
  });

  final List<Notificacion> elementos;
  final int noLeidas;
  final int pagina;
  final int totalPaginas;

  bool get hayMas => pagina < totalPaginas;
}

/// Lanza `ExcepcionApi` si el backend responde con error.
abstract interface class NotificacionesRepositorio {
  Future<PaginaNotificaciones> listar({int pagina = 1});

  Future<void> marcarLeida(int id);

  Future<void> marcarTodasLeidas();
}
