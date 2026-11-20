import 'package:flutter/material.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Mensaje centrado para listas vacías o con error, con acción opcional
/// (por ejemplo "Reintentar").
class VistaEstado extends StatelessWidget {
  const VistaEstado({
    super.key,
    required this.icono,
    required this.mensaje,
    this.esError = false,
    this.textoAccion,
    this.alPresionar,
  });

  final IconData icono;
  final String mensaje;
  final bool esError;
  final String? textoAccion;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Espaciados.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: esError ? ColoresApp.error : ColoresApp.acento),
            const SizedBox(height: Espaciados.md),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: ColoresApp.textoSecundario),
            ),
            if (textoAccion != null && alPresionar != null) ...[
              const SizedBox(height: Espaciados.md),
              OutlinedButton(onPressed: alPresionar, child: Text(textoAccion!)),
            ],
          ],
        ),
      ),
    );
  }
}
