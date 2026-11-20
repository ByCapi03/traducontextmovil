import 'package:dio/dio.dart';

import 'package:traducontextmovil/nucleo/almacenamiento/almacenamiento_seguro.dart';
import 'package:traducontextmovil/nucleo/red/notificador_sesion_expirada.dart';

/// Anade `Authorization: Bearer <token>` y, ante un 401, borra el token y
/// avisa para volver a /login (equivalente al autenticacion.interceptor del web).
class InterceptorAutenticacion extends Interceptor {
  InterceptorAutenticacion({
    required AlmacenamientoSeguro almacenamiento,
    required NotificadorSesionExpirada notificador,
  })  : _almacenamiento = almacenamiento,
        _notificador = notificador;

  final AlmacenamientoSeguro _almacenamiento;
  final NotificadorSesionExpirada _notificador;

  /// En estas rutas un 401 significa "credenciales invalidas" o "sesion ya
  /// cerrada", no "sesion expirada", asi que no se fuerza la redireccion.
  static const List<String> _rutasSinRedireccion = [
    '/autenticacion/iniciar-sesion',
    '/autenticacion/cerrar-sesion',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _almacenamiento.leerToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final ruta = err.requestOptions.path;
    final esRutaExcluida = _rutasSinRedireccion.any(ruta.endsWith);
    if (err.response?.statusCode == 401 && !esRutaExcluida) {
      await _almacenamiento.eliminarToken();
      _notificador.notificar();
    }
    handler.next(err);
  }
}
