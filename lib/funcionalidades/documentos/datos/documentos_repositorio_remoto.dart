import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/documentos/dominio/documentos.dart';
import 'package:traducontextmovil/nucleo/archivos/gestor_archivos.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// app/api/routes/documentos.py. El usuario sale del token.
class DocumentosRepositorioRemoto implements DocumentosRepositorio {
  DocumentosRepositorioRemoto(this._dio);

  final Dio _dio;

  /// La traducción de un documento es síncrona y puede superar el tiempo
  /// de respuesta general (60 s).
  static const Duration tiempoTraduccion = Duration(minutes: 10);

  @override
  Future<List<Documento>> listarOriginales() async => [
        for (final json in listaDeMapas(await resultadoDe(_dio.get<dynamic>('/documentos'))))
          _documento(json),
      ];

  @override
  Future<List<DocumentoTraducido>> listarTraducidos() async => [
        for (final json
            in listaDeMapas(await resultadoDe(_dio.get<dynamic>('/documentos/traducciones'))))
          _traducido(json),
      ];

  @override
  Future<Documento> subir({required String nombre, required List<int> bytes}) async {
    final formulario = FormData.fromMap({
      'archivo': MultipartFile.fromBytes(bytes, filename: nombre),
    });
    final json = await resultadoDe(
      _dio.post<dynamic>(
        '/documentos/subir',
        data: formulario,
        options: Options(contentType: 'multipart/form-data', sendTimeout: tiempoTraduccion),
      ),
    ) as Map<String, dynamic>;
    return _documento(json);
  }

  @override
  Future<DocumentoTraducido> traducir({
    required int idDocumento,
    required String idiomaDestino,
    String? idiomaOrigen,
  }) async {
    final json = await resultadoDe(
      _dio.post<dynamic>(
        '/documentos/traducir',
        data: {
          'id_documento': idDocumento,
          'idioma_destino': idiomaDestino,
          'idioma_origen': ?idiomaOrigen,
        },
        options: Options(receiveTimeout: tiempoTraduccion),
      ),
    ) as Map<String, dynamic>;
    return _traducido(json);
  }

  @override
  Future<ArchivoDescargado> descargar(DocumentoTraducido traducido) => descargarArchivo(
        _dio,
        '/documentos/descargar/${traducido.id}',
        nombrePorDefecto: traducido.nombre,
      );

  @override
  Future<void> eliminarOriginal(int idDocumento) =>
      resultadoDe(_dio.delete<dynamic>('/documentos/$idDocumento'));

  @override
  Future<void> eliminarTraducido(int idTraduccion) =>
      resultadoDe(_dio.delete<dynamic>('/documentos/traducciones/$idTraduccion'));

  Documento _documento(Map<String, dynamic> json) => Documento(
        id: json['id_documento'] as int,
        nombre: json['nombre'] as String,
        extension: json['extension'] as String,
        tamano: json['tamano'] as int? ?? 0,
        fecha: fechaDe(json['fecha_carga']) ?? DateTime.now(),
      );

  DocumentoTraducido _traducido(Map<String, dynamic> json) => DocumentoTraducido(
        id: json['id_traduccion_documento'] as int,
        idDocumento: json['id_documento'] as int?,
        nombre: json['nombre'] as String,
        estado: json['estado'] as String,
        fecha: fechaDe(json['fecha']) ?? DateTime.now(),
        codigoOrigen: json['codigo_idioma_origen'] as String?,
        codigoDestino: json['codigo_idioma_destino'] as String?,
        nombreOriginal: json['nombre_documento_original'] as String?,
      );
}

final documentosRepositorioProvider = Provider<DocumentosRepositorio>(
  (ref) => DocumentosRepositorioRemoto(ref.watch(clienteHttpProvider)),
);
