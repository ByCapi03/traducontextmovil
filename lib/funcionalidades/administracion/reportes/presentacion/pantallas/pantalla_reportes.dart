import 'package:flutter/material.dart';

import 'package:traducontextmovil/compartido/widgets/pantalla_en_construccion.dart';

class PantallaReportes extends StatelessWidget {
  const PantallaReportes({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaEnConstruccion(
      titulo: 'Reportes',
      icono: Icons.description_outlined,
      descripcion: 'Reportes de actividad (M4).',
    );
  }
}
