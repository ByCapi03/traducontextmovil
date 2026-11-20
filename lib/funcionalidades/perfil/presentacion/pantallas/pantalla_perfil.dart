import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/validadores.dart';
import 'package:traducontextmovil/compartido/widgets/boton_cerrar_sesion.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
import 'package:traducontextmovil/funcionalidades/perfil/datos/perfil_api.dart';
import 'package:traducontextmovil/funcionalidades/perfil/presentacion/widgets/avatar_perfil.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Perfil del usuario y sección "Más" con el resto de módulos de la web.
/// En la carcasa de administración ([esAdministracion]) muestra en su lugar
/// planes y suscripciones (aún no existen en el backend).
class PantallaPerfil extends ConsumerWidget {
  const PantallaPerfil({super.key, this.esAdministracion = false});

  final bool esAdministracion;

  Future<void> _editarNombre(BuildContext context, WidgetRef ref, String actual) async {
    final nuevo = await showDialog<String>(
      context: context,
      builder: (contexto) => _DialogoNombre(nombreActual: actual),
    );
    if (nuevo == null || nuevo == actual) return;
    try {
      await ref.read(perfilApiProvider).actualizarNombre(nuevo);
      await ref.read(sesionProvider.notifier).recargarUsuario();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Nombre actualizado.')));
      }
    } on ExcepcionApi catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(MensajesError.de(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioActualProvider);
    if (usuario == null) return const SizedBox.shrink();
    final textos = Theme.of(context).textTheme;

    return ContenidoAdaptable.lista(
      child: ListView(
        padding: const EdgeInsets.all(Espaciados.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Espaciados.lg),
              child: Column(
                children: [
                  AvatarPerfil(nombre: usuario.nombre),
                  const SizedBox(height: Espaciados.sm),
                  Text(usuario.nombre, style: textos.titleLarge, textAlign: TextAlign.center),
                  Text(
                    usuario.correo,
                    textAlign: TextAlign.center,
                    style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
                  ),
                  const SizedBox(height: Espaciados.sm),
                  Chip(label: Text(usuario.rol.nombre)),
                  TextButton.icon(
                    onPressed: () => _editarNombre(context, ref, usuario.nombre),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar nombre'),
                  ),
                ],
              ),
            ),
          ),
          if (esAdministracion) ...[
            const SizedBox(height: Espaciados.lg),
            Text('Administración', style: textos.titleMedium),
            const SizedBox(height: Espaciados.sm),
            const Card(
              child: Column(
                children: [
                  _Opcion(
                    icono: Icons.workspace_premium_outlined,
                    titulo: 'Planes',
                    subtitulo: 'Próximamente',
                    ruta: Rutas.administracionPlanes,
                  ),
                  _Opcion(
                    icono: Icons.card_membership_outlined,
                    titulo: 'Suscripciones',
                    subtitulo: 'Próximamente',
                    ruta: Rutas.administracionSuscripciones,
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: Espaciados.lg),
            Text('Más', style: textos.titleMedium),
            const SizedBox(height: Espaciados.sm),
            const Card(
              child: Column(
                children: [
                  _Opcion(
                    icono: Icons.description_outlined,
                    titulo: 'Documentos',
                    subtitulo: 'Traduce archivos .docx, .xlsx y .pdf',
                    ruta: Rutas.documentos,
                  ),
                  _Opcion(
                    icono: Icons.menu_book_outlined,
                    titulo: 'Glosarios',
                    subtitulo: 'Términos personalizados',
                    ruta: Rutas.glosarios,
                  ),
                  _Opcion(
                    icono: Icons.tune,
                    titulo: 'Preferencias de traducción',
                    subtitulo: 'Contexto, tono y variante regional',
                    ruta: Rutas.preferencias,
                  ),
                  _Opcion(
                    icono: Icons.link,
                    titulo: 'Integraciones',
                    subtitulo: 'Google Meet y Zoom · Próximamente',
                    ruta: Rutas.integraciones,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Espaciados.lg),
          const Center(child: BotonCerrarSesion(conTexto: true)),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.ruta,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final String ruta;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, color: ColoresApp.primario),
      title: Text(titulo),
      subtitle: Text(subtitulo),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(ruta),
    );
  }
}

class _DialogoNombre extends StatefulWidget {
  const _DialogoNombre({required this.nombreActual});

  final String nombreActual;

  @override
  State<_DialogoNombre> createState() => _DialogoNombreState();
}

class _DialogoNombreState extends State<_DialogoNombre> {
  final _formulario = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.nombreActual);

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(Validadores.normalizarNombre(_nombre.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar nombre'),
      content: Form(
        key: _formulario,
        child: TextFormField(
          controller: _nombre,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre'),
          validator: Validadores.nombre,
          onFieldSubmitted: (_) => _guardar(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
