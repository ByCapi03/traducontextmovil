import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

/// Recuperacion de contrasena (HU-03) de app/api/routes/autenticacion.py.
class RecuperacionApi {
  RecuperacionApi(this._dio);

  final Dio _dio;

  /// 200 siempre (no revela si el correo existe); 502 si falla el envio del correo.
  Future<void> solicitarRecuperacion({required String correo}) =>
      _enviar('/autenticacion/solicitar-recuperacion', {'correo': correo});

  /// 400 si el codigo es invalido o expiro.
  Future<void> validarCodigo({required String correo, required String codigo}) =>
      _enviar('/autenticacion/validar-codigo-recuperacion', {'correo': correo, 'codigo': codigo});

  /// 400 si el codigo es invalido o expiro; 422 si la contrasena no cumple las reglas.
  Future<void> restablecerContrasena({
    required String correo,
    required String codigo,
    required String nuevaContrasena,
  }) =>
      _enviar('/autenticacion/restablecer-contrasena', {
        'correo': correo,
        'codigo': codigo,
        'nueva_contrasena': nuevaContrasena,
      });

  Future<void> _enviar(String ruta, Map<String, String> datos) async {
    try {
      await _dio.post<Map<String, dynamic>>(ruta, data: datos);
    } on DioException catch (error) {
      throw ExcepcionApi.desdeDio(error);
    }
  }
}

final recuperacionApiProvider = Provider<RecuperacionApi>(
  (ref) => RecuperacionApi(ref.watch(clienteHttpProvider)),
);
