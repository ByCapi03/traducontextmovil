import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/autenticacion_repositorio.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/usuario_actual.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

/// Repositorio simulado: registra cada llamada y lanza el error configurado
/// para ese metodo, si lo hay.
class RepositorioFalso implements AutenticacionRepositorio {
  final Map<String, ExcepcionApi> errores = {};
  final List<(String, Map<String, String>)> llamadas = [];

  UsuarioActual usuario = const UsuarioActual(
    id: 1,
    nombre: 'Ana',
    correo: 'ana@correo.com',
    estado: 'ACTIVO',
    rol: Rol(id: 2, nombre: 'USUARIO'),
    permisos: [],
  );

  List<Map<String, String>> llamadasA(String metodo) =>
      [for (final (nombre, datos) in llamadas) if (nombre == metodo) datos];

  Future<void> _registrar(String metodo, Map<String, String> datos) async {
    llamadas.add((metodo, datos));
    final error = errores[metodo];
    if (error != null) throw error;
  }

  @override
  Future<UsuarioActual> iniciarSesion({required String correo, required String contrasena}) async {
    await _registrar('iniciarSesion', {'correo': correo});
    return usuario;
  }

  @override
  Future<UsuarioActual?> restaurarSesion() async => null;

  @override
  Future<void> cerrarSesion() => _registrar('cerrarSesion', {});

  @override
  Future<void> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) =>
      _registrar('registrar', {'nombre': nombre, 'correo': correo});

  @override
  Future<void> verificarCorreo({required String correo, required String codigo}) =>
      _registrar('verificarCorreo', {'correo': correo, 'codigo': codigo});

  @override
  Future<void> reenviarCodigoVerificacion({required String correo}) =>
      _registrar('reenviarCodigoVerificacion', {'correo': correo});

  @override
  Future<void> solicitarRecuperacion({required String correo}) =>
      _registrar('solicitarRecuperacion', {'correo': correo});

  @override
  Future<void> validarCodigoRecuperacion({required String correo, required String codigo}) =>
      _registrar('validarCodigoRecuperacion', {'correo': correo, 'codigo': codigo});

  @override
  Future<void> restablecerContrasena({
    required String correo,
    required String codigo,
    required String nuevaContrasena,
  }) =>
      _registrar('restablecerContrasena', {'correo': correo, 'codigo': codigo});
}
