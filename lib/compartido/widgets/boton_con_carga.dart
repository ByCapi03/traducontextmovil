import 'package:flutter/material.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';

/// Boton principal que se deshabilita y muestra un indicador mientras carga.
class BotonConCarga extends StatelessWidget {
  const BotonConCarga({
    super.key,
    required this.texto,
    required this.cargando,
    required this.alPresionar,
  });

  final String texto;
  final bool cargando;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: cargando ? null : alPresionar,
      child: cargando
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: ColoresApp.textoClaro),
            )
          : Text(texto),
    );
  }
}
