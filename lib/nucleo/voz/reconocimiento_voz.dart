import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:traducontextmovil/nucleo/voz/idioma_voz.dart';

/// Motivo por el que no se puede reconocer el habla (HU-25, como la web).
enum ErrorReconocimiento {
  /// El dispositivo no tiene servicio de reconocimiento de voz.
  sinSoporte,

  /// El usuario o el sistema denegaron el micrófono (RECORD_AUDIO).
  sinPermiso,
  sinMicrofono,
  sinConexion,

  /// No se detectó habla (no detiene la captura).
  sinVoz,

  /// Hubo habla pero no se entendió (no detiene la captura).
  noReconocido,

  /// La captura se corta una y otra vez sin recibir sonido.
  sinAudio,
  idiomaNoSoportado,
  desconocido;

  /// Errores tras los que se sigue escuchando.
  bool get leve => this == sinVoz || this == noReconocido;
}

/// Oyentes de una captura en curso.
class OyentesReconocimiento {
  const OyentesReconocimiento({
    required this.alParcial,
    required this.alFinal,
    required this.alError,
    required this.alDetenerse,
  });

  /// Texto provisional de la frase en curso ('' al terminarla).
  final ValueChanged<String> alParcial;

  /// Frase final reconocida, ya sin espacios sobrantes.
  final ValueChanged<String> alFinal;

  /// Error de la captura. Si no es [ErrorReconocimiento.leve], la captura ya se detuvo.
  final ValueChanged<ErrorReconocimiento> alError;

  /// La captura terminó sin que la detuviera el usuario (error grave).
  final VoidCallback alDetenerse;
}

/// Transcripción en tiempo real con el reconocimiento de voz del dispositivo.
abstract interface class ReconocimientoVoz {
  /// Empieza a escuchar en [idioma] ('es', 'en-US'...). Si ya escuchaba, se
  /// reinicia con el nuevo idioma. Devuelve el idioma con región usado, o
  /// lanza [ExcepcionReconocimiento] si no puede empezar.
  Future<String> iniciar(String idioma, OyentesReconocimiento oyentes);

  Future<void> detener();
}

class ExcepcionReconocimiento implements Exception {
  const ExcepcionReconocimiento(this.error);

  final ErrorReconocimiento error;

  @override
  String toString() => 'ExcepcionReconocimiento($error)';
}

/// Códigos de error de speech_to_text (Android). `null`: no es un error para el usuario.
const Map<String, ErrorReconocimiento?> _erroresDispositivo = {
  'error_permission': ErrorReconocimiento.sinPermiso,
  'error_insufficient_permissions': ErrorReconocimiento.sinPermiso,
  'error_audio_error': ErrorReconocimiento.sinMicrofono,
  'error_network': ErrorReconocimiento.sinConexion,
  'error_network_timeout': ErrorReconocimiento.sinConexion,
  'error_server': ErrorReconocimiento.sinConexion,
  'error_server_disconnected': ErrorReconocimiento.sinConexion,
  'error_too_many_requests': ErrorReconocimiento.sinConexion,
  'error_speech_timeout': ErrorReconocimiento.sinVoz,
  'error_no_match': ErrorReconocimiento.noReconocido,
  'error_language_not_supported': ErrorReconocimiento.idiomaNoSoportado,
  'error_language_unavailable': ErrorReconocimiento.idiomaNoSoportado,
  // Lo provocan detener() o un reinicio.
  'error_client': null,
  'error_busy': null,
};

/// Implementación con `speech_to_text`. El motor de Android corta la captura
/// tras un silencio: mientras el usuario no la detenga, se reinicia (como la web).
class ReconocimientoVozDispositivo implements ReconocimientoVoz {
  ReconocimientoVozDispositivo([SpeechToText? motor]) : _motor = motor ?? SpeechToText();

  final SpeechToText _motor;

  static const int _maximoReiniciosSinSonido = 3;
  static const Duration _ventanaReinicios = Duration(seconds: 10);

  OyentesReconocimiento? _oyentes;
  String _idioma = '';
  List<String>? _disponibles;
  List<DateTime> _reiniciosSinSonido = [];
  bool _reiniciando = false;

