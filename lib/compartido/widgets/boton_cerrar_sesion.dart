import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';

class BotonCerrarSesion extends ConsumerWidget {
  const BotonCerrarSesion({super.key});

  Future<void> _confirmar(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmado ?? false) {
      await ref.read(sesionProvider.notifier).cerrarSesion();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Cerrar sesión',
      icon: const Icon(Icons.logout),
      onPressed: () => _confirmar(context, ref),
    );
  }
}
