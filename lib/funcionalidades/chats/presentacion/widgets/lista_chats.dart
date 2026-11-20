import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/formato.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/chats/datos/chats_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/chats/dominio/chats.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Mis chats, del más reciente al más antiguo, con el último mensaje en mi
/// idioma y los no leídos. Se recarga al volver de un chat.
class ListaChats extends ConsumerStatefulWidget {
  const ListaChats({super.key});

  @override
  ConsumerState<ListaChats> createState() => _ListaChatsState();
}

class _ListaChatsState extends ConsumerState<ListaChats> {
  List<Chat>? _chats;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_cargar());
  }

  Future<void> _cargar() async {
    try {
      final chats = await ref.read(chatsRepositorioProvider).listar();
      if (mounted) {
        setState(() {
          _chats = chats;
          _error = null;
        });
      }
    } on ExcepcionApi catch (error) {
      if (mounted) setState(() => _error = MensajesError.de(error));
    }
  }

  Future<void> _abrir(String ruta) async {
    await context.push<void>(ruta);
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final chats = _chats;
    final textos = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Espaciados.md, Espaciados.md, Espaciados.md, 0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _abrir(Rutas.nuevoChat),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Nuevo chat'),
            ),
          ),
        ),
        Expanded(
          child: switch (chats) {
            null when _error != null => VistaEstado(
                icono: Icons.cloud_off_outlined,
                esError: true,
                mensaje: _error!,
                textoAccion: 'Reintentar',
                alPresionar: _cargar,
              ),
            null => const Center(child: CircularProgressIndicator()),
            _ => RefreshIndicator(
                onRefresh: _cargar,
                child: chats.isEmpty
                    ? ListView(
                        children: const [
                          VistaEstado(
                            icono: Icons.chat_bubble_outline,
                            mensaje: 'Aún no tienes chats. Cada persona lee los mensajes en su idioma.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(Espaciados.md),
                        itemCount: chats.length,
                        itemBuilder: (context, indice) {
                          final chat = chats[indice];
                          final ultimo = chat.ultimoMensaje;
                          return Card(
                            child: ListTile(
                              onTap: () => _abrir(Rutas.chat(chat.id)),
                              leading: CircleAvatar(
                                child: Text(
                                  chat.otroUsuario.nombre.isEmpty
                                      ? '?'
                                      : chat.otroUsuario.nombre[0].toUpperCase(),
                                ),
                              ),
                              title: Text(chat.otroUsuario.nombre, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                ultimo == null
                                    ? 'Sin mensajes'
                                    : '${ultimo.esMio ? 'Tú: ' : ''}${ultimo.texto}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (chat.fechaUltimoMensaje != null)
                                    Text(Formato.relativa(chat.fechaUltimoMensaje!), style: textos.bodySmall),
                                  if (chat.noLeidos > 0)
                                    Badge(
                                      label: Text('${chat.noLeidos}'),
                                      backgroundColor: ColoresApp.acento,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
          },
        ),
      ],
    );
  }
}
