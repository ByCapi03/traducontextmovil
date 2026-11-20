import 'package:flutter/material.dart';

import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Carcasa vacia para las pantallas que se implementan en hitos posteriores.
class PantallaEnConstruccion extends StatelessWidget {
  const PantallaEnConstruccion({
    super.key,
    required this.titulo,
    required this.icono,
    this.descripcion = 'Disponible proximamente.',
  });

  final String titulo;
  final IconData icono;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espaciados.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: ColoresApp.acento),
            const SizedBox(height: Espaciados.md),
            Text(titulo, style: textos.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: Espaciados.sm),
            Text(
              descripcion,
              style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
