import 'package:flutter/material.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';

/// Mensaje centrado bajo un formulario: error en rojo o aviso de exito en verde.
class MensajeFormulario extends StatelessWidget {
  const MensajeFormulario(this.texto, {super.key, this.esError = true});

  final String texto;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: esError ? ColoresApp.error : ColoresApp.exito,
          ),
    );
  }
}
