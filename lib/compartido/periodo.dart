import 'package:traducontextmovil/compartido/formato.dart';

/// Periodos rápidos para el dashboard y los reportes.
enum Periodo {
  semana('Últimos 7 días', 7),
  mes('Últimos 30 días', 30),
  trimestre('Últimos 90 días', 90),
  anio('Últimos 12 meses', 365);

  const Periodo(this.etiqueta, this.dias);

  final String etiqueta;
  final int dias;

  /// Parámetros `fecha_desde`/`fecha_hasta` (inclusive) hasta [hoy].
  Map<String, String> parametros({DateTime? hoy}) {
    final hasta = hoy ?? DateTime.now();
    final desde = hasta.subtract(Duration(days: dias - 1));
    return {'fecha_desde': Formato.fechaApi(desde), 'fecha_hasta': Formato.fechaApi(hasta)};
  }
}

/// El backend espera una zona IANA; Dart no la expone sin un plugin, así que
/// se usa UTC (ver docs/pendientes_movil.md).
const String zonaHorariaReportes = 'UTC';
