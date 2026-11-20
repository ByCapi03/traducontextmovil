/// Traducción guardada en el historial (GET /traducciones/historial).
class EntradaHistorial {
  const EntradaHistorial({
    required this.id,
    required this.textoOriginal,
    required this.textoTraducido,
    required this.idiomaOrigen,
    required this.idiomaDestino,
    required this.fecha,
    required this.favorito,
    this.nombreContexto,
  });

  final int id;
  final String textoOriginal;
  final String textoTraducido;
  final String idiomaOrigen;
  final String idiomaDestino;
  final DateTime fecha;
  final bool favorito;
  final String? nombreContexto;

  EntradaHistorial conFavorito(bool valor) => EntradaHistorial(
        id: id,
        textoOriginal: textoOriginal,
        textoTraducido: textoTraducido,
        idiomaOrigen: idiomaOrigen,
        idiomaDestino: idiomaDestino,
        fecha: fecha,
        favorito: valor,
        nombreContexto: nombreContexto,
      );
}

/// Lanza `ExcepcionApi` si el backend responde con error.
abstract interface class HistorialRepositorio {
  Future<List<EntradaHistorial>> listar({String? texto, bool soloFavoritos = false});

  Future<void> marcarFavorito(int id, {required bool favorito});

  Future<void> eliminar(int id);
}
