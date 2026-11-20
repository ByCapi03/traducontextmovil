import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/nombres_idioma.dart';
import 'package:traducontextmovil/compartido/periodo.dart';
import 'package:traducontextmovil/funcionalidades/administracion/dashboard/dominio/dashboard.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// GET /dashboard (requiere el permiso ver_dashboard).
class DashboardRepositorioRemoto implements DashboardRepositorio {
  DashboardRepositorioRemoto(this._dio);

  final Dio _dio;

  @override
  Future<Dashboard> consultar(Periodo periodo) async {
    final json = await resultadoDe(
      _dio.get<dynamic>(
        '/dashboard',
        queryParameters: {...periodo.parametros(), 'zona_horaria': zonaHorariaReportes},
      ),
    ) as Map<String, dynamic>;
    final usuarios = json['usuarios'] as Map<String, dynamic>;
    final actividad = json['actividad'] as Map<String, dynamic>;
    final periodoJson = json['periodo'] as Map<String, dynamic>?;
    return Dashboard(
      usuariosTotal: usuarios['total'] as int,
      usuariosActivos: usuarios['activos_periodo'] as int,
      usuariosNuevos: usuarios['nuevos_periodo'] as int,
      traducciones: actividad['traducciones_texto'] as int,
      documentos: actividad['documentos_traducidos'] as int,
      conversaciones: actividad['conversaciones'] as int,
      idiomas: [
        for (final idioma in listaDeMapas(json['idiomas_mas_utilizados']))
          UsoElemento(
            nombre: nombreIdioma(idioma['codigo'] as String?, respaldo: idioma['nombre'] as String),
            total: idioma['total'] as int,
          ),
      ],
      contextos: [
        for (final contexto in listaDeMapas(json['contextos_mas_utilizados']))
          UsoElemento(nombre: contexto['nombre'] as String, total: contexto['total'] as int),
      ],
      evolucion: [
        for (final punto in listaDeMapas(json['evolucion']))
          PuntoEvolucion(
            fecha: DateTime.parse(punto['fecha'] as String),
            traducciones: punto['traducciones_texto'] as int,
            documentos: punto['documentos'] as int,
            conversaciones: punto['conversaciones'] as int,
          ),
      ],
      agrupacionMensual: periodoJson?['agrupacion'] == 'mes',
    );
  }
}

final dashboardRepositorioProvider = Provider<DashboardRepositorio>(
  (ref) => DashboardRepositorioRemoto(ref.watch(clienteHttpProvider)),
);
