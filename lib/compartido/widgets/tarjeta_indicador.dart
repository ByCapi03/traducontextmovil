import 'package:flutter/material.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Indicador numérico (KPI) para el dashboard y los reportes.
class TarjetaIndicador extends StatelessWidget {
  const TarjetaIndicador({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.icono,
    this.detalle,
  });

  final String etiqueta;
  final String valor;
  final IconData icono;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Espaciados.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: ColoresApp.primario),
            const SizedBox(height: Espaciados.sm),
            Text(valor, style: textos.headlineMedium),
            Text(
              etiqueta,
              style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (detalle != null)
              Text(detalle!, style: textos.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
