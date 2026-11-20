import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/chats/datos/chats_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/chats/dominio/chats.dart';
import 'package:traducontextmovil/funcionalidades/chats/presentacion/proveedores/busqueda_usuarios.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Busca a otro usuario y abre (o crea) el chat con él. El backend busca
/// solo por nombre (no por correo): ver docs/pendientes_backend.md.
class PantallaNuevoChat extends ConsumerStatefulWidget {
  const PantallaNuevoChat({super.key});

  @override
  ConsumerState<PantallaNuevoChat> createState() => _PantallaNuevoChatState();
}

class _PantallaNuevoChatState extends ConsumerState<PantallaNuevoChat> {
  final _busqueda = TextEditingController();
  bool _abriendo = false;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
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
    final estado = ref.watch(busquedaUsuariosProvider);
    final busqueda = ref.read(busquedaUsuariosProvider.notifier);
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
                onChanged: busqueda.escribir,
                onSubmitted: (_) => busqueda.buscar(),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Buscar por nombre',
                  helperText: 'Escribe al menos ${BusquedaUsuarios.longitudMinima} letras.',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            if (estado is BusquedaEnCurso || _abriendo) const LinearProgressIndicator(),
            Expanded(
              child: switch (estado) {
                BusquedaInactiva() || BusquedaEnCurso() => const VistaEstado(
                    icono: Icons.person_search_outlined,
                    mensaje: 'Busca a la persona con la que quieres chatear.',
                  ),
                BusquedaFallida(:final mensaje) => VistaEstado(
                    icono: Icons.cloud_off_outlined,
                    esError: true,
                    mensaje: mensaje,
                    textoAccion: 'Reintentar',
                    alPresionar: busqueda.buscar,
                  ),
                BusquedaResuelta(usuarios: []) => const VistaEstado(
                    icono: Icons.person_off_outlined,
                    mensaje: 'No se encontraron usuarios con ese nombre.',
                  ),
                BusquedaResuelta(:final usuarios) => ListView(
                    children: [
                      for (final usuario in usuarios)
                        ListTile(
                          enabled: !_abriendo,
                          leading: CircleAvatar(
                            child: Text(usuario.nombre.isEmpty ? '?' : usuario.nombre[0].toUpperCase()),
                          ),
                          title: Text(usuario.nombre),
                          subtitle: usuario.correo == null ? null : Text(usuario.correo!),
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
