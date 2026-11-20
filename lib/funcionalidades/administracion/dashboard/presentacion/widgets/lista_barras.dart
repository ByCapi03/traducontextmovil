import 'package:flutter/material.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Ranking con barras horizontales proporcionales al máximo.
class ListaBarras extends StatelessWidget {
  const ListaBarras({
    super.key,
    required this.titulo,
    required this.elementos,
    this.textoVacio = 'Sin datos en este periodo.',
  });

  final String titulo;

  /// (etiqueta, valor)
  final List<(String, int)> elementos;
  final String textoVacio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final maximo = elementos.fold<int>(0, (actual, e) => e.$2 > actual ? e.$2 : actual);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Espaciados.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titulo, style: textos.titleMedium),
            const SizedBox(height: Espaciados.sm),
            if (elementos.isEmpty)
              Text(textoVacio, style: textos.bodySmall)
            else
              for (final (etiqueta, valor) in elementos)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Espaciados.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(etiqueta, overflow: TextOverflow.ellipsis),
                          ),
                          Text('$valor', style: textos.labelLarge),
                        ],
                      ),
                      const SizedBox(height: Espaciados.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Radios.pequeno),
                        child: LinearProgressIndicator(
                          value: maximo == 0 ? 0 : valor / maximo,
                          minHeight: 8,
                          color: ColoresApp.acento,
                          backgroundColor: ColoresApp.fondoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
