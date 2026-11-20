import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/dominio/idioma.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// Catálogos de solo lectura compartidos por varias funcionalidades.
class CatalogosApi {
  CatalogosApi(this._dio);

  final Dio _dio;

  /// GET /idiomas
  Future<List<Idioma>> idiomas() async {
    final resultado = await resultadoDe(_dio.get<dynamic>('/idiomas'));
    final idiomas = [
      for (final json in listaDeMapas(resultado))
        Idioma(
          id: json['id_idioma'] as int,
          nombre: json['nombre'] as String,
          codigo: json['codigo'] as String,
        ),
    ]..sort((a, b) => a.nombre.compareTo(b.nombre));
    return idiomas;
  }
}

final catalogosApiProvider = Provider<CatalogosApi>(
  (ref) => CatalogosApi(ref.watch(clienteHttpProvider)),
);

/// Se pide una vez por sesión de la app; `ref.invalidate` para reintentar.
final idiomasProvider = FutureProvider<List<Idioma>>(
  (ref) => ref.watch(catalogosApiProvider).idiomas(),
);
