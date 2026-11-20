import 'dart:typed_data';

/// Reglas de la foto de perfil (app/services/perfil.py): JPG, PNG o WEBP de
/// hasta 5 MB.
abstract final class FotoPerfil {
  static const int tamanoMaximo = 5 * 1024 * 1024;
  static const List<String> extensiones = ['jpg', 'jpeg', 'png', 'webp'];

  /// Tipo MIME por extensión: el backend valida el `content_type`.
  static String? tipoMime(String nombre) => switch (nombre.split('.').last.toLowerCase()) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => null,
      };

  /// Mensaje de error o null si la imagen es válida.
  static String? validar(String nombre, int tamano) {
    if (tipoMime(nombre) == null) return 'La foto debe ser JPG, PNG o WEBP.';
    if (tamano == 0) return 'La imagen está vacía.';
    if (tamano > tamanoMaximo) return 'La foto no puede superar los 5 MB.';
    return null;
  }
}

/// Lanza `ExcepcionApi` si el backend responde con error.
abstract interface class PerfilRepositorio {
  /// PATCH /perfil. El correo no es editable.
  Future<void> actualizarNombre(String nombre);

  /// GET /perfil/foto. null si el usuario no tiene foto (404).
  Future<Uint8List?> obtenerFoto();

  /// PUT /perfil/foto (multipart, campo `archivo`). Reemplaza la anterior.
  Future<void> subirFoto({required String nombre, required List<int> bytes});

  /// DELETE /perfil/foto.
  Future<void> eliminarFoto();
}
