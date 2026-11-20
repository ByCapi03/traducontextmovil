import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../almacenamiento/almacenamiento_seguro.dart';
import '../configuracion/configuracion_api.dart';
import 'interceptor_autenticacion.dart';
import 'notificador_sesion_expirada.dart';

final clienteHttpProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ConfiguracionApi.urlBase,
      connectTimeout: ConfiguracionApi.tiempoConexion,
      receiveTimeout: ConfiguracionApi.tiempoRespuesta,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorAutenticacion(
      almacenamiento: ref.watch(almacenamientoSeguroProvider),
      notificador: ref.watch(notificadorSesionExpiradaProvider),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});
