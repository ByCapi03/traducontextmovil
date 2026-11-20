import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/formato.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/cuadricula_indicadores.dart';
import 'package:traducontextmovil/compartido/widgets/tarjeta_indicador.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/datos/usuarios_admin_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/dominio/usuarios_admin.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/presentacion/widgets/insignia_estado.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/usuario_actual.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Detalle de una cuenta con suspender/reactivar y cambio de rol (HU-42/HU-43).
/// Devuelve true al salir si hubo cambios, para recargar el listado.
class PantallaDetalleUsuario extends ConsumerStatefulWidget {
  const PantallaDetalleUsuario({super.key, required this.idUsuario});

  final int idUsuario;

  @override
  ConsumerState<PantallaDetalleUsuario> createState() => _PantallaDetalleUsuarioState();
}

class _PantallaDetalleUsuarioState extends ConsumerState<PantallaDetalleUsuario> {
  static const String _operacionNoPermitida =
      'No se puede realizar esta acción sobre esta cuenta (por ejemplo, sobre tu propia cuenta '
      'o si ya está en ese estado).';

  DetalleUsuarioAdmin? _detalle;
  List<Rol> _roles = const [];
  String? _error;
  bool _procesando = false;
  bool _huboCambios = false;

  UsuariosAdminRepositorio get _repositorio => ref.read(usuariosAdminRepositorioProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_cargar());
  }

  Future<void> _cargar() async {
    try {
      final resultados = await Future.wait([
        _repositorio.detalle(widget.idUsuario),
        _repositorio.roles(),
      ]);
      if (!mounted) return;
      setState(() {
        _detalle = resultados[0] as DetalleUsuarioAdmin;
        _roles = resultados[1] as List<Rol>;
        _error = null;
      });
    } on ExcepcionApi catch (error) {
      if (mounted) setState(() => _error = MensajesError.de(error));
    }
  }

  Future<bool> _confirmar(String titulo, String mensaje, String accion) async =>
      await showDialog<bool>(
        context: context,
        builder: (contexto) => AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(onPressed: () => Navigator.of(contexto).pop(true), child: Text(accion)),
          ],
        ),
      ) ??
      false;

  Future<void> _ejecutar(Future<DetalleUsuarioAdmin> Function() accion, String exito) async {
    setState(() => _procesando = true);
    try {
      final detalle = await accion();
      if (!mounted) return;
      setState(() {
        _detalle = detalle;
        _huboCambios = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exito)));
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(MensajesError.de(error, porCodigo: {400: _operacionNoPermitida}))),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _suspender(DetalleUsuarioAdmin detalle) async {
    final confirmado = await _confirmar(
      'Suspender cuenta',
      '${detalle.nombre} no podrá iniciar sesión y se cerrarán sus sesiones activas.',
      'Suspender',
    );
    if (confirmado) await _ejecutar(() => _repositorio.suspender(detalle.id), 'Cuenta suspendida.');
  }

  Future<void> _reactivar(DetalleUsuarioAdmin detalle) async {
    final confirmado = await _confirmar(
      'Reactivar cuenta',
      '${detalle.nombre} podrá volver a iniciar sesión.',
      'Reactivar',
    );
    if (confirmado) await _ejecutar(() => _repositorio.reactivar(detalle.id), 'Cuenta reactivada.');
  }

  Future<void> _cambiarRol(DetalleUsuarioAdmin detalle, int? idRol) async {
    if (idRol == null || idRol == detalle.rol.id) return;
    final rol = _roles.firstWhere((r) => r.id == idRol);
    final confirmado = await _confirmar(
      'Cambiar rol',
      '¿Asignar el rol ${rol.nombre} a ${detalle.nombre}? Sus permisos cambiarán al iniciar sesión.',
      'Cambiar',
    );
    if (confirmado) {
      await _ejecutar(() => _repositorio.cambiarRol(detalle.id, idRol), 'Rol actualizado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) context.pop(_huboCambios);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Detalle de usuario')),
        body: _cuerpo(),
      ),
    );
  }

  Widget _cuerpo() {
    final detalle = _detalle;
    if (detalle == null && _error != null) {
      return VistaEstado(
        icono: Icons.cloud_off_outlined,
        esError: true,
        mensaje: _error!,
        textoAccion: 'Reintentar',
        alPresionar: _cargar,
      );
    }
    if (detalle == null) return const Center(child: CircularProgressIndicator());

    final textos = Theme.of(context).textTheme;
    final esPropia = ref.watch(usuarioActualProvider)?.id == detalle.id;
    final estado = EstadoCuenta.desdeCodigo(detalle.estado);
    return ContenidoAdaptable.lista(
      child: ListView(
        padding: const EdgeInsets.all(Espaciados.md),
        children: [
          Text(detalle.nombre, style: textos.headlineMedium),
          Text(
            detalle.correo,
            style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
          ),
          const SizedBox(height: Espaciados.sm),
          Wrap(
            spacing: Espaciados.sm,
            runSpacing: Espaciados.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InsigniaEstado(estado: detalle.estado),
              Text('Alta: ${Formato.fecha(detalle.fechaCreacion)}', style: textos.bodySmall),
              Text(
                detalle.ultimoAcceso == null
                    ? 'Sin accesos'
                    : 'Último acceso: ${Formato.fechaHora(detalle.ultimoAcceso!)}',
                style: textos.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: Espaciados.md),
          CuadriculaIndicadores(
            children: [
              TarjetaIndicador(
                etiqueta: 'Traducciones',
                valor: '${detalle.totalTraducciones}',
                icono: Icons.translate,
              ),
              TarjetaIndicador(
                etiqueta: 'Documentos',
                valor: '${detalle.totalDocumentos}',
                icono: Icons.description_outlined,
              ),
              TarjetaIndicador(
                etiqueta: 'Conversaciones',
                valor: '${detalle.totalConversaciones}',
                icono: Icons.forum_outlined,
              ),
              TarjetaIndicador(
                etiqueta: 'Glosarios',
                valor: '${detalle.totalGlosarios}',
                icono: Icons.menu_book_outlined,
              ),
              TarjetaIndicador(
                etiqueta: 'Sesiones activas',
                valor: '${detalle.sesionesActivas}',
                icono: Icons.devices_outlined,
              ),
            ],
          ),
          const SizedBox(height: Espaciados.lg),
          if (esPropia)
            Text(
              'Esta es tu cuenta: no puedes suspenderla ni cambiar tu propio rol.',
              style: textos.bodySmall,
            )
          else ...[
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Rol'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _roles.any((r) => r.id == detalle.rol.id) ? detalle.rol.id : null,
                  isExpanded: true,
                  onChanged: _procesando ? null : (idRol) => _cambiarRol(detalle, idRol),
                  items: [
                    for (final rol in _roles)
                      DropdownMenuItem(value: rol.id, child: Text(rol.nombre)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Espaciados.md),
            if (estado == EstadoCuenta.suspendido)
              FilledButton.icon(
                onPressed: _procesando ? null : () => _reactivar(detalle),
                icon: const Icon(Icons.lock_open),
                label: const Text('Reactivar cuenta'),
              )
            else if (estado == EstadoCuenta.activo)
              OutlinedButton.icon(
                onPressed: _procesando ? null : () => _suspender(detalle),
                style: OutlinedButton.styleFrom(foregroundColor: ColoresApp.error),
                icon: const Icon(Icons.block),
                label: const Text('Suspender cuenta'),
              )
            else
              Text(
                'La cuenta aún no verificó su correo: no se puede suspender ni reactivar.',
                style: textos.bodySmall,
              ),
          ],
        ],
      ),
    );
  }
}
