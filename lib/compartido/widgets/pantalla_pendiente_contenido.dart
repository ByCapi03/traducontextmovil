import 'package:flutter/material.dart';
import 'package:traducontextmovil/compartido/widgets/pantalla_en_construccion.dart';

/// Igual que PantallaPendiente pero sin barra: para usar dentro de una pestaña.
class PantallaPendienteContenido extends StatelessWidget {
  const PantallaPendienteContenido({super.key, required this.titulo, required this.icono});

  final String titulo;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return PantallaEnConstruccion(
      titulo: titulo,
      icono: icono,
      descripcion: 'Disponible próximamente en la app. Mientras tanto, puedes usarlo desde la web.',
    );
  }
}
