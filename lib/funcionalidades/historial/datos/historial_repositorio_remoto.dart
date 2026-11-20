import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/historial/dominio/historial.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// Historial de app/api/routes/traducciones.py. El usuario sale del token.
class HistorialRepositorioRemoto implements HistorialRepositorio {
  HistorialRepositorioRemoto(this._dio);

  final Dio _dio;

  @override
  Future<List<EntradaHistorial>> listar({String? texto, bool soloFavoritos = false}) async {
    final resultado = await resultadoDe(
      _dio.get<dynamic>(
        '/traducciones/historial',
        queryParameters: parametros({
          'texto': texto?.trim(),
          if (soloFavoritos) 'solo_favoritos': true,
        }),
      ),
    );
    return [
      for (final json in listaDeMapas(resultado))
        EntradaHistorial(
          id: json['id_traduccion'] as int,
          textoOriginal: json['texto_original'] as String,
          textoTraducido: json['texto_traducido'] as String,
          idiomaOrigen: json['idioma_origen'] as String,
          idiomaDestino: json['idioma_destino'] as String,
          fecha: fechaDe(json['fecha_creacion']) ?? DateTime.now(),
          favorito: json['favorito'] as bool? ?? false,
          nombreContexto: json['nombre_contexto'] as String?,
        ),
    ];
  }

  @override
  Future<void> marcarFavorito(int id, {required bool favorito}) => resultadoDe(
        _dio.patch<dynamic>('/traducciones/$id/favorito', data: {'favorito': favorito}),
      );

  @override
  Future<void> eliminar(int id) => resultadoDe(_dio.delete<dynamic>('/traducciones/$id'));
}

/// Se incrementa cuando se guarda una traducción nueva para que el historial
/// (que conserva su estado en la pestaña) se recargue.
final versionHistorialProvider = StateProvider<int>((ref) => 0);

final historialRepositorioProvider = Provider<HistorialRepositorio>(
  (ref) => HistorialRepositorioRemoto(ref.watch(clienteHttpProvider)),
);
