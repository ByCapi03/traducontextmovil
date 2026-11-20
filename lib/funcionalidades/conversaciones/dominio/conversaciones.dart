/// Estados de una conversación con intérprete.
enum EstadoConversacion {
  activa('activa', 'Activa'),
  pausada('pausada', 'Pausada'),
  finalizada('finalizada', 'Finalizada');

  const EstadoConversacion(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  static EstadoConversacion desdeCodigo(String codigo) =>
      values.firstWhere((estado) => estado.codigo == codigo, orElse: () => finalizada);
}

class Participante {
  const Participante({
    required this.id,
    required this.nombre,
    required this.orden,
    this.codigoIdioma,
    this.nombreIdioma,
  });

  final int id;
  final String nombre;
  final int orden;
  final String? codigoIdioma;
  final String? nombreIdioma;
}

class Conversacion {
  const Conversacion({
    required this.id,
    required this.estado,
    required this.fechaInicio,
    required this.participantes,
    this.nombreIdiomaOrigen,
    this.nombreIdiomaDestino,
    this.nombreEntorno,
    this.nombreContexto,
    this.descripcionContexto,
  });

  final int id;
  final EstadoConversacion estado;
  final DateTime fechaInicio;
  final List<Participante> participantes;
  final String? nombreIdiomaOrigen;
  final String? nombreIdiomaDestino;
  final String? nombreEntorno;
  final String? nombreContexto;
  final String? descripcionContexto;

  String get idiomas => '${nombreIdiomaOrigen ?? '?'} ↔ ${nombreIdiomaDestino ?? '?'}';
}

/// Estados de una intervención (schemas/intervencion.py).
abstract final class EstadoIntervencion {
  static const String procesando = 'procesando';
  static const String traducida = 'traducida';
  static const String error = 'error';
}

class Intervencion {
  const Intervencion({
    required this.id,
    required this.orden,
    required this.textoOriginal,
    required this.estado,
    required this.fecha,
    this.idParticipante,
    this.nombreParticipante,
    this.ordenParticipante,
    this.textoTraducido,
    this.nombreIdiomaOrigen,
    this.nombreIdiomaDestino,
  });

  final int id;
  final int orden;
  final int? idParticipante;
  final String? nombreParticipante;
  final int? ordenParticipante;
  final String textoOriginal;
  final String? textoTraducido;
  final String? nombreIdiomaOrigen;
  final String? nombreIdiomaDestino;
  final String estado;
  final DateTime fecha;

  /// Igual que la web: se puede reintentar si no quedó traducida.
  bool get puedeReintentar => estado != EstadoIntervencion.traducida;
}

class NuevaConversacion {
  const NuevaConversacion({
    required this.idIdiomaOrigen,
    required this.idIdiomaDestino,
    required this.idEntorno,
    this.idContexto,
    this.descripcionContexto,
    this.mantenerContexto = true,
  });

  final int idIdiomaOrigen;
  final int idIdiomaDestino;
  final int idEntorno;
  final int? idContexto;
  final String? descripcionContexto;
  final bool mantenerContexto;
}

/// Lanza `ExcepcionApi` si el backend responde con error.
abstract interface class ConversacionesRepositorio {
  Future<List<Conversacion>> listar();

  Future<Conversacion> iniciar(NuevaConversacion datos);

  Future<Conversacion> obtener(int id);

  Future<List<Intervencion>> intervenciones(int id, {int? despuesDe});

  /// Síncrono: devuelve la intervención ya traducida (o en error).
  /// [idParticipante] null = "No identificado" (el backend detecta el idioma).
  Future<Intervencion> registrar(int id, {required String texto, int? idParticipante});

  Future<Intervencion> reintentar(int id, int idIntervencion);

  Future<Conversacion> pausar(int id);

  Future<Conversacion> reanudar(int id);

  Future<Conversacion> finalizar(int id);
}
