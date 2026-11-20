import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/datos/catalogos_api.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/datos/glosarios_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/dominio/glosarios.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/presentacion/proveedores/acciones_glosarios.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/presentacion/widgets/dialogos_glosario.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Glosarios del usuario (HU-32): lista, crear, editar y eliminar. Cada
/// glosario abre su lista de términos.
class PantallaGlosarios extends ConsumerWidget {
  const PantallaGlosarios({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glosarios = ref.watch(glosariosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Glosarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editarGlosario(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo glosario'),
      ),
      body: SafeArea(
        child: switch (glosarios) {
          AsyncValue(:final value?) when value.isEmpty => const VistaEstado(
              icono: Icons.menu_book_outlined,
              mensaje: 'Todavía no tienes glosarios. Crea uno para fijar cómo se traducen tus términos.',
            ),
          AsyncValue(:final value?) => RefreshIndicator(
              onRefresh: () => ref.refresh(glosariosProvider.future),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(Espaciados.md, Espaciados.md, Espaciados.md, 96),
                itemCount: value.length,
                separatorBuilder: (_, _) => const SizedBox(height: Espaciados.sm),
                itemBuilder: (context, indice) => _TarjetaGlosario(glosario: value[indice]),
              ),
            ),
          AsyncValue(:final error?) => VistaEstado(
              icono: Icons.cloud_off_outlined,
              esError: true,
              mensaje: MensajesError.de(error, porDefecto: 'No se pudieron cargar tus glosarios.'),
              textoAccion: 'Reintentar',
              alPresionar: () => ref.invalidate(glosariosProvider),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// Abre el diálogo de crear (o editar [editado]) un glosario.
Future<void> editarGlosario(BuildContext context, WidgetRef ref, {Glosario? editado}) async {
  final idiomas = await ref.read(idiomasProvider.future).catchError((Object _) => <Never>[]);
  if (!context.mounted) return;
  final acciones = ref.read(accionesGlosariosProvider);
  Glosario? creado;
  final guardado = await mostrarDialogoGlosario(
    context,
    idiomas: idiomas,
    editado: editado,
    guardar: (datos) async {
      final resultado = await acciones.guardarGlosario(datos, editado: editado);
      creado = resultado.valor;
      return resultado.error;
    },
  );
  if (!guardado || !context.mounted) return;
  mostrarAviso(context, editado == null ? 'Glosario creado.' : 'Glosario actualizado.');
  final nuevo = creado;
  if (editado == null && nuevo != null) unawaited(context.push(Rutas.glosario(nuevo.id)));
}

void mostrarAviso(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensaje)));
}

/// Elimina tras confirmar. Devuelve true si se eliminó.
Future<bool> eliminarGlosario(BuildContext context, WidgetRef ref, Glosario glosario) async {
  final confirmado = await confirmarEliminacion(
    context,
    titulo: 'Eliminar glosario',
    mensaje: '¿Eliminar "${glosario.nombre}" y todos sus términos? No se puede deshacer.',
  );
  if (!confirmado || !context.mounted) return false;
  final error = await ref.read(accionesGlosariosProvider).eliminarGlosario(glosario);
  if (!context.mounted) return false;
  mostrarAviso(context, error ?? 'Glosario eliminado.');
  return error == null;
}

class _TarjetaGlosario extends ConsumerWidget {
  const _TarjetaGlosario({required this.glosario});

  final Glosario glosario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terminos = glosario.cantidadTerminos;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.menu_book_outlined),
        title: Text(glosario.nombre, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${glosario.parIdiomas} · $terminos ${terminos == 1 ? 'término' : 'términos'}'),
        onTap: () => context.push(Rutas.glosario(glosario.id)),
        trailing: PopupMenuButton<String>(
          tooltip: 'Opciones de ${glosario.nombre}',
          onSelected: (accion) => accion == 'editar'
              ? editarGlosario(context, ref, editado: glosario)
              : eliminarGlosario(context, ref, glosario),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'editar', child: Text('Editar')),
            PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}
