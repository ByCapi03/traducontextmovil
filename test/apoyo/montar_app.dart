import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traducontextmovil/aplicacion.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/espera_reenvio.dart';

import 'falsos.dart';
import 'repositorio_falso.dart';

/// Reloj controlable para la espera de reenvio.
class RelojFalso {
  DateTime ahora = DateTime(2026, 11, 20, 10);

  void avanzar(Duration duracion) => ahora = ahora.add(duracion);
}

/// Monta la app real con repositorios simulados. Sin sesión guardada arranca
/// en /login; con `Falsos().conSesion()` arranca en la pantalla inicial.
Future<Falsos> montarApp(
  WidgetTester tester, {
  RepositorioFalso? repositorio,
  Falsos? falsos,
  RelojFalso? reloj,
  Size tamano = const Size(400, 800),
}) async {
  tester.view
    ..physicalSize = tamano
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final todos = falsos ?? Falsos(autenticacion: repositorio);
  final relojUsado = reloj ?? RelojFalso();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...todos.overrides,
        relojProvider.overrideWithValue(() => relojUsado.ahora),
      ],
      child: const Aplicacion(),
    ),
  );
  await tester.pumpAndSettle();
  return todos;
}

/// Hace visible el widget (los formularios tienen scroll) y lo pulsa.
Future<void> tocar(WidgetTester tester, Finder objetivo) async {
  // Las listas perezosas no construyen lo que está fuera de pantalla.
  if (objetivo.evaluate().isEmpty) {
    await tester.scrollUntilVisible(objetivo, 200, scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(objetivo);
  await tester.pumpAndSettle();
  await tester.tap(objetivo);
  await tester.pumpAndSettle();
}

/// Captura lo que la app copia al portapapeles.
List<String> capturarPortapapeles(WidgetTester tester) {
  final copiados = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
    if (llamada.method == 'Clipboard.setData') {
      copiados.add((llamada.arguments as Map<Object?, Object?>)['text']! as String);
    }
    return null;
  });
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return copiados;
}

Finder campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);

Finder boton(String texto) => find.widgetWithText(FilledButton, texto);

/// Selecciona una pestaña de la barra inferior por su icono.
Future<void> irAPestana(WidgetTester tester, IconData icono) =>
    tocar(tester, find.descendant(of: find.byType(NavigationBar), matching: find.byIcon(icono)));
