import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traducontextmovil/compartido/validadores.dart';

/// Campo para el código de 6 dígitos: teclado numérico, solo dígitos,
/// máximo 6 y autocompletado de código de un solo uso.
class CampoCodigo extends StatelessWidget {
  const CampoCodigo({
    super.key,
    required this.controlador,
    this.habilitado = true,
    this.alEnviar,
  });

  final TextEditingController controlador;
  final bool habilitado;
  final VoidCallback? alEnviar;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      enabled: habilitado,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode],
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(Validadores.longitudCodigo),
      ],
      onFieldSubmitted: alEnviar == null ? null : (_) => alEnviar!(),
      decoration: const InputDecoration(
        labelText: 'Código de 6 dígitos',
        prefixIcon: Icon(Icons.pin_outlined),
      ),
      validator: Validadores.codigo,
    );
  }
}
