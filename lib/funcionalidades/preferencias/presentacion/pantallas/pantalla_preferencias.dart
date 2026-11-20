import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/widgets/desplegable.dart';
import 'package:traducontextmovil/compartido/widgets/mensaje_formulario.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/datos/catalogos_api.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/dominio/idioma.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/datos/glosarios_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/dominio/glosarios.dart';
import 'package:traducontextmovil/funcionalidades/preferencias/dominio/preferencias.dart';
import 'package:traducontextmovil/funcionalidades/preferencias/presentacion/proveedores/controlador_preferencias.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Preferencias de traducción (HU-33), como la pantalla web: idioma de
/// destino, variante regional, contexto, tono, glosario predeterminado y
/// opciones. Se cargan solas al traducir.
class PantallaPreferencias extends ConsumerWidget {
  const PantallaPreferencias({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorPreferenciasProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias de traducción')),
      body: SafeArea(child: _cuerpo(ref, estado)),
    );
  }

  Widget _cuerpo(WidgetRef ref, EstadoPreferencias estado) {
    final idiomas = ref.watch(idiomasProvider);
    final contextos = ref.watch(contextosProvider);
    final tonos = ref.watch(tonosProvider);
    if (estado.cargando || idiomas.isLoading || contextos.isLoading || tonos.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final controlador = ref.read(controladorPreferenciasProvider.notifier);
    if (idiomas.hasError || contextos.hasError || tonos.hasError) {
      return VistaEstado(
        icono: Icons.cloud_off_outlined,
        esError: true,
        mensaje: 'No se pudieron cargar los catálogos de traducción.',
        textoAccion: 'Reintentar',
        alPresionar: () {
          ref
            ..invalidate(idiomasProvider)
            ..invalidate(contextosProvider)
            ..invalidate(tonosProvider);
        },
      );
    }
    final errorCarga = estado.errorCarga;
    if (errorCarga != null) {
      return VistaEstado(
        icono: Icons.cloud_off_outlined,
        esError: true,
        mensaje: errorCarga,
        textoAccion: 'Reintentar',
        alPresionar: controlador.cargar,
      );
    }
    return FormularioPreferencias(
      estado: estado,
      idiomas: idiomas.requireValue,
      contextos: contextos.requireValue,
      tonos: tonos.requireValue,
      // Las variantes son opcionales: sin ellas el selector queda vacío.
      variantes: ref.watch(variantesRegionalesProvider).valueOrNull ?? const [],
      glosarios: ref.watch(glosariosProvider).valueOrNull ?? const [],
    );
  }
}

class FormularioPreferencias extends ConsumerWidget {
  const FormularioPreferencias({
    super.key,
    required this.estado,
    required this.idiomas,
    required this.contextos,
    required this.tonos,
    required this.variantes,
    required this.glosarios,
  });

  final EstadoPreferencias estado;
  final List<Idioma> idiomas;
  final List<OpcionCatalogo> contextos;
  final List<OpcionCatalogo> tonos;
  final List<VarianteRegional> variantes;
  final List<Glosario> glosarios;

  /// Solo los glosarios cuyo idioma de destino es el preferido.
  List<Glosario> _glosariosDe(String? codigo) => [
        for (final g in glosarios)
          if (g.aplicaA(destino: codigo)) g,
      ];

