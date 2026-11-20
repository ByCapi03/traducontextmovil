import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/espera_reenvio.dart';

/// Botón "Reenviar código" con espera de 60 s. La espera se guarda en
/// [esperaReenvioProvider], así que se mantiene al salir y volver a la pantalla.
class BotonReenviarCodigo extends ConsumerStatefulWidget {
  const BotonReenviarCodigo({
    super.key,
    required this.clave,
    required this.alReenviar,
    this.habilitado = true,
  });

  /// Clave de la espera (ver [ControladorEsperaReenvio.claveVerificacion]).
  final String clave;

  /// Debe llamar al backend y devolver true si el código se envió.
  final Future<bool> Function() alReenviar;
  final bool habilitado;

  @override
  ConsumerState<BotonReenviarCodigo> createState() => _BotonReenviarCodigoState();
}

class _BotonReenviarCodigoState extends ConsumerState<BotonReenviarCodigo> {
  Timer? _temporizador;
  bool _enviando = false;

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  void _asegurarTemporizador(int restantes) {
    if (restantes > 0 && _temporizador == null) {
      _temporizador = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final quedan = ref.read(esperaReenvioProvider.notifier).segundosRestantes(widget.clave);
        if (quedan == 0) {
          _temporizador?.cancel();
          _temporizador = null;
        }
        setState(() {});
      });
    }
  }

  Future<void> _reenviar() async {
    setState(() => _enviando = true);
    try {
      final enviado = await widget.alReenviar();
      if (enviado) ref.read(esperaReenvioProvider.notifier).registrarEnvio(widget.clave);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(esperaReenvioProvider);
    final restantes = ref.read(esperaReenvioProvider.notifier).segundosRestantes(widget.clave);
    _asegurarTemporizador(restantes);

    final puedeReenviar = widget.habilitado && !_enviando && restantes == 0;
    return TextButton.icon(
      onPressed: puedeReenviar ? _reenviar : null,
      icon: const Icon(Icons.refresh),
      label: Text(restantes > 0 ? 'Reenviar código en $restantes s' : 'Reenviar código'),
    );
  }
}
