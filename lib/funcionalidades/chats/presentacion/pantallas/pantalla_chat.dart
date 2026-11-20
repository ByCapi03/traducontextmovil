import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/datos/catalogos_api.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/dominio/idioma.dart';
import 'package:traducontextmovil/funcionalidades/chats/datos/chats_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/chats/dominio/chats.dart';
import 'package:traducontextmovil/funcionalidades/chats/presentacion/widgets/burbuja_mensaje.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/presentacion/proveedores/servicio_push.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Intervalo del refresco (el backend no tiene WebSocket).
final intervaloRefrescoChatProvider = Provider<Duration>((ref) => const Duration(seconds: 4));

/// Chat entre usuarios con traducción automática a mi idioma de lectura.
/// Se refresca periódicamente solo mientras esta pantalla está abierta y la
/// app en primer plano.
class PantallaChat extends ConsumerStatefulWidget {
  const PantallaChat({super.key, required this.idChat});

  final int idChat;

  @override
  ConsumerState<PantallaChat> createState() => _PantallaChatState();
}

class _PantallaChatState extends ConsumerState<PantallaChat> {
  static const int longitudMaxima = 2000;

  final _texto = TextEditingController();
  late final AppLifecycleListener _ciclo;
  Timer? _temporizador;
  Chat? _chat;
  List<MensajeChat> _mensajes = const [];
  bool _hayAnteriores = false;
  bool _cargandoAnteriores = false;
  bool _refrescando = false;
  bool _enviando = false;
  String? _error;

  /// Se lee en initState: en dispose() ya no se puede usar ref.
  late final ServicioPush _push = ref.read(servicioPushProvider);

  ChatsRepositorio get _repositorio => ref.read(chatsRepositorioProvider);

  @override
  void initState() {
    super.initState();
    _ciclo = AppLifecycleListener(onResume: _iniciarRefresco, onPause: _detenerRefresco);
    // Con este chat en pantalla no se muestran sus notificaciones locales.
    _push.alAbrirChat(widget.idChat);
    unawaited(_cargar());
  }

  @override
  void dispose() {
    _push.alCerrarChat(widget.idChat);
    _detenerRefresco();
    _ciclo.dispose();
    _texto.dispose();
    super.dispose();
  }

  void _iniciarRefresco() {
    _temporizador?.cancel();
    _temporizador = Timer.periodic(ref.read(intervaloRefrescoChatProvider), (_) => _refrescar());
  }

  void _detenerRefresco() {
    _temporizador?.cancel();
    _temporizador = null;
  }

