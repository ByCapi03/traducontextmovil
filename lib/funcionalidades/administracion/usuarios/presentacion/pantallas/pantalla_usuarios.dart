import 'package:flutter/material.dart';

import 'package:traducontextmovil/compartido/widgets/pantalla_en_construccion.dart';

class PantallaUsuarios extends StatelessWidget {
  const PantallaUsuarios({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaEnConstruccion(
      titulo: 'Usuarios',
      icono: Icons.people_outline,
      descripcion: 'Gestion de usuarios (M4).',
    );
  }
}
