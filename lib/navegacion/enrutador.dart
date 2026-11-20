import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/widgets/pantalla_carga.dart';
import 'package:traducontextmovil/compartido/widgets/pantalla_pendiente.dart';
import 'package:traducontextmovil/funcionalidades/administracion/dashboard/presentacion/pantallas/pantalla_dashboard.dart';
import 'package:traducontextmovil/funcionalidades/administracion/reportes/presentacion/pantallas/pantalla_reportes.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/presentacion/pantallas/pantalla_detalle_usuario.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/presentacion/pantallas/pantalla_usuarios.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/pantallas/pantalla_inicio_sesion.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/pantallas/pantalla_recuperar_contrasena.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/pantallas/pantalla_registro.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/pantallas/pantalla_verificar_correo.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
import 'package:traducontextmovil/funcionalidades/chats/presentacion/pantallas/pantalla_chat.dart';
import 'package:traducontextmovil/funcionalidades/chats/presentacion/pantallas/pantalla_nuevo_chat.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/presentacion/pantallas/pantalla_conversacion.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/presentacion/pantallas/pantalla_conversaciones.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/presentacion/pantallas/pantalla_nueva_conversacion.dart';
import 'package:traducontextmovil/funcionalidades/documentos/presentacion/pantallas/pantalla_documentos.dart';
import 'package:traducontextmovil/funcionalidades/historial/presentacion/pantallas/pantalla_historial.dart';
import 'package:traducontextmovil/funcionalidades/inicio/presentacion/pantallas/pantalla_inicio.dart';
import 'package:traducontextmovil/funcionalidades/perfil/presentacion/pantallas/pantalla_perfil.dart';
import 'package:traducontextmovil/funcionalidades/preferencias/presentacion/pantallas/pantalla_preferencias.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/presentacion/pantallas/pantalla_traducir.dart';
import 'package:traducontextmovil/navegacion/carcasas/carcasa_administracion.dart';
import 'package:traducontextmovil/navegacion/carcasas/carcasa_usuario.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';

/// Decide a donde ir segun la sesion. Reune lo que en el web hacen
/// autenticacionGuard (hay token) y permisoGuard (tiene el permiso de la ruta).
@visibleForTesting
String? redirigirSegunSesion(EstadoSesion sesion, String ubicacion) {
  switch (sesion) {
    case SesionCargando():
      return ubicacion == Rutas.cargando ? null : Rutas.cargando;
    case SesionNoAutenticada():
      return Rutas.publicas.contains(ubicacion) ? null : Rutas.login;
    case SesionAutenticada(:final usuario):
      final rutaInicial = Rutas.inicialPara(usuario);
      if (ubicacion == Rutas.cargando || Rutas.publicas.contains(ubicacion)) {
        return rutaInicial;
      }
      final permisoRequerido = Rutas.permisoPara(ubicacion);
      if (permisoRequerido != null && !usuario.tienePermiso(permisoRequerido)) {
        return rutaInicial;
      }
      // El resto de la carcasa de administracion (perfil, planes...) solo para administradores.
      if (ubicacion.startsWith('${Rutas.prefijoAdministracion}/') && !usuario.esAdministrador) {
        return rutaInicial;
      }
      return null;
  }
}

