import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/datos/notificaciones_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/datos/push/dispositivos_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/datos/push/mensajeria_firebase.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/agrupador_notificaciones.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/destino_notificacion.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/push.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/presentacion/proveedores/bandeja_notificaciones.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

/// Abre una ruta de la app (lo implementa el enrutador; se inyecta para no
/// depender de go_router aquí).
typedef Navegador = void Function(String ruta);

/// Lógica de los push (M3):
/// - al iniciar sesión pide permiso, obtiene el token y lo registra con
///   plataforma "android"; también cuando FCM lo renueva;
/// - antes de cerrar sesión elimina el token del backend;
/// - en primer plano muestra una notificación local (agrupada por chat, estilo
///   mensajería) salvo si el chat que llega es el que está en pantalla, y
///   recarga la bandeja;
/// - al tocar una notificación (primer o segundo plano, o app cerrada) abre
///   su pantalla; si aún no hay sesión, espera a que la haya.
///
/// El token solo se guarda en memoria y nunca se registra en logs.
class ServicioPush {
  ServicioPush(this._ref, this._mensajeria);

  final Ref _ref;
  final MensajeriaPush? _mensajeria;
  final List<StreamSubscription<Object?>> _suscripciones = [];
  final AgrupadorNotificaciones _agrupador = AgrupadorNotificaciones();
  Navegador? _navegador;
  bool _disponible = false;
  String? _token;
  String? _rutaPendiente;

  /// Usuario para el que ya se pidió permiso y se registró el token; evita
  /// repetirlo si la sesión se restaura mientras Firebase se inicia.
  int? _usuarioPreparado;

  bool get disponible => _disponible;

  Future<void> iniciar(Navegador navegador) async {
    _navegador = navegador;
    final mensajeria = _mensajeria;
    if (mensajeria == null || _disponible) return;
    _disponible = await mensajeria.iniciar();
    if (!_disponible) return;

    _suscripciones
      ..add(mensajeria.mensajesPrimerPlano.listen(_alRecibirEnPrimerPlano))
      ..add(mensajeria.notificacionesTocadas.listen(_abrir))
      ..add(mensajeria.tokenRenovado.listen(_registrarToken));

    final inicial = await mensajeria.mensajeInicial();
    if (inicial != null) _abrir(inicial);
    if (_ref.read(sesionProvider) is SesionAutenticada) await alIniciarSesion();
  }

  /// Llamado por Aplicacion cuando la sesión pasa a autenticada.
  Future<void> alIniciarSesion() async {
    final mensajeria = _mensajeria;
    final sesion = _ref.read(sesionProvider);
    if (!_disponible || mensajeria == null || sesion is! SesionAutenticada) return;
    if (_usuarioPreparado == sesion.usuario.id) return;
    _usuarioPreparado = sesion.usuario.id;
    final ruta = _rutaPendiente;
    if (ruta != null) {
      _rutaPendiente = null;
      _navegador?.call(ruta);
    }
    if (!await mensajeria.pedirPermiso()) return;
    final token = await mensajeria.obtenerToken();
    if (token != null) await _registrarToken(token);
  }

  /// Debe llamarse antes de invalidar la sesión (el DELETE necesita el token de sesión).
  Future<void> antesDeCerrarSesion() async {
    _usuarioPreparado = null;
    final token = _token;
    if (token == null) return;
    _token = null;
    try {
      await _ref.read(dispositivosRepositorioProvider).eliminar(token);
    } on ExcepcionApi {
      // Sin conexión o ya eliminado: el backend desactiva los tokens inválidos.
    }
  }

  Future<void> _registrarToken(String token) async {
    if (_ref.read(sesionProvider) is! SesionAutenticada) return;
    try {
      await _ref.read(dispositivosRepositorioProvider).registrar(token);
      _token = token;
    } on ExcepcionApi {
      // Se reintenta en el próximo inicio de sesión o renovación del token.
    }
  }

  /// La pantalla de un chat avisa al abrirse: no se notifica ese chat y se
  /// quita su notificación.
  void alAbrirChat(int idChat) {
    _agrupador.abrirChat(idChat);
    if (_disponible) unawaited(_mensajeria?.cancelar(AgrupadorNotificaciones.idNotificacionChat(idChat)));
  }

  void alCerrarChat(int idChat) => _agrupador.cerrarChat(idChat);

  Future<void> _alRecibirEnPrimerPlano(MensajePush mensaje) async {
    final notificacion = _agrupador.preparar(mensaje);
    if (notificacion != null) await _mensajeria?.mostrar(notificacion);
    if (_ref.read(sesionProvider) is SesionAutenticada) {
      await _ref.read(bandejaNotificacionesProvider.notifier).recargar();
    }
  }

  void _abrir(Map<String, String> datos) {
    final ruta = rutaParaNotificacion(datos['tipo'] ?? '', datos);
    final idNotificacion = int.tryParse(datos['id_notificacion'] ?? '');
    if (_ref.read(sesionProvider) is! SesionAutenticada) {
      _rutaPendiente = ruta;
      return;
    }
    if (idNotificacion != null) unawaited(_marcarLeida(idNotificacion));
    if (ruta != null) _navegador?.call(ruta);
  }

  Future<void> _marcarLeida(int idNotificacion) async {
    try {
      await _ref.read(notificacionesRepositorioProvider).marcarLeida(idNotificacion);
      await _ref.read(bandejaNotificacionesProvider.notifier).recargar();
    } on ExcepcionApi {
      // Secundario: la bandeja se corrige en la próxima recarga.
    }
  }

  Future<void> cerrar() async {
    for (final suscripcion in _suscripciones) {
      await suscripcion.cancel();
    }
    _suscripciones.clear();
  }
}

/// No escucha la sesión aquí: el controlador de sesión lee este provider al
/// cerrar sesión y eso formaría un ciclo. Aplicacion llama a [ServicioPush.alIniciarSesion].
final servicioPushProvider = Provider<ServicioPush>((ref) {
  final servicio = ServicioPush(ref, ref.watch(mensajeriaPushProvider));
  ref.onDispose(servicio.cerrar);
  return servicio;
});
