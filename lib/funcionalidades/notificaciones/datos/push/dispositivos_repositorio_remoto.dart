import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/push.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// app/api/routes/dispositivos.py. El usuario sale del token de sesión.
class DispositivosRepositorioRemoto implements DispositivosRepositorio {
  DispositivosRepositorioRemoto(this._dio);

  final Dio _dio;

  /// La app móvil solo se publica para Android por ahora.
  static const String plataforma = 'android';

  /// POST /dispositivos: idempotente; si el token era de otra cuenta, pasa a esta.
  @override
  Future<void> registrar(String tokenFcm) => resultadoDe(
        _dio.post<dynamic>(
          '/dispositivos',
          data: {'token_fcm': tokenFcm, 'plataforma': plataforma},
        ),
      );

  /// DELETE /dispositivos/{token_fcm}: antes de cerrar sesión.
  @override
  Future<void> eliminar(String tokenFcm) =>
      resultadoDe(_dio.delete<dynamic>('/dispositivos/${Uri.encodeComponent(tokenFcm)}'));
}

final dispositivosRepositorioProvider = Provider<DispositivosRepositorio>(
  (ref) => DispositivosRepositorioRemoto(ref.watch(clienteHttpProvider)),
);
