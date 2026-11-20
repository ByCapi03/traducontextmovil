import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
import 'package:traducontextmovil/funcionalidades/perfil/dominio/perfil.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// app/api/routes/perfil.py. El usuario sale del token.
class PerfilApi implements PerfilRepositorio {
  PerfilApi(this._dio);

  final Dio _dio;

  @override
  Future<void> actualizarNombre(String nombre) =>
      resultadoDe(_dio.patch<dynamic>('/perfil', data: {'nombre': nombre}));

  @override
  Future<Uint8List?> obtenerFoto() async {
    try {
      final respuesta = await _dio.get<List<int>>(
        '/perfil/foto',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = respuesta.data;
      return bytes == null || bytes.isEmpty ? null : Uint8List.fromList(bytes);
    } on DioException catch (error) {
      final excepcion = ExcepcionApi.desdeDio(error);
      if (excepcion.codigoEstado == 404) return null;
      throw excepcion;
    }
  }

  @override
  Future<void> subirFoto({required String nombre, required List<int> bytes}) {
    final tipo = FotoPerfil.tipoMime(nombre) ?? 'image/jpeg';
    final formulario = FormData.fromMap({
      'archivo': MultipartFile.fromBytes(bytes, filename: nombre, contentType: DioMediaType.parse(tipo)),
    });
    return resultadoDe(
      _dio.put<dynamic>('/perfil/foto', data: formulario, options: Options(contentType: 'multipart/form-data')),
    );
  }

  @override
  Future<void> eliminarFoto() => resultadoDe(_dio.delete<dynamic>('/perfil/foto'));
}

final perfilApiProvider = Provider<PerfilRepositorio>((ref) => PerfilApi(ref.watch(clienteHttpProvider)));

/// Foto del usuario actual (null sin foto). `ref.invalidate` tras cambiarla.
final fotoPerfilProvider = FutureProvider<Uint8List?>((ref) {
  final id = ref.watch(usuarioActualProvider.select((usuario) => usuario?.id));
  if (id == null) return null;
  return ref.watch(perfilApiProvider).obtenerFoto();
});
