import 'package:traducontextmovil/nucleo/archivos/gestor_archivos.dart';

/// Extensiones que acepta el backend (traduccion_documentos.py).
const List<String> extensionesDocumento = ['docx', 'xlsx', 'pdf'];

/// Documento original subido por el usuario.
class Documento {
  const Documento({
    required this.id,
    required this.nombre,
    required this.extension,
    required this.tamano,
    required this.fecha,
  });

  final int id;
  final String nombre;
  final String extension;
  final int tamano;
  final DateTime fecha;
}

/// Traducción de un documento (el archivo traducido descargable).
class DocumentoTraducido {
  const DocumentoTraducido({
    required this.id,
    required this.nombre,
    required this.estado,
    required this.fecha,
    this.idDocumento,
    this.codigoOrigen,
    this.codigoDestino,
    this.nombreOriginal,
  });

  final int id;
  final int? idDocumento;
  final String nombre;
  final String estado;
  final DateTime fecha;
  final String? codigoOrigen;
  final String? codigoDestino;
  final String? nombreOriginal;

  bool get completado => estado.toUpperCase() == 'COMPLETADO';
}

/// Lanza `ExcepcionApi` si el backend responde con error.
abstract interface class DocumentosRepositorio {
  Future<List<Documento>> listarOriginales();

  Future<List<DocumentoTraducido>> listarTraducidos();

  Future<Documento> subir({required String nombre, required List<int> bytes});

  /// Síncrono en el backend: puede tardar según el tamaño del documento.
  Future<DocumentoTraducido> traducir({
    required int idDocumento,
    required String idiomaDestino,
    String? idiomaOrigen,
  });

  Future<ArchivoDescargado> descargar(DocumentoTraducido traducido);

  Future<void> eliminarOriginal(int idDocumento);

  Future<void> eliminarTraducido(int idTraduccion);
}
