import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/formato.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/periodo.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/cuadricula_indicadores.dart';
import 'package:traducontextmovil/compartido/widgets/tarjeta_indicador.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/administracion/reportes/datos/reportes_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/administracion/reportes/dominio/reportes.dart';
import 'package:traducontextmovil/nucleo/archivos/gestor_archivos.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Reporte de actividad con filtros y exportación PDF/Excel (HU-47/HU-48).
class PantallaReportes extends ConsumerStatefulWidget {
  const PantallaReportes({super.key});

  @override
  ConsumerState<PantallaReportes> createState() => _PantallaReportesState();
}

class _PantallaReportesState extends ConsumerState<PantallaReportes> {
  FiltrosReporte _filtros = const FiltrosReporte();
  ReporteActividad? _reporte;
  List<ActividadReporte> _actividades = const [];
  String? _error;
  bool _cargandoMas = false;
  FormatoExportacion? _exportando;

  ReportesRepositorio get _repositorio => ref.read(reportesRepositorioProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_cargar());
  }

  Future<void> _cargar({bool siguiente = false}) async {
    final pagina = siguiente ? (_reporte?.pagina ?? 0) + 1 : 1;
    setState(() {
      if (siguiente) {
        _cargandoMas = true;
      } else {
        _reporte = null;
        _error = null;
      }
    });
    try {
      final reporte = await _repositorio.consultar(_filtros, pagina: pagina);
      if (!mounted) return;
      setState(() {
        _reporte = reporte;
        _actividades = [if (siguiente) ..._actividades, ...reporte.actividades];
      });
    } on ExcepcionApi catch (error) {
      if (mounted) setState(() => _error = MensajesError.de(error));
    } finally {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  void _filtrar(FiltrosReporte filtros) {
    _filtros = filtros;
    unawaited(_cargar());
  }

  Future<void> _exportar(FormatoExportacion formato) async {
    setState(() => _exportando = formato);
    try {
      final archivo = await _repositorio.exportar(_filtros, formato);
      await ref.read(gestorArchivosProvider).guardarYCompartir(archivo);
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo exportar el reporte. ${MensajesError.de(error)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final reporte = _reporte;
    return ContenidoAdaptable.lista(
      child: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          padding: const EdgeInsets.all(Espaciados.md),
          children: [
            Wrap(
              spacing: Espaciados.sm,
              runSpacing: Espaciados.xs,
              children: [
                for (final periodo in Periodo.values)
                  ChoiceChip(
                    label: Text(periodo.etiqueta),
                    selected: _filtros.periodo == periodo,
                    onSelected: (_) => _filtrar(FiltrosReporte(periodo: periodo, tipo: _filtros.tipo)),
                  ),
              ],
            ),
            const SizedBox(height: Espaciados.xs),
            Wrap(
              spacing: Espaciados.sm,
              runSpacing: Espaciados.xs,
              children: [
                for (final tipo in [null, ...TipoServicio.values])
                  FilterChip(
                    label: Text(tipo?.etiqueta ?? 'Todos los servicios'),
                    selected: _filtros.tipo == tipo,
                    onSelected: (_) => _filtrar(FiltrosReporte(periodo: _filtros.periodo, tipo: tipo)),
                  ),
              ],
            ),
            const SizedBox(height: Espaciados.sm),
            Wrap(
              spacing: Espaciados.sm,
              runSpacing: Espaciados.xs,
              children: [
                for (final formato in FormatoExportacion.values)
                  OutlinedButton.icon(
                    onPressed: _exportando == null ? () => _exportar(formato) : null,
                    icon: _exportando == formato
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text('Exportar ${formato.etiqueta}'),
                  ),
              ],
            ),
            const SizedBox(height: Espaciados.md),
            if (_error != null && reporte == null)
              VistaEstado(
                icono: Icons.cloud_off_outlined,
                esError: true,
                mensaje: _error!,
                textoAccion: 'Reintentar',
                alPresionar: _cargar,
              )
            else if (reporte == null)
              const Padding(
                padding: EdgeInsets.all(Espaciados.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              CuadriculaIndicadores(
                children: [
                  TarjetaIndicador(etiqueta: 'Total', valor: '${reporte.total}', icono: Icons.summarize),
                  TarjetaIndicador(etiqueta: 'Texto', valor: '${reporte.texto}', icono: Icons.translate),
                  TarjetaIndicador(
                    etiqueta: 'Documentos',
                    valor: '${reporte.documento}',
                    icono: Icons.description_outlined,
                  ),
                  TarjetaIndicador(
                    etiqueta: 'Conversaciones',
                    valor: '${reporte.conversacion}',
                    icono: Icons.forum_outlined,
                  ),
                ],
              ),
              const SizedBox(height: Espaciados.md),
              Text('Actividad', style: textos.titleMedium),
              const SizedBox(height: Espaciados.sm),
              if (_actividades.isEmpty)
                const VistaEstado(icono: Icons.inbox_outlined, mensaje: 'No hay actividad en este periodo.')
              else
                for (final actividad in _actividades) _FilaActividad(actividad: actividad),
              if (reporte.hayMas)
                Center(
                  child: _cargandoMas
                      ? const Padding(
                          padding: EdgeInsets.all(Espaciados.md),
                          child: CircularProgressIndicator(),
                        )
                      : TextButton(
                          onPressed: () => _cargar(siguiente: true),
                          child: const Text('Cargar más'),
                        ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilaActividad extends StatelessWidget {
  const _FilaActividad({required this.actividad});

  final ActividadReporte actividad;

  @override
  Widget build(BuildContext context) {
    final idiomas = [actividad.idiomaOrigen, actividad.idiomaDestino].whereType<String>().join(' → ');
    final extra = [
      if (idiomas.isNotEmpty) idiomas,
      ?actividad.contexto,
      ?actividad.detalle,
      ?actividad.estado,
    ].join(' · ');
    return Card(
      child: ListTile(
        title: Text(
          '${TipoServicio.etiquetaDe(actividad.tipoServicio)} · ${actividad.nombreUsuario}',
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [Formato.fechaHora(actividad.fecha), if (extra.isNotEmpty) extra].join('\n'),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
