import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traducontextmovil/funcionalidades/historial/dominio/historial.dart';
import 'package:traducontextmovil/funcionalidades/inicio/presentacion/pantallas/pantalla_inicio.dart';

import '../apoyo/falsos.dart';
import '../apoyo/montar_app.dart';

void main() {
  testWidgets('con sesión de usuario arranca en Inicio con la bandeja y el contador', (tester) async {
    final falsos = await montarApp(tester, falsos: Falsos().conSesion());

    expect(find.byType(PantallaInicio), findsOneWidget);
    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Notificaciones (1 sin leer)'), findsOneWidget);
    expect(find.text('Tu documento está listo'), findsOneWidget);

    await tocar(tester, find.text('Marcar todas como leídas'));
    expect(falsos.notificaciones.todasMarcadas, 1);
    expect(find.text('Notificaciones'), findsOneWidget);
  });

  testWidgets('tocar una notificación la marca como leída y abre su pantalla', (tester) async {
    final falsos = await montarApp(tester, falsos: Falsos().conSesion());
    await tocar(tester, find.text('Tu documento está listo'));

    expect(falsos.notificaciones.marcadas, [10]);
    expect(find.widgetWithText(AppBar, 'Documentos'), findsOneWidget);
  });

  group('traducir', () {
    testWidgets('traduce con detección automática, copia e intercambia idiomas', (tester) async {
      final copiados = capturarPortapapeles(tester);
      final falsos = await montarApp(tester, falsos: Falsos().conSesion());
      await irAPestana(tester, Icons.translate_outlined);

      // La configuración se asegura antes de traducir.
      expect(falsos.traduccion.configuracionesPedidas, 1);

      await tester.enterText(find.widgetWithText(TextField, 'Texto a traducir'), 'Good morning');
      await tocar(tester, find.widgetWithText(FilledButton, 'Traducir'));

      expect(falsos.traduccion.traducciones.single, {
        'texto': 'Good morning',
        'origen': null,
        'destino': 'en',
      });
      expect(find.text('Traducido: Good morning'), findsOneWidget);
      expect(find.text('Idioma detectado: Español'), findsOneWidget);

      await tocar(tester, find.byTooltip('Copiar traducción'));
      expect(copiados, ['Traducido: Good morning']);
      expect(find.text('Traducción copiada.'), findsOneWidget);

      await tocar(tester, find.byTooltip('Intercambiar idiomas'));
      expect(
        tester.widget<TextField>(find.widgetWithText(TextField, 'Texto a traducir')).controller!.text,
        'Traducido: Good morning',
      );
      await tocar(tester, find.widgetWithText(FilledButton, 'Traducir'));
      expect(falsos.traduccion.traducciones.last['origen'], 'en');
      expect(falsos.traduccion.traducciones.last['destino'], 'es');
    });

    testWidgets('no traduce un texto vacío', (tester) async {
      final falsos = await montarApp(tester, falsos: Falsos().conSesion());
      await irAPestana(tester, Icons.translate_outlined);
      await tocar(tester, find.widgetWithText(FilledButton, 'Traducir'));

      expect(find.text('Escribe el texto que quieres traducir.'), findsOneWidget);
      expect(falsos.traduccion.traducciones, isEmpty);
    });
  });

  group('historial', () {
    testWidgets('marca favorito y elimina con confirmación', (tester) async {
      final falsos = await montarApp(tester, falsos: Falsos().conSesion());
      await irAPestana(tester, Icons.history_outlined);

      expect(find.text('Buenos días'), findsOneWidget);
      expect(find.text('Inglés → Español · 20/11/2026 09:30'), findsOneWidget);

      await tocar(tester, find.byTooltip('Marcar como favorito'));
      expect(falsos.historial.favoritos, [(1, true)]);
      expect(find.byTooltip('Marcar como favorito'), findsNothing);

      await tocar(tester, find.byTooltip('Más opciones').first);
      await tocar(tester, find.text('Eliminar'));
      expect(find.text('¿Quieres eliminar esta traducción del historial?'), findsOneWidget);
      await tocar(tester, find.widgetWithText(TextButton, 'Eliminar'));

      expect(falsos.historial.eliminadas, [1]);
      expect(find.text('Buenos días'), findsNothing);
    });

    testWidgets('filtra solo favoritos', (tester) async {
      await montarApp(tester, falsos: Falsos().conSesion());
      await irAPestana(tester, Icons.history_outlined);
      await tocar(tester, find.text('Solo favoritos'));

      expect(find.text('Gracias'), findsOneWidget);
      expect(find.text('Buenos días'), findsNothing);
    });

    testWidgets('una traducción nueva recarga el historial', (tester) async {
      final falsos = await montarApp(tester, falsos: Falsos().conSesion());
      await irAPestana(tester, Icons.history_outlined);
      expect(find.text('Hola'), findsNothing);

      falsos.historial.entradas = [
        EntradaHistorial(
          id: 3,
          textoOriginal: 'Hello',
          textoTraducido: 'Hola',
          idiomaOrigen: 'en',
          idiomaDestino: 'es',
          fecha: DateTime(2026, 11, 20, 11),
          favorito: false,
        ),
        ...falsos.historial.entradas,
      ];
      await irAPestana(tester, Icons.translate_outlined);
      await tester.enterText(find.widgetWithText(TextField, 'Texto a traducir'), 'Hello');
      await tocar(tester, find.widgetWithText(FilledButton, 'Traducir'));
      await irAPestana(tester, Icons.history_outlined);

      expect(find.text('Hola'), findsOneWidget);
    });
  });

  group('sin desbordes', () {
    for (final ancho in [360.0, 420.0]) {
      testWidgets('pestañas del usuario a $ancho px', (tester) async {
        await montarApp(tester, falsos: Falsos().conSesion(), tamano: Size(ancho, 640));
        for (final icono in [
          Icons.translate_outlined,
          Icons.history_outlined,
          Icons.forum_outlined,
          Icons.person_outline,
        ]) {
          await irAPestana(tester, icono);
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
