import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/usuario_actual.dart';

/// Convierte `UsuarioPerfilDetalle` (GET /usuarios/me, app/schemas/usuario.py)
/// en la entidad [UsuarioActual].
abstract final class UsuarioActualModelo {
  static UsuarioActual desdeJson(Map<String, dynamic> json) {
    final rol = json['rol'] as Map<String, dynamic>;
    return UsuarioActual(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String,
      estado: json['estado'] as String,
      rol: Rol(id: rol['id'] as int, nombre: rol['nombre'] as String),
      permisos: [
        for (final permiso in (json['permisos'] as List<dynamic>? ?? const []))
          permiso as String,
      ],
    );
  }
}
