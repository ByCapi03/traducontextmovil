import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/datos/notificaciones_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/notificacion.dart';

/// Estado de la bandeja: notificaciones cargadas hasta ahora y contador.
class EstadoBandeja {
  const EstadoBandeja({
    required this.elementos,
    required this.noLeidas,
    required this.pagina,
    required this.hayMas,
  });

  final List<Notificacion> elementos;
  final int noLeidas;
  final int pagina;
  final bool hayMas;

  EstadoBandeja copiar({List<Notificacion>? elementos, int? noLeidas, int? pagina, bool? hayMas}) =>
      EstadoBandeja(
        elementos: elementos ?? this.elementos,
        noLeidas: noLeidas ?? this.noLeidas,
        pagina: pagina ?? this.pagina,
        hayMas: hayMas ?? this.hayMas,
      );
}

/// Bandeja de notificaciones del usuario actual. Se recarga al cambiar de
/// cuenta y cuando llega un push (M3) con [recargar].
class ControladorBandeja extends AsyncNotifier<EstadoBandeja> {
  NotificacionesRepositorio get _repositorio => ref.read(notificacionesRepositorioProvider);

  @override
  Future<EstadoBandeja> build() async {
    ref.watch(usuarioActualProvider.select((usuario) => usuario?.id));
    return _primeraPagina();
  }

  Future<EstadoBandeja> _primeraPagina() async {
    final pagina = await _repositorio.listar();
    return EstadoBandeja(
      elementos: pagina.elementos,
      noLeidas: pagina.noLeidas,
      pagina: pagina.pagina,
      hayMas: pagina.hayMas,
    );
  }

  Future<void> recargar() async {
    state = await AsyncValue.guard(_primeraPagina);
  }

  Future<void> cargarMas() async {
    final actual = state.valueOrNull;
    if (actual == null || !actual.hayMas) return;
    final siguiente = await _repositorio.listar(pagina: actual.pagina + 1);
    final idsCargados = {for (final n in actual.elementos) n.id};
    state = AsyncData(
      actual.copiar(
        elementos: [
          ...actual.elementos,
          ...siguiente.elementos.where((n) => !idsCargados.contains(n.id)),
        ],
        noLeidas: siguiente.noLeidas,
        pagina: siguiente.pagina,
        hayMas: siguiente.hayMas,
      ),
    );
  }

  /// Marca como leída en local de inmediato y luego en el backend.
  Future<void> marcarLeida(Notificacion notificacion) async {
    final actual = state.valueOrNull;
    if (actual == null || notificacion.leida) return;
    state = AsyncData(
      actual.copiar(
        elementos: [
          for (final n in actual.elementos) n.id == notificacion.id ? n.marcadaLeida() : n,
        ],
        noLeidas: (actual.noLeidas - 1).clamp(0, actual.noLeidas),
      ),
    );
    await _repositorio.marcarLeida(notificacion.id);
  }

  Future<void> marcarTodasLeidas() async {
    await _repositorio.marcarTodasLeidas();
    final actual = state.valueOrNull;
    if (actual == null) return;
    state = AsyncData(
      actual.copiar(
        elementos: [for (final n in actual.elementos) n.marcadaLeida()],
        noLeidas: 0,
      ),
    );
  }
}

final bandejaNotificacionesProvider =
    AsyncNotifierProvider<ControladorBandeja, EstadoBandeja>(ControladorBandeja.new);

/// Contador para los distintivos (badge) de la navegación.
final notificacionesNoLeidasProvider = Provider<int>(
  (ref) => ref.watch(bandejaNotificacionesProvider).valueOrNull?.noLeidas ?? 0,
);
