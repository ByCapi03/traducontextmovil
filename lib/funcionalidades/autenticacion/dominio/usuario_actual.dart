import 'package:traducontextmovil/nucleo/permisos/permisos.dart';

/// Rol del usuario autenticado.
class Rol {
  const Rol({required this.id, required this.nombre});

  final int id;
  final String nombre;
}

/// Usuario autenticado (entidad de dominio, sin dependencias de red).
class UsuarioActual {
  const UsuarioActual({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.estado,
    required this.rol,
    required this.permisos,
  });

  final int id;
  final String nombre;
  final String correo;
  final String estado;
  final Rol rol;
  final List<String> permisos;

  bool tienePermiso(String permiso) => permisos.contains(permiso);

  /// Igual que el sidebar web: el menu se decide por permisos, no por nombre de rol.
  bool get esAdministrador => Permisos.administracion.any(tienePermiso);
}
