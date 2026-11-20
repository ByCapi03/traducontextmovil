import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/formato.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/datos/conversaciones_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/dominio/conversaciones.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Mis conversaciones con intérprete. Se recarga al volver de una.
class ListaConversaciones extends ConsumerStatefulWidget {
  const ListaConversaciones({super.key});

  @override
  ConsumerState<ListaConversaciones> createState() => _ListaConversacionesState();
}

class _ListaConversacionesState extends ConsumerState<ListaConversaciones> {
  List<Conversacion>? _conversaciones;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_cargar());
  }

  Future<void> _cargar() async {
    try {
      final lista = await ref.read(conversacionesRepositorioProvider).listar();
      if (mounted) {
        setState(() {
          _conversaciones = lista;
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
    final conversaciones = _conversaciones;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Espaciados.md, Espaciados.md, Espaciados.md, 0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _abrir(Rutas.nuevaConversacion),
              icon: const Icon(Icons.add),
              label: const Text('Nueva conversación'),
            ),
          ),
        ),
        Expanded(
          child: switch (conversaciones) {
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
                child: conversaciones.isEmpty
                    ? ListView(
                        children: const [
                          VistaEstado(
                            icono: Icons.record_voice_over_outlined,
                            mensaje: 'Inicia una conversación: cada intervención se traduce al '
                                'idioma de la otra persona.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(Espaciados.md),
                        itemCount: conversaciones.length,
                        itemBuilder: (context, indice) {
                          final conversacion = conversaciones[indice];
                          return Card(
                            child: ListTile(
                              onTap: () => _abrir(Rutas.conversacion(conversacion.id)),
                              leading: const Icon(Icons.forum_outlined, color: ColoresApp.primario),
                              title: Text(conversacion.idiomas, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                [
                                  ?conversacion.nombreEntorno,
                                  Formato.fechaHora(conversacion.fechaInicio),
                                ].join(' · '),
                              ),
                              trailing: Text(
                                conversacion.estado.etiqueta,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: conversacion.estado == EstadoConversacion.activa
                                          ? ColoresApp.exito
                                          : ColoresApp.textoSecundario,
                                    ),
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
