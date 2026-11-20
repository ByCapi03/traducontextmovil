import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';

/// En M0 solo muestra lo que devuelve GET /usuarios/me (sirve para verificarlo).
class PantallaPerfil extends ConsumerWidget {
  const PantallaPerfil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioActualProvider);
    if (usuario == null) return const SizedBox.shrink();
    final textos = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(Espaciados.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Espaciados.lg),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: ColoresApp.primario,
                  child: Text(
                    usuario.nombre.isNotEmpty ? usuario.nombre[0].toUpperCase() : '?',
                    style: textos.headlineMedium?.copyWith(color: ColoresApp.textoClaro),
                  ),
                ),
                const SizedBox(height: Espaciados.md),
                Text(usuario.nombre, style: textos.titleLarge, textAlign: TextAlign.center),
                Text(
                  usuario.correo,
                  style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
                ),
                const SizedBox(height: Espaciados.sm),
                Chip(label: Text(usuario.rol.nombre)),
              ],
            ),
          ),
        ),
        const SizedBox(height: Espaciados.md),
        Text(
          'La edición del perfil llegará en M2.',
          textAlign: TextAlign.center,
          style: textos.bodySmall,
        ),
      ],
    );
  }
}
