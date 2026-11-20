import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/boton_con_carga.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/mensaje_formulario.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/datos/catalogos_api.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/dominio/idioma.dart';
import 'package:traducontextmovil/compartido/widgets/desplegable.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/datos/glosarios_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/dominio/glosarios.dart';
import 'package:traducontextmovil/funcionalidades/historial/datos/historial_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/datos/repositorios/traduccion_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/dominio/traduccion.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/presentacion/widgets/selector_idioma.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Traducción de texto (HU-13). Antes de traducir se asegura la configuración
/// del usuario (GET y, solo si no existe, creación por defecto).
class PantallaTraducir extends ConsumerStatefulWidget {
  const PantallaTraducir({super.key});

  static const int longitudMaxima = 5000;

  @override
  ConsumerState<PantallaTraducir> createState() => _PantallaTraducirState();
}

class _PantallaTraducirState extends ConsumerState<PantallaTraducir> {
  final _texto = TextEditingController();

  /// null: detección automática.
  String? _origen;
  String? _destino;
  ResultadoTraduccion? _resultado;

  /// Glosario elegido para esta traducción (solo los del par de idiomas actual).
  int? _idGlosario;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  String _destinoPorDefecto(List<Idioma> idiomas, ConfiguracionTraduccion configuracion) {
    for (final codigo in [configuracion.codigoIdiomaDestino, 'en', 'es']) {
      if (idiomas.porCodigo(codigo) != null) return codigo!;
    }
    return idiomas.first.codigo;
  }

