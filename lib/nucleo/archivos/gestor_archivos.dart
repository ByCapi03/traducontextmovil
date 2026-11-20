import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

/// Archivo descargado del backend (reporte exportado, documento traducido).
class ArchivoDescargado {
  const ArchivoDescargado({required this.bytes, required this.nombre});

  final List<int> bytes;
  final String nombre;
}

/// Descarga un archivo binario y toma el nombre de Content-Disposition.
Future<ArchivoDescargado> descargarArchivo(
  Dio dio,
  String ruta, {
  Map<String, dynamic>? parametros,
  required String nombrePorDefecto,
}) async {
  try {
    final respuesta = await dio.get<List<int>>(
      ruta,
      queryParameters: parametros,
      options: Options(responseType: ResponseType.bytes),
    );
    final disposicion = respuesta.headers.value('content-disposition') ?? '';
    final coincidencia = RegExp(r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''').firstMatch(disposicion);
    final nombre = coincidencia == null
        ? nombrePorDefecto
        : Uri.decodeComponent(coincidencia.group(1)!.trim());
    return ArchivoDescargado(bytes: respuesta.data ?? const [], nombre: nombre);
  } on DioException catch (error) {
    throw ExcepcionApi.desdeDio(error);
  }
}

/// Guarda un archivo y abre el menú del sistema para abrirlo, guardarlo o
/// compartirlo. Interfaz para poder sustituirlo en las pruebas.
abstract interface class GestorArchivos {
  Future<void> guardarYCompartir(ArchivoDescargado archivo);
}

class GestorArchivosDispositivo implements GestorArchivos {
  @override
  Future<void> guardarYCompartir(ArchivoDescargado archivo) async {
    final carpeta = await getTemporaryDirectory();
    final nombreSeguro = archivo.nombre.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final ruta = '${carpeta.path}${Platform.pathSeparator}$nombreSeguro';
    await File(ruta).writeAsBytes(archivo.bytes, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(ruta)], title: nombreSeguro));
  }
}

final gestorArchivosProvider = Provider<GestorArchivos>((ref) => GestorArchivosDispositivo());
