import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:traducontextmovil/compartido/widgets/pantalla_carga.dart';
import 'package:traducontextmovil/funcionalidades/administracion/dashboard/presentacion/pantallas/pantalla_dashboard.dart';
import 'package:traducontextmovil/funcionalidades/administracion/reportes/presentacion/pantallas/pantalla_reportes.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/presentacion/pantallas/pantalla_usuarios.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/pantallas/pantalla_inicio_sesion.dart';
import 'package:traducontextmovil/navegacion/carcasas/carcasa_administracion.dart';
import 'package:traducontextmovil/navegacion/carcasas/carcasa_usuario.dart';
import 'package:traducontextmovil/funcionalidades/inicio/presentacion/pantallas/pantalla_inicio.dart';
import 'package:traducontextmovil/funcionalidades/perfil/presentacion/pantallas/pantalla_perfil.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';

/// Decide a donde ir segun la sesion. Reune lo que en el web hacen
/// autenticacionGuard (hay token) y permisoGuard (tiene el permiso de la ruta).
@visibleForTesting
String? redirigirSegunSesion(EstadoSesion sesion, String ubicacion) {
  switch (sesion) {
    case SesionCargando():
      return ubicacion == Rutas.cargando ? null : Rutas.cargando;
    case SesionNoAutenticada():
      return ubicacion == Rutas.login ? null : Rutas.login;
    case SesionAutenticada(:final usuario):
      final rutaInicial = Rutas.inicialPara(usuario);
      if (ubicacion == Rutas.login || ubicacion == Rutas.cargando) {
        return rutaInicial;
      }
      final permisoRequerido = Rutas.permisoPorRuta[ubicacion];
      if (permisoRequerido != null && !usuario.tienePermiso(permisoRequerido)) {
        return rutaInicial;
      }
      return null;
  }
}

final enrutadorProvider = Provider<GoRouter>((ref) {
  // go_router reevalua el redirect cada vez que cambia la sesion.
  final refresco = ValueNotifier<int>(0);
  ref.listen<EstadoSesion>(sesionProvider, (_, _) => refresco.value++);

  final enrutador = GoRouter(
    initialLocation: Rutas.cargando,
    refreshListenable: refresco,
    redirect: (context, estado) =>
        redirigirSegunSesion(ref.read(sesionProvider), estado.matchedLocation),
    routes: [
      GoRoute(
        path: Rutas.cargando,
        builder: (context, estado) => const PantallaCarga(),
      ),
      GoRoute(
        path: Rutas.login,
        builder: (context, estado) => const PantallaInicioSesion(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, estado, navegacion) => CarcasaUsuario(navegacion: navegacion),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Rutas.inicio, builder: (context, estado) => const PantallaInicio()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Rutas.perfil, builder: (context, estado) => const PantallaPerfil()),
          ]),
        ],
      ),
      // El orden de estas ramas lo usa CarcasaAdministracion (indiceRama).
      StatefulShellRoute.indexedStack(
        builder: (context, estado, navegacion) => CarcasaAdministracion(navegacion: navegacion),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.administracionUsuarios,
              builder: (context, estado) => const PantallaUsuarios(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.administracionDashboard,
              builder: (context, estado) => const PantallaDashboard(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rutas.administracionReportes,
              builder: (context, estado) => const PantallaReportes(),
            ),
          ]),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    enrutador.dispose();
    refresco.dispose();
  });
  return enrutador;
});
