/// Preferencias de traducción del usuario (HU-33, GET/POST/DELETE
/// /configuracion-traduccion). Se aplican solas al traducir.
class PreferenciasTraduccion {
  const PreferenciasTraduccion({
    this.idContexto,
    this.idTono,
    this.idVariante,
    this.codigoIdiomaDestino,
    this.idGlosario,
    this.explicarExpresiones = false,
    this.generarAlternativas = false,
  });

  final int? idContexto;
  final int? idTono;
  final int? idVariante;
  final String? codigoIdiomaDestino;
  final int? idGlosario;
  final bool explicarExpresiones;
  final bool generarAlternativas;

  /// Los `Function()?` permiten poner un campo a null.
  PreferenciasTraduccion copiarCon({
    int? Function()? idContexto,
    int? Function()? idTono,
    int? Function()? idVariante,
    String? Function()? codigoIdiomaDestino,
    int? Function()? idGlosario,
    bool? explicarExpresiones,
    bool? generarAlternativas,
  }) =>
      PreferenciasTraduccion(
        idContexto: idContexto == null ? this.idContexto : idContexto(),
        idTono: idTono == null ? this.idTono : idTono(),
        idVariante: idVariante == null ? this.idVariante : idVariante(),
        codigoIdiomaDestino: codigoIdiomaDestino == null ? this.codigoIdiomaDestino : codigoIdiomaDestino(),
        idGlosario: idGlosario == null ? this.idGlosario : idGlosario(),
        explicarExpresiones: explicarExpresiones ?? this.explicarExpresiones,
        generarAlternativas: generarAlternativas ?? this.generarAlternativas,
      );

  @override
  bool operator ==(Object other) =>
      other is PreferenciasTraduccion &&
      other.idContexto == idContexto &&
      other.idTono == idTono &&
      other.idVariante == idVariante &&
      other.codigoIdiomaDestino == codigoIdiomaDestino &&
      other.idGlosario == idGlosario &&
      other.explicarExpresiones == explicarExpresiones &&
      other.generarAlternativas == generarAlternativas;

  @override
  int get hashCode => Object.hash(
        idContexto,
        idTono,
        idVariante,
        codigoIdiomaDestino,
        idGlosario,
        explicarExpresiones,
        generarAlternativas,
      );
}

/// Variante regional de un idioma (GET /variantes-regionales).
class VarianteRegional {
  const VarianteRegional({required this.id, required this.nombre, required this.codigo, required this.idIdioma});

  final int id;
  final String nombre;
  final String codigo;
  final int idIdioma;
}

/// Lanza `ExcepcionApi` si el backend responde con error.
abstract interface class PreferenciasRepositorio {
  /// null si el usuario aún no guardó preferencias (404).
  Future<PreferenciasTraduccion?> obtener();

  /// POST: crea o actualiza. Exige contexto y tono.
  Future<PreferenciasTraduccion> guardar(PreferenciasTraduccion preferencias);

  /// DELETE: vuelve a los valores por defecto (primer contexto y tono).
  Future<PreferenciasTraduccion> restablecer();
}
