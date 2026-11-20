import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/funcionalidades/chats/datos/chats_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/chats/dominio/chats.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

/// Estado de la búsqueda de usuarios para un chat nuevo.
sealed class EstadoBusquedaUsuarios {
  const EstadoBusquedaUsuarios();
}

/// Menos de [BusquedaUsuarios.longitudMinima] caracteres.
class BusquedaInactiva extends EstadoBusquedaUsuarios {
  const BusquedaInactiva();
}

class BusquedaEnCurso extends EstadoBusquedaUsuarios {
  const BusquedaEnCurso();
}

class BusquedaResuelta extends EstadoBusquedaUsuarios {
  const BusquedaResuelta(this.usuarios);

  final List<UsuarioChat> usuarios;
}

class BusquedaFallida extends EstadoBusquedaUsuarios {
  const BusquedaFallida(this.mensaje);

  final String mensaje;
}

/// GET /chats/usuarios?q= con espera entre pulsaciones. Solo cuenta la
/// respuesta de la última búsqueda (las anteriores se descartan).
class BusquedaUsuarios extends AutoDisposeNotifier<EstadoBusquedaUsuarios> {
  static const int longitudMinima = 3;
  static const Duration espera = Duration(milliseconds: 400);

  Timer? _temporizador;
  String _texto = '';
  int _peticion = 0;

  @override
  EstadoBusquedaUsuarios build() {
    ref.onDispose(() => _temporizador?.cancel());
    return const BusquedaInactiva();
  }

  void escribir(String texto) {
    _temporizador?.cancel();
    _texto = texto.trim();
    _peticion++;
    if (_texto.length < longitudMinima) {
      state = const BusquedaInactiva();
      return;
    }
    _temporizador = Timer(espera, buscar);
  }

  Future<void> buscar() async {
    if (_texto.length < longitudMinima) return;
    final peticion = ++_peticion;
    state = const BusquedaEnCurso();
    try {
      final usuarios = await ref.read(chatsRepositorioProvider).buscarUsuarios(_texto);
      if (peticion == _peticion) state = BusquedaResuelta(usuarios);
    } on ExcepcionApi catch (error) {
      if (peticion == _peticion) {
        state = BusquedaFallida(MensajesError.de(error, porDefecto: 'No se pudo buscar usuarios.'));
      }
    }
  }
}

final busquedaUsuariosProvider =
    NotifierProvider.autoDispose<BusquedaUsuarios, EstadoBusquedaUsuarios>(BusquedaUsuarios.new);
