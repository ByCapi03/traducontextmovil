/// Formatos de fecha para mostrar (sin depender de intl).
abstract final class Formato {
  static String _dos(int valor) => valor.toString().padLeft(2, '0');

  /// 20/11/2026
  static String fecha(DateTime fecha) => '${_dos(fecha.day)}/${_dos(fecha.month)}/${fecha.year}';

  /// 20/11/2026 14:05
  static String fechaHora(DateTime fecha) =>
      '${Formato.fecha(fecha)} ${_dos(fecha.hour)}:${_dos(fecha.minute)}';

  /// 14:05
  static String hora(DateTime fecha) => '${_dos(fecha.hour)}:${_dos(fecha.minute)}';

  /// AAAA-MM-DD para los parámetros del backend.
  static String fechaApi(DateTime fecha) =>
      '${fecha.year}-${_dos(fecha.month)}-${_dos(fecha.day)}';

  /// "Hace 5 min", "Hace 3 h" o la fecha si es más antigua que un día.
  static String relativa(DateTime fecha, {DateTime? ahora}) {
    final diferencia = (ahora ?? DateTime.now()).difference(fecha);
    if (diferencia.inMinutes < 1) return 'Ahora';
    if (diferencia.inMinutes < 60) return 'Hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'Hace ${diferencia.inHours} h';
    return Formato.fecha(fecha);
  }
}
