import 'package:traducontextmovil/nucleo/permisos/permisos.dart';

/// Espejo de `RolDetalle` (app/schemas/usuario.py).
class Rol {
  const Rol({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory Rol.desdeJson(Map<String, dynamic> json) =>
      Rol(id: json['id'] as int, nombre: json['nombre'] as String);
}

/// Espejo de `UsuarioPerfilDetalle`, devuelto por GET /usuarios/me.
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

  factory UsuarioActual.desdeJson(Map<String, dynamic> json) => UsuarioActual(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        correo: json['correo'] as String,
        estado: json['estado'] as String,
        rol: Rol.desdeJson(json['rol'] as Map<String, dynamic>),
        permisos: [
          for (final permiso in (json['permisos'] as List<dynamic>? ?? const []))
            permiso as String,
        ],
      );

  bool tienePermiso(String permiso) => permisos.contains(permiso);

  /// Igual que el sidebar web: el menu se decide por permisos, no por nombre de rol.
  bool get esAdministrador => Permisos.administracion.any(tienePermiso);
}
