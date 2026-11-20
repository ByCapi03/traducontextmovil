import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/chats/dominio/chats.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// Endpoints REST de app/api/routes/chats.py. No hay WebSocket en el
/// backend: el chat abierto se refresca periódicamente.
class ChatsRepositorioRemoto implements ChatsRepositorio {
  ChatsRepositorioRemoto(this._dio);

  final Dio _dio;

  @override
  Future<List<Chat>> listar() async => [
        for (final json in listaDeMapas(await resultadoDe(_dio.get<dynamic>('/chats')))) _chat(json),
      ];

  @override
  Future<List<UsuarioChat>> buscarUsuarios(String texto) async => [
        for (final json in listaDeMapas(
          await resultadoDe(
            _dio.get<dynamic>('/chats/usuarios', queryParameters: {'q': texto.trim(), 'limite': 20}),
          ),
        ))
          UsuarioChat(id: json['id_usuario'] as int, nombre: json['nombre'] as String),
      ];

  @override
  Future<Chat> crearOObtener(int idUsuario) async =>
      _chat(await resultadoDe(_dio.post<dynamic>('/chats', data: {'id_usuario': idUsuario})) as Map<String, dynamic>);

  @override
  Future<Chat> obtener(int idChat) async =>
      _chat(await resultadoDe(_dio.get<dynamic>('/chats/$idChat')) as Map<String, dynamic>);

  @override
  Future<Chat> cambiarIdiomaLectura(int idChat, String codigoIdioma) async => _chat(
        await resultadoDe(
          _dio.patch<dynamic>('/chats/$idChat/idioma-lectura', data: {'codigo_idioma': codigoIdioma}),
        ) as Map<String, dynamic>,
      );

  @override
  Future<PaginaMensajes> mensajes(int idChat, {int? despuesDe, int? antesDe}) async {
    final json = await resultadoDe(
      _dio.get<dynamic>(
        '/chats/$idChat/mensajes',
        queryParameters: parametros({'despues_de': despuesDe, 'antes_de': antesDe, 'limite': 50}),
      ),
    ) as Map<String, dynamic>;
    return PaginaMensajes(
      elementos: [for (final mensaje in listaDeMapas(json['elementos'])) _mensaje(mensaje)],
      hayMas: json['hay_mas'] as bool? ?? false,
    );
  }

  @override
  Future<MensajeChat> enviar(int idChat, String texto) async => _mensaje(
        await resultadoDe(_dio.post<dynamic>('/chats/$idChat/mensajes', data: {'texto': texto.trim()}))
            as Map<String, dynamic>,
      );

  @override
  Future<void> marcarLeido(int idChat, int idMensaje) =>
      resultadoDe(_dio.post<dynamic>('/chats/$idChat/leido', data: {'id_mensaje': idMensaje}));

  Chat _chat(Map<String, dynamic> json) {
    final otro = json['otro_usuario'] as Map<String, dynamic>;
    final idioma = json['mi_idioma_lectura'] as Map<String, dynamic>;
    final ultimo = json['ultimo_mensaje'] as Map<String, dynamic>?;
    return Chat(
      id: json['id_chat'] as int,
      otroUsuario: UsuarioChat(id: otro['id_usuario'] as int, nombre: otro['nombre'] as String),
      codigoIdiomaLectura: idioma['codigo'] as String,
      nombreIdiomaLectura: idioma['nombre'] as String,
      ultimoMensaje: ultimo == null ? null : _mensaje(ultimo),
      noLeidos: json['no_leidos'] as int? ?? 0,
      fechaCreacion: fechaDe(json['fecha_creacion']) ?? DateTime.now(),
      fechaUltimoMensaje: fechaDe(json['fecha_ultimo_mensaje']),
    );
  }

  MensajeChat _mensaje(Map<String, dynamic> json) => MensajeChat(
        id: json['id_mensaje'] as int,
        esMio: json['es_mio'] as bool,
        texto: json['texto'] as String,
        textoOriginal: json['texto_original'] as String,
        idiomaOriginal: json['idioma_original'] as String?,
        idiomaTexto: json['idioma_texto'] as String?,
        estadoLectura: json['estado_lectura'] as String,
        fecha: fechaDe(json['fecha_envio']) ?? DateTime.now(),
      );
}

final chatsRepositorioProvider = Provider<ChatsRepositorio>(
  (ref) => ChatsRepositorioRemoto(ref.watch(clienteHttpProvider)),
);
