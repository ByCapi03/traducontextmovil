import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/usuario_actual.dart';

/// Contrato de autenticacion. Todos los metodos lanzan `ExcepcionApi` si el
/// backend responde con error o no hay conexion.
abstract interface class AutenticacionRepositorio {
  /// Login + guardado del token + carga de /usuarios/me.
  Future<UsuarioActual> iniciarSesion({required String correo, required String contrasena});

  /// Devuelve el usuario si hay un token guardado y sigue siendo valido.
  Future<UsuarioActual?> restaurarSesion();

  /// Cierra la sesion en el backend; el token local se borra aunque falle la red.
  Future<void> cerrarSesion();

  /// HU-01: crea la cuenta (queda INACTIVA) y el backend envia el codigo por correo.
  Future<void> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  });

  Future<void> verificarCorreo({required String correo, required String codigo});

  Future<void> reenviarCodigoVerificacion({required String correo});

  /// HU-03 paso 1. El backend responde igual exista o no el correo.
  Future<void> solicitarRecuperacion({required String correo});

  /// HU-03 paso 2. No consume el codigo.
  Future<void> validarCodigoRecuperacion({required String correo, required String codigo});

  /// HU-03 paso 3. Consume el codigo y cierra las sesiones activas del usuario.
  Future<void> restablecerContrasena({
    required String correo,
    required String codigo,
    required String nuevaContrasena,
  });
}
