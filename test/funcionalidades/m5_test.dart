import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/funcionalidades/chats/dominio/chats.dart';
import 'package:traducontextmovil/funcionalidades/chats/presentacion/pantallas/pantalla_chat.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/dominio/conversaciones.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/presentacion/pantallas/pantalla_conversacion.dart';
import 'package:traducontextmovil/funcionalidades/documentos/dominio/documentos.dart';
import 'package:traducontextmovil/funcionalidades/inicio/presentacion/pantallas/pantalla_inicio.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/archivos/selector_archivos.dart';

import '../apoyo/falsos.dart';
import '../apoyo/montar_app.dart';

/// Abre una ruta como lo haría la app (push sobre la pestaña actual).
Future<void> _abrir(WidgetTester tester, String ruta) async {
  GoRouter.of(tester.element(find.byType(PantallaInicio))).push(ruta);
  await tester.pumpAndSettle();
}

void main() {
  group('documentos', () {
    testWidgets('sube, traduce con detección automática y descarga', (tester) async {
      final falsos = await montarApp(tester, falsos: Falsos().conSesion());
      await _abrir(tester, Rutas.documentos);
      expect(find.text('Aún no has subido documentos.'), findsOneWidget);

      await tocar(tester, find.text('Subir y traducir'));
      expect(find.text('Traducir documento'), findsOneWidget);
      await tocar(tester, find.widgetWithText(TextButton, 'Traducir'));

      expect(falsos.documentos.eventos, ['subir:informe.docx', 'traducir:1:auto:en']);
      expect(find.text('Documento traducido. Ya puedes descargarlo.'), findsOneWidget);
      expect(find.text('informe_en.docx'), findsOneWidget);

      await tocar(tester, find.byTooltip('Opciones del documento'));
      await tocar(tester, find.text('Descargar'));
      expect(falsos.documentos.eventos.last, 'descargar:50');
      expect(falsos.archivos.compartidos, ['informe_en.docx']);
    });

    testWidgets('rechaza extensiones no admitidas sin llamar al backend', (tester) async {
      final falsos = Falsos().conSesion();
      falsos.selectorArchivos.archivo = const ArchivoSeleccionado(nombre: 'foto.png', bytes: [1]);
      await montarApp(tester, falsos: falsos);
      await _abrir(tester, Rutas.documentos);
      await tocar(tester, find.text('Subir y traducir'));

      expect(find.text('Solo se admiten archivos .docx, .xlsx y .pdf.'), findsOneWidget);
      expect(falsos.documentos.eventos, isEmpty);
    });

    testWidgets('elimina un documento original tras confirmar', (tester) async {
      final falsos = Falsos().conSesion();
      falsos.documentos.originales = [
        Documento(id: 7, nombre: 'contrato.pdf', extension: 'pdf', tamano: 2048, fecha: DateTime(2026, 11, 1)),
      ];
      await montarApp(tester, falsos: falsos);
      await _abrir(tester, Rutas.documentos);
      await tocar(tester, find.byTooltip('Opciones del original'));
      await tocar(tester, find.text('Eliminar'));
      await tocar(tester, find.widgetWithText(TextButton, 'Eliminar'));

      expect(falsos.documentos.eventos, ['eliminar-original:7']);
      expect(find.text('contrato.pdf'), findsNothing);
    });
  });

  group('chats', () {
    testWidgets('muestra el texto traducido y el original, envía y marca como leído', (tester) async {
      final falsos = await montarApp(tester, falsos: Falsos().conSesion());
      await _abrir(tester, Rutas.chat(3));

      expect(find.text('Luis'), findsOneWidget);
      expect(find.text('Lees en Español'), findsOneWidget);
      expect(find.text('Hola, ¿cómo estás?'), findsOneWidget);
      expect(find.text('Original (Inglés): Hi, how are you?'), findsOneWidget);
      expect(falsos.chats.leidos, [1]);

      await tester.enterText(find.byType(TextField), 'Muy bien, gracias');
      await tocar(tester, find.byTooltip('Enviar'));
      expect(falsos.chats.enviados, ['Muy bien, gracias']);
      expect(find.text('Muy bien, gracias'), findsOneWidget);
    });

    testWidgets('se refresca solo mientras la pantalla está abierta', (tester) async {
      final falsos = await montarApp(tester, falsos: Falsos().conSesion());
      await _abrir(tester, Rutas.chat(3));
      final consultasIniciales = falsos.chats.consultasMensajes;

      falsos.chats.mensajesServidor = [
        ...falsos.chats.mensajesServidor,
        MensajeChat(
          id: 2,
          esMio: false,
          texto: 'Nos vemos mañana',
          textoOriginal: 'See you tomorrow',
          idiomaOriginal: 'en',
          estadoLectura: EstadoLectura.traducido,
          fecha: DateTime(2026, 11, 20, 9, 10),
        ),
      ];
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text('Nos vemos mañana'), findsOneWidget);
      expect(falsos.chats.leidos.last, 2);

      await tocar(tester, find.byType(BackButton));
      final consultasAlSalir = falsos.chats.consultasMensajes;
      expect(consultasAlSalir, greaterThan(consultasIniciales));
      await tester.pump(const Duration(seconds: 30));
      expect(falsos.chats.consultasMensajes, consultasAlSalir);
    });

    testWidgets('un mensaje pendiente se actualiza al traducirse', (tester) async {
      final falsos = Falsos().conSesion();
      falsos.chats.mensajesServidor = [
        MensajeChat(
          id: 1,
          esMio: false,
          texto: 'Bonjour',
          textoOriginal: 'Bonjour',
          idiomaOriginal: 'fr',
          estadoLectura: EstadoLectura.pendiente,
          fecha: DateTime(2026, 11, 20, 9),
        ),
      ];
      await montarApp(tester, falsos: falsos);
      await _abrir(tester, Rutas.chat(3));
      expect(find.text('Traduciendo…'), findsOneWidget);

      falsos.chats.mensajesServidor = [
        MensajeChat(
          id: 1,
          esMio: false,
          texto: 'Buenos días',
          textoOriginal: 'Bonjour',
          idiomaOriginal: 'fr',
          estadoLectura: EstadoLectura.traducido,
          fecha: DateTime(2026, 11, 20, 9),
        ),
      ];
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text('Buenos días'), findsOneWidget);
      expect(find.text('Traduciendo…'), findsNothing);
    });

    testWidgets('cambia el idioma de lectura', (tester) async {
      final falsos = await montarApp(tester, falsos: Falsos().conSesion());
      await _abrir(tester, Rutas.chat(3));
      await tocar(tester, find.byTooltip('Cambiar idioma de lectura'));
      await tocar(tester, find.text('Francés'));

      expect(falsos.chats.cambiosIdioma, ['fr']);
      expect(find.text('Lees en Francés'), findsOneWidget);
    });

    testWidgets('busca un usuario y abre el chat con él', (tester) async {
      await montarApp(tester, falsos: Falsos().conSesion());
      await _abrir(tester, Rutas.nuevoChat);
      await tester.enterText(find.byType(TextField), 'lu');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Luis'));

      expect(find.byType(PantallaChat), findsOneWidget);
    });

    testWidgets('la pestaña Conversaciones lista los chats', (tester) async {
      await montarApp(tester, falsos: Falsos().conSesion());
      await irAPestana(tester, Icons.forum_outlined);
      await tocar(tester, find.text('Chats'));

      expect(find.text('Luis'), findsOneWidget);
      expect(find.text('Hola, ¿cómo estás?'), findsOneWidget);
    });
  });

  group('conversación con intérprete', () {
    testWidgets('crea la conversación con entorno obligatorio y abre la sesión', (tester) async {
      final falsos = await montarApp(tester, falsos: Falsos().conSesion());
      await irAPestana(tester, Icons.forum_outlined);
      await tocar(tester, find.text('Nueva conversación'));

      await tocar(tester, find.text('Iniciar conversación'));
      expect(find.text('Elige el entorno de la conversación.'), findsOneWidget);

      await tocar(tester, find.byType(DropdownButton<int?>).first);
      await tocar(tester, find.text('Consulta médica').last);
      await tocar(tester, find.text('Iniciar conversación'));

      expect(falsos.conversaciones.creada?.idIdiomaOrigen, 1);
      expect(falsos.conversaciones.creada?.idIdiomaDestino, 3);
      expect(falsos.conversaciones.creada?.idEntorno, 1);
      expect(find.byType(PantallaConversacion), findsOneWidget);
    });

    testWidgets('envía intervenciones por participante, reintenta y finaliza', (tester) async {
      final falsos = await montarApp(tester, falsos: Falsos().conSesion());
      await _abrir(tester, Rutas.conversacion(4));

      await tester.enterText(find.byType(TextField), 'Me duele la cabeza');
      await tocar(tester, find.byTooltip('Enviar intervención'));
      expect(falsos.conversaciones.eventos.last, 'registrar:21:Me duele la cabeza');
      expect(find.text('EN: Me duele la cabeza'), findsOneWidget);

      falsos.conversaciones.fallarTraduccion = true;
      await tocar(tester, find.text('Participante 2 (Inglés)'));
      await tester.enterText(find.byType(TextField), 'Since when?');
      await tocar(tester, find.byTooltip('Enviar intervención'));
      expect(falsos.conversaciones.eventos.last, 'registrar:22:Since when?');
      expect(find.text('No se pudo traducir esta intervención.'), findsOneWidget);

      await tocar(tester, find.text('Reintentar'));
      expect(falsos.conversaciones.eventos.last, 'reintentar:2');
      expect(find.text('EN: Since when?'), findsOneWidget);

      await tocar(tester, find.byTooltip('Opciones de la conversación'));
      await tocar(tester, find.text('Finalizar'));
      await tocar(tester, find.widgetWithText(TextButton, 'Finalizar'));
      expect(falsos.conversaciones.estado, EstadoConversacion.finalizada);
      expect(find.text('La conversación finalizó. Solo puedes consultarla.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('sin desbordes', () {
    for (final ancho in [360.0, 420.0]) {
      testWidgets('pantallas de M5 a $ancho px', (tester) async {
        final falsos = Falsos().conSesion();
        falsos.documentos.originales = [
          Documento(
            id: 1,
            nombre: 'un_nombre_de_documento_bastante_largo_para_probar.docx',
            extension: 'docx',
            tamano: 123456,
            fecha: DateTime(2026, 11, 1),
          ),
        ];
        await montarApp(tester, falsos: falsos, tamano: Size(ancho, 640));
        await irAPestana(tester, Icons.forum_outlined);
        await tocar(tester, find.text('Chats'));
        await irAPestana(tester, Icons.home_outlined);
        for (final ruta in [
          Rutas.documentos,
          Rutas.chat(3),
          Rutas.nuevoChat,
          Rutas.nuevaConversacion,
          Rutas.conversacion(4),
        ]) {
          await _abrir(tester, ruta);
          await tocar(tester, find.byType(BackButton));
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
