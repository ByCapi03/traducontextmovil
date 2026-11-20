import 'package:traducontextmovil/compartido/periodo.dart';

/// Uso de un idioma o contexto en el periodo.
class UsoElemento {
  const UsoElemento({required this.nombre, required this.total});

  final String nombre;
  final int total;
}

class PuntoEvolucion {
  const PuntoEvolucion({
    required this.fecha,
    required this.traducciones,
    required this.documentos,
    required this.conversaciones,
  });

  final DateTime fecha;
  final int traducciones;
  final int documentos;
  final int conversaciones;

  int get total => traducciones + documentos + conversaciones;
}

/// Resultado de GET /dashboard (HU-45).
class Dashboard {
  const Dashboard({
    required this.usuariosTotal,
    required this.usuariosActivos,
    required this.usuariosNuevos,
    required this.traducciones,
    required this.documentos,
    required this.conversaciones,
    required this.idiomas,
    required this.contextos,
    required this.evolucion,
    required this.agrupacionMensual,
  });

  final int usuariosTotal;
  final int usuariosActivos;
  final int usuariosNuevos;
  final int traducciones;
  final int documentos;
  final int conversaciones;
  final List<UsoElemento> idiomas;
  final List<UsoElemento> contextos;
  final List<PuntoEvolucion> evolucion;

  /// true si cada punto de [evolucion] es un mes (si no, un día).
  final bool agrupacionMensual;
}

abstract interface class DashboardRepositorio {
  Future<Dashboard> consultar(Periodo periodo);
}
