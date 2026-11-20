import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/dominio/traduccion.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// app/api/routes/configuracion_traduccion.py y traducciones.py.
class TraduccionApi {
  TraduccionApi(this._dio);

  final Dio _dio;

  /// GET /configuracion-traduccion. 404 si el usuario no tiene configuración.
  Future<ConfiguracionTraduccion> obtenerConfiguracion() async =>
      _configuracion(await resultadoDe(_dio.get<dynamic>('/configuracion-traduccion')));

  /// DELETE /configuracion-traduccion: restablece los valores por defecto y,
  /// si la configuración no existe, la crea (primer contexto general y primer tono).
  Future<ConfiguracionTraduccion> crearConfiguracionPorDefecto() async =>
      _configuracion(await resultadoDe(_dio.delete<dynamic>('/configuracion-traduccion')));

  /// POST /traducciones. El usuario y su configuración salen del token.
  Future<ResultadoTraduccion> traducir({
    required String texto,
    required String idiomaDestino,
    String? idiomaOrigen,
    int? idGlosario,
  }) async {
    final json = await resultadoDe(
      _dio.post<dynamic>(
        '/traducciones',
        data: {
          'texto_origen': texto,
          'idioma_destino': idiomaDestino,
          'idioma_origen': ?idiomaOrigen,
          'id_glosario': ?idGlosario,
        },
      ),
    ) as Map<String, dynamic>;
    return ResultadoTraduccion(
      textoOrigen: json['texto_origen'] as String,
      idiomaOrigen: json['idioma_origen'] as String,
      idiomaDestino: json['idioma_destino'] as String,
      traduccion: json['traduccion'] as String,
      idTraduccion: json['id_traduccion'] as int?,
      confianzaDeteccion: (json['confianza_deteccion'] as num?)?.toDouble(),
      alternativas: [
        for (final alternativa in listaDeMapas(json['alternativas']))
          AlternativaTraduccion(
            traduccion: alternativa['traduccion'] as String,
            explicacion: alternativa['explicacion'] as String?,
          ),
      ],
    );
  }

  ConfiguracionTraduccion _configuracion(dynamic resultado) {
    final json = resultado as Map<String, dynamic>;
    return ConfiguracionTraduccion(
      id: json['id_configuracion_traduccion'] as int,
      nombreContexto: json['nombre_contexto'] as String?,
      nombreTono: json['nombre_tono'] as String?,
      codigoIdiomaDestino: json['codigo_idioma_destino'] as String?,
    );
  }
}

final traduccionApiProvider = Provider<TraduccionApi>(
  (ref) => TraduccionApi(ref.watch(clienteHttpProvider)),
);
