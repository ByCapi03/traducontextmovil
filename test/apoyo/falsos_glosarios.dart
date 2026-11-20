import 'package:traducontextmovil/funcionalidades/glosarios/dominio/glosarios.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

const _codigos = {1: ('es', 'Español'), 2: ('fr', 'Francés'), 3: ('en', 'Inglés')};

/// Glosarios en memoria con los idiomas de `idiomasPrueba`.
class GlosariosFalsos implements GlosariosRepositorio {
  GlosariosFalsos() {
    _glosarios = [
      _nuevo(1, 'Medicina', 3, 1, [
        const TerminoGlosario(id: 11, terminoOrigen: 'Headache', traduccionPreferida: 'Cefalea'),
      ]),
    ];
  }

  late List<Glosario> _glosarios;
  final List<String> eventos = [];
  int _siguiente = 100;

  /// Se lanza en la próxima escritura.
  ExcepcionApi? errorEscritura;

  List<Glosario> get glosarios => _glosarios;

  Glosario _nuevo(int id, String nombre, int origen, int destino, List<TerminoGlosario> terminos, [String? descripcion]) =>
      Glosario(
        id: id,
        nombre: nombre,
        descripcion: descripcion,
        idIdiomaOrigen: origen,
        idIdiomaDestino: destino,
        codigoIdiomaOrigen: _codigos[origen]!.$1,
        codigoIdiomaDestino: _codigos[destino]!.$1,
        nombreIdiomaOrigen: _codigos[origen]!.$2,
        nombreIdiomaDestino: _codigos[destino]!.$2,
        cantidadTerminos: terminos.length,
        terminos: terminos,
      );

  void _fallarSiToca() {
    final error = errorEscritura;
    errorEscritura = null;
    if (error != null) throw error;
  }

  @override
  Future<List<Glosario>> listar() async => _glosarios;

  @override
  Future<Glosario> obtener(int id) async =>
      _glosarios.firstWhere((g) => g.id == id, orElse: () => throw const ExcepcionApi('no', codigoEstado: 404));

  @override
  Future<Glosario> crear(DatosGlosario datos) async {
    _fallarSiToca();
    eventos.add('crear:${datos.nombre}');
    final glosario = _nuevo(_siguiente++, datos.nombre.trim(), datos.idIdiomaOrigen!, datos.idIdiomaDestino!, const [],
        datos.descripcion);
    _glosarios = [glosario, ..._glosarios];
    return glosario;
  }

  @override
  Future<Glosario> actualizar(int id, DatosGlosario datos) async {
    _fallarSiToca();
    eventos.add('actualizar:$id:${datos.nombre}');
    final anterior = await obtener(id);
    final glosario =
        _nuevo(id, datos.nombre.trim(), datos.idIdiomaOrigen!, datos.idIdiomaDestino!, anterior.terminos, datos.descripcion);
    _glosarios = [for (final g in _glosarios) g.id == id ? glosario : g];
    return glosario;
  }

  @override
  Future<void> eliminar(int id) async {
    _fallarSiToca();
    eventos.add('eliminar:$id');
    _glosarios = [..._glosarios.where((g) => g.id != id)];
  }

  void _cambiarTerminos(int idGlosario, List<TerminoGlosario> Function(List<TerminoGlosario>) cambio) {
    _glosarios = [
      for (final g in _glosarios)
        if (g.id == idGlosario)
          _nuevo(g.id, g.nombre, g.idIdiomaOrigen, g.idIdiomaDestino, cambio(g.terminos), g.descripcion)
        else
          g,
    ];
  }

  TerminoGlosario _termino(int id, DatosTermino datos) => TerminoGlosario(
        id: id,
        terminoOrigen: datos.terminoOrigen.trim(),
        traduccionPreferida: datos.conservarOriginal ? null : datos.traduccionPreferida?.trim(),
        conservarOriginal: datos.conservarOriginal,
        distinguirMayusculas: datos.distinguirMayusculas,
        nota: (datos.nota?.trim().isEmpty ?? true) ? null : datos.nota!.trim(),
      );

  @override
  Future<TerminoGlosario> agregarTermino(int idGlosario, DatosTermino datos) async {
    _fallarSiToca();
    eventos.add('agregarTermino:$idGlosario:${datos.terminoOrigen}');
    final termino = _termino(_siguiente++, datos);
    _cambiarTerminos(idGlosario, (terminos) => [...terminos, termino]);
    return termino;
  }

  @override
  Future<TerminoGlosario> actualizarTermino(int idGlosario, int idTermino, DatosTermino datos) async {
    _fallarSiToca();
    eventos.add('actualizarTermino:$idTermino:${datos.terminoOrigen}');
    final termino = _termino(idTermino, datos);
    _cambiarTerminos(idGlosario, (terminos) => [for (final t in terminos) t.id == idTermino ? termino : t]);
    return termino;
  }

  @override
  Future<void> eliminarTermino(int idGlosario, int idTermino) async {
    _fallarSiToca();
    eventos.add('eliminarTermino:$idTermino');
    _cambiarTerminos(idGlosario, (terminos) => [...terminos.where((t) => t.id != idTermino)]);
  }
}
