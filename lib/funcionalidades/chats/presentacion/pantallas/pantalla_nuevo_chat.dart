import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/chats/datos/chats_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/chats/dominio/chats.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Busca a otro usuario por nombre y abre (o crea) el chat con él.
class PantallaNuevoChat extends ConsumerStatefulWidget {
  const PantallaNuevoChat({super.key});

  static const int longitudMinima = 2;

  @override
  ConsumerState<PantallaNuevoChat> createState() => _PantallaNuevoChatState();
}

class _PantallaNuevoChatState extends ConsumerState<PantallaNuevoChat> {
  final _busqueda = TextEditingController();
  Timer? _espera;
  List<UsuarioChat>? _resultados;
  bool _buscando = false;
  bool _abriendo = false;
  String? _error;

  @override
  void dispose() {
    _espera?.cancel();
    _busqueda.dispose();
    super.dispose();
  }

  void _alEscribir(String texto) {
    _espera?.cancel();
    if (texto.trim().length < PantallaNuevoChat.longitudMinima) {
      setState(() => _resultados = null);
      return;
    }
    _espera = Timer(const Duration(milliseconds: 400), _buscar);
  }

  Future<void> _buscar() async {
    setState(() => _buscando = true);
    try {
      final resultados = await ref.read(chatsRepositorioProvider).buscarUsuarios(_busqueda.text);
      if (mounted) setState(() => _resultados = resultados);
    } on ExcepcionApi catch (error) {
      if (mounted) setState(() => _error = MensajesError.de(error));
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _abrir(UsuarioChat usuario) async {
    setState(() => _abriendo = true);
    try {
      final chat = await ref.read(chatsRepositorioProvider).crearOObtener(usuario.id);
      if (mounted) context.pushReplacement(Rutas.chat(chat.id));
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              MensajesError.de(error, porCodigo: {404: 'Ese usuario ya no está disponible.'}),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _abriendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultados = _resultados;
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo chat')),
      body: ContenidoAdaptable.lista(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Espaciados.md),
              child: TextField(
                controller: _busqueda,
                autofocus: true,
                onChanged: _alEscribir,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Buscar por nombre',
                  helperText: 'Escribe al menos 2 letras.',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            if (_buscando || _abriendo) const LinearProgressIndicator(),
            Expanded(
              child: switch (resultados) {
                null when _error != null => VistaEstado(
                    icono: Icons.cloud_off_outlined,
                    esError: true,
                    mensaje: _error!,
                  ),
                null => const VistaEstado(
                    icono: Icons.person_search_outlined,
                    mensaje: 'Busca a la persona con la que quieres chatear.',
                  ),
                [] => const VistaEstado(
                    icono: Icons.person_off_outlined,
                    mensaje: 'No se encontraron usuarios.',
                  ),
                _ => ListView(
                    children: [
                      for (final usuario in resultados)
                        ListTile(
                          enabled: !_abriendo,
                          leading: CircleAvatar(
                            child: Text(usuario.nombre.isEmpty ? '?' : usuario.nombre[0].toUpperCase()),
                          ),
                          title: Text(usuario.nombre),
                          trailing: const Icon(Icons.chat_bubble_outline),
                          onTap: () => _abrir(usuario),
                        ),
                    ],
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
