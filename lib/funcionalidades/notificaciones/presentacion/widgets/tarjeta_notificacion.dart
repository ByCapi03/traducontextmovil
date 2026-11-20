import 'package:flutter/material.dart';
import 'package:traducontextmovil/compartido/formato.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/notificacion.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';

class TarjetaNotificacion extends StatelessWidget {
  const TarjetaNotificacion({super.key, required this.notificacion, required this.alTocar});

  final Notificacion notificacion;
  final VoidCallback alTocar;

  IconData get _icono => switch (notificacion.tipo) {
        TiposNotificacion.documentoListo => Icons.description_outlined,
        TiposNotificacion.documentoError => Icons.error_outline,
        TiposNotificacion.mensajeChat => Icons.chat_bubble_outline,
        _ => Icons.notifications_none,
      };

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final noLeida = !notificacion.leida;
    return Card(
      child: ListTile(
        onTap: alTocar,
        leading: CircleAvatar(
          backgroundColor: ColoresApp.primario.withValues(alpha: noLeida ? 0.12 : 0.05),
          child: Icon(_icono, color: noLeida ? ColoresApp.primario : ColoresApp.textoSecundario),
        ),
        title: Text(
          notificacion.titulo,
          style: textos.titleMedium?.copyWith(
            fontWeight: noLeida ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        subtitle: Text('${notificacion.cuerpo}\n${Formato.relativa(notificacion.fecha)}'),
        isThreeLine: true,
        trailing: noLeida
            ? const Icon(Icons.circle, size: 10, color: ColoresApp.acento, semanticLabel: 'No leída')
            : null,
      ),
    );
  }
}
