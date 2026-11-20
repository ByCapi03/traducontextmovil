import 'package:flutter/material.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Coloca indicadores en 2 columnas (3 si hay espacio) sin desbordes:
/// cada fila toma la altura de su contenido.
class CuadriculaIndicadores extends StatelessWidget {
  const CuadriculaIndicadores({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final columnas = restricciones.maxWidth >= 600 ? 3 : 2;
        final ancho = (restricciones.maxWidth - Espaciados.sm * (columnas - 1)) / columnas;
        return Wrap(
          spacing: Espaciados.sm,
          runSpacing: Espaciados.sm,
          children: [for (final hijo in children) SizedBox(width: ancho, child: hijo)],
        );
      },
    );
  }
}
