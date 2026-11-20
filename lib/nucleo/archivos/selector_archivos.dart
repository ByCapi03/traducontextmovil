import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Archivo elegido por el usuario, ya leído en memoria.
class ArchivoSeleccionado {
  const ArchivoSeleccionado({required this.nombre, required this.bytes});

  final String nombre;
  final List<int> bytes;
}

/// Selector de archivos del sistema (interfaz para sustituirlo en pruebas).
abstract interface class SelectorArchivos {
  /// null si el usuario cancela.
  Future<ArchivoSeleccionado?> elegir({required List<String> extensiones});
}

class SelectorArchivosDispositivo implements SelectorArchivos {
  @override
  Future<ArchivoSeleccionado?> elegir({required List<String> extensiones}) async {
    final archivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensiones,
    );
    if (archivo == null) return null;
    return ArchivoSeleccionado(nombre: archivo.name, bytes: await archivo.readAsBytes());
  }
}

final selectorArchivosProvider = Provider<SelectorArchivos>((ref) => SelectorArchivosDispositivo());
