import 'package:flutter/material.dart';

/// Campo de contraseña con botón para mostrar u ocultar.
class CampoContrasena extends StatefulWidget {
  const CampoContrasena({
    super.key,
    required this.controlador,
    required this.etiqueta,
    required this.validador,
    this.habilitado = true,
    this.esNueva = false,
    this.accion = TextInputAction.next,
    this.alEnviar,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final FormFieldValidator<String> validador;
  final bool habilitado;

  /// true en registro y recuperación: el gestor de contraseñas propone una nueva.
  final bool esNueva;
  final TextInputAction accion;
  final VoidCallback? alEnviar;

  @override
  State<CampoContrasena> createState() => _CampoContrasenaState();
}

class _CampoContrasenaState extends State<CampoContrasena> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controlador,
      enabled: widget.habilitado,
      obscureText: _oculta,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: widget.accion,
      autofillHints: [widget.esNueva ? AutofillHints.newPassword : AutofillHints.password],
      onFieldSubmitted: widget.alEnviar == null ? null : (_) => widget.alEnviar!(),
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _oculta ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(_oculta ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _oculta = !_oculta),
        ),
      ),
      validator: widget.validador,
    );
  }
}
