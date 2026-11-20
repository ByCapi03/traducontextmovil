import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// app/api/routes/perfil.py. El usuario sale del token.
class PerfilApi {
  PerfilApi(this._dio);

  final Dio _dio;

  /// PATCH /perfil. El correo no es editable.
  Future<void> actualizarNombre(String nombre) =>
      resultadoDe(_dio.patch<dynamic>('/perfil', data: {'nombre': nombre}));
}

final perfilApiProvider = Provider<PerfilApi>((ref) => PerfilApi(ref.watch(clienteHttpProvider)));
