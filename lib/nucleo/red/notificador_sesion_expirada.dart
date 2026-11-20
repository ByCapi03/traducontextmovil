import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Canal desacoplado entre la capa de red y el estado de sesion:
/// el interceptor avisa aqui cuando recibe un 401 y el controlador de sesion
/// escucha, sin que `nucleo/red` dependa de `presentacion`.
class NotificadorSesionExpirada {
  final StreamController<void> _controlador = StreamController<void>.broadcast();

  Stream<void> get eventos => _controlador.stream;

  void notificar() {
    if (!_controlador.isClosed) _controlador.add(null);
  }

  Future<void> cerrar() => _controlador.close();
}

final notificadorSesionExpiradaProvider = Provider<NotificadorSesionExpirada>((ref) {
  final notificador = NotificadorSesionExpirada();
  ref.onDispose(notificador.cerrar);
  return notificador;
});
