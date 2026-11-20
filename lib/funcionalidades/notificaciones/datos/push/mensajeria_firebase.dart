import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/push.dart';

/// Mensajes de datos recibidos con la app en segundo plano o cerrada. Los push
/// con `notification` los muestra el sistema y, al tocarlos, llegan por
/// `onMessageOpenedApp`/`getInitialMessage`; aquí no hay nada más que hacer.
@pragma('vm:entry-point')
Future<void> manejarPushEnSegundoPlano(RemoteMessage mensaje) async {
  await Firebase.initializeApp();
}

/// Implementación real con Firebase Cloud Messaging y notificaciones locales.
class MensajeriaFirebase implements MensajeriaPush {
  static const String _idCanal = 'traducontext_general';

  final FlutterLocalNotificationsPlugin _locales = FlutterLocalNotificationsPlugin();
  final StreamController<Map<String, String>> _toquesLocales =
      StreamController<Map<String, String>>.broadcast();
  int _siguienteId = 0;

  @override
  Future<bool> iniciar() async {
    try {
      await Firebase.initializeApp();
    } on Object {
      // Sin google-services.json válido. No se registra nada personal.
      debugPrint('Push desactivado: Firebase no está configurado en esta compilación.');
      return false;
    }
    FirebaseMessaging.onBackgroundMessage(manejarPushEnSegundoPlano);

    await _locales.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (respuesta) {
        final carga = respuesta.payload;
        if (carga == null) return;
        _toquesLocales.add(Map<String, String>.from(jsonDecode(carga) as Map));
      },
    );
    await _locales
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _idCanal,
            'Avisos de TraduContext',
            description: 'Documentos traducidos y mensajes de chat.',
            importance: Importance.high,
          ),
        );
    return true;
  }

  @override
  Future<bool> pedirPermiso() async {
    final ajustes = await FirebaseMessaging.instance.requestPermission();
    return ajustes.authorizationStatus == AuthorizationStatus.authorized ||
        ajustes.authorizationStatus == AuthorizationStatus.provisional;
  }

  // Se mantiene el token de registro de FCM aunque esté marcado como obsoleto:
  // el backend envía con `messaging.MulticastMessage(tokens=...)` (push_fcm.py) y el
  // nuevo register()/onRegistered devuelve un Installation ID, que no sirve ahí.
  @override
  // ignore: deprecated_member_use
  Future<String?> obtenerToken() => FirebaseMessaging.instance.getToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get tokenRenovado => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<MensajePush> get mensajesPrimerPlano => FirebaseMessaging.onMessage.map(_convertir);

  @override
  Stream<Map<String, String>> get notificacionesTocadas => StreamGroupSimple.unir([
        FirebaseMessaging.onMessageOpenedApp.map((mensaje) => _datos(mensaje.data)),
        _toquesLocales.stream,
      ]);

  @override
  Future<Map<String, String>?> mensajeInicial() async {
    final mensaje = await FirebaseMessaging.instance.getInitialMessage();
    return mensaje == null ? null : _datos(mensaje.data);
  }

  @override
  Future<void> mostrar(MensajePush mensaje) => _locales.show(
        id: _siguienteId++,
        title: mensaje.titulo,
        body: mensaje.cuerpo,
        payload: jsonEncode(mensaje.datos),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _idCanal,
            'Avisos de TraduContext',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );

  MensajePush _convertir(RemoteMessage mensaje) => MensajePush(
        titulo: mensaje.notification?.title,
        cuerpo: mensaje.notification?.body,
        datos: _datos(mensaje.data),
      );

  Map<String, String> _datos(Map<String, dynamic> datos) => {
        for (final MapEntry(:key, :value) in datos.entries)
          if (value != null) key: '$value',
      };
}

/// Une varios streams en uno (sin depender de package:async).
abstract final class StreamGroupSimple {
  static Stream<T> unir<T>(List<Stream<T>> fuentes) {
    late final StreamController<T> controlador;
    final suscripciones = <StreamSubscription<T>>[];
    controlador = StreamController<T>.broadcast(
      onListen: () {
        for (final fuente in fuentes) {
          suscripciones.add(fuente.listen(controlador.add, onError: controlador.addError));
        }
      },
      onCancel: () async {
        for (final suscripcion in suscripciones) {
          await suscripcion.cancel();
        }
        suscripciones.clear();
      },
    );
    return controlador.stream;
  }
}

/// null si la plataforma no tiene push (en la app solo Android; en tests, ninguna).
final mensajeriaPushProvider = Provider<MensajeriaPush?>(
  (ref) => !kIsWeb && Platform.isAndroid ? MensajeriaFirebase() : null,
);
