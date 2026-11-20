import 'package:flutter/material.dart';

import 'package:traducontextmovil/compartido/widgets/pantalla_en_construccion.dart';

class PantallaDashboard extends StatelessWidget {
  const PantallaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaEnConstruccion(
      titulo: 'Dashboard',
      icono: Icons.insights_outlined,
      descripcion: 'Indicadores de uso (M4).',
    );
  }
}
