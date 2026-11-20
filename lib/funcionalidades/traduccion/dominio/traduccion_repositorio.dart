import 'package:traducontextmovil/funcionalidades/traduccion/dominio/traduccion.dart';

/// Lanza `ExcepcionApi` si el backend responde con error.
abstract interface class TraduccionRepositorio {
  /// Consulta la configuración del usuario y, solo si no existe (404), crea
  /// la configuración por defecto del backend.
  Future<ConfiguracionTraduccion> obtenerOCrearConfiguracion();

  /// [idiomaOrigen] null: el backend detecta el idioma. [idGlosario]: glosario
  /// del mismo par de idiomas a aplicar (HU-32).
  Future<ResultadoTraduccion> traducir({
    required String texto,
    required String idiomaDestino,
    String? idiomaOrigen,
    int? idGlosario,
  });
}
