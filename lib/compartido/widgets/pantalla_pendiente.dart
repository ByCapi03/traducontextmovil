import 'package:flutter/material.dart';
import 'package:traducontextmovil/compartido/widgets/pantalla_en_construccion.dart';

/// Pantalla completa (con barra y botón atrás) para un módulo de la web que
/// aún no está en el móvil. Ver docs/pendientes_movil.md.
class PantallaPendiente extends StatelessWidget {
  const PantallaPendiente({
    super.key,
    required this.titulo,
    required this.icono,
    this.descripcion = 'Disponible próximamente en la app. Mientras tanto, puedes usarlo desde la web.',
  });

  final String titulo;
  final IconData icono;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: PantallaEnConstruccion(titulo: titulo, icono: icono, descripcion: descripcion),
    );
  }
}
