import 'package:flutter/material.dart';
import 'package:traducontextmovil/compartido/formato.dart';
import 'package:traducontextmovil/funcionalidades/historial/dominio/historial.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

class TarjetaHistorial extends StatelessWidget {
  const TarjetaHistorial({
    super.key,
    required this.entrada,
    required this.idiomas,
    required this.alCambiarFavorito,
    required this.alEliminar,
    required this.alCopiar,
  });

  final EntradaHistorial entrada;

  /// Ejemplo: "Español → Inglés".
  final String idiomas;
  final VoidCallback alCambiarFavorito;
  final VoidCallback alEliminar;
  final VoidCallback alCopiar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espaciados.md, Espaciados.sm, Espaciados.xs, Espaciados.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$idiomas · ${Formato.fechaHora(entrada.fecha)}',
                    style: textos.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: entrada.favorito ? 'Quitar de favoritos' : 'Marcar como favorito',
                  icon: Icon(
                    entrada.favorito ? Icons.star : Icons.star_border,
                    color: entrada.favorito ? ColoresApp.advertencia : null,
                  ),
                  onPressed: alCambiarFavorito,
                ),
                PopupMenuButton<VoidCallback>(
                  tooltip: 'Más opciones',
                  onSelected: (accion) => accion(),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: alCopiar, child: const Text('Copiar traducción')),
                    PopupMenuItem(value: alEliminar, child: const Text('Eliminar')),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: Espaciados.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    entrada.textoOriginal,
                    style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Espaciados.xs),
                  Text(entrada.textoTraducido, style: textos.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
