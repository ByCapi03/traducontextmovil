import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/widgets/desplegable.dart';
import 'package:traducontextmovil/funcionalidades/inicio/presentacion/pantallas/pantalla_inicio.dart';
import 'package:traducontextmovil/funcionalidades/preferencias/dominio/preferencias.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

import '../apoyo/falsos.dart';
import '../apoyo/montar_app.dart';

Future<Falsos> _abrir(WidgetTester tester, Falsos falsos, {Size tamano = const Size(400, 800)}) async {
  await montarApp(tester, falsos: falsos, tamano: tamano);
  GoRouter.of(tester.element(find.byType(PantallaInicio))).push(Rutas.preferencias);
  await tester.pumpAndSettle();
  return falsos;
}

Finder _selector(String etiqueta) => find.byWidgetPredicate(
      (w) => w is Desplegable && w.etiqueta == etiqueta,
    );

Future<void> _elegir(WidgetTester tester, String etiqueta, String opcion) async {
  await tocar(tester, find.descendant(of: _selector(etiqueta), matching: find.byWidgetPredicate((w) => w is DropdownButton)));
  await tocar(tester, find.text(opcion).last);
}

void main() {
  testWidgets('carga lo guardado, filtra variantes por idioma y guarda', (tester) async {
    final falsos = Falsos().conSesion();
    falsos.preferenciasTraduccion.servidor = const PreferenciasTraduccion(idContexto: 2, idTono: 1);
    await _abrir(tester, falsos);

    expect(find.text('Médico'), findsOneWidget);
    expect(find.text('Neutral'), findsOneWidget);
    expect(find.text('Elige primero un idioma de destino.'), findsOneWidget);
    // Sin cambios no se puede guardar.
    await tester.scrollUntilVisible(find.text('Guardar preferencias'), 200, scrollable: find.byType(Scrollable).last);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();

    await _elegir(tester, 'Idioma de destino', 'Inglés');
    expect(find.text('Solo se muestran las del idioma de destino.'), findsOneWidget);
    await _elegir(tester, 'Variante regional', 'Inglés británico');
    await _elegir(tester, 'Tono *', 'Formal');
    await tocar(tester, find.text('Mostrar alternativas de traducción'));

    await tocar(tester, find.text('Guardar preferencias'));
    expect(
      falsos.preferenciasTraduccion.guardadas.single,
      const PreferenciasTraduccion(
        idContexto: 2,
        idTono: 2,
        idVariante: 6,
        codigoIdiomaDestino: 'en',
        generarAlternativas: true,
      ),
    );
    expect(find.text('Preferencias guardadas. Se aplicarán en tus próximas traducciones.'), findsOneWidget);
  });

  testWidgets('al cambiar de idioma se quita la variante que no corresponde', (tester) async {
    final falsos = Falsos().conSesion();
    falsos.preferenciasTraduccion.servidor =
        const PreferenciasTraduccion(idContexto: 2, idTono: 1, codigoIdiomaDestino: 'en', idVariante: 6);
    await _abrir(tester, falsos);
    expect(find.text('Inglés británico'), findsOneWidget);

    await _elegir(tester, 'Idioma de destino', 'Español');
    expect(find.text('Inglés británico'), findsNothing);
    await tocar(tester, find.text('Guardar preferencias'));
    expect(falsos.preferenciasTraduccion.guardadas.single.idVariante, isNull);
    expect(falsos.preferenciasTraduccion.guardadas.single.codigoIdiomaDestino, 'es');
  });

  testWidgets('sin preferencias exige contexto y tono; restablece tras confirmar', (tester) async {
    final falsos = await _abrir(tester, Falsos().conSesion());
    await tocar(tester, find.text('Mostrar alternativas de traducción'));
    await tocar(tester, find.text('Guardar preferencias'));
    expect(find.text('Selecciona un contexto y un tono.'), findsOneWidget);
    expect(falsos.preferenciasTraduccion.guardadas, isEmpty);

    await tocar(tester, find.text('Restablecer valores por defecto'));
    await tocar(tester, find.widgetWithText(TextButton, 'Restablecer'));
    expect(falsos.preferenciasTraduccion.restablecidas, 1);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Preferencias restablecidas a los valores por defecto.'), findsOneWidget);
  });

  testWidgets('un 400 al guardar muestra un texto propio', (tester) async {
    final falsos = Falsos().conSesion();
    falsos.preferenciasTraduccion
      ..servidor = const PreferenciasTraduccion(idContexto: 2, idTono: 1)
      ..errorGuardar = const ExcepcionApi('variante', codigoEstado: 400);
    await _abrir(tester, falsos);
    await _elegir(tester, 'Tono *', 'Formal');
    await tocar(tester, find.text('Guardar preferencias'));
    expect(find.textContaining('No se pudieron guardar las preferencias.'), findsOneWidget);
  });

  for (final ancho in [360.0, 420.0]) {
    testWidgets('sin desbordes a $ancho px', (tester) async {
      final falsos = Falsos().conSesion();
      falsos.preferenciasTraduccion.servidor = const PreferenciasTraduccion(idContexto: 2, idTono: 1);
      await _abrir(tester, falsos, tamano: Size(ancho, 640));
      expect(tester.takeException(), isNull);
    });
  }
}
