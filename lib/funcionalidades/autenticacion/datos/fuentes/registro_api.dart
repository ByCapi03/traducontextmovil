import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

/// Endpoints publicos de registro y verificacion de app/api/routes/usuarios.py.
class RegistroApi {
  RegistroApi(this._dio);

  final Dio _dio;

  /// POST /usuarios/registrar -> 201. 409 si el correo ya existe.
  Future<void> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) =>
      _enviar('/usuarios/registrar', {
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
      });

  /// POST /usuarios/verificar-codigo -> 200. 400 codigo invalido/expirado o ya activo; 403 suspendido.
  Future<void> verificarCodigo({required String correo, required String codigo}) =>
      _enviar('/usuarios/verificar-codigo', {'correo': correo, 'codigo': codigo});

  /// POST /usuarios/reenviar-codigo -> 200. 400 ya activo; 403 suspendido; 404 no existe.
  Future<void> reenviarCodigo({required String correo}) =>
      _enviar('/usuarios/reenviar-codigo', {'correo': correo});

  Future<void> _enviar(String ruta, Map<String, String> datos) async {
    try {
      await _dio.post<Map<String, dynamic>>(ruta, data: datos);
    } on DioException catch (error) {
      throw ExcepcionApi.desdeDio(error);
    }
  }
}

final registroApiProvider = Provider<RegistroApi>(
  (ref) => RegistroApi(ref.watch(clienteHttpProvider)),
);
