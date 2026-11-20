import 'package:flutter/material.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/dominio/conversaciones.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Intervención con su texto original y la traducción. El participante 2
/// se alinea a la derecha, como en la web.
class TarjetaIntervencion extends StatelessWidget {
  const TarjetaIntervencion({
    super.key,
    required this.intervencion,
    required this.reintentando,
    required this.alCopiar,
    this.alReintentar,
    this.alLeer,
    this.leyendo = false,
  });

  final Intervencion intervencion;
  final bool reintentando;
  final VoidCallback? alReintentar;
  final ValueChanged<String> alCopiar;

  /// Lee la traducción en voz alta (o la detiene si [leyendo]).
  final VoidCallback? alLeer;
  final bool leyendo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final aLaDerecha = intervencion.ordenParticipante == 2;
    final traducido = intervencion.textoTraducido;
    return Align(
      alignment: aLaDerecha ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
        child: Card(
          color: aLaDerecha ? ColoresApp.primario.withValues(alpha: 0.06) : ColoresApp.fondo,
          margin: const EdgeInsets.symmetric(vertical: Espaciados.xs),
          child: Padding(
            padding: const EdgeInsets.all(Espaciados.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  [
                    intervencion.nombreParticipante ?? 'No identificado',
                    if (intervencion.nombreIdiomaOrigen != null) intervencion.nombreIdiomaOrigen!,
                  ].join(' · '),
                  style: textos.labelLarge?.copyWith(color: ColoresApp.primario),
                ),
                const SizedBox(height: Espaciados.xs),
                Text(
                  intervencion.textoOriginal,
                  style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
                ),
                const SizedBox(height: Espaciados.sm),
                switch (intervencion.estado) {
                  EstadoIntervencion.traducida when traducido != null => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: SelectableText(traducido, style: textos.bodyLarge)),
                        if (alLeer != null)
                          IconButton(
                            tooltip: leyendo ? 'Detener lectura' : 'Escuchar traducción',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(leyendo ? Icons.stop_circle_outlined : Icons.volume_up_outlined, size: 18),
                            onPressed: alLeer,
                          ),
                        IconButton(
                          tooltip: 'Copiar traducción',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          onPressed: () => alCopiar(traducido),
                        ),
                      ],
                    ),
                  EstadoIntervencion.procesando => Text('Traduciendo…', style: textos.bodySmall),
                  _ => Text(
                      'No se pudo traducir esta intervención.',
                      style: textos.bodySmall?.copyWith(color: ColoresApp.error),
                    ),
                },
                if (alReintentar != null && intervencion.puedeReintentar)
                  Align(
                    alignment: Alignment.centerRight,
                    child: reintentando
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton.icon(
                            onPressed: alReintentar,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reintentar'),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
