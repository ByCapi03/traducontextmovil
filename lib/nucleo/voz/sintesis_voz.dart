import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:traducontextmovil/nucleo/voz/idioma_voz.dart';

/// Resultado de un intento de reproducción por voz (HU-28, como la web).
enum ResultadoVoz {
  reproduciendo,

  /// El dispositivo no tiene motor de síntesis de voz.
  sinSoporte,

  /// No hay ninguna voz para el idioma pedido.
  sinVoz,
  sinTexto,
}

/// Lectura en voz alta con el motor del dispositivo.
abstract interface class SintesisVoz {
  /// Lee [texto] en [idioma] ('es', 'en-US'...). Corta la lectura anterior.
  /// [alTerminar] se llama al acabar, al fallar o al detenerla.
  Future<ResultadoVoz> reproducir(String texto, String idioma, {VoidCallback? alTerminar});

  Future<void> detener();
}

class SintesisVozDispositivo implements SintesisVoz {
  SintesisVozDispositivo([FlutterTts? motor]) : _motor = motor ?? FlutterTts();

  final FlutterTts _motor;
  bool _configurado = false;
  VoidCallback? _alTerminar;

  void _configurar() {
    if (_configurado) return;
    _configurado = true;
    _motor
      ..setCompletionHandler(_terminar)
      ..setCancelHandler(_terminar)
      ..setErrorHandler((_) => _terminar());
  }

  void _terminar() {
    final alTerminar = _alTerminar;
    _alTerminar = null;
    alTerminar?.call();
  }

  @override
  Future<ResultadoVoz> reproducir(String texto, String idioma, {VoidCallback? alTerminar}) async {
    final contenido = texto.trim();
    if (contenido.isEmpty) return ResultadoVoz.sinTexto;
    try {
      _configurar();
      await detener();
      final resuelto = resolverIdiomaVoz(idioma);
      if (resuelto.isEmpty) return ResultadoVoz.sinVoz;
      final disponible = await _motor.isLanguageAvailable(resuelto) == true ||
          await _motor.isLanguageAvailable(resuelto.split('-').first) == true;
      if (!disponible) return ResultadoVoz.sinVoz;
      await _motor.setLanguage(resuelto);
      _alTerminar = alTerminar;
      final resultado = await _motor.speak(contenido);
      if (resultado != 1) {
        _terminar();
        return ResultadoVoz.sinSoporte;
      }
      return ResultadoVoz.reproduciendo;
    } on MissingPluginException {
      return ResultadoVoz.sinSoporte;
    } on PlatformException {
      return ResultadoVoz.sinSoporte;
    }
  }

  @override
  Future<void> detener() async {
    // Primero se suelta el oyente: la lectura anterior no debe cambiar el estado de la nueva.
    _terminar();
    try {
      await _motor.stop();
    } on MissingPluginException {
      // Sin motor: no había nada que detener.
    } on PlatformException {
      // Ya estaba detenido.
    }
  }
}

final sintesisVozProvider = Provider<SintesisVoz>((ref) {
  final sintesis = SintesisVozDispositivo();
  ref.onDispose(sintesis.detener);
  return sintesis;
});
