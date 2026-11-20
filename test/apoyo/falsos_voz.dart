import 'package:flutter/foundation.dart';
import 'package:traducontextmovil/nucleo/preferencias/preferencias_locales.dart';
import 'package:traducontextmovil/nucleo/voz/idioma_voz.dart';
import 'package:traducontextmovil/nucleo/voz/reconocimiento_voz.dart';
import 'package:traducontextmovil/nucleo/voz/sintesis_voz.dart';

/// Reconocimiento simulado: la prueba dicta frases con [decir].
class ReconocimientoFalso implements ReconocimientoVoz {
  /// Si no es null, [iniciar] falla con este error (sin permiso, sin soporte...).
  ErrorReconocimiento? errorAlIniciar;
  final List<String> idiomas = [];
  OyentesReconocimiento? _oyentes;

  bool get escuchando => _oyentes != null;

  @override
  Future<String> iniciar(String idioma, OyentesReconocimiento oyentes) async {
    final error = errorAlIniciar;
    if (error != null) throw ExcepcionReconocimiento(error);
    final resuelto = resolverIdiomaVoz(idioma);
    idiomas.add(resuelto);
    _oyentes = oyentes;
    return resuelto;
  }

  @override
  Future<void> detener() async => _oyentes = null;

  void parcial(String texto) => _oyentes?.alParcial(texto);

  void decir(String texto) {
    _oyentes?.alParcial('');
    _oyentes?.alFinal(texto);
  }

  /// Error grave: la captura se detiene.
  void fallar(ErrorReconocimiento error) {
    final oyentes = _oyentes;
    if (!error.leve) _oyentes = null;
    oyentes?.alError(error);
    if (!error.leve) oyentes?.alDetenerse();
  }
}

class SintesisFalsa implements SintesisVoz {
  ResultadoVoz resultado = ResultadoVoz.reproduciendo;
  final List<(String, String)> lecturas = [];
  int detenciones = 0;
  VoidCallback? _alTerminar;

  @override
  Future<ResultadoVoz> reproducir(String texto, String idioma, {VoidCallback? alTerminar}) async {
    if (resultado != ResultadoVoz.reproduciendo) return resultado;
    lecturas.add((texto, idioma));
    _alTerminar = alTerminar;
    return resultado;
  }

  @override
  Future<void> detener() async {
    detenciones++;
    terminar();
  }

  void terminar() {
    final alTerminar = _alTerminar;
    _alTerminar = null;
    alTerminar?.call();
  }
}

class PreferenciasFalsas implements PreferenciasLocales {
  final Map<String, String> valores = {};

  @override
  Future<String?> leer(String clave) async => valores[clave];

  @override
  Future<void> guardar(String clave, String valor) async => valores[clave] = valor;
}
