/// Otro participante de un chat (solo id y nombre: sin correo ni foto).
class UsuarioChat {
  const UsuarioChat({required this.id, required this.nombre});

  final int id;
  final String nombre;
}

/// Estados de lectura de un mensaje según el backend (schemas/chat.py).
abstract final class EstadoLectura {
  static const String propio = 'propio';
  static const String pendiente = 'pendiente';
  static const String traducido = 'traducido';
  static const String sinTraduccion = 'sin_traduccion';
  static const String error = 'error';
}

class MensajeChat {
  const MensajeChat({
    required this.id,
    required this.esMio,
    required this.texto,
    required this.textoOriginal,
    required this.estadoLectura,
    required this.fecha,
    this.idiomaOriginal,
    this.idiomaTexto,
  });

  final int id;
  final bool esMio;

  /// Texto en mi idioma de lectura (o el original si no hizo falta traducir).
  final String texto;
  final String textoOriginal;
  final String? idiomaOriginal;
  final String? idiomaTexto;
  final String estadoLectura;
  final DateTime fecha;

  bool get pendiente => estadoLectura == EstadoLectura.pendiente;

  /// Se muestran ambos textos solo si son distintos (hubo traducción).
  bool get tieneTraduccion =>
      !esMio && estadoLectura == EstadoLectura.traducido && texto != textoOriginal;
}

class Chat {
  const Chat({
    required this.id,
    required this.otroUsuario,
    required this.codigoIdiomaLectura,
    required this.nombreIdiomaLectura,
    required this.noLeidos,
    required this.fechaCreacion,
    this.ultimoMensaje,
    this.fechaUltimoMensaje,
  });

  final int id;
  final UsuarioChat otroUsuario;
  final String codigoIdiomaLectura;
  final String nombreIdiomaLectura;
  final MensajeChat? ultimoMensaje;
  final int noLeidos;
  final DateTime fechaCreacion;
  final DateTime? fechaUltimoMensaje;
}

class PaginaMensajes {
  const PaginaMensajes({required this.elementos, required this.hayMas});

  /// Del más antiguo al más reciente.
  final List<MensajeChat> elementos;
  final bool hayMas;
}

/// Lanza `ExcepcionApi` si el backend responde con error.
abstract interface class ChatsRepositorio {
  Future<List<Chat>> listar();

  /// Mínimo 2 caracteres (lo exige el backend).
  Future<List<UsuarioChat>> buscarUsuarios(String texto);

  /// Idempotente: si ya existe un chat con ese usuario, lo devuelve.
  Future<Chat> crearOObtener(int idUsuario);

  Future<Chat> obtener(int idChat);

  Future<Chat> cambiarIdiomaLectura(int idChat, String codigoIdioma);

  /// [despuesDe]: mensajes con id mayor (para el refresco); [antesDe]: anteriores.
  Future<PaginaMensajes> mensajes(int idChat, {int? despuesDe, int? antesDe});

  Future<MensajeChat> enviar(int idChat, String texto);

  Future<void> marcarLeido(int idChat, int idMensaje);
}