  /// La variante regional debe corresponder al idioma de destino.
  List<VarianteRegional> _variantesDe(String? codigo) {
    final idioma = idiomas.porCodigo(codigo);
    if (idioma == null) return const [];
    return [for (final v in variantes) if (v.idIdioma == idioma.id) v];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlador = ref.read(controladorPreferenciasProvider.notifier);
    final f = estado.formulario;
    final habilitado = !estado.guardando;
    final variantesIdioma = _variantesDe(f.codigoIdiomaDestino);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Anchos.formulario),
        child: ListView(
          padding: const EdgeInsets.all(Espaciados.md),
          children: [
            Text(
              'Se cargan solas al traducir un texto, un documento o en una conversación. Allí puedes '
              'cambiarlas para una traducción puntual sin modificar lo que guardes aquí.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: Espaciados.md),
            Desplegable<String>(
              etiqueta: 'Idioma de destino',
              valor: f.codigoIdiomaDestino,
              textoVacio: 'Sin preferencia',
              habilitado: habilitado,
              opciones: [for (final idioma in idiomas) (idioma.codigo, idioma.nombre)],
              alCambiar: (codigo) => controlador.cambiarIdioma(
                codigo,
                variantesValidas: {for (final v in _variantesDe(codigo)) v.id},
                glosariosValidos: {for (final g in _glosariosDe(codigo)) g.id},
              ),
            ),
            if (f.codigoIdiomaDestino != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: habilitado
                      ? () => controlador.cambiarIdioma(null, variantesValidas: const {}, glosariosValidos: const {})
                      : null,
                  child: const Text('Quitar idioma'),
                ),
              ),
            const SizedBox(height: Espaciados.md),
            Desplegable<int>(
              etiqueta: 'Variante regional',
              valor: f.idVariante,
              textoVacio: 'Sin variante',
              habilitado: habilitado,
              opciones: [for (final v in variantesIdioma) (v.id, v.nombre)],
              ayuda: f.codigoIdiomaDestino == null
                  ? 'Elige primero un idioma de destino.'
                  : variantesIdioma.isEmpty
                      ? 'Este idioma no tiene variantes regionales.'
                      : 'Solo se muestran las del idioma de destino.',
              alCambiar: (id) => controlador.editar(f.copiarCon(idVariante: () => id)),
            ),
            const SizedBox(height: Espaciados.md),
            Desplegable<int>(
              etiqueta: 'Contexto *',
              valor: f.idContexto,
              habilitado: habilitado,
              opciones: [for (final c in contextos) (c.id, c.nombre)],
              alCambiar: (id) => controlador.editar(f.copiarCon(idContexto: () => id)),
            ),
            const SizedBox(height: Espaciados.md),
            Desplegable<int>(
              etiqueta: 'Tono *',
              valor: f.idTono,
              habilitado: habilitado,
              opciones: [for (final t in tonos) (t.id, t.nombre)],
              alCambiar: (id) => controlador.editar(f.copiarCon(idTono: () => id)),
            ),
            const SizedBox(height: Espaciados.md),
            Desplegable<int>(
              etiqueta: 'Glosario predeterminado',
              valor: f.idGlosario,
              textoVacio: 'Sin glosario',
              habilitado: habilitado,
              opciones: [for (final g in _glosariosDe(f.codigoIdiomaDestino)) (g.id, '${g.nombre} (${g.parIdiomas})')],
              ayuda: 'Solo se aplica cuando el idioma de origen de la traducción coincide con el del glosario.',
              alCambiar: (id) => controlador.editar(f.copiarCon(idGlosario: () => id)),
            ),
            if (f.idGlosario != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: habilitado ? () => controlador.editar(f.copiarCon(idGlosario: () => null)) : null,
                  child: const Text('Quitar glosario'),
                ),
              ),
            const SizedBox(height: Espaciados.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Explicar modismos y expresiones'),
              value: f.explicarExpresiones,
              onChanged: habilitado ? (v) => controlador.editar(f.copiarCon(explicarExpresiones: v)) : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar alternativas de traducción'),
              value: f.generarAlternativas,
              onChanged: habilitado ? (v) => controlador.editar(f.copiarCon(generarAlternativas: v)) : null,
            ),
            if (estado.error != null) ...[
              const SizedBox(height: Espaciados.sm),
              MensajeFormulario(estado.error!),
            ],
            if (estado.mensaje != null) ...[
              const SizedBox(height: Espaciados.sm),
              MensajeFormulario(estado.mensaje!, esError: false),
            ],
            const SizedBox(height: Espaciados.md),
            FilledButton.icon(
              onPressed: habilitado && estado.hayCambios ? controlador.guardar : null,
              icon: estado.guardando
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(estado.guardando ? 'Guardando…' : 'Guardar preferencias'),
            ),
            if (estado.hayCambios && estado.guardado != null)
              TextButton(onPressed: habilitado ? controlador.descartar : null, child: const Text('Descartar cambios')),
            OutlinedButton.icon(
              onPressed: habilitado ? () => _confirmarRestablecer(context, controlador) : null,
              icon: const Icon(Icons.undo),
              label: const Text('Restablecer valores por defecto'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarRestablecer(BuildContext context, ControladorPreferencias controlador) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Restablecer preferencias'),
        content: const Text(
          'Tus preferencias volverán a los valores por defecto: primer contexto y tono, sin idioma, '
          'variante ni glosario predeterminados.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(contexto).pop(true), child: const Text('Restablecer')),
        ],
      ),
    );
    if (confirmado ?? false) await controlador.restablecer();
  }
}
