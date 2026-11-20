import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/usuario_actual.dart';
import 'package:traducontextmovil/nucleo/permisos/permisos.dart';

/// Rutas de la app. Las de administracion coinciden con las del front web.
abstract final class Rutas {
  static const String cargando = '/cargando';
  static const String login = '/login';

  // Publicas (sin sesion). verificarCorreo recibe el correo en `extra`.
  static const String registro = '/registro';
  static const String verificarCorreo = '/verificar-correo';
  static const String recuperarContrasena = '/recuperar-contrasena';

  static const Set<String> publicas = {login, registro, verificarCorreo, recuperarContrasena};

  // Carcasa de usuario
  static const String inicio = '/inicio';
  static const String perfil = '/perfil';

  // Carcasa de administracion
  static const String administracionUsuarios = '/administracion/usuarios';
  static const String administracionDashboard = '/administracion/dashboard';
  static const String administracionReportes = '/administracion/reportes';

  /// Equivalente a `data: { permiso }` + permisoGuard en app.routes.ts.
  /// El orden define la pantalla inicial de un administrador.
  static const Map<String, String> permisoPorRuta = {
    administracionUsuarios: Permisos.gestionarUsuarios,
    administracionDashboard: Permisos.verDashboard,
    administracionReportes: Permisos.generarReportes,
  };

  /// Pantalla de entrada segun permisos: admin -> primera ruta permitida; usuario -> inicio.
  static String inicialPara(UsuarioActual usuario) {
    for (final entrada in permisoPorRuta.entries) {
      if (usuario.tienePermiso(entrada.value)) return entrada.key;
    }
    return inicio;
  }
}
