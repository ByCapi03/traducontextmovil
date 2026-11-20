import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/datos/conversaciones_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/dominio/conversaciones.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/presentacion/widgets/tarjeta_intervencion.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';
import 'package:traducontextmovil/nucleo/voz/modo_voz.dart';
import 'package:traducontextmovil/nucleo/voz/reconocimiento_voz.dart';
import 'package:traducontextmovil/nucleo/voz/sintesis_voz.dart';

/// Textos de los errores del reconocimiento (adaptados de la web al dispositivo).
const Map<ErrorReconocimiento, String> mensajesReconocimiento = {
  ErrorReconocimiento.sinSoporte:
      'Este dispositivo no tiene reconocimiento de voz disponible. Puedes seguir escribiendo la intervención.',
  ErrorReconocimiento.sinPermiso:
      'Sin permiso para usar el micrófono. Actívalo en los ajustes del dispositivo o escribe la intervención.',
  ErrorReconocimiento.sinMicrofono: 'No se pudo usar el micrófono del dispositivo.',
  ErrorReconocimiento.sinConexion: 'No hay conexión con el servicio de reconocimiento de voz.',
  ErrorReconocimiento.sinVoz: 'No se detectó voz. Sigue hablando o revisa el micrófono.',
  ErrorReconocimiento.noReconocido:
      'No se entendió lo que dijiste. Repítelo más despacio o más cerca del micrófono.',
  ErrorReconocimiento.sinAudio:
      'El micrófono no recibe sonido. Comprueba que otra aplicación no lo esté usando.',
  ErrorReconocimiento.idiomaNoSoportado: 'El reconocimiento de voz no admite el idioma de este participante.',
  ErrorReconocimiento.desconocido: 'No se pudo reconocer el audio. Vuelve a intentarlo.',
};

/// Conversación con intérprete (misma lógica que la web): se elige quién
/// habla, se escribe o se dicta (HU-25, reconocimiento del dispositivo en el
/// idioma de ese participante) y el backend devuelve la intervención traducida
/// al idioma del otro, que se puede leer en voz alta (HU-28, manual o
/// automática). Se puede reintentar una intervención que quedó en error, y
/// pausar, reanudar o finalizar la sesión.
class PantallaConversacion extends ConsumerStatefulWidget {
  const PantallaConversacion({super.key, required this.idConversacion});

  final int idConversacion;

  @override
  ConsumerState<PantallaConversacion> createState() => _PantallaConversacionState();
}

class _PantallaConversacionState extends ConsumerState<PantallaConversacion> {
  static const int longitudMaxima = 2000;
  static const int _noIdentificado = -1;

  final _texto = TextEditingController();
  Conversacion? _conversacion;
  List<Intervencion> _intervenciones = const [];
  int _hablante = 0;
  bool _enviando = false;
  final Set<int> _reintentando = {};
  String? _error;
  String? _errorEnvio;

  // Voz: dictado (HU-25) y lectura (HU-28).
  bool _escuchando = false;
  String _idiomaEscucha = '';
  String _parcial = '';
  String? _avisoMicrofono;
  String? _avisoVoz;
  int? _idReproduciendo;
  bool _cerrando = false;
  final List<(String, int)> _colaVoz = [];
  late final ReconocimientoVoz _reconocimiento = ref.read(reconocimientoVozProvider);
  late final SintesisVoz _sintesis = ref.read(sintesisVozProvider);

  ConversacionesRepositorio get _repositorio => ref.read(conversacionesRepositorioProvider);

  bool get _activa => _conversacion?.estado == EstadoConversacion.activa;

  @override
  void initState() {
    super.initState();
    // Se leen aquí: en dispose() ya no se puede usar ref.
    _reconocimiento;
    _sintesis;
    unawaited(_cargar());
  }

