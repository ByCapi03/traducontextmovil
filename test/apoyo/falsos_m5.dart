import 'package:traducontextmovil/funcionalidades/chats/dominio/chats.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/dominio/conversaciones.dart';
import 'package:traducontextmovil/funcionalidades/documentos/dominio/documentos.dart';
import 'package:traducontextmovil/nucleo/archivos/gestor_archivos.dart';
import 'package:traducontextmovil/nucleo/archivos/selector_archivos.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

class DocumentosFalsos implements DocumentosRepositorio {
  List<Documento> originales = [];
  List<DocumentoTraducido> traducidos = [];
  final List<String> eventos = [];

  @override
  Future<List<Documento>> listarOriginales() async => originales;

  @override
  Future<List<DocumentoTraducido>> listarTraducidos() async => traducidos;

  @override
  Future<Documento> subir({required String nombre, required List<int> bytes}) async {
    eventos.add('subir:$nombre');
    final documento = Documento(
      id: originales.length + 1,
      nombre: nombre,
      extension: nombre.split('.').last,
      tamano: bytes.length,
      fecha: DateTime(2026, 11, 20, 10),
    );
    originales = [...originales, documento];
    return documento;
  }

  @override
  Future<DocumentoTraducido> traducir({
    required int idDocumento,
    required String idiomaDestino,
    String? idiomaOrigen,
  }) async {
    eventos.add('traducir:$idDocumento:${idiomaOrigen ?? 'auto'}:$idiomaDestino');
    final traducido = DocumentoTraducido(
      id: 50 + traducidos.length,
      idDocumento: idDocumento,
      nombre: 'informe_$idiomaDestino.docx',
      estado: 'COMPLETADO',
      fecha: DateTime(2026, 11, 20, 10, 5),
      codigoOrigen: idiomaOrigen ?? 'es',
      codigoDestino: idiomaDestino,
    );
    traducidos = [...traducidos, traducido];
    return traducido;
  }

  @override
  Future<ArchivoDescargado> descargar(DocumentoTraducido traducido) async {
    eventos.add('descargar:${traducido.id}');
    return ArchivoDescargado(bytes: const [1, 2], nombre: traducido.nombre);
  }

  @override
  Future<void> eliminarOriginal(int idDocumento) async {
    eventos.add('eliminar-original:$idDocumento');
    originales = [...originales.where((d) => d.id != idDocumento)];
  }

  @override
  Future<void> eliminarTraducido(int idTraduccion) async {
    eventos.add('eliminar-traducido:$idTraduccion');
    traducidos = [...traducidos.where((d) => d.id != idTraduccion)];
  }
}

class SelectorArchivosFalso implements SelectorArchivos {
  ArchivoSeleccionado? archivo = const ArchivoSeleccionado(nombre: 'informe.docx', bytes: [1, 2, 3]);

  @override
  Future<ArchivoSeleccionado?> elegir({required List<String> extensiones}) async => archivo;
}

class GestorArchivosFalso implements GestorArchivos {
  final List<String> compartidos = [];

  @override
  Future<void> guardarYCompartir(ArchivoDescargado archivo) async => compartidos.add(archivo.nombre);
}

class ChatsFalsos implements ChatsRepositorio {
  static const UsuarioChat luis = UsuarioChat(id: 9, nombre: 'Luis');

  List<MensajeChat> mensajesServidor = [
    MensajeChat(
      id: 1,
      esMio: false,
      texto: 'Hola, ¿cómo estás?',
      textoOriginal: 'Hi, how are you?',
      idiomaOriginal: 'en',
      idiomaTexto: 'es',
      estadoLectura: EstadoLectura.traducido,
      fecha: DateTime(2026, 11, 20, 9),
    ),
  ];
  final List<String> enviados = [];
  final List<int> leidos = [];
  int consultasMensajes = 0;
  final List<String> cambiosIdioma = [];

  Chat _chat({String codigo = 'es', String nombre = 'Español'}) => Chat(
        id: 3,
        otroUsuario: luis,
        codigoIdiomaLectura: codigo,
        nombreIdiomaLectura: nombre,
        noLeidos: 1,
        fechaCreacion: DateTime(2026, 11, 19),
        ultimoMensaje: mensajesServidor.last,
        fechaUltimoMensaje: mensajesServidor.last.fecha,
      );

  @override
  Future<List<Chat>> listar() async => [_chat()];

  final List<String> busquedas = [];
  ExcepcionApi? errorBusqueda;

  @override
  Future<List<UsuarioChat>> buscarUsuarios(String texto) async {
    busquedas.add(texto);
    final error = errorBusqueda;
    if (error != null) throw error;
    return 'luis'.contains(texto.toLowerCase()) ? [luis] : [];
  }

  @override
  Future<Chat> crearOObtener(int idUsuario) async => _chat();

  @override
  Future<Chat> obtener(int idChat) async => _chat();

  @override
  Future<Chat> cambiarIdiomaLectura(int idChat, String codigoIdioma) async {
    cambiosIdioma.add(codigoIdioma);
    return _chat(codigo: codigoIdioma, nombre: codigoIdioma == 'fr' ? 'Francés' : codigoIdioma);
  }

