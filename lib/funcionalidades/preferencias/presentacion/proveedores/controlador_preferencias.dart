import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/funcionalidades/preferencias/datos/preferencias_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/preferencias/dominio/preferencias.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

/// Estado de la pantalla de preferencias: lo guardado en el servidor y el
/// formulario que se está editando.
class EstadoPreferencias {
  const EstadoPreferencias({
    this.cargando = true,
    this.guardando = false,
    this.guardado,
    this.formulario = const PreferenciasTraduccion(),
    this.mensaje,
    this.error,
    this.errorCarga,
  });

  final bool cargando;
  final bool guardando;

  /// null: el usuario aún no tiene preferencias guardadas.
  final PreferenciasTraduccion? guardado;
  final PreferenciasTraduccion formulario;
  final String? mensaje;
  final String? error;

  /// No se pudo leer lo guardado: la pantalla ofrece reintentar.
  final String? errorCarga;

  bool get hayCambios => formulario != guardado;

  EstadoPreferencias copiarCon({
    bool? cargando,
    bool? guardando,
    PreferenciasTraduccion? guardado,
    PreferenciasTraduccion? formulario,
    String? Function()? mensaje,
    String? Function()? error,
  }) =>
      EstadoPreferencias(
        cargando: cargando ?? this.cargando,
        guardando: guardando ?? this.guardando,
        guardado: guardado ?? this.guardado,
        formulario: formulario ?? this.formulario,
        mensaje: mensaje == null ? this.mensaje : mensaje(),
        error: error == null ? this.error : error(),
        errorCarga: errorCarga,
      );
}

/// Misma lógica que `preferencias.ts` de la web (HU-33).
class ControladorPreferencias extends AutoDisposeNotifier<EstadoPreferencias> {
  PreferenciasRepositorio get _repositorio => ref.read(preferenciasRepositorioProvider);

  @override
  EstadoPreferencias build() {
    // Tras build: cargar() lee y escribe el estado.
    unawaited(Future.microtask(cargar));
    return const EstadoPreferencias();
  }

  Future<void> cargar() async {
    state = const EstadoPreferencias();
    try {
      final guardado = await _repositorio.obtener();
      state = EstadoPreferencias(
        cargando: false,
        guardado: guardado,
        formulario: guardado ?? const PreferenciasTraduccion(),
      );
    } on ExcepcionApi catch (error) {
      state = EstadoPreferencias(
        cargando: false,
        errorCarga: MensajesError.de(error, porDefecto: 'No se pudieron cargar tus preferencias.'),
      );
    }
  }

  void editar(PreferenciasTraduccion formulario) =>
      state = state.copiarCon(formulario: formulario, mensaje: () => null, error: () => null);

  /// Al cambiar el idioma se quitan la variante y el glosario que ya no
  /// correspondan. [variantesValidas] y [glosariosValidos] son los del nuevo idioma.
  void cambiarIdioma(String? codigo, {required Set<int> variantesValidas, required Set<int> glosariosValidos}) {
    final actual = state.formulario;
    editar(
      actual.copiarCon(
        codigoIdiomaDestino: () => codigo,
        idVariante: () => variantesValidas.contains(actual.idVariante) ? actual.idVariante : null,
        idGlosario: () => glosariosValidos.contains(actual.idGlosario) ? actual.idGlosario : null,
      ),
    );
  }

  void descartar() {
    final guardado = state.guardado;
    if (guardado != null) editar(guardado);
  }

  Future<void> guardar() async {
    final formulario = state.formulario;
    if (formulario.idContexto == null || formulario.idTono == null) {
      state = state.copiarCon(error: () => 'Selecciona un contexto y un tono.', mensaje: () => null);
      return;
    }
    await _ejecutar(
      () => _repositorio.guardar(formulario),
      exito: 'Preferencias guardadas. Se aplicarán en tus próximas traducciones.',
      fallo: 'No se pudieron guardar las preferencias.',
    );
  }

  Future<void> restablecer() => _ejecutar(
        _repositorio.restablecer,
        exito: 'Preferencias restablecidas a los valores por defecto.',
        fallo: 'No se pudieron restablecer las preferencias.',
      );

  Future<void> _ejecutar(
    Future<PreferenciasTraduccion> Function() accion, {
    required String exito,
    required String fallo,
  }) async {
    state = state.copiarCon(guardando: true, mensaje: () => null, error: () => null);
    try {
      final guardado = await accion();
      state = EstadoPreferencias(cargando: false, guardado: guardado, formulario: guardado, mensaje: exito);
    } on ExcepcionApi catch (error) {
      state = state.copiarCon(
        guardando: false,
        error: () => MensajesError.de(
          error,
          // El backend valida que variante y glosario correspondan al idioma.
          porCodigo: {400: '$fallo Revisa que la variante y el glosario correspondan al idioma de destino.'},
          porDefecto: fallo,
        ),
      );
    }
  }
}

final controladorPreferenciasProvider =
    NotifierProvider.autoDispose<ControladorPreferencias, EstadoPreferencias>(ControladorPreferencias.new);
