import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/nombres_idioma.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/dominio/glosarios.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// app/api/routes/glosarios.py.
class GlosariosRepositorioRemoto implements GlosariosRepositorio {
  GlosariosRepositorioRemoto(this._dio);

  final Dio _dio;

  @override
  Future<List<Glosario>> listar() async => [
        for (final json in listaDeMapas(await resultadoDe(_dio.get<dynamic>('/glosarios')))) _glosario(json),
      ];

  @override
  Future<Glosario> obtener(int id) async => _glosarioDe(_dio.get<dynamic>('/glosarios/$id'));

  @override
  Future<Glosario> crear(DatosGlosario datos) => _glosarioDe(_dio.post<dynamic>('/glosarios', data: _json(datos)));

  @override
  Future<Glosario> actualizar(int id, DatosGlosario datos) =>
      _glosarioDe(_dio.patch<dynamic>('/glosarios/$id', data: _json(datos)));

  @override
  Future<void> eliminar(int id) => resultadoDe(_dio.delete<dynamic>('/glosarios/$id'));

  @override
  Future<TerminoGlosario> agregarTermino(int idGlosario, DatosTermino datos) async => _termino(
        await resultadoDe(_dio.post<dynamic>('/glosarios/$idGlosario/terminos', data: _jsonTermino(datos)))
            as Map<String, dynamic>,
      );

  @override
  Future<TerminoGlosario> actualizarTermino(int idGlosario, int idTermino, DatosTermino datos) async => _termino(
        await resultadoDe(
          _dio.patch<dynamic>('/glosarios/$idGlosario/terminos/$idTermino', data: _jsonTermino(datos)),
        ) as Map<String, dynamic>,
      );

  @override
  Future<void> eliminarTermino(int idGlosario, int idTermino) =>
      resultadoDe(_dio.delete<dynamic>('/glosarios/$idGlosario/terminos/$idTermino'));

  Map<String, dynamic> _json(DatosGlosario datos) => {
        'nombre': datos.nombre.trim(),
        'descripcion': (datos.descripcion?.trim().isEmpty ?? true) ? null : datos.descripcion!.trim(),
        'id_idioma_origen': datos.idIdiomaOrigen,
        'id_idioma_destino': datos.idIdiomaDestino,
      };

  Map<String, dynamic> _jsonTermino(DatosTermino datos) => {
        'termino_origen': datos.terminoOrigen.trim(),
        'traduccion_preferida': datos.conservarOriginal ? null : datos.traduccionPreferida?.trim(),
        'conservar_original': datos.conservarOriginal,
        'distinguir_mayusculas': datos.distinguirMayusculas,
        'nota': (datos.nota?.trim().isEmpty ?? true) ? null : datos.nota!.trim(),
      };

  Future<Glosario> _glosarioDe(Future<Response<dynamic>> peticion) async =>
      _glosario(await resultadoDe(peticion) as Map<String, dynamic>);

  Glosario _glosario(Map<String, dynamic> json) => Glosario(
        id: json['id_glosario'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        idIdiomaOrigen: json['id_idioma_origen'] as int,
        idIdiomaDestino: json['id_idioma_destino'] as int,
        codigoIdiomaOrigen: json['codigo_idioma_origen'] as String?,
        codigoIdiomaDestino: json['codigo_idioma_destino'] as String?,
        nombreIdiomaOrigen: nombreIdiomaOpcional(
          json['codigo_idioma_origen'] as String?,
          respaldo: json['nombre_idioma_origen'] as String?,
        ),
        nombreIdiomaDestino: nombreIdiomaOpcional(
          json['codigo_idioma_destino'] as String?,
          respaldo: json['nombre_idioma_destino'] as String?,
        ),
        cantidadTerminos: json['cantidad_terminos'] as int? ?? 0,
        terminos: [for (final termino in listaDeMapas(json['terminos'])) _termino(termino)],
      );

  TerminoGlosario _termino(Map<String, dynamic> json) => TerminoGlosario(
        id: json['id_termino_glosario'] as int,
        terminoOrigen: json['termino_origen'] as String,
        traduccionPreferida: json['traduccion_preferida'] as String?,
        conservarOriginal: json['conservar_original'] as bool? ?? false,
        distinguirMayusculas: json['distinguir_mayusculas'] as bool? ?? false,
        nota: json['nota'] as String?,
      );
}

final glosariosRepositorioProvider = Provider<GlosariosRepositorio>(
  (ref) => GlosariosRepositorioRemoto(ref.watch(clienteHttpProvider)),
);

/// Glosarios del usuario (lista y selectores). `ref.invalidate` tras cambiarlos.
final glosariosProvider = FutureProvider<List<Glosario>>((ref) {
  ref.watch(usuarioActualProvider.select((usuario) => usuario?.id));
  return ref.watch(glosariosRepositorioProvider).listar();
});

/// Detalle de un glosario con sus términos.
final glosarioProvider = FutureProvider.autoDispose.family<Glosario, int>(
  (ref, id) => ref.watch(glosariosRepositorioProvider).obtener(id),
);
