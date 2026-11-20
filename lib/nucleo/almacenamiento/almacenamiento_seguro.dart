import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el token de sesion en el almacenamiento cifrado del dispositivo
/// (Keystore en Android, Keychain en iOS). Misma clave que el front web.
class AlmacenamientoSeguro {
  AlmacenamientoSeguro(this._almacenamiento);

  final FlutterSecureStorage _almacenamiento;
  static const String _claveToken = 'auth_token';

  Future<String?> leerToken() => _almacenamiento.read(key: _claveToken);

  Future<void> guardarToken(String token) =>
      _almacenamiento.write(key: _claveToken, value: token);

  Future<void> eliminarToken() => _almacenamiento.delete(key: _claveToken);
}

final almacenamientoSeguroProvider = Provider<AlmacenamientoSeguro>(
  (ref) => AlmacenamientoSeguro(const FlutterSecureStorage()),
);
