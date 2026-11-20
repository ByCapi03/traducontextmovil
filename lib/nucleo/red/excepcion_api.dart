import 'package:dio/dio.dart';

/// Error normalizado del backend. El backend responde siempre
/// `{ "mensaje": "...", "resultado": ... }`, tambien en los errores (app/main.py).
class ExcepcionApi implements Exception {
  const ExcepcionApi(this.mensaje, {this.codigoEstado});

  final String mensaje;
  final int? codigoEstado;

  factory ExcepcionApi.desdeDio(DioException error) {
    final respuesta = error.response;
    if (respuesta == null) {
      return const ExcepcionApi(
        'No se pudo conectar con el servidor. Verifica tu conexion.',
      );
    }
    final datos = respuesta.data;
    final mensaje = (datos is Map && datos['mensaje'] is String)
        ? datos['mensaje'] as String
        : 'Ocurrio un error inesperado (${respuesta.statusCode}).';
    return ExcepcionApi(mensaje, codigoEstado: respuesta.statusCode);
  }

  bool get esNoAutorizado => codigoEstado == 401;

  @override
  String toString() => mensaje;
}