final enrutadorProvider = Provider<GoRouter>((ref) {
  // go_router reevalua el redirect cada vez que cambia la sesion.
  final refresco = ValueNotifier<int>(0);
  ref.listen<EstadoSesion>(sesionProvider, (_, _) => refresco.value++);

  GoRoute pestana(String ruta, Widget pantalla) =>
      GoRoute(path: ruta, builder: (context, estado) => pantalla);

  final enrutador = GoRouter(
    initialLocation: Rutas.cargando,
    refreshListenable: refresco,
    redirect: (context, estado) =>
        redirigirSegunSesion(ref.read(sesionProvider), estado.matchedLocation),
    routes: [
      GoRoute(path: Rutas.cargando, builder: (context, estado) => const PantallaCarga()),
      GoRoute(path: Rutas.login, builder: (context, estado) => const PantallaInicioSesion()),
      GoRoute(path: Rutas.registro, builder: (context, estado) => const PantallaRegistro()),
      GoRoute(
        path: Rutas.verificarCorreo,
        builder: (context, estado) =>
            PantallaVerificarCorreo(correo: estado.extra is String ? estado.extra! as String : null),
      ),
      GoRoute(
        path: Rutas.recuperarContrasena,
        builder: (context, estado) => const PantallaRecuperarContrasena(),
      ),
      // El orden de estas ramas lo usa CarcasaUsuario.
      StatefulShellRoute.indexedStack(
        builder: (context, estado, navegacion) => CarcasaUsuario(navegacion: navegacion),
        branches: [
          StatefulShellBranch(routes: [pestana(Rutas.inicio, const PantallaInicio())]),
          StatefulShellBranch(routes: [pestana(Rutas.traducir, const PantallaTraducir())]),
          StatefulShellBranch(routes: [pestana(Rutas.historial, const PantallaHistorial())]),
          StatefulShellBranch(
            routes: [
              pestana(Rutas.conversaciones, const PantallaConversaciones()),
            ],
          ),
          StatefulShellBranch(routes: [pestana(Rutas.perfil, const PantallaPerfil())]),
        ],
      ),
      // Pantallas completas del usuario (modulos de la web aun no portados).
      pestana(Rutas.documentos, const PantallaDocumentos()),
      pestana(
        Rutas.glosarios,
        const PantallaPendiente(titulo: 'Glosarios', icono: Icons.menu_book_outlined),
      ),
      pestana(Rutas.preferencias, const PantallaPreferencias()),
      pestana(
        Rutas.integraciones,
        const PantallaPendiente(titulo: 'Integraciones', icono: Icons.link),
      ),
      // /chats/nuevo antes que /chats/:idChat.
      pestana(Rutas.nuevoChat, const PantallaNuevoChat()),
      GoRoute(
        path: Rutas.chatPatron,
        builder: (context, estado) =>
            PantallaChat(idChat: int.parse(estado.pathParameters['idChat']!)),
      ),
      pestana(Rutas.nuevaConversacion, const PantallaNuevaConversacion()),
      GoRoute(
        path: Rutas.conversacionPatron,
        builder: (context, estado) => PantallaConversacion(
          idConversacion: int.parse(estado.pathParameters['idConversacion']!),
        ),
      ),
      // Pantallas completas de administracion. Van antes de la carcasa para
      // que /administracion/usuarios/:id no se resuelva dentro de la pestaña.
      GoRoute(
        path: Rutas.detalleUsuarioPatron,
        builder: (context, estado) => PantallaDetalleUsuario(
          idUsuario: int.parse(estado.pathParameters['idUsuario']!),
        ),
      ),
      pestana(
        Rutas.administracionPlanes,
        const PantallaPendiente(
          titulo: 'Planes',
          icono: Icons.workspace_premium_outlined,
          descripcion: 'Próximamente. Los planes aún no existen en el backend.',
        ),
      ),
      pestana(
        Rutas.administracionSuscripciones,
        const PantallaPendiente(
          titulo: 'Suscripciones',
          icono: Icons.card_membership_outlined,
          descripcion: 'Próximamente. Las suscripciones aún no existen en el backend.',
        ),
      ),
      // El orden de estas ramas lo usa CarcasaAdministracion (indiceRama).
      StatefulShellRoute.indexedStack(
        builder: (context, estado, navegacion) => CarcasaAdministracion(navegacion: navegacion),
        branches: [
          StatefulShellBranch(
            routes: [pestana(Rutas.administracionDashboard, const PantallaDashboard())],
          ),
          StatefulShellBranch(
            routes: [pestana(Rutas.administracionUsuarios, const PantallaUsuarios())],
          ),
          StatefulShellBranch(
            routes: [pestana(Rutas.administracionReportes, const PantallaReportes())],
          ),
          StatefulShellBranch(
            routes: [
              pestana(Rutas.administracionPerfil, const PantallaPerfil(esAdministracion: true)),
            ],
          ),
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