  Future<void> _cargar() async {
    try {
      final chat = await _repositorio.obtener(widget.idChat);
      final pagina = await _repositorio.mensajes(widget.idChat);
      if (!mounted) return;
      setState(() {
        _chat = chat;
        _mensajes = pagina.elementos;
        _hayAnteriores = pagina.hayMas;
        _error = null;
      });
      await _marcarLeidos();
      _iniciarRefresco();
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(
          () => _error = MensajesError.de(error, porCodigo: {404: 'Este chat no existe o ya no tienes acceso.'}),
        );
      }
    }
  }

  /// Pide los mensajes nuevos y vuelve a pedir los que seguían pendientes
  /// de traducción (para mostrar su texto traducido).
  Future<void> _refrescar() async {
    if (_refrescando || _chat == null) return;
    _refrescando = true;
    try {
      final pendientes = _mensajes.where((m) => m.pendiente).map((m) => m.id);
      final despuesDe = pendientes.isNotEmpty
          ? pendientes.reduce((a, b) => a < b ? a : b) - 1
          : (_mensajes.isEmpty ? 0 : _mensajes.last.id);
      final pagina = await _repositorio.mensajes(widget.idChat, despuesDe: despuesDe);
      if (!mounted || pagina.elementos.isEmpty) return;
      final hayNuevosAjenos = pagina.elementos.any(
        (nuevo) => !nuevo.esMio && !_mensajes.any((actual) => actual.id == nuevo.id),
      );
      _combinar(pagina.elementos);
      if (hayNuevosAjenos) await _marcarLeidos();
    } on ExcepcionApi {
      // Sin conexión momentánea: se reintenta en el siguiente ciclo.
    } finally {
      _refrescando = false;
    }
  }

  void _combinar(List<MensajeChat> nuevos) {
    final porId = {for (final mensaje in _mensajes) mensaje.id: mensaje};
    for (final mensaje in nuevos) {
      porId[mensaje.id] = mensaje;
    }
    setState(() => _mensajes = porId.values.toList()..sort((a, b) => a.id.compareTo(b.id)));
  }

  /// Marca como leído el último mensaje recibido (y con él los anteriores).
  Future<void> _marcarLeidos() async {
    MensajeChat? ultimoAjeno;
    for (final mensaje in _mensajes.reversed) {
      if (!mensaje.esMio) {
        ultimoAjeno = mensaje;
        break;
      }
    }
    if (ultimoAjeno == null) return;
    try {
      await _repositorio.marcarLeido(widget.idChat, ultimoAjeno.id);
    } on ExcepcionApi {
      // Secundario: se marcará en el siguiente refresco.
    }
  }

  Future<void> _cargarAnteriores() async {
    if (_mensajes.isEmpty) return;
    setState(() => _cargandoAnteriores = true);
    try {
      final pagina = await _repositorio.mensajes(widget.idChat, antesDe: _mensajes.first.id);
      if (!mounted) return;
      _combinar(pagina.elementos);
      setState(() => _hayAnteriores = pagina.hayMas);
    } on ExcepcionApi catch (error) {
      if (mounted) _avisar(MensajesError.de(error));
    } finally {
      if (mounted) setState(() => _cargandoAnteriores = false);
    }
  }

  Future<void> _enviar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      final mensaje = await _repositorio.enviar(widget.idChat, texto);
      if (!mounted) return;
      _texto.clear();
      _combinar([mensaje]);
    } on ExcepcionApi catch (error) {
      if (mounted) {
        _avisar(
          MensajesError.de(
            error,
            porCodigo: {
              429: 'Estás enviando mensajes muy rápido. Espera un momento.',
              400: 'No se pudo enviar el mensaje.',
            },
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _cambiarIdioma(List<Idioma> idiomas) async {
    final chat = _chat;
    if (chat == null) return;
    final codigo = await showDialog<String>(
      context: context,
      builder: (contexto) => SimpleDialog(
        title: const Text('Leer este chat en'),
        children: [
          for (final idioma in idiomas)
            SimpleDialogOption(
              onPressed: () => Navigator.of(contexto).pop(idioma.codigo),
              child: Row(
                children: [
                  Expanded(child: Text(idioma.nombre)),
                  if (idioma.codigo == chat.codigoIdiomaLectura)
                    const Icon(Icons.check, color: ColoresApp.primario),
                ],
              ),
            ),
        ],
      ),
    );
    if (codigo == null || codigo == chat.codigoIdiomaLectura) return;
    try {
      final actualizado = await _repositorio.cambiarIdiomaLectura(widget.idChat, codigo);
      final pagina = await _repositorio.mensajes(widget.idChat);
      if (!mounted) return;
      setState(() {
        _chat = actualizado;
        _mensajes = pagina.elementos;
        _hayAnteriores = pagina.hayMas;
      });
      _avisar('Ahora lees este chat en ${actualizado.nombreIdiomaLectura}.');
    } on ExcepcionApi catch (error) {
      if (mounted) _avisar(MensajesError.de(error));
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final chat = _chat;
    final idiomas = ref.watch(idiomasProvider).valueOrNull ?? const <Idioma>[];
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chat?.otroUsuario.nombre ?? 'Chat', overflow: TextOverflow.ellipsis),
            if (chat != null)
              Text(
                'Lees en ${chat.nombreIdiomaLectura}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          if (chat != null && idiomas.isNotEmpty)
            IconButton(
              tooltip: 'Cambiar idioma de lectura',
              icon: const Icon(Icons.translate),
              onPressed: () => _cambiarIdioma(idiomas),
            ),
        ],
      ),
      body: _cuerpo(idiomas),
    );
  }

  Widget _cuerpo(List<Idioma> idiomas) {
    if (_chat == null && _error != null) {
      return VistaEstado(
        icono: Icons.cloud_off_outlined,
        esError: true,
        mensaje: _error!,
        textoAccion: 'Reintentar',
        alPresionar: _cargar,
      );
    }
    if (_chat == null) return const Center(child: CircularProgressIndicator());
    final invertidos = _mensajes.reversed.toList();
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Anchos.contenido),
          child: Column(
            children: [
              Expanded(
                child: invertidos.isEmpty
                    ? const VistaEstado(
                        icono: Icons.chat_bubble_outline,
                        mensaje: 'Escribe el primer mensaje. Se traducirá al idioma de la otra persona.',
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(Espaciados.md),
                        itemCount: invertidos.length + (_hayAnteriores ? 1 : 0),
                        itemBuilder: (context, indice) {
                          if (indice == invertidos.length) {
                            return Center(
                              child: _cargandoAnteriores
                                  ? const Padding(
                                      padding: EdgeInsets.all(Espaciados.sm),
                                      child: CircularProgressIndicator(),
                                    )
                                  : TextButton(
                                      onPressed: _cargarAnteriores,
                                      child: const Text('Ver mensajes anteriores'),
                                    ),
                            );
                          }
                          final mensaje = invertidos[indice];
                          return BurbujaMensaje(
                            key: ValueKey(mensaje.id),
                            mensaje: mensaje,
                            nombreIdioma: idiomas.nombreDe,
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(Espaciados.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _texto,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: longitudMaxima,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje',
                          counterText: '',
                        ),
                        onSubmitted: (_) => _enviar(),
                      ),
                    ),
                    const SizedBox(width: Espaciados.sm),
                    IconButton.filled(
                      tooltip: 'Enviar',
                      onPressed: _enviando ? null : _enviar,
                      icon: _enviando
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