  @override
  Future<PaginaMensajes> mensajes(int idChat, {int? despuesDe, int? antesDe}) async {
    consultasMensajes++;
    return PaginaMensajes(
      elementos: [
        for (final mensaje in mensajesServidor)
          if ((despuesDe == null || mensaje.id > despuesDe) && (antesDe == null || mensaje.id < antesDe))
            mensaje,
      ],
      hayMas: false,
    );
  }

  @override
  Future<MensajeChat> enviar(int idChat, String texto) async {
    enviados.add(texto);
    final mensaje = MensajeChat(
      id: mensajesServidor.last.id + 1,
      esMio: true,
      texto: texto,
      textoOriginal: texto,
      estadoLectura: EstadoLectura.propio,
      fecha: DateTime(2026, 11, 20, 9, 5),
    );
    mensajesServidor = [...mensajesServidor, mensaje];
    return mensaje;
  }

  @override
  Future<void> marcarLeido(int idChat, int idMensaje) async => leidos.add(idMensaje);
}

class ConversacionesFalsas implements ConversacionesRepositorio {
  EstadoConversacion estado = EstadoConversacion.activa;
  List<Intervencion> intervencionesServidor = [];
  final List<String> eventos = [];
  NuevaConversacion? creada;
  bool fallarTraduccion = false;

  Conversacion get _conversacion => Conversacion(
        id: 4,
        estado: estado,
        fechaInicio: DateTime(2026, 11, 20, 8),
        nombreIdiomaOrigen: 'Español',
        nombreIdiomaDestino: 'Inglés',
        nombreEntorno: 'Consulta médica',
        participantes: const [
          Participante(id: 21, nombre: 'Participante 1', orden: 1, codigoIdioma: 'es', nombreIdioma: 'Español'),
          Participante(id: 22, nombre: 'Participante 2', orden: 2, codigoIdioma: 'en', nombreIdioma: 'Inglés'),
        ],
      );

  @override
  Future<List<Conversacion>> listar() async => [_conversacion];

  @override
  Future<Conversacion> iniciar(NuevaConversacion datos) async {
    creada = datos;
    return _conversacion;
  }

  @override
  Future<Conversacion> obtener(int id) async => _conversacion;

  @override
  Future<List<Intervencion>> intervenciones(int id, {int? despuesDe}) async => [
        for (final i in intervencionesServidor)
          if (despuesDe == null || i.id > despuesDe) i,
      ];

  @override
  Future<Intervencion> registrar(int id, {required String texto, int? idParticipante}) async {
    eventos.add('registrar:${idParticipante ?? 'ninguno'}:$texto');
    final intervencion = Intervencion(
      id: intervencionesServidor.length + 1,
      orden: intervencionesServidor.length + 1,
      idParticipante: idParticipante,
      nombreParticipante: idParticipante == 22 ? 'Participante 2' : 'Participante 1',
      ordenParticipante: idParticipante == 22 ? 2 : 1,
      textoOriginal: texto,
      textoTraducido: fallarTraduccion ? null : 'EN: $texto',
      estado: fallarTraduccion ? EstadoIntervencion.error : EstadoIntervencion.traducida,
      codigoIdiomaDestino: idParticipante == 22 ? 'es' : 'en',
      nombreIdiomaDestino: idParticipante == 22 ? 'Español' : 'Inglés',
      fecha: DateTime(2026, 11, 20, 8, 1),
    );
    intervencionesServidor = [...intervencionesServidor, intervencion];
    return intervencion;
  }

  @override
  Future<Intervencion> reintentar(int id, int idIntervencion) async {
    eventos.add('reintentar:$idIntervencion');
    final original = intervencionesServidor.firstWhere((i) => i.id == idIntervencion);
    final corregida = Intervencion(
      id: original.id,
      orden: original.orden,
      idParticipante: original.idParticipante,
      nombreParticipante: original.nombreParticipante,
      ordenParticipante: original.ordenParticipante,
      textoOriginal: original.textoOriginal,
      textoTraducido: 'EN: ${original.textoOriginal}',
      estado: EstadoIntervencion.traducida,
      fecha: original.fecha,
    );
    intervencionesServidor = [for (final i in intervencionesServidor) i.id == idIntervencion ? corregida : i];
    return corregida;
  }

  Future<Conversacion> _cambiar(String accion, EstadoConversacion nuevo) async {
    eventos.add(accion);
    if (estado == EstadoConversacion.finalizada) {
      throw const ExcepcionApi('ya finalizada', codigoEstado: 400);
    }
    estado = nuevo;
    return _conversacion;
  }

  @override
  Future<Conversacion> pausar(int id) => _cambiar('pausar', EstadoConversacion.pausada);

  @override
  Future<Conversacion> reanudar(int id) => _cambiar('reanudar', EstadoConversacion.activa);

  @override
  Future<Conversacion> finalizar(int id) => _cambiar('finalizar', EstadoConversacion.finalizada);
}
