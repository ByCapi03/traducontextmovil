import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

/// Endpoints de app/api/routes/autenticacion.py.
class AutenticacionApi {
  AutenticacionApi(this._dio);

  final Dio _dio;

  /// POST /autenticacion/iniciar-sesion -> { resultado: [ { token } ] }
  Future<String> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final respuesta = await _dio.post<Map<String, dynamic>>(
        '/autenticacion/iniciar-sesion',
        data: {'correo': correo, 'contrasena': contrasena},
      );
      final resultado = respuesta.data?['resultado'];
      if (resultado is List && resultado.isNotEmpty) {
        final primero = resultado.first;
        if (primero is Map && primero['token'] is String) {
          return primero['token'] as String;
        }
      }
      throw const ExcepcionApi('Respuesta inesperada del servidor al iniciar sesión.');
    } on DioException catch (error) {
      throw ExcepcionApi.desdeDio(error);
    }
  }

  /// POST /autenticacion/cerrar-sesion (el Bearer lo pone el interceptor).
  Future<void> cerrarSesion() async {
    try {
      await _dio.post<void>('/autenticacion/cerrar-sesion');
    } on DioException catch (error) {
      throw ExcepcionApi.desdeDio(error);
    }
  }
}

final autenticacionApiProvider = Provider<AutenticacionApi>(
  (ref) => AutenticacionApi(ref.watch(clienteHttpProvider)),
);
