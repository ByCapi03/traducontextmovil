import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

/// Textos propios (con tildes) para errores del backend fuera de la
/// autenticacion. Nunca se muestra el `detail` del backend: llega sin tildes.
abstract final class MensajesError {
  static const String sinConexion = 'No se pudo conectar con el servidor. Verifica tu conexión.';
  static const String generico = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  static const String sinPermiso = 'No tienes permiso para realizar esta acción.';
  static const String noEncontrado = 'No se encontró lo que buscabas. Puede que ya no exista.';
  static const String demasiadasSolicitudes =
      'Has hecho demasiadas solicitudes. Espera un momento y vuelve a intentarlo.';
  static const String servidor = 'El servidor tuvo un problema. Inténtalo más tarde.';
  static const String datosInvalidos = 'Revisa los datos ingresados.';

  /// [porCodigo] permite textos específicos de cada pantalla.
  static String de(Object error, {Map<int, String> porCodigo = const {}, String? porDefecto}) {
    if (error is! ExcepcionApi) return generico;
    if (error.sinConexion) return sinConexion;
    final codigo = error.codigoEstado;
    final especifico = porCodigo[codigo];
    if (especifico != null) return especifico;
    return switch (codigo) {
      403 => sinPermiso,
      404 => noEncontrado,
      422 => datosInvalidos,
      429 => demasiadasSolicitudes,
      final int c when c >= 500 => servidor,
      _ => porDefecto ?? generico,
    };
  }
}
