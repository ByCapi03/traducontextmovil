import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traducontextmovil/aplicacion.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/datos/repositorios/autenticacion_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/espera_reenvio.dart';

import 'repositorio_falso.dart';

/// Reloj controlable para la espera de reenvio.
class RelojFalso {
  DateTime ahora = DateTime(2026, 11, 20, 10);

  void avanzar(Duration duracion) => ahora = ahora.add(duracion);
}

/// Monta la app real con el repositorio simulado. Arranca en /login porque
/// el repositorio falso no restaura ninguna sesion.
Future<void> montarApp(
  WidgetTester tester, {
  required RepositorioFalso repositorio,
  RelojFalso? reloj,
  Size tamano = const Size(400, 800),
}) async {
  tester.view
    ..physicalSize = tamano
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final relojUsado = reloj ?? RelojFalso();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        autenticacionRepositorioProvider.overrideWithValue(repositorio),
        relojProvider.overrideWithValue(() => relojUsado.ahora),
      ],
      child: const Aplicacion(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Hace visible el widget (los formularios tienen scroll) y lo pulsa.
Future<void> tocar(WidgetTester tester, Finder objetivo) async {
  await tester.ensureVisible(objetivo);
  await tester.pumpAndSettle();
  await tester.tap(objetivo);
  await tester.pumpAndSettle();
}

Finder campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);

Finder boton(String texto) => find.widgetWithText(FilledButton, texto);
