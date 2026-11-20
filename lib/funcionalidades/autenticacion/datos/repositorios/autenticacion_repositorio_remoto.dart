import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/validadores.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/datos/fuentes/autenticacion_api.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/datos/fuentes/recuperacion_api.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/datos/fuentes/registro_api.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/datos/fuentes/usuarios_api.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/autenticacion_repositorio.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/usuario_actual.dart';
import 'package:traducontextmovil/nucleo/almacenamiento/almacenamiento_seguro.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

class AutenticacionRepositorioRemoto implements AutenticacionRepositorio {
  AutenticacionRepositorioRemoto({
    required AutenticacionApi autenticacionApi,
    required UsuariosApi usuariosApi,
    required RegistroApi registroApi,
    required RecuperacionApi recuperacionApi,
    required AlmacenamientoSeguro almacenamiento,
  })  : _autenticacionApi = autenticacionApi,
        _usuariosApi = usuariosApi,
        _registroApi = registroApi,
        _recuperacionApi = recuperacionApi,
        _almacenamiento = almacenamiento;

  final AutenticacionApi _autenticacionApi;
  final UsuariosApi _usuariosApi;
  final RegistroApi _registroApi;
  final RecuperacionApi _recuperacionApi;
  final AlmacenamientoSeguro _almacenamiento;

  @override
  Future<UsuarioActual> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final token = await _autenticacionApi.iniciarSesion(
      correo: Validadores.normalizarCorreo(correo),
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

  @override
  Future<UsuarioActual?> restaurarSesion() async {
    final token = await _almacenamiento.leerToken();
    if (token == null || token.isEmpty) return null;
    return _usuariosApi.obtenerMiPerfil();
  }

  @override
  Future<void> cerrarSesion() async {
    try {
      await _autenticacionApi.cerrarSesion();
    } on ExcepcionApi {
      // Sesion ya cerrada o sin conexion: localmente se cierra igual.
    } finally {
      await _almacenamiento.eliminarToken();
    }
  }

  @override
  Future<void> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) =>
      _registroApi.registrar(
        nombre: Validadores.normalizarNombre(nombre),
        correo: Validadores.normalizarCorreo(correo),
        contrasena: contrasena,
      );

  @override
  Future<void> verificarCorreo({required String correo, required String codigo}) =>
      _registroApi.verificarCodigo(
        correo: Validadores.normalizarCorreo(correo),
        codigo: codigo.trim(),
      );

  @override
  Future<void> reenviarCodigoVerificacion({required String correo}) =>
      _registroApi.reenviarCodigo(correo: Validadores.normalizarCorreo(correo));

  @override
  Future<void> solicitarRecuperacion({required String correo}) =>
      _recuperacionApi.solicitarRecuperacion(correo: Validadores.normalizarCorreo(correo));

  @override
  Future<void> validarCodigoRecuperacion({required String correo, required String codigo}) =>
      _recuperacionApi.validarCodigo(
        correo: Validadores.normalizarCorreo(correo),
        codigo: codigo.trim(),
      );

  @override
  Future<void> restablecerContrasena({
    required String correo,
    required String codigo,
    required String nuevaContrasena,
  }) =>
      _recuperacionApi.restablecerContrasena(
        correo: Validadores.normalizarCorreo(correo),
        codigo: codigo.trim(),
        nuevaContrasena: nuevaContrasena,
      );
}

final autenticacionRepositorioProvider = Provider<AutenticacionRepositorio>(
  (ref) => AutenticacionRepositorioRemoto(
    autenticacionApi: ref.watch(autenticacionApiProvider),
    usuariosApi: ref.watch(usuariosApiProvider),
    registroApi: ref.watch(registroApiProvider),
    recuperacionApi: ref.watch(recuperacionApiProvider),
    almacenamiento: ref.watch(almacenamientoSeguroProvider),
  ),
);
