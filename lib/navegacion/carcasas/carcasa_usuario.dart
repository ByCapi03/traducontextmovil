import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/presentacion/proveedores/bandeja_notificaciones.dart';

/// Carcasa del rol usuario. El orden de las ramas debe coincidir con el de
/// StatefulShellRoute en el enrutador.
class CarcasaUsuario extends ConsumerWidget {
  const CarcasaUsuario({super.key, required this.navegacion});

  final StatefulNavigationShell navegacion;

  static const List<String> _titulos = [
    'Inicio',
    'Traducir',
    'Historial',
    'Conversaciones',
    'Perfil',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noLeidas = ref.watch(notificacionesNoLeidasProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_titulos[navegacion.currentIndex])),
      body: navegacion,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navegacion.currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (indice) => navegacion.goBranch(
          indice,
          initialLocation: indice == navegacion.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: noLeidas > 0,
              label: Text(noLeidas > 99 ? '99+' : '$noLeidas'),
              child: const Icon(Icons.home_outlined),
            ),
            selectedIcon: const Icon(Icons.home),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.translate_outlined),
            selectedIcon: Icon(Icons.translate),
            label: 'Traducir',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          const NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Conversaciones',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