  @override
  void dispose() {
    _cerrando = true;
    unawaited(_reconocimiento.detener());
    unawaited(_sintesis.detener());
    _texto.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final conversacion = await _repositorio.obtener(widget.idConversacion);
      final intervenciones = await _repositorio.intervenciones(widget.idConversacion);
      if (!mounted) return;
      setState(() {
        _conversacion = conversacion;
        _intervenciones = intervenciones;
        if (_hablante == 0 && conversacion.participantes.isNotEmpty) {
          _hablante = conversacion.participantes.first.id;
        }
        _error = null;
      });
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(
          () => _error = MensajesError.de(
            error,
            porCodigo: {404: 'Esta conversación no existe o ya no tienes acceso.'},
          ),
        );
      }
    }
  }

  void _combinar(Intervencion intervencion) {
    final porId = {for (final i in _intervenciones) i.id: i}..[intervencion.id] = intervencion;
    setState(() => _intervenciones = porId.values.toList()..sort((a, b) => a.orden.compareTo(b.orden)));
  }

  Future<void> _enviar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _enviando) return;
    await _registrar(texto, _hablante, desdeVoz: false);
  }

  /// Envía una intervención escrita o dictada; solo la escrita limpia la caja.
  /// Lo dictado que no se pudo enviar pasa a la caja para no perderlo.
  Future<void> _registrar(String texto, int hablante, {required bool desdeVoz}) async {
    setState(() {
      _enviando = true;
      _errorEnvio = null;
      _avisoVoz = null;
    });
    try {
      final intervencion = await _repositorio.registrar(
        widget.idConversacion,
        texto: texto,
        idParticipante: hablante == _noIdentificado ? null : hablante,
      );
      if (!mounted) return;
      if (!desdeVoz) _texto.clear();
      _combinar(intervencion);
      unawaited(_reproducirAutomatica(intervencion));
    } on ExcepcionApi catch (error) {
      if (!mounted) return;
      setState(
        () => _errorEnvio = MensajesError.de(
          error,
          porCodigo: {400: 'No se pudo enviar: la conversación no está activa o el texto no es válido.'},
        ),
      );
      // Como en la web: ante un fallo del servidor puede haberse guardado igual.
      if (error.sinConexion || (error.codigoEstado ?? 0) >= 500) {
        await _sincronizar();
      } else if (desdeVoz) {
        _conservarTextoVoz(texto);
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
        _procesarColaVoz();
      }
    }
  }

  // --- Dictado (HU-25) ---

  Future<void> _alternarMicrofono() async {
    if (_escuchando) {
      await _detenerMicrofono();
      return;
    }
    await _iniciarMicrofono();
  }

  Future<void> _detenerMicrofono({String? aviso}) async {
    await _reconocimiento.detener();
    if (mounted) {
      setState(() {
        _escuchando = false;
        _parcial = '';
        _avisoMicrofono = aviso;
      });
    }
  }

  Future<void> _iniciarMicrofono() async {
    if (!_activa) return;
    // El reconocimiento necesita el idioma de quien habla.
    if (_hablante == _noIdentificado) {
      await _detenerMicrofono(
        aviso: 'Para dictar, elige quién habla: el reconocimiento de voz necesita su idioma.',
      );
      return;
    }
    final participante = _conversacion?.participantes.where((p) => p.id == _hablante).firstOrNull;
    if (participante == null) return;
    // Evita transcribir la voz sintetizada que esté sonando.
    await _detenerReproduccion();
    setState(() {
      _avisoMicrofono = null;
      _parcial = '';
    });
    try {
      final idioma = await _reconocimiento.iniciar(
        participante.codigoIdioma ?? '',
        OyentesReconocimiento(
          alParcial: (texto) {
            if (mounted) setState(() => _parcial = texto);
          },
          alFinal: _encolarVoz,
          alError: (error) {
            if (mounted) setState(() => _avisoMicrofono = mensajesReconocimiento[error]);
          },
          alDetenerse: () {
            if (mounted) {
              setState(() {
                _escuchando = false;
                _parcial = '';
              });
            }
          },
        ),
      );
      if (mounted) {
        setState(() {
          _escuchando = true;
          _idiomaEscucha = idioma;
        });
      }
    } on ExcepcionReconocimiento catch (excepcion) {
      if (mounted) {
        setState(() {
          _escuchando = false;
          _avisoMicrofono = mensajesReconocimiento[excepcion.error];
        });
      }
    }
  }

  /// Cambia quién habla; si el micrófono está activo, se reinicia con su idioma.
  void _cambiarHablante(int id) {
    setState(() => _hablante = id);
    if (_escuchando) unawaited(_iniciarMicrofono());
  }

  /// Cada frase final dictada se envía como intervención del hablante elegido, en orden.
  void _encolarVoz(String texto) {
    if (!mounted || _hablante == _noIdentificado) return;
    final recortado = texto.length > longitudMaxima ? texto.substring(0, longitudMaxima) : texto;
    setState(() => _avisoMicrofono = null);
    _colaVoz.add((recortado, _hablante));
    _procesarColaVoz();
  }

  void _procesarColaVoz() {
    if (_enviando || !_activa || _colaVoz.isEmpty) return;
    final (texto, hablante) = _colaVoz.removeAt(0);
    unawaited(_registrar(texto, hablante, desdeVoz: true));
  }

  void _conservarTextoVoz(String texto) {
    final actual = _texto.text.trim();
    final unido = actual.isEmpty ? texto : '$actual $texto';
    _texto.text = unido.length > longitudMaxima ? unido.substring(0, longitudMaxima) : unido;
  }

  // --- Lectura en voz alta (HU-28) ---

  Future<void> _alternarLectura(Intervencion intervencion) async {
    if (_idReproduciendo == intervencion.id) {
      await _detenerReproduccion();
      return;
    }
    setState(() => _avisoVoz = null);
    // Evita que el micrófono transcriba la propia voz sintetizada.
    if (_escuchando) {
      await _detenerMicrofono(aviso: 'Se detuvo el micrófono para no transcribir la voz reproducida.');
    }
    await _reproducir(intervencion);
  }

  /// En modo automático se lee cada traducción recibida, salvo con el
  /// micrófono encendido o la sesión inactiva. Una lectura nueva corta la anterior.
  Future<void> _reproducirAutomatica(Intervencion intervencion) async {
    if (ref.read(modoVozProvider) != ModoVoz.automatica ||
        !intervencion.puedeLeerse ||
        !_activa ||
        _escuchando) {
      return;
    }
    await _reproducir(intervencion);
  }

  Future<void> _reproducir(Intervencion intervencion) async {
    if (!intervencion.puedeLeerse) return;
    if (!_activa) {
      setState(() => _avisoVoz = 'La reproducción por voz solo está disponible con la sesión activa.');
      return;
    }
    final resultado = await _sintesis.reproducir(
      intervencion.textoTraducido!,
      intervencion.codigoIdiomaDestino ?? '',
      alTerminar: () {
        if (mounted && !_cerrando && _idReproduciendo == intervencion.id) {
          setState(() => _idReproduciendo = null);
        }
      },
    );
    if (!mounted) return;
    setState(() {
      switch (resultado) {
        case ResultadoVoz.reproduciendo:
          _idReproduciendo = intervencion.id;
        case ResultadoVoz.sinSoporte:
          _avisoVoz = 'Este dispositivo no puede leer el texto en voz alta.';
        case ResultadoVoz.sinVoz:
          final idioma = intervencion.nombreIdiomaDestino ?? intervencion.codigoIdiomaDestino ?? 'este idioma';
          _avisoVoz = 'No hay una voz disponible para $idioma en este dispositivo.';
        case ResultadoVoz.sinTexto:
          break;
      }
    });
  }

  Future<void> _detenerReproduccion() async {
    await _sintesis.detener();
    if (mounted && _idReproduciendo != null) setState(() => _idReproduciendo = null);
  }

  /// Con la sesión pausada o finalizada no se dicta ni se lee; lo dictado
  /// pendiente pasa a la caja de texto.
  Future<void> _detenerVozPorEstado() async {
    await _reconocimiento.detener();
    await _sintesis.detener();
    if (!mounted) return;
    setState(() {
      _escuchando = false;
      _parcial = '';
      _idReproduciendo = null;
      for (final (texto, _) in _colaVoz) {
        _conservarTextoVoz(texto);
      }
      _colaVoz.clear();
    });
  }

  Future<void> _sincronizar() async {
    try {
      final ultimo = _intervenciones.isEmpty ? null : _intervenciones.last.id;
      final nuevas = await _repositorio.intervenciones(widget.idConversacion, despuesDe: ultimo);
      if (mounted) nuevas.forEach(_combinar);
    } on ExcepcionApi {
      // Se verá al volver a abrir la conversación.
    }
  }

  Future<void> _reintentar(Intervencion intervencion) async {
    setState(() => _reintentando.add(intervencion.id));
    try {
      final corregida = await _repositorio.reintentar(widget.idConversacion, intervencion.id);
      if (!mounted) return;
      _combinar(corregida);
      unawaited(_reproducirAutomatica(corregida));
    } on ExcepcionApi catch (error) {
      if (mounted) _avisar('No se pudo reintentar la traducción. ${MensajesError.de(error)}');
    } finally {
      if (mounted) setState(() => _reintentando.remove(intervencion.id));
    }
  }

  Future<void> _cambiarEstado(String accion) async {
    if (accion == 'finalizar') {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (contexto) => AlertDialog(
          title: const Text('Finalizar conversación'),
          content: const Text('No podrás añadir más intervenciones. ¿Quieres finalizarla?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(true),
              child: const Text('Finalizar'),
            ),
          ],
        ),
      );
      if (!(confirmado ?? false)) return;
    }
    try {
      final id = widget.idConversacion;
      final conversacion = await switch (accion) {
        'pausar' => _repositorio.pausar(id),
        'reanudar' => _repositorio.reanudar(id),
        _ => _repositorio.finalizar(id),
      };
      if (mounted) setState(() => _conversacion = conversacion);
      if (conversacion.estado != EstadoConversacion.activa) await _detenerVozPorEstado();
    } on ExcepcionApi catch (error) {
      if (mounted) _avisar(MensajesError.de(error, porCodigo: {400: 'La conversación ya cambió de estado.'}));
      await _cargar();
    }
  }

  Future<void> _copiar(String texto) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (mounted) _avisar('Traducción copiada.');
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final conversacion = _conversacion;
    return Scaffold(
      appBar: AppBar(
        title: Text(conversacion?.idiomas ?? 'Conversación', overflow: TextOverflow.ellipsis),
        actions: [
          if (conversacion != null && conversacion.estado == EstadoConversacion.activa) const _MenuModoVoz(),
          if (conversacion != null && conversacion.estado != EstadoConversacion.finalizada)
            PopupMenuButton<String>(
              tooltip: 'Opciones de la conversación',
              onSelected: _cambiarEstado,
              itemBuilder: (context) => [
                if (conversacion.estado == EstadoConversacion.activa)
                  const PopupMenuItem(value: 'pausar', child: Text('Pausar'))
                else
                  const PopupMenuItem(value: 'reanudar', child: Text('Reanudar')),
                const PopupMenuItem(value: 'finalizar', child: Text('Finalizar')),
              ],
            ),
        ],
      ),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    final conversacion = _conversacion;
    if (conversacion == null && _error != null) {
      return VistaEstado(
        icono: Icons.cloud_off_outlined,
        esError: true,
        mensaje: _error!,
        textoAccion: 'Reintentar',
        alPresionar: _cargar,
      );
    }
    if (conversacion == null) return const Center(child: CircularProgressIndicator());
    final textos = Theme.of(context).textTheme;
    final activa = conversacion.estado == EstadoConversacion.activa;
    final invertidas = _intervenciones.reversed.toList();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Anchos.contenido),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: ColoresApp.fondo,
                padding: const EdgeInsets.symmetric(horizontal: Espaciados.md, vertical: Espaciados.sm),
                child: Text(
                  [
                    conversacion.estado.etiqueta,
                    ?conversacion.nombreEntorno,
                    ?conversacion.nombreContexto,
                  ].join(' · '),
                  style: textos.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: invertidas.isEmpty
                    ? const VistaEstado(
                        icono: Icons.record_voice_over_outlined,
                        mensaje: 'Elige quién habla y escribe lo que dice. Se traducirá al idioma '
                            'del otro participante.',
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(Espaciados.md),
                        itemCount: invertidas.length,
                        itemBuilder: (context, indice) {
                          final intervencion = invertidas[indice];
                          return TarjetaIntervencion(
                            key: ValueKey(intervencion.id),
                            intervencion: intervencion,
                            reintentando: _reintentando.contains(intervencion.id),
                            alReintentar:
                                activa && intervencion.puedeReintentar ? () => _reintentar(intervencion) : null,
                            alCopiar: _copiar,
                            leyendo: _idReproduciendo == intervencion.id,
                            alLeer: activa && intervencion.puedeLeerse ? () => _alternarLectura(intervencion) : null,
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              if (!activa)
                Padding(
                  padding: const EdgeInsets.all(Espaciados.md),
                  child: Text(
                    conversacion.estado == EstadoConversacion.pausada
                        ? 'La conversación está pausada. Reanúdala desde el menú para continuar.'
                        : 'La conversación finalizó. Solo puedes consultarla.',
                    textAlign: TextAlign.center,
                    style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
                  ),
                )
              else
                _Compositor(
                  participantes: conversacion.participantes,
                  hablante: _hablante,
                  idNoIdentificado: _noIdentificado,
                  alCambiarHablante: _cambiarHablante,
                  texto: _texto,
                  longitudMaxima: longitudMaxima,
                  enviando: _enviando,
                  error: _errorEnvio,
                  alEnviar: _enviar,
                  escuchando: _escuchando,
                  idiomaEscucha: _idiomaEscucha,
                  parcial: _parcial,
                  aviso: _avisoMicrofono ?? _avisoVoz,
                  alMicrofono: _alternarMicrofono,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Compositor extends StatelessWidget {
  const _Compositor({
    required this.participantes,
    required this.hablante,
    required this.idNoIdentificado,
    required this.alCambiarHablante,
    required this.texto,
    required this.longitudMaxima,
    required this.enviando,
    required this.error,
    required this.alEnviar,
    required this.escuchando,
    required this.idiomaEscucha,
    required this.parcial,
    required this.aviso,
    required this.alMicrofono,
  });

  final List<Participante> participantes;
  final int hablante;
  final int idNoIdentificado;
  final ValueChanged<int> alCambiarHablante;
  final TextEditingController texto;
  final int longitudMaxima;
  final bool enviando;
  final String? error;
  final VoidCallback alEnviar;
  final bool escuchando;
  final String idiomaEscucha;
  final String parcial;
  final String? aviso;
  final VoidCallback alMicrofono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Espaciados.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Espaciados.sm,
            runSpacing: Espaciados.xs,
            children: [
              for (final participante in participantes)
                ChoiceChip(
                  label: Text('${participante.nombre} (${participante.nombreIdioma ?? '?'})'),
                  selected: hablante == participante.id,
                  onSelected: enviando ? null : (_) => alCambiarHablante(participante.id),
                ),
              ChoiceChip(
                label: const Text('No identificado'),
                selected: hablante == idNoIdentificado,
                onSelected: enviando ? null : (_) => alCambiarHablante(idNoIdentificado),
              ),
            ],
          ),
          if (escuchando) _IndicadorEscucha(idioma: idiomaEscucha, parcial: parcial),
          if (aviso != null)
            Padding(
              padding: const EdgeInsets.only(top: Espaciados.xs),
              child: Text(
                aviso!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColoresApp.textoSecundario),
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: Espaciados.xs),
              child: Text(
                error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColoresApp.error),
              ),
            ),
          const SizedBox(height: Espaciados.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: escuchando ? 'Detener micrófono' : 'Dictar con el micrófono',
                color: escuchando ? ColoresApp.error : null,
                onPressed: alMicrofono,
                icon: Icon(escuchando ? Icons.mic : Icons.mic_none),
              ),
              Expanded(
                child: TextField(
                  controller: texto,
                  enabled: !enviando,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: longitudMaxima,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Escribe la intervención',
                    counterText: '',
                  ),
                  onSubmitted: (_) => alEnviar(),
                ),
              ),
              const SizedBox(width: Espaciados.sm),
              IconButton.filled(
                tooltip: 'Enviar intervención',
                onPressed: enviando ? null : alEnviar,
                icon: enviando
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Te estoy escuchando…" con el idioma de reconocimiento y el texto parcial.
class _IndicadorEscucha extends StatelessWidget {
  const _IndicadorEscucha({required this.idioma, required this.parcial});

  final String idioma;
  final String parcial;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: Espaciados.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq, size: 16, color: ColoresApp.error),
              const SizedBox(width: Espaciados.xs),
              Flexible(
                child: Text(
                  idioma.isEmpty ? 'Te estoy escuchando…' : 'Te estoy escuchando… ($idioma)',
                  style: textos.bodySmall?.copyWith(color: ColoresApp.error),
                ),
              ),
            ],
          ),
          if (parcial.isNotEmpty)
            Text(
              parcial,
              style: textos.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

/// Menú de la reproducción por voz: Manual o Automática (se guarda en el dispositivo).
class _MenuModoVoz extends ConsumerWidget {
  const _MenuModoVoz();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modo = ref.watch(modoVozProvider);
    return PopupMenuButton<ModoVoz>(
      tooltip: 'Reproducción por voz: ${modo.etiqueta}',
      icon: Icon(modo == ModoVoz.automatica ? Icons.volume_up : Icons.volume_up_outlined),
      onSelected: (nuevo) => ref.read(modoVozProvider.notifier).cambiar(nuevo),
      itemBuilder: (context) => [
        for (final opcion in ModoVoz.values)
          CheckedPopupMenuItem(
            value: opcion,
            checked: opcion == modo,
            child: Text('Lectura ${opcion.etiqueta.toLowerCase()}'),
          ),
      ],
    );
  }
}