  Future<void> _traducir() async {
    FocusScope.of(context).unfocus();
    final texto = _texto.text.trim();
    final destino = _destino;
    if (texto.isEmpty) {
      setState(() => _error = 'Escribe el texto que quieres traducir.');
      return;
    }
    if (destino == null) return;
    if (_origen == destino) {
      setState(() => _error = 'El idioma de origen y el de destino deben ser distintos.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resultado = await ref
          .read(traduccionRepositorioProvider)
          .traducir(
            texto: texto,
            idiomaDestino: destino,
            idiomaOrigen: _origen,
            idGlosario: _glosarioValido(ref.read(glosariosProvider).valueOrNull ?? const []),
          );
      if (resultado.idTraduccion != null) ref.read(versionHistorialProvider.notifier).state++;
      if (mounted) setState(() => _resultado = resultado);
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(
          () => _error = MensajesError.de(
            error,
            porCodigo: {
              400: 'No se pudo traducir el texto. Revisa los idiomas elegidos e inténtalo de nuevo.',
            },
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _intercambiar() {
    final origenEfectivo = _origen ?? _resultado?.idiomaOrigen;
    if (origenEfectivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elige el idioma de origen o traduce primero para poder intercambiar.'),
        ),
      );
      return;
    }
    setState(() {
      final destinoAnterior = _destino;
      _destino = origenEfectivo;
      _origen = destinoAnterior;
      final resultado = _resultado;
      if (resultado != null) {
        _texto.text = resultado.traduccion;
        _resultado = null;
      }
      _error = null;
    });
  }

  /// Como en la web: un glosario por traducción, del destino elegido y, si
  /// se conoce, del origen (elegido o detectado en la última traducción).
  List<Glosario> _glosariosDisponibles(List<Glosario> glosarios) => [
        for (final g in glosarios)
          if (g.aplicaA(origen: _origen ?? _resultado?.idiomaOrigen, destino: _destino)) g,
      ];

  int? _glosarioValido(List<Glosario> glosarios) =>
      _glosariosDisponibles(glosarios).any((g) => g.id == _idGlosario) ? _idGlosario : null;

  /// Solo aparece si el usuario tiene glosarios para el par de idiomas.
  List<Widget> _selectorGlosario() {
    final disponibles = _glosariosDisponibles(ref.watch(glosariosProvider).valueOrNull ?? const []);
    if (disponibles.isEmpty) return const [];
    return [
      const SizedBox(height: Espaciados.md),
      Desplegable<int>(
        etiqueta: 'Glosario',
        valor: _glosarioValido(disponibles),
        textoVacio: 'Sin glosario',
        habilitado: !_cargando,
        opciones: [
          (0, 'Sin glosario'),
          for (final g in disponibles) (g.id, '${g.nombre} (${g.parIdiomas})'),
        ],
        alCambiar: (id) => setState(() => _idGlosario = id == 0 ? null : id),
      ),
    ];
  }

  Future<void> _copiar(String texto) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Traducción copiada.')));
  }

  void _reintentarCarga() {
    ref
      ..invalidate(idiomasProvider)
      ..invalidate(configuracionTraduccionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final idiomas = ref.watch(idiomasProvider);
    final configuracion = ref.watch(configuracionTraduccionProvider);

    if (idiomas.hasError || configuracion.hasError) {
      final error = idiomas.error ?? configuracion.error!;
      return VistaEstado(
        icono: Icons.cloud_off_outlined,
        esError: true,
        mensaje: 'No se pudo preparar el traductor. ${MensajesError.de(error)}',
        textoAccion: 'Reintentar',
        alPresionar: _reintentarCarga,
      );
    }
    final listaIdiomas = idiomas.valueOrNull;
    final configuracionUsuario = configuracion.valueOrNull;
    if (listaIdiomas == null || configuracionUsuario == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (listaIdiomas.isEmpty) {
      return const VistaEstado(
        icono: Icons.translate,
        mensaje: 'No hay idiomas disponibles para traducir.',
      );
    }
    _destino ??= _destinoPorDefecto(listaIdiomas, configuracionUsuario);

    return ContenidoAdaptable.lista(
      child: ListView(
        padding: const EdgeInsets.all(Espaciados.md),
        children: [
          Row(
            children: [
              Expanded(
                child: SelectorIdioma(
                  etiqueta: 'De',
                  valor: _origen,
                  idiomas: listaIdiomas,
                  permitirDeteccion: true,
                  habilitado: !_cargando,
                  alCambiar: (codigo) => setState(() => _origen = codigo),
                ),
              ),
              IconButton(
                tooltip: 'Intercambiar idiomas',
                icon: const Icon(Icons.swap_horiz),
                onPressed: _cargando ? null : _intercambiar,
              ),
              Expanded(
                child: SelectorIdioma(
                  etiqueta: 'A',
                  valor: _destino,
                  idiomas: listaIdiomas,
                  habilitado: !_cargando,
                  alCambiar: (codigo) => setState(() => _destino = codigo),
                ),
              ),
            ],
          ),
          ..._selectorGlosario(),
          const SizedBox(height: Espaciados.md),
          TextField(
            controller: _texto,
            enabled: !_cargando,
            minLines: 4,
            maxLines: 10,
            maxLength: PantallaTraducir.longitudMaxima,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: 'Texto a traducir',
              alignLabelWithHint: true,
              suffixIcon: IconButton(
                tooltip: 'Borrar texto',
                icon: const Icon(Icons.clear),
                onPressed: _cargando
                    ? null
                    : () => setState(() {
                          _texto.clear();
                          _resultado = null;
                          _error = null;
                        }),
              ),
            ),
          ),
          if (_error != null) ...[
            MensajeFormulario(_error!),
            const SizedBox(height: Espaciados.md),
          ],
          BotonConCarga(texto: 'Traducir', cargando: _cargando, alPresionar: _traducir),
          if (configuracionUsuario.nombreContexto != null) ...[
            const SizedBox(height: Espaciados.sm),
            Text(
              'Contexto: ${configuracionUsuario.nombreContexto}'
              '${configuracionUsuario.nombreTono == null ? '' : ' · Tono: ${configuracionUsuario.nombreTono}'}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_resultado != null) ...[
            const SizedBox(height: Espaciados.lg),
            _TarjetaResultado(
              resultado: _resultado!,
              idiomas: listaIdiomas,
              alCopiar: _copiar,
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetaResultado extends StatelessWidget {
  const _TarjetaResultado({
    required this.resultado,
    required this.idiomas,
    required this.alCopiar,
  });

  final ResultadoTraduccion resultado;
  final List<Idioma> idiomas;
  final ValueChanged<String> alCopiar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Espaciados.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    idiomas.nombreDe(resultado.idiomaDestino),
                    style: textos.titleMedium?.copyWith(color: ColoresApp.primario),
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar traducción',
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () => alCopiar(resultado.traduccion),
                ),
              ],
            ),
            SelectableText(resultado.traduccion, style: textos.bodyLarge),
            if (resultado.confianzaDeteccion != null) ...[
              const SizedBox(height: Espaciados.sm),
              Text(
                'Idioma detectado: ${idiomas.nombreDe(resultado.idiomaOrigen)}',
                style: textos.bodySmall,
              ),
            ],
            if (resultado.alternativas.isNotEmpty) ...[
              const SizedBox(height: Espaciados.md),
              Text('Alternativas', style: textos.titleMedium),
              for (final alternativa in resultado.alternativas)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(alternativa.traduccion),
                  subtitle: alternativa.explicacion == null ? null : Text(alternativa.explicacion!),
                  trailing: IconButton(
                    tooltip: 'Copiar alternativa',
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: () => alCopiar(alternativa.traduccion),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
