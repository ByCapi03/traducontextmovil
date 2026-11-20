import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/funcionalidades/inicio/presentacion/pantallas/pantalla_inicio.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/voz/idioma_voz.dart';
import 'package:traducontextmovil/nucleo/voz/modo_voz.dart';
import 'package:traducontextmovil/nucleo/voz/reconocimiento_voz.dart';
import 'package:traducontextmovil/nucleo/voz/sintesis_voz.dart';

import '../apoyo/falsos.dart';
import '../apoyo/montar_app.dart';

Future<Falsos> _abrirConversacion(WidgetTester tester, [Falsos? falsos]) async {
  final todos = await montarApp(tester, falsos: falsos ?? Falsos().conSesion());
  GoRouter.of(tester.element(find.byType(PantallaInicio))).push(Rutas.conversacion(4));
  await tester.pumpAndSettle();
  return todos;
}

void main() {
  group('idioma de voz', () {
    test('usa la región de la tabla o la del dispositivo', () {
      expect(resolverIdiomaVoz('es'), 'es-ES');
      expect(resolverIdiomaVoz('en'), 'en-US');
      expect(resolverIdiomaVoz('es', disponibles: ['en_US', 'es_MX']), 'es-MX');
      expect(resolverIdiomaVoz('es', disponibles: ['es_MX', 'es_ES']), 'es-ES');
      expect(resolverIdiomaVoz('pt_PT'), 'pt-PT');
      expect(resolverIdiomaVoz(''), '');
    });
  });

  group('dictado (HU-25)', () {
    testWidgets('escucha en el idioma del participante, muestra el parcial y envía cada frase', (tester) async {
      final falsos = await _abrirConversacion(tester);

      await tocar(tester, find.byTooltip('Dictar con el micrófono'));
      expect(falsos.reconocimiento.idiomas.last, 'es-ES');
      expect(find.text('Te estoy escuchando… (es-ES)'), findsOneWidget);

      falsos.reconocimiento.parcial('Me duele');
      await tester.pump();
      expect(find.text('Me duele'), findsOneWidget);

      falsos.reconocimiento.decir('Me duele la cabeza');
      await tester.pumpAndSettle();
      expect(falsos.conversaciones.eventos.last, 'registrar:21:Me duele la cabeza');
      expect(find.text('EN: Me duele la cabeza'), findsOneWidget);

      // Al cambiar de hablante se reinicia con su idioma.
      await tocar(tester, find.text('Participante 2 (Inglés)'));
      expect(falsos.reconocimiento.idiomas.last, 'en-US');

      await tocar(tester, find.byTooltip('Detener micrófono'));
      expect(falsos.reconocimiento.escuchando, isFalse);
      expect(find.textContaining('Te estoy escuchando'), findsNothing);
    });

    testWidgets('con "No identificado" pide elegir quién habla', (tester) async {
      final falsos = await _abrirConversacion(tester);
      await tocar(tester, find.text('No identificado'));
      await tocar(tester, find.byTooltip('Dictar con el micrófono'));
      expect(falsos.reconocimiento.idiomas, isEmpty);
      expect(
        find.text('Para dictar, elige quién habla: el reconocimiento de voz necesita su idioma.'),
        findsOneWidget,
      );
    });

    testWidgets('sin permiso o sin reconocimiento avisa y la escritura sigue funcionando', (tester) async {
      final falsos = Falsos().conSesion();
      falsos.reconocimiento.errorAlIniciar = ErrorReconocimiento.sinPermiso;
      await _abrirConversacion(tester, falsos);

      await tocar(tester, find.byTooltip('Dictar con el micrófono'));
      expect(find.text(mensajesReconocimientoPrueba(ErrorReconocimiento.sinPermiso)), findsOneWidget);

      falsos.reconocimiento.errorAlIniciar = ErrorReconocimiento.sinSoporte;
      await tocar(tester, find.byTooltip('Dictar con el micrófono'));
      expect(find.text(mensajesReconocimientoPrueba(ErrorReconocimiento.sinSoporte)), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Hola');
      await tocar(tester, find.byTooltip('Enviar intervención'));
      expect(falsos.conversaciones.eventos.last, 'registrar:21:Hola');
    });

    testWidgets('un error grave detiene la escucha y muestra el motivo', (tester) async {
      final falsos = await _abrirConversacion(tester);
      await tocar(tester, find.byTooltip('Dictar con el micrófono'));
      falsos.reconocimiento.fallar(ErrorReconocimiento.sinConexion);
      await tester.pumpAndSettle();
      expect(find.text('No hay conexión con el servicio de reconocimiento de voz.'), findsOneWidget);
      expect(find.byTooltip('Dictar con el micrófono'), findsOneWidget);
    });

    testWidgets('al pausar se detiene el micrófono', (tester) async {
      final falsos = await _abrirConversacion(tester);
      await tocar(tester, find.byTooltip('Dictar con el micrófono'));
      await tocar(tester, find.byTooltip('Opciones de la conversación'));
      await tocar(tester, find.text('Pausar'));
      expect(falsos.reconocimiento.escuchando, isFalse);
      expect(find.byTooltip('Dictar con el micrófono'), findsNothing);
    });
  });

  group('lectura en voz alta (HU-28)', () {
    testWidgets('manual: lee con el botón en el idioma de destino y se puede detener', (tester) async {
      final falsos = await _abrirConversacion(tester);
      await tester.enterText(find.byType(TextField), 'Hola');
      await tocar(tester, find.byTooltip('Enviar intervención'));
      expect(falsos.sintesis.lecturas, isEmpty);

      await tocar(tester, find.byTooltip('Escuchar traducción'));
      expect(falsos.sintesis.lecturas.last, ('EN: Hola', 'en'));
      expect(find.byTooltip('Detener lectura'), findsOneWidget);

      await tocar(tester, find.byTooltip('Detener lectura'));
      expect(find.byTooltip('Escuchar traducción'), findsOneWidget);
    });

    testWidgets('automática: se guarda con la clave de la web y lee cada traducción', (tester) async {
      final falsos = await _abrirConversacion(tester);
      await tocar(tester, find.byTooltip('Reproducción por voz: Manual'));
      await tocar(tester, find.byType(CheckedPopupMenuItem<ModoVoz>).last);
      expect(falsos.preferencias.valores[claveModoVoz], 'automatica');

      await tester.enterText(find.byType(TextField), 'Hola');
      await tocar(tester, find.byTooltip('Enviar intervención'));
      expect(falsos.sintesis.lecturas.last, ('EN: Hola', 'en'));
    });

    testWidgets('automática guardada: no lee mientras se dicta', (tester) async {
      final falsos = Falsos().conSesion();
      falsos.preferencias.valores[claveModoVoz] = 'automatica';
      await _abrirConversacion(tester, falsos);
      expect(find.byTooltip('Reproducción por voz: Automática'), findsOneWidget);

      await tocar(tester, find.byTooltip('Dictar con el micrófono'));
      falsos.reconocimiento.decir('Buenos días');
      await tester.pumpAndSettle();
      expect(find.text('EN: Buenos días'), findsOneWidget);
      expect(falsos.sintesis.lecturas, isEmpty);
    });

    testWidgets('sin voz para el idioma muestra un aviso', (tester) async {
      final falsos = await _abrirConversacion(tester);
      falsos.sintesis.resultado = ResultadoVoz.sinVoz;
      await tester.enterText(find.byType(TextField), 'Hola');
      await tocar(tester, find.byTooltip('Enviar intervención'));
      await tocar(tester, find.byTooltip('Escuchar traducción'));
      expect(find.text('No hay una voz disponible para Inglés en este dispositivo.'), findsOneWidget);
    });
  });
}

String mensajesReconocimientoPrueba(ErrorReconocimiento error) => switch (error) {
      ErrorReconocimiento.sinPermiso =>
        'Sin permiso para usar el micrófono. Actívalo en los ajustes del dispositivo o escribe la intervención.',
      ErrorReconocimiento.sinSoporte =>
        'Este dispositivo no tiene reconocimiento de voz disponible. Puedes seguir escribiendo la intervención.',
      _ => '',
    };
