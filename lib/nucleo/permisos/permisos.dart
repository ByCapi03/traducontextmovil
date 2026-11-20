/// Nombres de permisos tal como los siembra traducontextback/app/seeds/seed_rol.py.
abstract final class Permisos {
  static const String gestionarUsuarios = 'gestionar_usuarios';
  static const String administrarPlanes = 'administrar_planes';
  static const String verDashboard = 'ver_dashboard';
  static const String generarReportes = 'generar_reportes';

  /// Permisos que habilitan la carcasa de administracion
  /// (administrar_planes queda fuera de M4 por ahora).
  static const List<String> administracion = [
    gestionarUsuarios,
    verDashboard,
    generarReportes,
  ];
}
