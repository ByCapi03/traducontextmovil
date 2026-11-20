import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/destino_notificacion.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/notificacion.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/presentacion/proveedores/bandeja_notificaciones.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/presentacion/widgets/tarjeta_notificacion.dart';
import 'package:traducontextmovil/navegacion/navegar.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Inicio del usuario: saludo y bandeja de notificaciones.
class PantallaInicio extends ConsumerStatefulWidget {
  const PantallaInicio({super.key});

  @override
  ConsumerState<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends ConsumerState<PantallaInicio> {
  bool _cargandoMas = false;

  ControladorBandeja get _bandeja => ref.read(bandejaNotificacionesProvider.notifier);

  void _avisar(String mensaje) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));

  Future<void> _abrir(Notificacion notificacion) async {
    final ruta = rutaParaNotificacion(notificacion.tipo, notificacion.datos);
    if (ruta != null) navegarA(context, ruta);
    try {
      await _bandeja.marcarLeida(notificacion);
    } on ExcepcionApi {
      // La marca de leída es secundaria: se reintenta en la próxima recarga.
    }
  }

  Future<void> _marcarTodas() async {
    try {
      await _bandeja.marcarTodasLeidas();
    } on ExcepcionApi catch (error) {
      if (mounted) _avisar(MensajesError.de(error));
    }
  }

  Future<void> _cargarMas() async {
    setState(() => _cargandoMas = true);
    try {
      await _bandeja.cargarMas();
    } on ExcepcionApi catch (error) {
      if (mounted) _avisar(MensajesError.de(error));
    } finally {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(usuarioActualProvider);
    final bandeja = ref.watch(bandejaNotificacionesProvider);
    final textos = Theme.of(context).textTheme;
    final estado = bandeja.valueOrNull;

    return ContenidoAdaptable.lista(
      child: RefreshIndicator(
        onRefresh: _bandeja.recargar,
        child: ListView(
          padding: const EdgeInsets.all(Espaciados.md),
          children: [
            Text('Hola, ${usuario?.nombre ?? ''}', style: textos.headlineMedium),
            Text(
              'Aquí verás los avisos de tus documentos y chats.',
              style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
            ),
            const SizedBox(height: Espaciados.lg),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Espaciados.sm,
              children: [
                Text(
                  estado == null || estado.noLeidas == 0
                      ? 'Notificaciones'
                      : 'Notificaciones (${estado.noLeidas} sin leer)',
                  style: textos.titleMedium,
                ),
                if ((estado?.noLeidas ?? 0) > 0)
                  TextButton(
                    onPressed: _marcarTodas,
                    child: const Text('Marcar todas como leídas'),
                  ),
              ],
            ),
            const SizedBox(height: Espaciados.sm),
            ...switch (bandeja) {
              AsyncValue(:final error?) when estado == null => [
                  VistaEstado(
                    icono: Icons.cloud_off_outlined,
                    esError: true,
                    mensaje: MensajesError.de(error),
                    textoAccion: 'Reintentar',
                    alPresionar: _bandeja.recargar,
                  ),
                ],
              _ when estado == null => [
                  const Padding(
                    padding: EdgeInsets.all(Espaciados.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              _ when estado.elementos.isEmpty => [
                  const VistaEstado(
                    icono: Icons.notifications_none,
                    mensaje: 'No tienes notificaciones.',
                  ),
                ],
              _ => [
                  for (final notificacion in estado.elementos)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Espaciados.sm),
                      child: TarjetaNotificacion(
                        key: ValueKey(notificacion.id),
                        notificacion: notificacion,
                        alTocar: () => _abrir(notificacion),
                      ),
                    ),
                  if (estado.hayMas)
                    Center(
                      child: _cargandoMas
                          ? const CircularProgressIndicator()
                          : TextButton(onPressed: _cargarMas, child: const Text('Cargar más')),
                    ),
                ],
            },
          ],
        ),
      ),
    );
  }
}
