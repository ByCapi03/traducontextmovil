import 'package:flutter/material.dart';

/// Selector con etiqueta y ayuda opcional. Si [valor] no está entre las
/// [opciones] se muestra vacío (con [textoVacio]).
class Desplegable<T> extends StatelessWidget {
  const Desplegable({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.alCambiar,
    this.habilitado = true,
    this.textoVacio = 'Selecciona',
    this.ayuda,
  });

  final String etiqueta;
  final T? valor;
  final List<(T, String)> opciones;
  final ValueChanged<T?> alCambiar;
  final bool habilitado;
  final String textoVacio;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final activo = habilitado && opciones.isNotEmpty;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: etiqueta,
        helperText: ayuda,
        helperMaxLines: 3,
        enabled: activo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: opciones.any((o) => o.$1 == valor) ? valor : null,
          isExpanded: true,
          hint: Text(textoVacio),
          onChanged: activo ? alCambiar : null,
          items: [
            for (final (valor, nombre) in opciones)
              DropdownMenuItem<T>(value: valor, child: Text(nombre, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
