import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
import 'package:traducontextmovil/nucleo/permisos/permisos.dart';

class _DestinoAdministracion {
  const _DestinoAdministracion({
    required this.indiceRama,
    required this.etiqueta,
    required this.icono,
    required this.iconoSeleccionado,
    this.permiso,
  });

  final int indiceRama;

  /// null: visible para cualquier administrador (Perfil).
  final String? permiso;
  final String etiqueta;
  final IconData icono;
  final IconData iconoSeleccionado;
}

/// Carcasa de administración: Dashboard / Usuarios / Reportes / Perfil. Cada
/// pestaña con permiso aparece solo si el usuario lo tiene (como los
/// @if (tienePermiso(...)) del sidebar web). El orden de las ramas debe
/// coincidir con el de StatefulShellRoute en el enrutador.
class CarcasaAdministracion extends ConsumerWidget {
  const CarcasaAdministracion({super.key, required this.navegacion});

  final StatefulNavigationShell navegacion;

  static const List<_DestinoAdministracion> _destinos = [
    _DestinoAdministracion(
      indiceRama: 0,
      permiso: Permisos.verDashboard,
      etiqueta: 'Dashboard',
      icono: Icons.insights_outlined,
      iconoSeleccionado: Icons.insights,
    ),
    _DestinoAdministracion(
      indiceRama: 1,
      permiso: Permisos.gestionarUsuarios,
      etiqueta: 'Usuarios',
      icono: Icons.people_outline,
      iconoSeleccionado: Icons.people,
    ),
    _DestinoAdministracion(
      indiceRama: 2,
      permiso: Permisos.generarReportes,
      etiqueta: 'Reportes',
      icono: Icons.description_outlined,
      iconoSeleccionado: Icons.description,
    ),
    _DestinoAdministracion(
      indiceRama: 3,
      etiqueta: 'Perfil',
      icono: Icons.person_outline,
      iconoSeleccionado: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioActualProvider);
    final visibles = [
      for (final destino in _destinos)
        if (destino.permiso == null || (usuario?.tienePermiso(destino.permiso!) ?? false)) destino,
    ];
    final indiceVisible = visibles.indexWhere(
      (destino) => destino.indiceRama == navegacion.currentIndex,
    );

    return Scaffold(
      appBar: AppBar(title: Text(_destinos[navegacion.currentIndex].etiqueta)),
      body: navegacion,
      // Perfil siempre está visible, así que hay al menos 2 destinos.
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceVisible < 0 ? 0 : indiceVisible,
        onDestinationSelected: (indice) {
          final rama = visibles[indice].indiceRama;
          navegacion.goBranch(rama, initialLocation: rama == navegacion.currentIndex);
        },
        destinations: [
          for (final destino in visibles)
            NavigationDestination(
              icon: Icon(destino.icono),
              selectedIcon: Icon(destino.iconoSeleccionado),
              label: destino.etiqueta,
            ),
        ],
      ),
    );
  }
}
