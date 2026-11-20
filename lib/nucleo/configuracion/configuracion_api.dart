import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// URL base del backend (traducontextback), equivalente a `apiUrl` del front web.
///
/// Se puede sobrescribir sin tocar codigo:
///   flutter run --dart-define=API_URL=http://192.168.1.50:8000/api/v1
/// Por defecto: emulador Android -> 10.0.2.2 (localhost del PC); resto -> 127.0.0.1.
abstract final class ConfiguracionApi {
  static const String _urlDefinida = String.fromEnvironment('API_URL');
  static const String prefijoApi = '/api/v1';
  static const String _puertoLocal = '8000';

  static String get urlBase {
    if (_urlDefinida.isNotEmpty) return _urlDefinida;
    final host = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:$_puertoLocal$prefijoApi';
  }

  static const Duration tiempoConexion = Duration(seconds: 15);
  static const Duration tiempoRespuesta = Duration(seconds: 60);
}
