import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/formato.dart';
import 'package:traducontextmovil/compartido/periodo.dart';
import 'package:traducontextmovil/funcionalidades/administracion/reportes/dominio/reportes.dart';
import 'package:traducontextmovil/nucleo/archivos/gestor_archivos.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// app/api/routes/reportes.py (permiso generar_reportes).
class ReportesRepositorioRemoto implements ReportesRepositorio {
  ReportesRepositorioRemoto(this._dio);

  final Dio _dio;
  static const int tamanoPagina = 20;

  Map<String, dynamic> _parametros(FiltrosReporte filtros) => {
        ...filtros.periodo.parametros(),
        'zona_horaria': zonaHorariaReportes,
        'tipo_servicio': ?filtros.tipo?.codigo,
      };

  @override
  Future<ReporteActividad> consultar(FiltrosReporte filtros, {int pagina = 1}) async {
    final json = await resultadoDe(
      _dio.get<dynamic>(
        '/reportes/actividad',
        queryParameters: {..._parametros(filtros), 'pagina': pagina, 'tamano_pagina': tamanoPagina},
      ),
    ) as Map<String, dynamic>;
    final totales = json['totales'] as Map<String, dynamic>;
    return ReporteActividad(
      total: totales['total'] as int,
      texto: totales['texto'] as int,
      documento: totales['documento'] as int,
      conversacion: totales['conversacion'] as int,
      actividades: [
        for (final fila in listaDeMapas(json['actividades']))
          ActividadReporte(
            tipoServicio: fila['tipo_servicio'] as String,
            // fecha_local ya está en la zona del reporte; se muestra tal cual.
            fecha: DateTime.tryParse(fila['fecha_local'] as String? ?? '') ??
                fechaDe(fila['fecha']) ??
                DateTime.now(),
            nombreUsuario: fila['nombre_usuario'] as String,
            idiomaOrigen: fila['idioma_origen'] as String?,
            idiomaDestino: fila['idioma_destino'] as String?,
            contexto: fila['contexto'] as String?,
            estado: fila['estado'] as String?,
            detalle: fila['detalle'] as String?,
          ),
      ],
      pagina: json['pagina'] as int,
      totalPaginas: json['total_paginas'] as int,
    );
  }

  @override
  Future<ArchivoDescargado> exportar(FiltrosReporte filtros, FormatoExportacion formato) =>
      descargarArchivo(
        _dio,
        '/reportes/actividad/exportar',
        parametros: {..._parametros(filtros), 'formato': formato.codigo},
        nombrePorDefecto:
            'reporte_actividad_${Formato.fechaApi(DateTime.now())}.${formato.codigo}',
      );
}

final reportesRepositorioProvider = Provider<ReportesRepositorio>(
  (ref) => ReportesRepositorioRemoto(ref.watch(clienteHttpProvider)),
);
