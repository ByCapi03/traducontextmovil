/// Idioma disponible para traducir (GET /idiomas).
class Idioma {
  const Idioma({required this.id, required this.nombre, required this.codigo});

  final int id;
  final String nombre;
  final String codigo;

  @override
  bool operator ==(Object other) => other is Idioma && other.codigo == codigo;

  @override
  int get hashCode => codigo.hashCode;
}

extension BuscarIdioma on List<Idioma> {
  /// Nombre del idioma con ese código o, si no está en el catálogo, el código.
  String nombreDe(String? codigo) {
    if (codigo == null || codigo.isEmpty) return '';
    for (final idioma in this) {
      if (idioma.codigo == codigo) return idioma.nombre;
    }
    return codigo.toUpperCase();
  }

  Idioma? porCodigo(String? codigo) {
    for (final idioma in this) {
      if (idioma.codigo == codigo) return idioma;
    }
    return null;
  }
}

/// Elemento genérico de un catálogo (entorno, contexto...).
class OpcionCatalogo {
  const OpcionCatalogo({required this.id, required this.nombre, this.descripcion});

  final int id;
  final String nombre;
  final String? descripcion;
}
