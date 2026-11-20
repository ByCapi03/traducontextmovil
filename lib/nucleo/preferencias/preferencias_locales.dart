import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias no sensibles guardadas en el dispositivo (equivalente al
/// `localStorage` de la web). Los secretos van en `AlmacenamientoSeguro`.
abstract interface class PreferenciasLocales {
  Future<String?> leer(String clave);

  Future<void> guardar(String clave, String valor);
}

class PreferenciasCompartidas implements PreferenciasLocales {
  PreferenciasCompartidas([SharedPreferencesAsync? preferencias])
      : _preferencias = preferencias ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferencias;

  @override
  Future<String?> leer(String clave) => _preferencias.getString(clave);

  @override
  Future<void> guardar(String clave, String valor) => _preferencias.setString(clave, valor);
}

final preferenciasLocalesProvider = Provider<PreferenciasLocales>((ref) => PreferenciasCompartidas());