  @override
  Future<String> iniciar(String idioma, OyentesReconocimiento oyentes) async {
    await detener();
    final bool listo;
    try {
      listo = await _motor.initialize(onError: _alError, onStatus: _alEstado);
    } on PlatformException {
      throw const ExcepcionReconocimiento(ErrorReconocimiento.sinSoporte);
    } on MissingPluginException {
      throw const ExcepcionReconocimiento(ErrorReconocimiento.sinSoporte);
    }
    if (!listo) {
      final permiso = await _motor.hasPermission.catchError((_) => false);
      throw ExcepcionReconocimiento(
        permiso ? ErrorReconocimiento.sinSoporte : ErrorReconocimiento.sinPermiso,
      );
    }
    _disponibles ??= await _locales();
    final resuelto = resolverIdiomaVoz(idioma, disponibles: _disponibles!);
    if (resuelto.isEmpty) throw const ExcepcionReconocimiento(ErrorReconocimiento.idiomaNoSoportado);
    final base = resuelto.split('-').first.toLowerCase();
    if (_disponibles!.isNotEmpty &&
        !_disponibles!.any((l) => normalizarIdioma(l).toLowerCase().split('-').first == base)) {
      throw const ExcepcionReconocimiento(ErrorReconocimiento.idiomaNoSoportado);
    }
    _idioma = resuelto;
    _oyentes = oyentes;
    _reiniciosSinSonido = [];
    await _escuchar();
    return resuelto;
  }

  @override
  Future<void> detener() async {
    final habia = _oyentes != null;
    _oyentes = null;
    if (habia || _motor.isListening) {
      try {
        await _motor.cancel();
      } on PlatformException {
        // Ya estaba detenido.
      }
    }
  }

  Future<List<String>> _locales() async {
    try {
      return [for (final locale in await _motor.locales()) locale.localeId];
    } on PlatformException {
      return const [];
    }
  }

  Future<void> _escuchar() => _motor.listen(
        onResult: _alResultado,
        listenOptions: SpeechListenOptions(
          localeId: _idioma.replaceAll('-', '_'),
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          listenFor: const Duration(minutes: 1),
          pauseFor: const Duration(seconds: 4),
        ),
      );

  void _alResultado(SpeechRecognitionResult resultado) {
    final oyentes = _oyentes;
    if (oyentes == null) return;
    _reiniciosSinSonido = [];
    final texto = resultado.recognizedWords.trim();
    if (resultado.finalResult) {
      oyentes.alParcial('');
      if (texto.isNotEmpty) oyentes.alFinal(texto);
    } else {
      oyentes.alParcial(texto);
    }
  }

  void _alError(SpeechRecognitionError error) {
    final oyentes = _oyentes;
    if (oyentes == null) return;
    final tipo = _erroresDispositivo.containsKey(error.errorMsg)
        ? _erroresDispositivo[error.errorMsg]
        : ErrorReconocimiento.desconocido;
    if (tipo == null) return;
    if (!tipo.leve) {
      unawaited(detener());
      oyentes
        ..alError(tipo)
        ..alDetenerse();
      return;
    }
    oyentes.alError(tipo);
  }

  /// 'done' / 'notListening' sin que el usuario lo pidiera: se vuelve a escuchar.
  void _alEstado(String estado) {
    final oyentes = _oyentes;
    if (oyentes == null || estado == SpeechToText.listeningStatus || _reiniciando) return;
    if (estado != SpeechToText.doneStatus) return;
    oyentes.alParcial('');
    final ahora = DateTime.now();
    _reiniciosSinSonido = [
      ..._reiniciosSinSonido.where((t) => ahora.difference(t) < _ventanaReinicios),
      ahora,
    ];
    if (_reiniciosSinSonido.length > _maximoReiniciosSinSonido) {
      unawaited(detener());
      oyentes
        ..alError(ErrorReconocimiento.sinAudio)
        ..alDetenerse();
      return;
    }
    _reiniciando = true;
    _escuchar().catchError((Object _) {
      if (_oyentes == oyentes) {
        unawaited(detener());
        oyentes
          ..alError(ErrorReconocimiento.desconocido)
          ..alDetenerse();
      }
    }).whenComplete(() => _reiniciando = false);
  }
}

final reconocimientoVozProvider = Provider<ReconocimientoVoz>((ref) {
  final reconocimiento = ReconocimientoVozDispositivo();
  ref.onDispose(reconocimiento.detener);
  return reconocimiento;
});
