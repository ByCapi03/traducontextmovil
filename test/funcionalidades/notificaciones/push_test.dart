import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traducontextmovil/aplicacion.dart';
import 'package:traducontextmovil/funcionalidades/chats/presentacion/pantallas/pantalla_chat.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/datos/push/dispositivos_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/agrupador_notificaciones.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/destino_notificacion.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/notificacion.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/push.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';

import '../../apoyo/falsos.dart';
import '../../apoyo/montar_app.dart';

class _MensajeriaFalsa implements MensajeriaPush {
  _MensajeriaFalsa({this.configurada = true, this.inicial});

  final bool configurada;
  final Map<String, String>? inicial;
  final primerPlano = StreamController<MensajePush>.broadcast();
  final tocadas = StreamController<Map<String, String>>.broadcast();
  final renovados = StreamController<String>.broadcast();
  final List<NotificacionLocal> mostrados = [];
  final List<int> canceladas = [];
  int permisosPedidos = 0;

  @override
  Future<bool> iniciar() async => configurada;

  @override
  Future<bool> pedirPermiso() async {
    permisosPedidos++;
    return true;
  }

  @override
  Future<String?> obtenerToken() async => 'token-fcm-1';

  @override
  Stream<String> get tokenRenovado => renovados.stream;

  @override
  Stream<MensajePush> get mensajesPrimerPlano => primerPlano.stream;

  @override
  Stream<Map<String, String>> get notificacionesTocadas => tocadas.stream;

  @override
  Future<Map<String, String>?> mensajeInicial() async => inicial;

  @override
  Future<void> mostrar(NotificacionLocal notificacion) async => mostrados.add(notificacion);

  @override
  Future<void> cancelar(int id) async => canceladas.add(id);
}

class _DispositivosFalsos implements DispositivosRepositorio {
  final List<String> eventos = [];

  @override
  Future<void> registrar(String tokenFcm) async => eventos.add('registrar:$tokenFcm');

  @override
  Future<void> eliminar(String tokenFcm) async => eventos.add('eliminar:$tokenFcm');
}

