import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reloj inyectable para poder probar la espera sin esperar de verdad.
final relojProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Momento del ultimo envio de codigo por clave (tipo de codigo + correo).
///
/// Vive mientras la app esta abierta (provider sin autoDispose), asi que la
/// espera sobrevive a salir y volver a la pantalla. No se persiste.
class ControladorEsperaReenvio extends Notifier<Map<String, DateTime>> {
  static const Duration espera = Duration(seconds: 60);

  @override
  Map<String, DateTime> build() => const {};

  static String claveVerificacion(String correo) => 'verificacion:$correo';
  static String claveRecuperacion(String correo) => 'recuperacion:$correo';

  void registrarEnvio(String clave) {
    state = {...state, clave: ref.read(relojProvider)()};
  }

  /// Segundos que faltan para poder reenviar (0 si ya se puede).
  int segundosRestantes(String clave) {
    final ultimo = state[clave];
    if (ultimo == null) return 0;
    final restante = espera - ref.read(relojProvider)().difference(ultimo);
    if (restante <= Duration.zero) return 0;
    return (restante.inMilliseconds / 1000).ceil();
  }
}

final esperaReenvioProvider =
    NotifierProvider<ControladorEsperaReenvio, Map<String, DateTime>>(ControladorEsperaReenvio.new);
