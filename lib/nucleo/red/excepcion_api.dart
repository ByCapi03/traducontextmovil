import 'package:dio/dio.dart';

/// Error normalizado del backend. El backend responde siempre
/// `{ "mensaje": "...", "resultado": ... }`, tambien en los errores (app/main.py).
class ExcepcionApi implements Exception {
  const ExcepcionApi(this.mensaje, {this.codigoEstado, this.sinConexion = false});

  final String mensaje;
  final int? codigoEstado;

  /// No hubo respuesta del servidor (sin red, servidor caído o tiempo agotado).
  final bool sinConexion;

  factory ExcepcionApi.desdeDio(DioException error) {
    final respuesta = error.response;
    if (respuesta == null) {
      return const ExcepcionApi(
        'No se pudo conectar con el servidor. Verifica tu conexión.',
        sinConexion: true,
      );
    }
    final datos = respuesta.data;
    final mensaje = (datos is Map && datos['mensaje'] is String)
        ? datos['mensaje'] as String
        : 'Ocurrió un error inesperado (${respuesta.statusCode}).';
    return ExcepcionApi(mensaje, codigoEstado: respuesta.statusCode);
  }

  bool get esNoAutorizado => codigoEstado == 401;

  @override
  String toString() => mensaje;
}
