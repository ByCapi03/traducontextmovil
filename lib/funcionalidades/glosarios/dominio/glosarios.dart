/// Glosario del usuario (GET /glosarios): términos con una traducción fija
/// para un par de idiomas (HU-32).
class Glosario {
  const Glosario({
    required this.id,
    required this.nombre,
    required this.idIdiomaOrigen,
    required this.idIdiomaDestino,
    this.descripcion,
    this.codigoIdiomaOrigen,
    this.codigoIdiomaDestino,
    this.nombreIdiomaOrigen,
    this.nombreIdiomaDestino,
    this.cantidadTerminos = 0,
    this.terminos = const [],
  });

  final int id;
  final String nombre;
  final String? descripcion;
  final int idIdiomaOrigen;
  final int idIdiomaDestino;
  final String? codigoIdiomaOrigen;
  final String? codigoIdiomaDestino;
  final String? nombreIdiomaOrigen;
  final String? nombreIdiomaDestino;
  final int cantidadTerminos;

  /// Solo en el detalle (GET /glosarios/{id}).
  final List<TerminoGlosario> terminos;

  /// 'EN → ES', como `par_idiomas` del backend.
  String get parIdiomas => '${(codigoIdiomaOrigen ?? '?').toUpperCase()} → ${(codigoIdiomaDestino ?? '?').toUpperCase()}';

  /// Sirve para traducir de [origen] a [destino] (códigos). Sin [origen]
  /// (detección automática) basta con que coincida el destino, como en la web.
  bool aplicaA({String? origen, required String? destino}) {
    final d = (destino ?? '').toLowerCase();
    if (d.isEmpty || (codigoIdiomaDestino ?? '').toLowerCase() != d) return false;
    final o = (origen ?? '').toLowerCase();
    return o.isEmpty || (codigoIdiomaOrigen ?? '').toLowerCase() == o;
  }
}

class TerminoGlosario {
  const TerminoGlosario({
    required this.id,
    required this.terminoOrigen,
    this.traduccionPreferida,
    this.conservarOriginal = false,
    this.distinguirMayusculas = false,
    this.nota,
  });

  final int id;
  final String terminoOrigen;
  final String? traduccionPreferida;
  final bool conservarOriginal;
  final bool distinguirMayusculas;
  final String? nota;
}

/// Datos de un glosario a crear o editar.
class DatosGlosario {
  const DatosGlosario({
    required this.nombre,
    required this.idIdiomaOrigen,
    required this.idIdiomaDestino,
    this.descripcion,
  });

  final String nombre;
  final String? descripcion;
  final int? idIdiomaOrigen;
  final int? idIdiomaDestino;
}

/// Datos de un término a crear o editar.
class DatosTermino {
  const DatosTermino({
    required this.terminoOrigen,
    this.traduccionPreferida,
    this.conservarOriginal = false,
    this.distinguirMayusculas = false,
    this.nota,
  });

  final String terminoOrigen;
  final String? traduccionPreferida;
  final bool conservarOriginal;
  final bool distinguirMayusculas;
  final String? nota;
}

/// Validaciones de `glosarios.ts` de la web (y del backend). Devuelven el
/// mensaje de error o null.
abstract final class ValidacionGlosarios {
  static const int longitudNombre = 100;
  static const int longitudTermino = 255;

  /// [otros] son los demás glosarios del usuario (el backend rechaza el
  /// nombre repetido sin distinguir mayúsculas).
  static String? glosario(DatosGlosario datos, {required Iterable<Glosario> otros}) {
    final nombre = datos.nombre.trim();
    if (nombre.isEmpty) return 'El nombre del glosario es obligatorio.';
    if (nombre.length > longitudNombre) return 'El nombre admite hasta $longitudNombre caracteres.';
    if (datos.idIdiomaOrigen == null || datos.idIdiomaDestino == null) {
      return 'Selecciona el idioma de origen y el de destino.';
    }
    if (datos.idIdiomaOrigen == datos.idIdiomaDestino) {
      return 'El idioma de origen y el de destino deben ser distintos.';
    }
    if (otros.any((g) => g.nombre.trim().toLowerCase() == nombre.toLowerCase())) {
      return 'Ya tienes un glosario con ese nombre.';
    }
    return null;
  }

  /// [existentes] son los términos del glosario; [idEditado] el que se edita.
  static String? termino(DatosTermino datos, {required Iterable<TerminoGlosario> existentes, int? idEditado}) {
    final origen = datos.terminoOrigen.trim();
    if (origen.isEmpty) return 'El término de origen es obligatorio.';
    if (origen.length > longitudTermino) return 'El término admite hasta $longitudTermino caracteres.';
    final traduccion = datos.traduccionPreferida?.trim() ?? '';
    if (!datos.conservarOriginal && traduccion.isEmpty) {
      return 'Indica la traducción preferida o marca el término para conservarlo.';
    }
    if (traduccion.length > longitudTermino) return 'La traducción admite hasta $longitudTermino caracteres.';
    final repetido = existentes.any(
      (t) => t.terminoOrigen.toLowerCase() == origen.toLowerCase() && t.id != idEditado,
    );
    if (repetido) return 'Ese término ya existe en el glosario.';
    return null;
  }
}

/// Lanza `ExcepcionApi` si el backend responde con error.
abstract interface class GlosariosRepositorio {
  Future<List<Glosario>> listar();

  Future<Glosario> obtener(int id);

  Future<Glosario> crear(DatosGlosario datos);

  Future<Glosario> actualizar(int id, DatosGlosario datos);

  Future<void> eliminar(int id);

  Future<TerminoGlosario> agregarTermino(int idGlosario, DatosTermino datos);

  Future<TerminoGlosario> actualizarTermino(int idGlosario, int idTermino, DatosTermino datos);

  Future<void> eliminarTermino(int idGlosario, int idTermino);
}
