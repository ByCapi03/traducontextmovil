/// Mensajería push del dispositivo (FCM + notificaciones locales).
///
/// Separada del servicio que decide qué hacer con los mensajes para poder
/// probar esa lógica sin Firebase. Los datos de un mensaje solo llevan
/// identificadores (`tipo`, `id_notificacion`, `id_chat`...).
abstract interface class MensajeriaPush {
  /// Inicializa Firebase y las notificaciones locales. false si no está
  /// configurado (falta google-services.json o no corresponde a la app).
  Future<bool> iniciar();

  /// Pide permiso para mostrar notificaciones (Android 13+). true si se concede.
  Future<bool> pedirPermiso();

  Future<String?> obtenerToken();

  Stream<String> get tokenRenovado;

  /// Mensajes recibidos con la app en primer plano.
  Stream<MensajePush> get mensajesPrimerPlano;

  /// Toques en una notificación (push del sistema o notificación local).
  Stream<Map<String, String>> get notificacionesTocadas;

  /// Notificación que abrió la app cuando estaba cerrada.
  Future<Map<String, String>?> mensajeInicial();

  /// Muestra una notificación local (en primer plano FCM no la muestra).
  Future<void> mostrar(MensajePush mensaje);
}

class MensajePush {
  const MensajePush({this.titulo, this.cuerpo, this.datos = const {}});

  final String? titulo;
  final String? cuerpo;
  final Map<String, String> datos;
}

/// Registro del token del dispositivo en el backend (POST/DELETE /dispositivos).
abstract interface class DispositivosRepositorio {
  Future<void> registrar(String tokenFcm);

  Future<void> eliminar(String tokenFcm);
}