Future<void> _montar(
  WidgetTester tester,
  Falsos falsos,
  MensajeriaPush? mensajeria,
  _DispositivosFalsos dispositivos,
) async {
  tester.view
    ..physicalSize = const Size(400, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...(falsos..mensajeria = mensajeria).overrides,
        dispositivosRepositorioProvider.overrideWithValue(dispositivos),
      ],
      child: const Aplicacion(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('cada tipo de notificación lleva a su pantalla', () {
    expect(rutaParaNotificacion(TiposNotificacion.documentoListo, const {}), Rutas.documentos);
    expect(rutaParaNotificacion(TiposNotificacion.documentoError, const {}), Rutas.documentos);
    expect(rutaParaNotificacion(TiposNotificacion.mensajeChat, const {'id_chat': '8'}), '/chats/8');
    expect(rutaParaNotificacion(TiposNotificacion.mensajeChat, const {}), Rutas.conversaciones);
    expect(rutaParaNotificacion(TiposNotificacion.sistema, const {}), isNull);
  });

  testWidgets('registra el token al iniciar sesión y lo elimina antes de cerrarla', (tester) async {
    final mensajeria = _MensajeriaFalsa();
    final dispositivos = _DispositivosFalsos();
    final falsos = Falsos().conSesion();
    await _montar(tester, falsos, mensajeria, dispositivos);

    expect(mensajeria.permisosPedidos, 1);
    expect(dispositivos.eventos, ['registrar:token-fcm-1']);

    mensajeria.renovados.add('token-fcm-2');
    await tester.pumpAndSettle();
    expect(dispositivos.eventos.last, 'registrar:token-fcm-2');

    await irAPestana(tester, Icons.person_outline);
    await tocar(tester, find.byIcon(Icons.logout));
    await tocar(tester, find.widgetWithText(TextButton, 'Cerrar sesión'));

    expect(dispositivos.eventos.last, 'eliminar:token-fcm-2');
    // El token se elimina antes de cerrar la sesión en el backend.
    expect(falsos.autenticacion.llamadasA('cerrarSesion'), hasLength(1));
  });

  testWidgets('en primer plano muestra la notificación local y recarga la bandeja', (tester) async {
    final mensajeria = _MensajeriaFalsa();
    final falsos = Falsos().conSesion();
    await _montar(tester, falsos, mensajeria, _DispositivosFalsos());
    expect(find.text('Chat nuevo'), findsNothing);

    falsos.notificaciones.elementos = [
      Notificacion(
        id: 20,
        tipo: TiposNotificacion.mensajeChat,
        titulo: 'Chat nuevo',
        cuerpo: 'Tienes un mensaje nuevo.',
        leida: false,
        fecha: DateTime(2026, 11, 20, 12),
        datos: const {'id_chat': '8'},
      ),
      ...falsos.notificaciones.elementos,
    ];
    mensajeria.primerPlano.add(
      const MensajePush(
        titulo: 'Chat nuevo',
        cuerpo: 'Tienes un mensaje nuevo.',
        datos: {'tipo': 'MENSAJE_CHAT', 'id_chat': '8', 'id_notificacion': '20'},
      ),
    );
    await tester.pumpAndSettle();

    expect(mensajeria.mostrados.single.titulo, 'Chat nuevo');
    expect(find.text('Chat nuevo'), findsOneWidget);
    expect(find.text('Notificaciones (2 sin leer)'), findsOneWidget);
  });

  testWidgets('tocar un push abre su pantalla y la marca como leída', (tester) async {
    final mensajeria = _MensajeriaFalsa();
    final falsos = Falsos().conSesion();
    await _montar(tester, falsos, mensajeria, _DispositivosFalsos());

    mensajeria.tocadas.add(const {'tipo': 'DOCUMENTO_LISTO', 'id_notificacion': '10'});
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Documentos'), findsOneWidget);
    expect(falsos.notificaciones.marcadas, [10]);
  });

  testWidgets('un push que abrió la app cerrada navega tras restaurar la sesión', (tester) async {
    final mensajeria = _MensajeriaFalsa(inicial: const {'tipo': 'DOCUMENTO_LISTO'});
    await _montar(tester, Falsos().conSesion(), mensajeria, _DispositivosFalsos());

    expect(find.widgetWithText(AppBar, 'Documentos'), findsOneWidget);
  });

  testWidgets('sin Firebase configurado la app arranca igual y no registra nada', (tester) async {
    final dispositivos = _DispositivosFalsos();
    await _montar(tester, Falsos().conSesion(), _MensajeriaFalsa(configurada: false), dispositivos);

    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(dispositivos.eventos, isEmpty);
  });

  group('agrupador (estilo mensajería)', () {
    MensajePush chat(int id, String remitente, String texto) => MensajePush(
          titulo: remitente,
          cuerpo: texto,
          datos: {'tipo': 'MENSAJE_CHAT', 'id_chat': '$id'},
        );

    test('agrupa por id_chat con un id fijo y acumula los últimos mensajes', () {
      final agrupador = AgrupadorNotificaciones(reloj: () => DateTime(2026, 11, 20, 12));
      final primera = agrupador.preparar(chat(8, 'Luis', 'Hola'))!;
      final segunda = agrupador.preparar(chat(8, 'Luis', '¿Qué tal?'))!;
      final otra = agrupador.preparar(chat(9, 'Eva', 'Buenas'))!;

      expect(primera.id, segunda.id);
      expect(primera.id, AgrupadorNotificaciones.idNotificacionChat(8));
      expect(otra.id, isNot(primera.id));
      expect(segunda.grupo, 'traducontext.chat.8');
      expect(segunda.lineas.map((l) => l.texto), ['Hola', '¿Qué tal?']);
      expect(segunda.cuerpo, '2 mensajes nuevos');
      expect(otra.lineas, hasLength(1));

      for (var i = 0; i < 10; i++) {
        agrupador.preparar(chat(8, 'Luis', 'm$i'));
      }
      final ultima = agrupador.preparar(chat(8, 'Luis', 'fin'))!;
      expect(ultima.lineas, hasLength(AgrupadorNotificaciones.maximoLineas));
      expect(ultima.lineas.last.texto, 'fin');
    });

    test('no notifica el chat en pantalla y empieza de cero al volver a él', () {
      final agrupador = AgrupadorNotificaciones()..preparar(chat(8, 'Luis', 'Hola'));
      agrupador.abrirChat(8);
      expect(agrupador.preparar(chat(8, 'Luis', 'Sigo aquí')), isNull);
      expect(agrupador.preparar(chat(9, 'Eva', 'Buenas')), isNotNull);

      agrupador.cerrarChat(8);
      expect(agrupador.preparar(chat(8, 'Luis', 'Otra'))!.lineas.map((l) => l.texto), ['Otra']);
    });

    test('otros tipos no se agrupan y un push sin texto no se muestra', () {
      final agrupador = AgrupadorNotificaciones();
      final a = agrupador.preparar(
        const MensajePush(titulo: 'Documento listo', datos: {'tipo': 'DOCUMENTO_LISTO', 'id_traduccion_documento': '5'}),
      )!;
      final b = agrupador.preparar(const MensajePush(titulo: 'Otro', datos: {'tipo': 'SISTEMA'}))!;
      expect(a.id, isNot(b.id));
      expect(a.grupo, isNull);
      expect(agrupador.preparar(const MensajePush(datos: {'tipo': 'MENSAJE_CHAT', 'id_chat': '8'})), isNull);
    });
  });

  testWidgets('con el chat abierto no se notifica ese chat, pero sí los demás', (tester) async {
    final mensajeria = _MensajeriaFalsa();
    final falsos = Falsos().conSesion();
    await _montar(tester, falsos, mensajeria, _DispositivosFalsos());

    mensajeria.tocadas.add(const {'tipo': 'MENSAJE_CHAT', 'id_chat': '3'});
    await tester.pumpAndSettle();
    expect(find.byType(PantallaChat), findsOneWidget);
    // Al abrir el chat se quita su notificación.
    expect(mensajeria.canceladas, [AgrupadorNotificaciones.idNotificacionChat(3)]);

    mensajeria.primerPlano
      ..add(const MensajePush(titulo: 'Luis', cuerpo: 'Hola', datos: {'tipo': 'MENSAJE_CHAT', 'id_chat': '3'}))
      ..add(const MensajePush(titulo: 'Eva', cuerpo: 'Buenas', datos: {'tipo': 'MENSAJE_CHAT', 'id_chat': '9'}));
    await tester.pumpAndSettle();
    expect(mensajeria.mostrados.single.titulo, 'Eva');
    expect(mensajeria.mostrados.single.id, AgrupadorNotificaciones.idNotificacionChat(9));
  });
}
