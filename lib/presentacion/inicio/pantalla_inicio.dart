import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../compartido/widgets/pantalla_en_construccion.dart';
import '../autenticacion/estado_sesion.dart';

class PantallaInicio extends ConsumerWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioActualProvider);
    return PantallaEnConstruccion(
      titulo: 'Hola, ${usuario?.nombre ?? ''}',
      icono: Icons.home_outlined,
      descripcion: 'Aqui veras tu resumen y notificaciones (M2).',
    );
  }
}
