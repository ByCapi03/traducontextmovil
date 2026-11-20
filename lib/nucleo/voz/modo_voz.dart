import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/nucleo/preferencias/preferencias_locales.dart';

/// Reproducción por voz (HU-28): solo con el botón de cada intervención o
/// también automática al recibir cada traducción.
enum ModoVoz {
  manual('manual', 'Manual'),
  automatica('automatica', 'Automática');

  const ModoVoz(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  static ModoVoz desdeCodigo(String? codigo) => codigo == automatica.codigo ? automatica : manual;
}

/// Misma clave y valores que el `localStorage` de la web
/// (`conversacion-sesion.ts`): común a todas las conversaciones del dispositivo.
const String claveModoVoz = 'traducontext.reproduccionVoz';

class ControladorModoVoz extends Notifier<ModoVoz> {
  bool _elegido = false;

  @override
  ModoVoz build() {
    unawaited(_cargar());
    return ModoVoz.manual;
  }

  Future<void> _cargar() async {
    try {
      final guardado = await ref.read(preferenciasLocalesProvider).leer(claveModoVoz);
      if (!_elegido) state = ModoVoz.desdeCodigo(guardado);
    } on Exception {
      // Sin preferencias legibles se queda en Manual.
    }
  }

  Future<void> cambiar(ModoVoz modo) async {
    _elegido = true;
    state = modo;
    try {
      await ref.read(preferenciasLocalesProvider).guardar(claveModoVoz, modo.codigo);
    } on Exception {
      // Se mantiene en memoria aunque no se pueda guardar.
    }
  }
}

final modoVozProvider = NotifierProvider<ControladorModoVoz, ModoVoz>(ControladorModoVoz.new);
