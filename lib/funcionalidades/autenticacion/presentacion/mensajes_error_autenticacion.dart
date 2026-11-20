import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

/// Operaciones de autenticacion cuyos errores se traducen a textos propios.
enum OperacionAutenticacion {
  inicioSesion,
  registro,
  verificacionCorreo,
  reenvioCodigo,
  solicitudRecuperacion,
  validacionCodigoRecuperacion,
  restablecimientoContrasena,
}

/// Textos propios (con tildes) por operacion y codigo HTTP.
///
/// Se decide solo por codigo HTTP, nunca por el texto `detail` del backend
/// (que llega sin tildes y puede cambiar). Codigos reales del backend:
/// - iniciar-sesion: 401 credenciales; 403 cuenta suspendida o sin verificar
///   (mismo codigo para ambos casos); 422 formato.
/// - registrar: 409 correo existente; 500 rol o SMTP sin configurar; 502 envio fallido; 422.
/// - verificar-codigo: 400 codigo invalido, expirado o cuenta ya activa; 403 suspendida; 422.
/// - reenviar-codigo: 400 ya activa; 403 suspendida; 404 correo inexistente; 500/502 correo; 422.
/// - solicitar-recuperacion: 200 siempre (no revela si existe); 502 envio fallido.
/// - validar-codigo-recuperacion / restablecer-contrasena: 400 invalido o expirado; 422.
/// El backend no limita la frecuencia (no devuelve 429); si algun dia lo hace,
/// ya hay texto propio.
abstract final class MensajesErrorAutenticacion {
  static const String sinConexion = 'No se pudo conectar con el servidor. Verifica tu conexión.';
  static const String demasiadosIntentos =
      'Has hecho demasiados intentos. Espera un momento y vuelve a intentarlo.';
  static const String generico = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  static const String datosInvalidos = 'Revisa los datos ingresados.';
  static const String cuentaSuspendida =
      'Tu cuenta está suspendida. Contacta con un administrador.';
  static const String credencialesIncorrectas = 'Correo o contraseña incorrectos.';
  static const String cuentaNoActiva = 'Tu cuenta no está activa.';
  static const String correoYaRegistrado = 'Ya existe una cuenta con ese correo.';
  static const String correoNoEnviado = 'No pudimos enviar el correo. Inténtalo más tarde.';
  static const String codigoVerificacionInvalido =
      'El código no es válido o ya expiró. Si ya verificaste tu cuenta, inicia sesión.';
  static const String cuentaYaVerificada = 'Tu cuenta ya está verificada. Inicia sesión.';
  static const String correoSinCuenta = 'No encontramos una cuenta con ese correo.';
  static const String codigoRecuperacionInvalido = 'El código no es válido o ya expiró.';
  static const String contrasenaNoValida =
      'La contraseña no cumple los requisitos: 8 a 72 caracteres, con al menos una letra y un número.';

  static String para(OperacionAutenticacion operacion, ExcepcionApi error) {
    if (error.sinConexion) return sinConexion;
    final codigo = error.codigoEstado;
    if (codigo == 429) return demasiadosIntentos;

    final especifico = switch ((operacion, codigo)) {
      (OperacionAutenticacion.inicioSesion, 401) => credencialesIncorrectas,
      (OperacionAutenticacion.inicioSesion, 403) => cuentaNoActiva,
      (OperacionAutenticacion.registro, 409) => correoYaRegistrado,
      (OperacionAutenticacion.registro, 500 || 502) => correoNoEnviado,
      (OperacionAutenticacion.verificacionCorreo, 400) => codigoVerificacionInvalido,
      (OperacionAutenticacion.verificacionCorreo, 403) => cuentaSuspendida,
      (OperacionAutenticacion.reenvioCodigo, 400) => cuentaYaVerificada,
      (OperacionAutenticacion.reenvioCodigo, 403) => cuentaSuspendida,
      (OperacionAutenticacion.reenvioCodigo, 404) => correoSinCuenta,
      (OperacionAutenticacion.reenvioCodigo, 500 || 502) => correoNoEnviado,
      (OperacionAutenticacion.solicitudRecuperacion, 500 || 502) => correoNoEnviado,
      (OperacionAutenticacion.validacionCodigoRecuperacion, 400) => codigoRecuperacionInvalido,
      (OperacionAutenticacion.restablecimientoContrasena, 400) => codigoRecuperacionInvalido,
      (OperacionAutenticacion.restablecimientoContrasena, 422) => contrasenaNoValida,
      _ => null,
    };
    if (especifico != null) return especifico;
    if (codigo == 422) return datosInvalidos;
    return generico;
  }

  /// Login con 403: puede ser cuenta sin verificar o suspendida (el backend usa
  /// el mismo codigo). La pantalla ofrece el enlace a verificar; si estaba
  /// suspendida, la verificacion responde 403 y se muestra [cuentaSuspendida].
  static bool esCuentaNoActiva(OperacionAutenticacion operacion, ExcepcionApi error) =>
      operacion == OperacionAutenticacion.inicioSesion && error.codigoEstado == 403;
}
