import 'package:flutter/material.dart';

import '../../nucleo/tema/colores.dart';

/// Se muestra mientras se valida el token guardado contra /usuarios/me.
class PantallaCarga extends StatelessWidget {
  const PantallaCarga({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: ColoresApp.primario),
      ),
    );
  }
}
