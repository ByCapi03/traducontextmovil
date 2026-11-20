import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/datos/glosarios_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/dominio/glosarios.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

/// Resultado de una acción: [error] null si salió bien.
typedef ResultadoAccion<T> = ({T? valor, String? error});

/// Crear, editar y eliminar glosarios y términos. Valida como la web antes
/// de llamar al backend y refresca los providers al terminar.
class AccionesGlosarios {
  AccionesGlosarios(this._ref);

  final Ref _ref;

  GlosariosRepositorio get _repositorio => _ref.read(glosariosRepositorioProvider);

  Future<ResultadoAccion<Glosario>> guardarGlosario(DatosGlosario datos, {Glosario? editado}) async {
    final todos = await _ref.read(glosariosProvider.future).catchError((Object _) => <Glosario>[]);
    final error = ValidacionGlosarios.glosario(
      datos,
      otros: todos.where((g) => g.id != editado?.id),
    );
    if (error != null) return (valor: null, error: error);
    return _ejecutar(
      () => editado == null ? _repositorio.crear(datos) : _repositorio.actualizar(editado.id, datos),
      idGlosario: editado?.id,
      porCodigo: {400: 'No se pudo guardar: revisa que el nombre no esté repetido y que los idiomas sean distintos.'},
    );
  }

  Future<String?> eliminarGlosario(Glosario glosario) async =>
      (await _ejecutar(() => _repositorio.eliminar(glosario.id))).error;

  Future<String?> guardarTermino(Glosario glosario, DatosTermino datos, {TerminoGlosario? editado}) async {
    final error = ValidacionGlosarios.termino(datos, existentes: glosario.terminos, idEditado: editado?.id);
    if (error != null) return error;
    return (await _ejecutar(
      () => editado == null
          ? _repositorio.agregarTermino(glosario.id, datos)
          : _repositorio.actualizarTermino(glosario.id, editado.id, datos),
      idGlosario: glosario.id,
      porCodigo: {400: 'No se pudo guardar el término: puede que ya exista en el glosario.'},
    ))
        .error;
  }

  Future<String?> eliminarTermino(Glosario glosario, TerminoGlosario termino) async =>
      (await _ejecutar(() => _repositorio.eliminarTermino(glosario.id, termino.id), idGlosario: glosario.id)).error;

  Future<ResultadoAccion<T>> _ejecutar<T>(
    Future<T> Function() accion, {
    int? idGlosario,
    Map<int, String> porCodigo = const {},
  }) async {
    try {
      final valor = await accion();
      _ref.invalidate(glosariosProvider);
      if (idGlosario != null) _ref.invalidate(glosarioProvider(idGlosario));
      return (valor: valor, error: null);
    } on ExcepcionApi catch (error) {
      return (valor: null, error: MensajesError.de(error, porCodigo: porCodigo));
    }
  }
}

final accionesGlosariosProvider = Provider<AccionesGlosarios>(AccionesGlosarios.new);
