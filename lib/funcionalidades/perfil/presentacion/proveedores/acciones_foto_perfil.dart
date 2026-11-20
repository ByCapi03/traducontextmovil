import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/funcionalidades/perfil/datos/perfil_api.dart';
import 'package:traducontextmovil/funcionalidades/perfil/dominio/perfil.dart';
import 'package:traducontextmovil/nucleo/archivos/selector_archivos.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

/// Cambiar o quitar la foto de perfil. Devuelven el mensaje para el usuario
/// (null si canceló).
class AccionesFotoPerfil {
  AccionesFotoPerfil(this._ref);

  final Ref _ref;

  Future<String?> cambiar() async {
    final archivo = await _ref.read(selectorArchivosProvider).elegir(extensiones: FotoPerfil.extensiones);
    if (archivo == null) return null;
    final error = FotoPerfil.validar(archivo.nombre, archivo.bytes.length);
    if (error != null) return error;
    return _ejecutar(
      () => _ref.read(perfilApiProvider).subirFoto(nombre: archivo.nombre, bytes: archivo.bytes),
      exito: 'Foto de perfil actualizada.',
      porCodigo: {400: 'La imagen no es válida: usa JPG, PNG o WEBP de hasta 5 MB.'},
    );
  }

  Future<String> quitar() => _ejecutar(
        () => _ref.read(perfilApiProvider).eliminarFoto(),
        exito: 'Foto de perfil eliminada.',
      );

  Future<String> _ejecutar(
    Future<void> Function() accion, {
    required String exito,
    Map<int, String> porCodigo = const {},
  }) async {
    try {
      await accion();
      _ref.invalidate(fotoPerfilProvider);
      return exito;
    } on ExcepcionApi catch (error) {
      return MensajesError.de(error, porCodigo: porCodigo);
    }
  }
}

final accionesFotoPerfilProvider = Provider<AccionesFotoPerfil>(AccionesFotoPerfil.new);
