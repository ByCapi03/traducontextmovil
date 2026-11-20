import 'package:flutter_test/flutter_test.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/datos/fuentes/traduccion_api.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/datos/repositorios/traduccion_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/dominio/traduccion.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

class _ApiFalsa implements TraduccionApi {
  _ApiFalsa({this.errorObtener});

  final ExcepcionApi? errorObtener;
  int creadas = 0;

  @override
  Future<ConfiguracionTraduccion> obtenerConfiguracion() async {
    final error = errorObtener;
    if (error != null) throw error;
    return const ConfiguracionTraduccion(id: 1);
  }

  @override
  Future<ConfiguracionTraduccion> crearConfiguracionPorDefecto() async {
    creadas++;
    return const ConfiguracionTraduccion(id: 2);
  }

  @override
  Future<ResultadoTraduccion> traducir({
    required String texto,
    required String idiomaDestino,
    String? idiomaOrigen,
  }) =>
      throw UnimplementedError();
}

void main() {
  test('usa la configuración existente sin crear otra', () async {
    final api = _ApiFalsa();
    final configuracion = await TraduccionRepositorioRemoto(api).obtenerOCrearConfiguracion();
    expect(configuracion.id, 1);
    expect(api.creadas, 0);
  });

  test('crea la configuración por defecto solo si no existe (404)', () async {
    final api = _ApiFalsa(errorObtener: const ExcepcionApi('no', codigoEstado: 404));
    final configuracion = await TraduccionRepositorioRemoto(api).obtenerOCrearConfiguracion();
    expect(configuracion.id, 2);
    expect(api.creadas, 1);
  });

  test('otros errores se propagan y no crean nada', () async {
    final api = _ApiFalsa(errorObtener: const ExcepcionApi('caido', codigoEstado: 500));
    await expectLater(
      TraduccionRepositorioRemoto(api).obtenerOCrearConfiguracion(),
      throwsA(isA<ExcepcionApi>()),
    );
    expect(api.creadas, 0);
  });
}
