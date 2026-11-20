import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/preferencias/dominio/preferencias.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// app/api/routes/configuracion_traduccion.py.
class PreferenciasRepositorioRemoto implements PreferenciasRepositorio {
  PreferenciasRepositorioRemoto(this._dio);

  final Dio _dio;
  static const String _ruta = '/configuracion-traduccion';

  @override
  Future<PreferenciasTraduccion?> obtener() async {
    try {
      return _preferencias(await resultadoDe(_dio.get<dynamic>(_ruta)));
    } on ExcepcionApi catch (error) {
      if (error.codigoEstado == 404) return null;
      rethrow;
    }
  }

  @override
  Future<PreferenciasTraduccion> guardar(PreferenciasTraduccion p) async => _preferencias(
        await resultadoDe(
          _dio.post<dynamic>(
            _ruta,
            data: {
              'id_contexto': p.idContexto,
              'id_tono': p.idTono,
              'id_variante_regional': p.idVariante,
              'explicar_expresiones': p.explicarExpresiones,
              'generar_alternativas': p.generarAlternativas,
              'idioma_destino': p.codigoIdiomaDestino,
              'id_glosario': p.idGlosario,
            },
          ),
        ),
      );

  @override
  Future<PreferenciasTraduccion> restablecer() async =>
      _preferencias(await resultadoDe(_dio.delete<dynamic>(_ruta)));

  PreferenciasTraduccion _preferencias(dynamic resultado) {
    final json = resultado as Map<String, dynamic>;
    return PreferenciasTraduccion(
      idContexto: json['id_contexto'] as int?,
      idTono: json['id_tono'] as int?,
      idVariante: json['id_variante_regional'] as int?,
      codigoIdiomaDestino: json['codigo_idioma_destino'] as String?,
      idGlosario: json['id_glosario'] as int?,
      explicarExpresiones: json['explicar_expresiones'] as bool? ?? false,
      generarAlternativas: json['generar_alternativas'] as bool? ?? false,
    );
  }
}

final preferenciasRepositorioProvider = Provider<PreferenciasRepositorio>(
  (ref) => PreferenciasRepositorioRemoto(ref.watch(clienteHttpProvider)),
);
