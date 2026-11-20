import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/perfil/datos/perfil_api.dart';
import 'package:traducontextmovil/funcionalidades/perfil/presentacion/proveedores/acciones_foto_perfil.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Foto de perfil (o la inicial si no hay) con las acciones cambiar y quitar.
class AvatarPerfil extends ConsumerStatefulWidget {
  const AvatarPerfil({super.key, required this.nombre});

  final String nombre;

  @override
  ConsumerState<AvatarPerfil> createState() => _AvatarPerfilState();
}

class _AvatarPerfilState extends ConsumerState<AvatarPerfil> {
  bool _ocupado = false;

  Future<void> _ejecutar(Future<String?> Function(AccionesFotoPerfil acciones) accion) async {
    setState(() => _ocupado = true);
    final mensaje = await accion(ref.read(accionesFotoPerfilProvider));
    if (!mounted) return;
    setState(() => _ocupado = false);
    if (mensaje != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final foto = ref.watch(fotoPerfilProvider);
    final bytes = foto.valueOrNull;
    final cargando = _ocupado || foto.isLoading;
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: ColoresApp.primario,
          foregroundImage: bytes == null ? null : MemoryImage(bytes),
          child: cargando
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ColoresApp.textoClaro),
                )
              : Text(
                  widget.nombre.isNotEmpty ? widget.nombre[0].toUpperCase() : '?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: ColoresApp.textoClaro),
                ),
        ),
        const SizedBox(height: Espaciados.xs),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton.icon(
              onPressed: cargando ? null : () => _ejecutar((acciones) => acciones.cambiar()),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(bytes == null ? 'Agregar foto' : 'Cambiar foto'),
            ),
            if (bytes != null)
              TextButton.icon(
                onPressed: cargando ? null : () => _ejecutar((acciones) => acciones.quitar()),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Quitar foto'),
              ),
          ],
        ),
      ],
    );
  }
}
