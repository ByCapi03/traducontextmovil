import 'package:flutter/material.dart';
import 'package:traducontextmovil/compartido/formato.dart';
import 'package:traducontextmovil/funcionalidades/chats/dominio/chats.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Mensaje de chat. Los recibidos y traducidos muestran el texto en mi
/// idioma y, debajo, el original.
class BurbujaMensaje extends StatelessWidget {
  const BurbujaMensaje({super.key, required this.mensaje, required this.nombreIdioma});

  final MensajeChat mensaje;

  /// Nombre de un idioma a partir de su código.
  final String Function(String? codigo) nombreIdioma;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esMio = mensaje.esMio;
    final colorTexto = esMio ? ColoresApp.textoClaro : ColoresApp.texto;
    final colorSecundario = esMio ? ColoresApp.textoClaroSecundario : ColoresApp.textoSecundario;

    final (principal, aviso) = switch (mensaje.estadoLectura) {
      EstadoLectura.pendiente => (mensaje.textoOriginal, 'Traduciendo…'),
      EstadoLectura.error => (mensaje.textoOriginal, 'No se pudo traducir este mensaje.'),
      _ => (mensaje.texto, null),
    };

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: Espaciados.xs),
          padding: const EdgeInsets.symmetric(horizontal: Espaciados.md, vertical: Espaciados.sm),
          decoration: BoxDecoration(
            color: esMio ? ColoresApp.primario : ColoresApp.fondo,
            borderRadius: BorderRadius.circular(Radios.grande),
            boxShadow: Sombras.suave,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(principal, style: textos.bodyLarge?.copyWith(color: colorTexto)),
              if (mensaje.tieneTraduccion) ...[
                const SizedBox(height: Espaciados.xs),
                Text(
                  'Original (${nombreIdioma(mensaje.idiomaOriginal)}): ${mensaje.textoOriginal}',
                  style: textos.bodySmall?.copyWith(color: colorSecundario, fontStyle: FontStyle.italic),
                ),
              ],
              if (aviso != null) ...[
                const SizedBox(height: Espaciados.xs),
                Text(aviso, style: textos.bodySmall?.copyWith(color: colorSecundario)),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  Formato.hora(mensaje.fecha),
                  style: textos.bodySmall?.copyWith(color: colorSecundario, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
