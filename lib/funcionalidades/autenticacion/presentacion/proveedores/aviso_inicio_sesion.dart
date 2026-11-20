import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aviso de exito que muestra el login al volver de otro flujo
/// (correo verificado, contrasena restablecida).
class ControladorAvisoInicioSesion extends Notifier<String?> {
  @override
  String? build() => null;

  void mostrar(String aviso) => state = aviso;

  void limpiar() => state = null;
}

final avisoInicioSesionProvider =
    NotifierProvider<ControladorAvisoInicioSesion, String?>(ControladorAvisoInicioSesion.new);
