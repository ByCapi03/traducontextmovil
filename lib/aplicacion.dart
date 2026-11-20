import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:traducontextmovil/navegacion/enrutador.dart';
import 'package:traducontextmovil/nucleo/tema/tema_aplicacion.dart';

class Aplicacion extends ConsumerWidget {
  const Aplicacion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'TraduContext',
      debugShowCheckedModeBanner: false,
      theme: TemaAplicacion.claro,
      routerConfig: ref.watch(enrutadorProvider),
    );
  }
}
