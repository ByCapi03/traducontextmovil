import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/formato.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/periodo.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/cuadricula_indicadores.dart';
import 'package:traducontextmovil/compartido/widgets/tarjeta_indicador.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/administracion/dashboard/datos/dashboard_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/administracion/dashboard/dominio/dashboard.dart';
import 'package:traducontextmovil/funcionalidades/administracion/dashboard/presentacion/widgets/lista_barras.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Indicadores de uso de la plataforma (HU-45).
class PantallaDashboard extends ConsumerStatefulWidget {
  const PantallaDashboard({super.key});

  @override
  ConsumerState<PantallaDashboard> createState() => _PantallaDashboardState();
}

class _PantallaDashboardState extends ConsumerState<PantallaDashboard> {
  Periodo _periodo = Periodo.mes;
  late Future<Dashboard> _datos = _consultar();

  Future<Dashboard> _consultar() => ref.read(dashboardRepositorioProvider).consultar(_periodo);

  void _recargar() {
    setState(() {
      _datos = _consultar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContenidoAdaptable.lista(
      child: RefreshIndicator(
        onRefresh: () async {
          _recargar();
          await _datos.catchError((_) => _datos);
        },
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
                    selected: periodo == _periodo,
                    onSelected: (_) {
                      _periodo = periodo;
                      _recargar();
                    },
                  ),
              ],
            ),
            const SizedBox(height: Espaciados.md),
            FutureBuilder<Dashboard>(
              future: _datos,
              builder: (context, instantanea) {
                if (instantanea.hasError) {
                  return VistaEstado(
                    icono: Icons.cloud_off_outlined,
                    esError: true,
                    mensaje: MensajesError.de(instantanea.error!),
                    textoAccion: 'Reintentar',
                    alPresionar: _recargar,
                  );
                }
                final datos = instantanea.data;
                if (datos == null || instantanea.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(Espaciados.xl),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _Contenido(datos: datos);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.datos});

  final Dashboard datos;

  @override
  Widget build(BuildContext context) {
    final evolucion = [
      for (final punto in datos.evolucion.reversed.take(12))
        (
          datos.agrupacionMensual
              ? '${punto.fecha.month.toString().padLeft(2, '0')}/${punto.fecha.year}'
              : Formato.fecha(punto.fecha),
          punto.total,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CuadriculaIndicadores(
          children: [
            TarjetaIndicador(
              etiqueta: 'Usuarios registrados',
              valor: '${datos.usuariosTotal}',
              icono: Icons.people_outline,
              detalle: '${datos.usuariosNuevos} nuevos en el periodo',
            ),
            TarjetaIndicador(
              etiqueta: 'Usuarios activos',
              valor: '${datos.usuariosActivos}',
              icono: Icons.person_pin_outlined,
            ),
            TarjetaIndicador(
              etiqueta: 'Traducciones de texto',
              valor: '${datos.traducciones}',
              icono: Icons.translate,
            ),
            TarjetaIndicador(
              etiqueta: 'Documentos traducidos',
              valor: '${datos.documentos}',
              icono: Icons.description_outlined,
            ),
            TarjetaIndicador(
              etiqueta: 'Conversaciones',
              valor: '${datos.conversaciones}',
              icono: Icons.forum_outlined,
            ),
          ],
        ),
        const SizedBox(height: Espaciados.md),
        ListaBarras(
          titulo: 'Idiomas más utilizados',
          elementos: [for (final idioma in datos.idiomas) (idioma.nombre, idioma.total)],
        ),
        const SizedBox(height: Espaciados.md),
        ListaBarras(
          titulo: 'Contextos más utilizados',
          elementos: [for (final contexto in datos.contextos) (contexto.nombre, contexto.total)],
        ),
        const SizedBox(height: Espaciados.md),
        ListaBarras(
          titulo: datos.agrupacionMensual
              ? 'Actividad por mes (más recientes)'
              : 'Actividad por día (más recientes)',
          elementos: evolucion,
        ),
      ],
    );
  }
}
