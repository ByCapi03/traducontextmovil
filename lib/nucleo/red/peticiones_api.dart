import 'package:dio/dio.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

/// Ejecuta una peticion y devuelve el campo `resultado` de la respuesta
/// (`{ "mensaje": ..., "resultado": ... }`). Convierte los errores de dio en
/// [ExcepcionApi].
Future<dynamic> resultadoDe(Future<Response<dynamic>> peticion) async {
  try {
    final respuesta = await peticion;
    final datos = respuesta.data;
    return datos is Map ? datos['resultado'] : datos;
  } on DioException catch (error) {
    throw ExcepcionApi.desdeDio(error);
  }
}

/// Lee un `resultado` que debe ser una lista de objetos.
List<Map<String, dynamic>> listaDeMapas(dynamic resultado) => [
      for (final elemento in (resultado as List<dynamic>? ?? const []))
        elemento as Map<String, dynamic>,
    ];

/// Lee una fecha ISO del backend y la pasa a hora local.
DateTime? fechaDe(dynamic valor) =>
    valor is String ? DateTime.tryParse(valor)?.toLocal() : null;

/// Quita de los parametros de consulta los valores nulos o vacios.
Map<String, dynamic> parametros(Map<String, dynamic> valores) => {
      for (final MapEntry(:key, :value) in valores.entries)
        if (value != null && !(value is String && value.isEmpty)) key: value,
    };
