/// Configuración de traducción guardada del usuario (GET /configuracion-traduccion).
class ConfiguracionTraduccion {
  const ConfiguracionTraduccion({
    required this.id,
    this.nombreContexto,
    this.nombreTono,
    this.codigoIdiomaDestino,
  });

  final int id;
  final String? nombreContexto;
  final String? nombreTono;

  /// Idioma de destino preferido (puede no estar definido).
  final String? codigoIdiomaDestino;
}

/// Alternativa de traducción propuesta por el backend.
class AlternativaTraduccion {
  const AlternativaTraduccion({required this.traduccion, this.explicacion});

  final String traduccion;
  final String? explicacion;
}

/// Resultado de POST /traducciones.
class ResultadoTraduccion {
  const ResultadoTraduccion({
    required this.textoOrigen,
    required this.idiomaOrigen,
    required this.idiomaDestino,
    required this.traduccion,
    this.idTraduccion,
    this.confianzaDeteccion,
    this.alternativas = const [],
  });

  final String textoOrigen;

  /// Código del idioma de origen usado (detectado si no se envió).
  final String idiomaOrigen;
  final String idiomaDestino;
  final String traduccion;

  /// Registro creado en el historial (null si no se guardó).
  final int? idTraduccion;

  /// Solo viene cuando el idioma de origen se detectó automáticamente.
  final double? confianzaDeteccion;
  final List<AlternativaTraduccion> alternativas;
}
