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

/// Conversación con intérprete (misma lógica que la web, solo texto): se
/// elige quién habla, se envía la intervención y el backend la devuelve
/// traducida al idioma del otro participante. Se puede reintentar una
/// intervención que quedó en error, y pausar, reanudar o finalizar la sesión.
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

  ConversacionesRepositorio get _repositorio => ref.read(conversacionesRepositorioProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_cargar());
  }

  @override
  void dispose() {
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
    setState(() {
      _enviando = true;
      _errorEnvio = null;
    });
    try {
      final intervencion = await _repositorio.registrar(
        widget.idConversacion,
        texto: texto,
        idParticipante: _hablante == _noIdentificado ? null : _hablante,
      );
      if (!mounted) return;
      _texto.clear();
      _combinar(intervencion);
    } on ExcepcionApi catch (error) {
      if (!mounted) return;
      setState(
        () => _errorEnvio = MensajesError.de(
          error,
          porCodigo: {400: 'No se pudo enviar: la conversación no está activa o el texto no es válido.'},
        ),
      );
      // Como en la web: ante un fallo del servidor puede haberse guardado igual.
      if (error.sinConexion || (error.codigoEstado ?? 0) >= 500) await _sincronizar();
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
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
      _combinar(await _repositorio.reintentar(widget.idConversacion, intervencion.id));
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
                  alCambiarHablante: (id) => setState(() => _hablante = id),
                  texto: _texto,
                  longitudMaxima: longitudMaxima,
                  enviando: _enviando,
                  error: _errorEnvio,
                  alEnviar: _enviar,
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
