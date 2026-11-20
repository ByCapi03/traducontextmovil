import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/datos/fuentes/traduccion_api.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/dominio/traduccion.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/dominio/traduccion_repositorio.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

class TraduccionRepositorioRemoto implements TraduccionRepositorio {
  TraduccionRepositorioRemoto(this._api);

  final TraduccionApi _api;

  @override
  Future<ConfiguracionTraduccion> obtenerOCrearConfiguracion() async {
    try {
      return await _api.obtenerConfiguracion();
    } on ExcepcionApi catch (error) {
      // Solo se crea si de verdad no existe; cualquier otro error se propaga.
      if (error.codigoEstado != 404) rethrow;
      return _api.crearConfiguracionPorDefecto();
    }
  }

  @override
  Future<ResultadoTraduccion> traducir({
    required String texto,
    required String idiomaDestino,
    String? idiomaOrigen,
  }) =>
      _api.traducir(texto: texto.trim(), idiomaDestino: idiomaDestino, idiomaOrigen: idiomaOrigen);
}

final traduccionRepositorioProvider = Provider<TraduccionRepositorio>(
  (ref) => TraduccionRepositorioRemoto(ref.watch(traduccionApiProvider)),
);

/// Configuración asegurada antes de traducir (una vez por sesión de la app).
/// Depende del id del usuario: si cambia la cuenta, se vuelve a consultar.
final configuracionTraduccionProvider = FutureProvider<ConfiguracionTraduccion>((ref) {
  ref.watch(usuarioActualProvider.select((usuario) => usuario?.id));
  return ref.watch(traduccionRepositorioProvider).obtenerOCrearConfiguracion();
});
