import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:traducontextmovil/compartido/widgets/boton_cerrar_sesion.dart';

/// Carcasa del rol usuario: Inicio y Perfil.
class CarcasaUsuario extends StatelessWidget {
  const CarcasaUsuario({super.key, required this.navegacion});

  final StatefulNavigationShell navegacion;

  static const List<String> _titulos = ['Inicio', 'Perfil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[navegacion.currentIndex]),
        actions: const [BotonCerrarSesion()],
      ),
      body: navegacion,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navegacion.currentIndex,
        onDestinationSelected: (indice) => navegacion.goBranch(
          indice,
          initialLocation: indice == navegacion.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
