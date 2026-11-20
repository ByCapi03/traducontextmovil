import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/datos/usuarios_admin_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/dominio/usuarios_admin.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/presentacion/widgets/insignia_estado.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Gestión de usuarios (HU-42): búsqueda, filtro por estado y paginación.
class PantallaUsuarios extends ConsumerStatefulWidget {
  const PantallaUsuarios({super.key});

  @override
  ConsumerState<PantallaUsuarios> createState() => _PantallaUsuariosState();
}

class _PantallaUsuariosState extends ConsumerState<PantallaUsuarios> {
  final _busqueda = TextEditingController();
  Timer? _esperaBusqueda;
  EstadoCuenta? _estado;
  List<UsuarioAdmin>? _usuarios;
  int _pagina = 1;
  int _total = 0;
  bool _hayMas = false;
  bool _cargandoMas = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_cargar());
  }

  @override
  void dispose() {
    _esperaBusqueda?.cancel();
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargar({bool siguiente = false}) async {
    final pagina = siguiente ? _pagina + 1 : 1;
    if (siguiente) setState(() => _cargandoMas = true);
    try {
      final resultado = await ref
          .read(usuariosAdminRepositorioProvider)
          .listar(pagina: pagina, busqueda: _busqueda.text, estado: _estado);
      if (!mounted) return;
      setState(() {
        _usuarios = [if (siguiente) ...?_usuarios, ...resultado.elementos];
        _pagina = resultado.pagina;
        _total = resultado.total;
        _hayMas = resultado.hayMas;
        _error = null;
      });
    } on ExcepcionApi catch (error) {
      if (mounted) setState(() => _error = MensajesError.de(error));
    } finally {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  void _alBuscar(String _) {
    _esperaBusqueda?.cancel();
    _esperaBusqueda = Timer(const Duration(milliseconds: 400), _cargar);
  }

  Future<void> _abrir(UsuarioAdmin usuario) async {
    final cambio = await context.push<bool>(Rutas.detalleUsuario(usuario.id));
    if (cambio ?? false) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return ContenidoAdaptable.lista(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Espaciados.md, Espaciados.md, Espaciados.md, 0),
            child: TextField(
              controller: _busqueda,
              onChanged: _alBuscar,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o correo',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Espaciados.md, vertical: Espaciados.xs),
            child: Row(
              children: [
                for (final estado in [null, ...EstadoCuenta.values])
                  Padding(
                    padding: const EdgeInsets.only(right: Espaciados.sm),
                    child: ChoiceChip(
                      label: Text(estado?.etiqueta ?? 'Todas'),
                      selected: _estado == estado,
                      onSelected: (_) {
                        setState(() => _estado = estado);
                        unawaited(_cargar());
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _lista()),
        ],
      ),
    );
  }

  Widget _lista() {
    final usuarios = _usuarios;
    if (usuarios == null && _error != null) {
      return VistaEstado(
        icono: Icons.cloud_off_outlined,
        esError: true,
        mensaje: _error!,
        textoAccion: 'Reintentar',
        alPresionar: _cargar,
      );
    }
    if (usuarios == null) return const Center(child: CircularProgressIndicator());
    if (usuarios.isEmpty) {
      return const VistaEstado(icono: Icons.people_outline, mensaje: 'No hay usuarios que coincidan.');
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(Espaciados.md, 0, Espaciados.md, Espaciados.md),
        itemCount: usuarios.length + 2,
        itemBuilder: (context, indice) {
          if (indice == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: Espaciados.xs),
              child: Text('$_total usuarios', style: Theme.of(context).textTheme.bodySmall),
            );
          }
          if (indice == usuarios.length + 1) {
            if (!_hayMas) return const SizedBox.shrink();
            return Center(
              child: _cargandoMas
                  ? const Padding(
                      padding: EdgeInsets.all(Espaciados.md),
                      child: CircularProgressIndicator(),
                    )
                  : TextButton(
                      onPressed: () => _cargar(siguiente: true),
                      child: const Text('Cargar más'),
                    ),
            );
          }
          final usuario = usuarios[indice - 1];
          return Card(
            child: ListTile(
              onTap: () => _abrir(usuario),
              leading: CircleAvatar(
                backgroundColor: ColoresApp.primario.withValues(alpha: 0.12),
                child: Text(
                  usuario.nombre.isEmpty ? '?' : usuario.nombre[0].toUpperCase(),
                  style: const TextStyle(color: ColoresApp.primario),
                ),
              ),
              title: Text(usuario.nombre, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${usuario.correo}\n${usuario.rol.nombre}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              trailing: InsigniaEstado(estado: usuario.estado),
            ),
          );
        },
      ),
    );
  }
}
