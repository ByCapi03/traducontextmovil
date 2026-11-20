import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
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

  /// GET /entornos (HU-24): dónde ocurre la conversación.
  Future<List<OpcionCatalogo>> entornos() => _opciones('/entornos', 'id_entorno');

  /// GET /contextos: contextos de dominio activos (generales y del usuario).
  Future<List<OpcionCatalogo>> contextos() => _opciones('/contextos', 'id_contexto');

  Future<List<OpcionCatalogo>> _opciones(String ruta, String campoId) async {
    final resultado = await resultadoDe(_dio.get<dynamic>(ruta));
    return [
      for (final json in listaDeMapas(resultado))
        if (json['activo'] as bool? ?? true)
          OpcionCatalogo(
            id: json[campoId] as int,
            nombre: json['nombre'] as String,
            descripcion: json['descripcion'] as String?,
          ),
    ];
  }
}

final catalogosApiProvider = Provider<CatalogosApi>(
  (ref) => CatalogosApi(ref.watch(clienteHttpProvider)),
);

final entornosProvider = FutureProvider<List<OpcionCatalogo>>(
  (ref) => ref.watch(catalogosApiProvider).entornos(),
);

/// Incluye los contextos personalizados del usuario: depende de la cuenta.
final contextosProvider = FutureProvider<List<OpcionCatalogo>>((ref) {
  ref.watch(usuarioActualProvider.select((usuario) => usuario?.id));
  return ref.watch(catalogosApiProvider).contextos();
});

/// Se pide una vez por sesión de la app; `ref.invalidate` para reintentar.
final idiomasProvider = FutureProvider<List<Idioma>>(
  (ref) => ref.watch(catalogosApiProvider).idiomas(),
);
