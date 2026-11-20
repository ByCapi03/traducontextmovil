/// Validaciones de formulario alineadas con los esquemas del backend
/// (app/schemas/usuario.py y app/schemas/autenticacion.py).
abstract final class Validadores {
  static final RegExp _patronCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _patronCodigo = RegExp(r'^\d{6}$');
  static final RegExp _letra = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]');
  static final RegExp _digito = RegExp(r'\d');

  static const int longitudCodigo = 6;
  static const int minimoContrasena = 8;
  static const int maximoContrasena = 72;
  static const int minimoNombre = 2;
  static const int maximoNombre = 100;

  /// Igual que el backend: sin espacios y en minúsculas.
  static String normalizarCorreo(String correo) => correo.trim().toLowerCase();

  /// Igual que el backend: espacios internos colapsados.
  static String normalizarNombre(String nombre) =>
      nombre.trim().split(RegExp(r'\s+')).where((parte) => parte.isNotEmpty).join(' ');

  static String? correo(String? valor) {
    final texto = normalizarCorreo(valor ?? '');
    if (texto.isEmpty) return 'Ingresa tu correo.';
    if (texto.length > 255 || !_patronCorreo.hasMatch(texto)) return 'Correo no válido.';
    return null;
  }

  static String? nombre(String? valor) {
    final texto = normalizarNombre(valor ?? '');
    if (texto.isEmpty) return 'Ingresa tu nombre.';
    if (texto.length < minimoNombre || texto.length > maximoNombre) {
      return 'El nombre debe tener entre $minimoNombre y $maximoNombre caracteres.';
    }
    return null;
  }

  /// Contraseña para el login: solo se exige que no esté vacía.
  static String? contrasenaIngresada(String? valor) =>
      (valor == null || valor.isEmpty) ? 'Ingresa tu contraseña.' : null;

  /// Contraseña nueva (registro y recuperación): 8–72, al menos una letra y un número.
  static String? contrasenaNueva(String? valor) {
    final texto = valor ?? '';
    if (texto.isEmpty) return 'Ingresa una contraseña.';
    if (texto.length < minimoContrasena) {
      return 'La contraseña debe tener al menos $minimoContrasena caracteres.';
    }
    if (texto.length > maximoContrasena) {
      return 'La contraseña no puede tener más de $maximoContrasena caracteres.';
    }
    if (!_letra.hasMatch(texto) || !_digito.hasMatch(texto)) {
      return 'La contraseña debe incluir al menos una letra y un número.';
    }
    return null;
  }

  static String? Function(String?) confirmacion(String Function() original) =>
      (valor) {
        if (valor == null || valor.isEmpty) return 'Confirma la contraseña.';
        return valor == original() ? null : 'Las contraseñas no coinciden.';
      };

  static String? codigo(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Ingresa el código.';
    if (!_patronCodigo.hasMatch(texto)) return 'El código debe tener $longitudCodigo dígitos.';
    return null;
  }
}
