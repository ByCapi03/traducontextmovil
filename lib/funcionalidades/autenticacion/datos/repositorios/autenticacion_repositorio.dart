import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:traducontextmovil/nucleo/almacenamiento/almacenamiento_seguro.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/datos/modelos/usuario_actual.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/datos/fuentes/autenticacion_api.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/datos/fuentes/usuarios_api.dart';

class AutenticacionRepositorio {
  AutenticacionRepositorio({
    required AutenticacionApi autenticacionApi,
    required UsuariosApi usuariosApi,
    required AlmacenamientoSeguro almacenamiento,
  })  : _autenticacionApi = autenticacionApi,
        _usuariosApi = usuariosApi,
        _almacenamiento = almacenamiento;

  final AutenticacionApi _autenticacionApi;
  final UsuariosApi _usuariosApi;
  final AlmacenamientoSeguro _almacenamiento;

  /// Login + guardado del token + carga de /usuarios/me.
  Future<UsuarioActual> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final token = await _autenticacionApi.iniciarSesion(
      correo: correo.trim().toLowerCase(),
      contrasena: contrasena,
    );
    await _almacenamiento.guardarToken(token);
    try {
      return await _usuariosApi.obtenerMiPerfil();
    } on ExcepcionApi {
      await _almacenamiento.eliminarToken();
      rethrow;
    }
  }

  /// Devuelve el usuario si hay un token guardado y sigue siendo valido.
  Future<UsuarioActual?> restaurarSesion() async {
    final token = await _almacenamiento.leerToken();
    if (token == null || token.isEmpty) return null;
    return _usuariosApi.obtenerMiPerfil();
  }

  /// Cierra la sesion en el backend; el token local se borra aunque falle la red.
  Future<void> cerrarSesion() async {
    try {
      await _autenticacionApi.cerrarSesion();
    } on ExcepcionApi {
      // Sesion ya cerrada o sin conexion: localmente se cierra igual.
    } finally {
      await _almacenamiento.eliminarToken();
    }
  }
}

final autenticacionRepositorioProvider = Provider<AutenticacionRepositorio>(
  (ref) => AutenticacionRepositorio(
    autenticacionApi: ref.watch(autenticacionApiProvider),
    usuariosApi: ref.watch(usuariosApiProvider),
    almacenamiento: ref.watch(almacenamientoSeguroProvider),
  ),
);
