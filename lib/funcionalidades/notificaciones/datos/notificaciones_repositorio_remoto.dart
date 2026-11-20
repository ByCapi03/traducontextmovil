import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/notificacion.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// app/api/routes/notificaciones.py. El usuario sale del token.
class NotificacionesRepositorioRemoto implements NotificacionesRepositorio {
  NotificacionesRepositorioRemoto(this._dio);

  final Dio _dio;
  static const int tamanoPagina = 20;

  @override
  Future<PaginaNotificaciones> listar({int pagina = 1}) async {
    final json = await resultadoDe(
      _dio.get<dynamic>(
        '/notificaciones',
        queryParameters: {'pagina': pagina, 'tamano_pagina': tamanoPagina},
      ),
    ) as Map<String, dynamic>;
    return PaginaNotificaciones(
      elementos: [for (final elemento in listaDeMapas(json['elementos'])) _notificacion(elemento)],
      noLeidas: json['no_leidas'] as int? ?? 0,
      pagina: json['pagina'] as int? ?? pagina,
      totalPaginas: json['total_paginas'] as int? ?? 0,
    );
  }

  @override
  Future<void> marcarLeida(int id) =>
      resultadoDe(_dio.patch<dynamic>('/notificaciones/$id/leida'));

  @override
  Future<void> marcarTodasLeidas() => resultadoDe(_dio.patch<dynamic>('/notificaciones/leidas'));

  Notificacion _notificacion(Map<String, dynamic> json) => Notificacion(
        id: json['id_notificacion'] as int,
        tipo: json['tipo'] as String,
        titulo: json['titulo'] as String,
        cuerpo: json['cuerpo'] as String,
        leida: json['leida'] as bool? ?? false,
        fecha: fechaDe(json['fecha_creacion']) ?? DateTime.now(),
        datos: {
          for (final MapEntry(:key, :value)
              in ((json['datos'] as Map<String, dynamic>?) ?? const {}).entries)
            if (value != null) key: '$value',
        },
      );
}

final notificacionesRepositorioProvider = Provider<NotificacionesRepositorio>(
  (ref) => NotificacionesRepositorioRemoto(ref.watch(clienteHttpProvider)),
);
