import 'package:traducontextmovil/compartido/periodo.dart';
import 'package:traducontextmovil/nucleo/archivos/gestor_archivos.dart';

/// Tipos de servicio del reporte (sin sesiones externas: aún no existen).
enum TipoServicio {
  texto('texto', 'Texto'),
  documento('documento', 'Documentos'),
  conversacion('conversacion', 'Conversaciones');

  const TipoServicio(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  static String etiquetaDe(String codigo) {
    for (final tipo in values) {
      if (tipo.codigo == codigo) return tipo.etiqueta;
    }
    return codigo == 'sesion_externa' ? 'Sesión externa' : codigo;
  }
}

enum FormatoExportacion {
  pdf('pdf', 'PDF'),
  xlsx('xlsx', 'Excel');

  const FormatoExportacion(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;
}

class FiltrosReporte {
  const FiltrosReporte({this.periodo = Periodo.mes, this.tipo});

  final Periodo periodo;
  final TipoServicio? tipo;
}

class ActividadReporte {
  const ActividadReporte({
    required this.tipoServicio,
    required this.fecha,
    required this.nombreUsuario,
    this.idiomaOrigen,
    this.idiomaDestino,
    this.contexto,
    this.estado,
    this.detalle,
  });

  final String tipoServicio;
  final DateTime fecha;
  final String nombreUsuario;
  final String? idiomaOrigen;
  final String? idiomaDestino;
  final String? contexto;
  final String? estado;
  final String? detalle;
}

class ReporteActividad {
  const ReporteActividad({
    required this.total,
    required this.texto,
    required this.documento,
    required this.conversacion,
    required this.actividades,
    required this.pagina,
    required this.totalPaginas,
  });

  final int total;
  final int texto;
  final int documento;
  final int conversacion;
  final List<ActividadReporte> actividades;
  final int pagina;
  final int totalPaginas;

  bool get hayMas => pagina < totalPaginas;
}

abstract interface class ReportesRepositorio {
  Future<ReporteActividad> consultar(FiltrosReporte filtros, {int pagina = 1});

  Future<ArchivoDescargado> exportar(FiltrosReporte filtros, FormatoExportacion formato);
}
