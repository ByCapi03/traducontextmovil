import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:traducontextmovil/funcionalidades/autenticacion/datos/repositorios/autenticacion_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/autenticacion_repositorio.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/usuario_actual.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/presentacion/proveedores/servicio_push.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/red/notificador_sesion_expirada.dart';

sealed class EstadoSesion {
  const EstadoSesion();
}

/// Arranque: se esta comprobando si hay un token valido guardado.
class SesionCargando extends EstadoSesion {
  const SesionCargando();
}

class SesionNoAutenticada extends EstadoSesion {
  const SesionNoAutenticada({this.mensaje});

  /// Aviso para la pantalla de login (p. ej. "tu sesion expiro").
  final String? mensaje;
}

class SesionAutenticada extends EstadoSesion {
  const SesionAutenticada(this.usuario);

  final UsuarioActual usuario;
}

class ControladorSesion extends Notifier<EstadoSesion> {
  static const String _mensajeExpirada = 'Tu sesión expiró. Inicia sesión nuevamente.';

  AutenticacionRepositorio get _repositorio => ref.read(autenticacionRepositorioProvider);

  @override
  EstadoSesion build() {
    final suscripcion = ref
        .watch(notificadorSesionExpiradaProvider)
        .eventos
        .listen((_) => expirarSesion());
    ref.onDispose(suscripcion.cancel);

    unawaited(Future.microtask(_restaurarSesion));
    return const SesionCargando();
  }

  Future<void> _restaurarSesion() async {
    try {
      final usuario = await _repositorio.restaurarSesion();
      state = usuario == null ? const SesionNoAutenticada() : SesionAutenticada(usuario);
    } on ExcepcionApi catch (error) {
      // Si fue un 401 el interceptor ya disparo expirarSesion().
      if (state is SesionCargando) {
        state = SesionNoAutenticada(
          mensaje: error.esNoAutorizado
              ? _mensajeExpirada
              : (error.sinConexion ? error.mensaje : 'No se pudo restaurar la sesión. Inicia sesión nuevamente.'),
        );
      }
    }
  }

  /// Lanza [ExcepcionApi] para que la pantalla muestre el mensaje del backend.
  Future<void> iniciarSesion({required String correo, required String contrasena}) async {
    final usuario = await _repositorio.iniciarSesion(correo: correo, contrasena: contrasena);
    state = SesionAutenticada(usuario);
  }

  /// Vuelve a pedir /usuarios/me (por ejemplo, tras editar el perfil).
  Future<void> recargarUsuario() async {
    final usuario = await _repositorio.restaurarSesion();
    if (usuario != null && state is SesionAutenticada) state = SesionAutenticada(usuario);
  }

  Future<void> cerrarSesion() async {
    // El token push se elimina mientras la sesión aún es válida.
    await ref.read(servicioPushProvider).antesDeCerrarSesion();
    await _repositorio.cerrarSesion();
    state = const SesionNoAutenticada();
  }

  /// Llamado cuando cualquier peticion devuelve 401.
  void expirarSesion() {
    if (state is SesionNoAutenticada) return;
    state = const SesionNoAutenticada(mensaje: _mensajeExpirada);
  }
}

final sesionProvider = NotifierProvider<ControladorSesion, EstadoSesion>(ControladorSesion.new);

/// Usuario autenticado o null.
final usuarioActualProvider = Provider<UsuarioActual?>((ref) {
  final sesion = ref.watch(sesionProvider);
  return sesion is SesionAutenticada ? sesion.usuario : null;
});
