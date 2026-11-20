import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/boton_con_carga.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/mensaje_formulario.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/datos/catalogos_api.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/dominio/idioma.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/datos/conversaciones_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/dominio/conversaciones.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/presentacion/widgets/selector_idioma.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Configura una conversación con intérprete: idiomas de los dos
/// participantes, entorno (obligatorio), contexto y descripción (opcionales).
class PantallaNuevaConversacion extends ConsumerStatefulWidget {
  const PantallaNuevaConversacion({super.key});

  static const int longitudDescripcion = 1000;

  @override
  ConsumerState<PantallaNuevaConversacion> createState() => _PantallaNuevaConversacionState();
}

class _PantallaNuevaConversacionState extends ConsumerState<PantallaNuevaConversacion> {
  final _descripcion = TextEditingController();
  String? _origen = 'es';
  String? _destino = 'en';
  int? _idEntorno;
  int? _idContexto;
  bool _mantenerContexto = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _iniciar(List<Idioma> idiomas) async {
    final origen = idiomas.porCodigo(_origen);
    final destino = idiomas.porCodigo(_destino);
    if (origen == null || destino == null) {
      setState(() => _error = 'Elige los idiomas de los dos participantes.');
      return;
    }
    if (origen == destino) {
      setState(() => _error = 'Los dos participantes deben hablar idiomas distintos.');
      return;
    }
    final idEntorno = _idEntorno;
    if (idEntorno == null) {
      setState(() => _error = 'Elige el entorno de la conversación.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final descripcion = _descripcion.text.trim();
      final conversacion = await ref.read(conversacionesRepositorioProvider).iniciar(
            NuevaConversacion(
              idIdiomaOrigen: origen.id,
              idIdiomaDestino: destino.id,
              idEntorno: idEntorno,
              idContexto: _idContexto,
              descripcionContexto: descripcion.isEmpty ? null : descripcion,
              mantenerContexto: _mantenerContexto,
            ),
          );
      if (mounted) context.pushReplacement(Rutas.conversacion(conversacion.id));
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(
          () => _error = MensajesError.de(
            error,
            porCodigo: {400: 'No se pudo iniciar la conversación. Revisa los datos elegidos.'},
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final idiomas = ref.watch(idiomasProvider);
    final entornos = ref.watch(entornosProvider);
    final contextos = ref.watch(contextosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva conversación')),
      body: switch ((idiomas, entornos)) {
        (AsyncValue(:final error?), _) || (_, AsyncValue(:final error?)) => VistaEstado(
            icono: Icons.cloud_off_outlined,
            esError: true,
            mensaje: MensajesError.de(error),
            textoAccion: 'Reintentar',
            alPresionar: () => ref
              ..invalidate(idiomasProvider)
              ..invalidate(entornosProvider),
          ),
        (AsyncData(value: final listaIdiomas), AsyncData(value: final listaEntornos)) =>
          ContenidoAdaptable(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectorIdioma(
                  etiqueta: 'Idioma del participante 1',
                  valor: _origen,
                  idiomas: listaIdiomas,
                  habilitado: !_cargando,
                  alCambiar: (codigo) => setState(() => _origen = codigo),
                ),
                const SizedBox(height: Espaciados.md),
                SelectorIdioma(
                  etiqueta: 'Idioma del participante 2',
                  valor: _destino,
                  idiomas: listaIdiomas,
                  habilitado: !_cargando,
                  alCambiar: (codigo) => setState(() => _destino = codigo),
                ),
                const SizedBox(height: Espaciados.md),
                _Desplegable(
                  etiqueta: 'Entorno',
                  valor: _idEntorno,
                  opciones: [for (final e in listaEntornos) (e.id, e.nombre)],
                  habilitado: !_cargando,
                  alCambiar: (id) => setState(() => _idEntorno = id),
                ),
                const SizedBox(height: Espaciados.md),
                _Desplegable(
                  etiqueta: 'Contexto (opcional)',
                  valor: _idContexto,
                  opciones: [
                    (null, 'Sin contexto'),
                    for (final c in contextos.valueOrNull ?? const <OpcionCatalogo>[]) (c.id, c.nombre),
                  ],
                  habilitado: !_cargando,
                  alCambiar: (id) => setState(() => _idContexto = id),
                ),
                const SizedBox(height: Espaciados.md),
                TextField(
                  controller: _descripcion,
                  enabled: !_cargando,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: PantallaNuevaConversacion.longitudDescripcion,
                  decoration: const InputDecoration(
                    labelText: 'Describe la situación (opcional)',
                    helperText: 'Audiencia, terminología o tema. Mejora la traducción.',
                    alignLabelWithHint: true,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _mantenerContexto,
                  onChanged: _cargando ? null : (valor) => setState(() => _mantenerContexto = valor),
                  title: const Text('Mantener el contexto de la conversación'),
                  subtitle: const Text('Usa las intervenciones anteriores para traducir mejor.'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: Espaciados.sm),
                  MensajeFormulario(_error!),
                ],
                const SizedBox(height: Espaciados.lg),
                BotonConCarga(
                  texto: 'Iniciar conversación',
                  cargando: _cargando,
                  alPresionar: () => _iniciar(listaIdiomas),
                ),
              ],
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Desplegable extends StatelessWidget {
  const _Desplegable({
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.alCambiar,
    required this.habilitado,
  });

  final String etiqueta;
  final int? valor;
  final List<(int?, String)> opciones;
  final ValueChanged<int?> alCambiar;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: etiqueta,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: opciones.any((o) => o.$1 == valor) ? valor : null,
          isExpanded: true,
          hint: const Text('Elige una opción'),
          onChanged: habilitado ? alCambiar : null,
          items: [
            for (final (id, nombre) in opciones)
              DropdownMenuItem<int?>(
                value: id,
                child: Text(nombre, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
    );
  }
}
