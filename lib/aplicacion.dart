import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/presentacion/proveedores/servicio_push.dart';
import 'package:traducontextmovil/navegacion/enrutador.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/tema/tema_aplicacion.dart';

class Aplicacion extends ConsumerStatefulWidget {
  const Aplicacion({super.key});

  @override
  ConsumerState<Aplicacion> createState() => _AplicacionState();
}

class _AplicacionState extends ConsumerState<Aplicacion> {
  @override
  void initState() {
    super.initState();
    // Push (M3): si Firebase no está configurado, la app sigue sin push.
    unawaited(ref.read(servicioPushProvider).iniciar(_navegar));
  }

  /// Navega tras el siguiente frame para no competir con las redirecciones
  /// del enrutador (por ejemplo, al salir de /cargando).
  void _navegar(String ruta) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final enrutador = ref.read(enrutadorProvider);
      if (Rutas.pestanas.contains(ruta)) {
        enrutador.go(ruta);
      } else {
        unawaited(enrutador.push(ruta));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EstadoSesion>(sesionProvider, (anterior, actual) {
      if (actual is SesionAutenticada && anterior is! SesionAutenticada) {
        unawaited(ref.read(servicioPushProvider).alIniciarSesion());
      }
    });
    return MaterialApp.router(
      title: 'TraduContext',
      debugShowCheckedModeBanner: false,
      theme: TemaAplicacion.claro,
      routerConfig: ref.watch(enrutadorProvider),
    );
  }
}
