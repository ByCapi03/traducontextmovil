import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/datos/glosarios_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/dominio/glosarios.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/presentacion/pantallas/pantalla_glosarios.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/presentacion/proveedores/acciones_glosarios.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/presentacion/widgets/dialogos_glosario.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Términos de un glosario: lista, agregar, editar y eliminar.
class PantallaGlosario extends ConsumerWidget {
  const PantallaGlosario({super.key, required this.idGlosario});

  final int idGlosario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalle = ref.watch(glosarioProvider(idGlosario));
    final glosario = detalle.valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(glosario?.nombre ?? 'Glosario', overflow: TextOverflow.ellipsis),
        actions: [
          if (glosario != null)
            PopupMenuButton<String>(
              tooltip: 'Opciones del glosario',
              onSelected: (accion) async {
                if (accion == 'editar') {
                  await editarGlosario(context, ref, editado: glosario);
                } else if (await eliminarGlosario(context, ref, glosario) && context.mounted) {
                  context.pop();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar glosario')),
                PopupMenuItem(value: 'eliminar', child: Text('Eliminar glosario')),
              ],
            ),
        ],
      ),
      floatingActionButton: glosario == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _editarTermino(context, ref, glosario),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo término'),
            ),
      body: SafeArea(
        child: switch (detalle) {
          AsyncValue(:final value?) => _Terminos(glosario: value),
          AsyncValue(:final error?) => VistaEstado(
              icono: Icons.cloud_off_outlined,
              esError: true,
              mensaje: MensajesError.de(error, porCodigo: {404: 'Este glosario ya no existe.'}),
              textoAccion: 'Reintentar',
              alPresionar: () => ref.invalidate(glosarioProvider(idGlosario)),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

Future<void> _editarTermino(BuildContext context, WidgetRef ref, Glosario glosario, {TerminoGlosario? editado}) async {
  final acciones = ref.read(accionesGlosariosProvider);
  final guardado = await mostrarDialogoTermino(
    context,
    editado: editado,
    guardar: (datos) => acciones.guardarTermino(glosario, datos, editado: editado),
  );
  if (guardado && context.mounted) {
    mostrarAviso(context, editado == null ? 'Término agregado.' : 'Término actualizado.');
  }
}

Future<void> _eliminarTermino(BuildContext context, WidgetRef ref, Glosario glosario, TerminoGlosario termino) async {
  final confirmado = await confirmarEliminacion(
    context,
    titulo: 'Eliminar término',
    mensaje: '¿Eliminar el término "${termino.terminoOrigen}"?',
  );
  if (!confirmado || !context.mounted) return;
  final error = await ref.read(accionesGlosariosProvider).eliminarTermino(glosario, termino);
  if (context.mounted) mostrarAviso(context, error ?? 'Término eliminado.');
}

class _Terminos extends ConsumerWidget {
  const _Terminos({required this.glosario});

  final Glosario glosario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final cabecera = Padding(
      padding: const EdgeInsets.only(bottom: Espaciados.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${glosario.nombreIdiomaOrigen ?? glosario.codigoIdiomaOrigen ?? '?'} → '
            '${glosario.nombreIdiomaDestino ?? glosario.codigoIdiomaDestino ?? '?'}',
            style: textos.titleSmall,
          ),
          if (glosario.descripcion != null) Text(glosario.descripcion!, style: textos.bodyMedium),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(Espaciados.md, Espaciados.md, Espaciados.md, 96),
      children: [
        cabecera,
        if (glosario.terminos.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: Espaciados.xl),
            child: Text(
              'Este glosario no tiene términos. Agrega uno para fijar su traducción.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final termino in glosario.terminos)
          Card(
            key: ValueKey(termino.id),
            child: ListTile(
              title: Text(termino.terminoOrigen),
              subtitle: Text(
                [
                  if (termino.conservarOriginal) 'Se conserva sin traducir' else '→ ${termino.traduccionPreferida ?? ''}',
                  if (termino.distinguirMayusculas) 'Distingue mayúsculas',
                  ?termino.nota,
                ].join('\n'),
                style: textos.bodySmall?.copyWith(color: ColoresApp.textoSecundario),
              ),
              isThreeLine: termino.nota != null || termino.distinguirMayusculas,
              onTap: () => _editarTermino(context, ref, glosario, editado: termino),
              trailing: IconButton(
                tooltip: 'Eliminar ${termino.terminoOrigen}',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _eliminarTermino(context, ref, glosario, termino),
              ),
            ),
          ),
      ],
    );
  }
}
