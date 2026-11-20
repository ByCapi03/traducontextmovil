import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/red/cliente_http.dart';
import '../../nucleo/red/excepcion_api.dart';
import '../modelos/usuario_actual.dart';

/// Endpoints de app/api/routes/usuarios.py usados en M0.
class UsuariosApi {
  UsuariosApi(this._dio);

  final Dio _dio;

  /// GET /usuarios/me -> { resultado: UsuarioPerfilDetalle }
  Future<UsuarioActual> obtenerMiPerfil() async {
    try {
      final respuesta = await _dio.get<Map<String, dynamic>>('/usuarios/me');
      final resultado = respuesta.data?['resultado'];
      if (resultado is Map<String, dynamic>) {
        return UsuarioActual.desdeJson(resultado);
      }
      throw const ExcepcionApi('Respuesta inesperada del servidor al obtener el perfil.');
    } on DioException catch (error) {
      throw ExcepcionApi.desdeDio(error);
    }
  }
}

final usuariosApiProvider = Provider<UsuariosApi>(
  (ref) => UsuariosApi(ref.watch(clienteHttpProvider)),
);
