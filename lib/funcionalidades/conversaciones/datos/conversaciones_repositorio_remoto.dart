import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/dominio/conversaciones.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// app/api/routes/conversaciones.py e intervenciones.py.
class ConversacionesRepositorioRemoto implements ConversacionesRepositorio {
  ConversacionesRepositorioRemoto(this._dio);

  final Dio _dio;

  /// Traducir una intervención puede tardar más que una petición normal.
  static const Duration tiempoIntervencion = Duration(minutes: 2);

  @override
  Future<List<Conversacion>> listar() async => [
        for (final json in listaDeMapas(await resultadoDe(_dio.get<dynamic>('/conversaciones'))))
          _conversacion(json),
      ];

  @override
  Future<Conversacion> iniciar(NuevaConversacion datos) => _conversacionDe(
        _dio.post<dynamic>(
          '/conversaciones',
          data: {
            'id_idioma_origen': datos.idIdiomaOrigen,
            'id_idioma_destino': datos.idIdiomaDestino,
            'id_entorno': datos.idEntorno,
            'id_contexto': ?datos.idContexto,
            'descripcion_contexto': ?datos.descripcionContexto,
            'mantener_contexto': datos.mantenerContexto,
          },
        ),
      );

  @override
  Future<Conversacion> obtener(int id) => _conversacionDe(_dio.get<dynamic>('/conversaciones/$id'));

  @override
  Future<List<Intervencion>> intervenciones(int id, {int? despuesDe}) async => [
        for (final json in listaDeMapas(
          await resultadoDe(
            _dio.get<dynamic>(
              '/conversaciones/$id/intervenciones',
              queryParameters: parametros({'despues_de': despuesDe}),
            ),
          ),
        ))
          _intervencion(json),
      ];

  @override
  Future<Intervencion> registrar(int id, {required String texto, int? idParticipante}) async =>
      _intervencion(
        await resultadoDe(
          _dio.post<dynamic>(
            '/conversaciones/$id/intervenciones',
            data: {'id_participante': idParticipante, 'texto': texto.trim()},
            options: Options(receiveTimeout: tiempoIntervencion),
          ),
        ) as Map<String, dynamic>,
      );

  @override
  Future<Intervencion> reintentar(int id, int idIntervencion) async => _intervencion(
        await resultadoDe(
          _dio.post<dynamic>(
            '/conversaciones/$id/intervenciones/$idIntervencion/reintentar',
            options: Options(receiveTimeout: tiempoIntervencion),
          ),
        ) as Map<String, dynamic>,
      );

  @override
  Future<Conversacion> pausar(int id) =>
      _conversacionDe(_dio.post<dynamic>('/conversaciones/$id/pausar'));

  @override
  Future<Conversacion> reanudar(int id) =>
      _conversacionDe(_dio.post<dynamic>('/conversaciones/$id/reanudar'));

  @override
  Future<Conversacion> finalizar(int id) =>
      _conversacionDe(_dio.post<dynamic>('/conversaciones/$id/finalizar'));

  Future<Conversacion> _conversacionDe(Future<Response<dynamic>> peticion) async =>
      _conversacion(await resultadoDe(peticion) as Map<String, dynamic>);

  Conversacion _conversacion(Map<String, dynamic> json) => Conversacion(
        id: json['id_conversacion'] as int,
        estado: EstadoConversacion.desdeCodigo(json['estado'] as String),
        fechaInicio: fechaDe(json['fecha_inicio']) ?? DateTime.now(),
        nombreIdiomaOrigen: json['nombre_idioma_origen'] as String?,
        nombreIdiomaDestino: json['nombre_idioma_destino'] as String?,
        nombreEntorno: json['nombre_entorno'] as String?,
        nombreContexto: json['nombre_contexto'] as String?,
        descripcionContexto: json['descripcion_contexto'] as String?,
        participantes: [
          for (final participante in listaDeMapas(json['participantes']))
            Participante(
              id: participante['id_participante'] as int,
              nombre: participante['nombre'] as String,
              orden: participante['orden'] as int,
              codigoIdioma: participante['codigo_idioma'] as String?,
              nombreIdioma: participante['nombre_idioma'] as String?,
            ),
        ]..sort((a, b) => a.orden.compareTo(b.orden)),
      );

  Intervencion _intervencion(Map<String, dynamic> json) => Intervencion(
        id: json['id_intervencion'] as int,
        orden: json['orden'] as int,
        idParticipante: json['id_participante'] as int?,
        nombreParticipante: json['nombre_participante'] as String?,
        ordenParticipante: json['orden_participante'] as int?,
        textoOriginal: json['texto_original'] as String,
        textoTraducido: json['texto_traducido'] as String?,
        nombreIdiomaOrigen: json['nombre_idioma_origen'] as String?,
        nombreIdiomaDestino: json['nombre_idioma_destino'] as String?,
        estado: json['estado'] as String,
        fecha: fechaDe(json['fecha_creacion']) ?? DateTime.now(),
      );
}

final conversacionesRepositorioProvider = Provider<ConversacionesRepositorio>(
  (ref) => ConversacionesRepositorioRemoto(ref.watch(clienteHttpProvider)),
);
