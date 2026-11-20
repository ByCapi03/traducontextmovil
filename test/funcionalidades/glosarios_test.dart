import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/widgets/desplegable.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/dominio/glosarios.dart';
import 'package:traducontextmovil/funcionalidades/preferencias/dominio/preferencias.dart';
import 'package:traducontextmovil/funcionalidades/inicio/presentacion/pantallas/pantalla_inicio.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';

import '../apoyo/falsos.dart';
import '../apoyo/montar_app.dart';

Future<Falsos> _abrir(WidgetTester tester, String ruta, {Falsos? falsos, Size tamano = const Size(400, 800)}) async {
  final todos = await montarApp(tester, falsos: falsos ?? Falsos().conSesion(), tamano: tamano);
  GoRouter.of(tester.element(find.byType(PantallaInicio))).push(ruta);
  await tester.pumpAndSettle();
  return todos;
}

Finder _campo(String etiqueta) => find.widgetWithText(TextField, etiqueta);

Future<void> _elegir(WidgetTester tester, String etiqueta, String opcion) async {
  await tocar(
    tester,
    find.descendant(
      of: find.byWidgetPredicate((w) => w is Desplegable && w.etiqueta == etiqueta),
      matching: find.byWidgetPredicate((w) => w is DropdownButton),
    ),
  );
  await tocar(tester, find.text(opcion).last);
}

const _termino = TerminoGlosario(id: 1, terminoOrigen: 'Headache', traduccionPreferida: 'Cefalea');

void main() {
  group('validación (igual que la web)', () {
    test('glosario: nombre, idiomas distintos y nombre repetido sin distinguir mayúsculas', () {
      final otros = [
        const Glosario(id: 1, nombre: 'Medicina', idIdiomaOrigen: 3, idIdiomaDestino: 1),
      ];
      String? validar(String nombre, int? o, int? d) => ValidacionGlosarios.glosario(
            DatosGlosario(nombre: nombre, idIdiomaOrigen: o, idIdiomaDestino: d),
            otros: otros,
          );
      expect(validar('  ', 3, 1), 'El nombre del glosario es obligatorio.');
      expect(validar('Legal', null, 1), 'Selecciona el idioma de origen y el de destino.');
      expect(validar('Legal', 1, 1), 'El idioma de origen y el de destino deben ser distintos.');
      expect(validar(' MEDICINA ', 3, 1), 'Ya tienes un glosario con ese nombre.');
      expect(validar('Legal', 3, 1), isNull);
    });

    test('término: obligatorio, traducción o conservar, y repetido sin distinguir mayúsculas', () {
      String? validar(String origen, {String? traduccion, bool conservar = false, int? editado}) =>
          ValidacionGlosarios.termino(
            DatosTermino(terminoOrigen: origen, traduccionPreferida: traduccion, conservarOriginal: conservar),
            existentes: const [_termino],
            idEditado: editado,
          );
      expect(validar(''), 'El término de origen es obligatorio.');
      expect(validar('Fever'), 'Indica la traducción preferida o marca el término para conservarlo.');
      expect(validar('Fever', conservar: true), isNull);
      expect(validar('headache', traduccion: 'Dolor'), 'Ese término ya existe en el glosario.');
      // Editar el mismo término no cuenta como repetido.
      expect(validar('HEADACHE', traduccion: 'Dolor', editado: 1), isNull);
    });

    test('aplicaA filtra por destino y, si se conoce, por origen', () {
      const g = Glosario(
        id: 1,
        nombre: 'M',
        idIdiomaOrigen: 3,
        idIdiomaDestino: 1,
        codigoIdiomaOrigen: 'en',
        codigoIdiomaDestino: 'es',
      );
      expect(g.aplicaA(destino: 'es'), isTrue);
      expect(g.aplicaA(origen: 'en', destino: 'es'), isTrue);
      expect(g.aplicaA(origen: 'fr', destino: 'es'), isFalse);
      expect(g.aplicaA(destino: 'en'), isFalse);
    });
  });

  group('pantallas', () {
    testWidgets('crea un glosario, rechaza el nombre repetido y abre sus términos', (tester) async {
      final falsos = await _abrir(tester, Rutas.glosarios);
      expect(find.text('Medicina'), findsOneWidget);
      expect(find.text('EN → ES · 1 término'), findsOneWidget);

      await tocar(tester, find.text('Nuevo glosario'));
      await tester.enterText(_campo('Nombre *'), 'medicina');
      await _elegir(tester, 'Idioma de origen *', 'Inglés');
      await _elegir(tester, 'Idioma de destino *', 'Español');
      await tocar(tester, find.text('Guardar'));
      expect(find.text('Ya tienes un glosario con ese nombre.'), findsOneWidget);
      expect(falsos.glosarios.eventos, isEmpty);

      await tester.enterText(_campo('Nombre *'), 'Legal');
      await tocar(tester, find.text('Guardar'));
      expect(falsos.glosarios.eventos.single, 'crear:Legal');
      // Se abre el glosario recién creado.
      expect(find.text('Este glosario no tiene términos. Agrega uno para fijar su traducción.'), findsOneWidget);
    });

    testWidgets('agrega, rechaza duplicados, edita y elimina términos', (tester) async {
      final falsos = await _abrir(tester, Rutas.glosario(1));
      expect(find.text('Headache'), findsOneWidget);

      await tocar(tester, find.text('Nuevo término'));
      await tester.enterText(_campo('Término de origen *'), 'HEADACHE');
      await tester.enterText(_campo('Traducción preferida *'), 'Dolor de cabeza');
      await tocar(tester, find.text('Guardar'));
      expect(find.text('Ese término ya existe en el glosario.'), findsOneWidget);

      await tester.enterText(_campo('Término de origen *'), 'Paracetamol');
      await tocar(tester, find.text('Conservar en el idioma original'));
      expect(_campo('Traducción preferida *'), findsNothing);
      await tocar(tester, find.text('Guardar'));
      expect(falsos.glosarios.eventos.last, 'agregarTermino:1:Paracetamol');
      expect(find.text('Se conserva sin traducir'), findsOneWidget);

      await tocar(tester, find.text('Headache'));
      await tester.enterText(_campo('Traducción preferida *'), 'Migraña');
      await tocar(tester, find.text('Guardar'));
      expect(falsos.glosarios.eventos.last, 'actualizarTermino:11:Headache');
      expect(find.text('→ Migraña'), findsOneWidget);

      await tocar(tester, find.byTooltip('Eliminar Paracetamol'));
      await tocar(tester, find.widgetWithText(TextButton, 'Eliminar'));
      expect(falsos.glosarios.eventos.last, startsWith('eliminarTermino:'));
      expect(find.text('Paracetamol'), findsNothing);
    });

    testWidgets('edita y elimina un glosario desde la lista', (tester) async {
      final falsos = await _abrir(tester, Rutas.glosarios);
      await tocar(tester, find.byTooltip('Opciones de Medicina'));
      await tocar(tester, find.text('Editar'));
      await tester.enterText(_campo('Nombre *'), 'Medicina general');
      await tocar(tester, find.text('Guardar'));
      expect(falsos.glosarios.eventos.last, 'actualizar:1:Medicina general');

      await tocar(tester, find.byTooltip('Opciones de Medicina general'));
      await tocar(tester, find.text('Eliminar'));
      await tocar(tester, find.widgetWithText(TextButton, 'Eliminar'));
      expect(falsos.glosarios.eventos.last, 'eliminar:1');
      expect(find.textContaining('Todavía no tienes glosarios'), findsOneWidget);
    });

    for (final ancho in [360.0, 420.0]) {
      testWidgets('sin desbordes a $ancho px', (tester) async {
        await _abrir(tester, Rutas.glosarios, tamano: Size(ancho, 640));
        await tocar(tester, find.text('Medicina'));
        await tocar(tester, find.text('Nuevo término'));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('selector de glosario', () {
    testWidgets('al traducir solo ofrece los del par y envía el elegido', (tester) async {
      final falsos = await montarApp(tester, falsos: Falsos().conSesion());
      await irAPestana(tester, Icons.translate_outlined);
      // Destino por defecto: inglés; el glosario es EN → ES, no aplica.
      expect(find.text('Medicina (EN → ES)'), findsNothing);

      // Destino español (selector "A").
      await tocar(tester, find.byType(DropdownButton<String?>).last);
      await tocar(tester, find.text('Español').last);
      await _elegir(tester, 'Glosario', 'Medicina (EN → ES)');

      await tester.enterText(find.widgetWithText(TextField, 'Texto a traducir'), 'I have a headache');
      await tocar(tester, find.widgetWithText(FilledButton, 'Traducir'));
      expect(falsos.traduccion.traducciones.last['glosario'], 1);
    });

    testWidgets('las preferencias solo ofrecen glosarios del idioma de destino', (tester) async {
      final falsos = Falsos().conSesion();
      falsos.preferenciasTraduccion.servidor = const PreferenciasTraduccion(idContexto: 2, idTono: 1, codigoIdiomaDestino: 'es');
      await _abrir(tester, Rutas.preferencias, falsos: falsos);
      await _elegir(tester, 'Glosario predeterminado', 'Medicina (EN → ES)');

      await _elegir(tester, 'Idioma de destino', 'Francés');
      await tester.scrollUntilVisible(find.text('Guardar preferencias'), 200, scrollable: find.byType(Scrollable).last);
      await tocar(tester, find.text('Guardar preferencias'));
      expect(falsos.preferenciasTraduccion.guardadas.single.idGlosario, isNull);
    });

    testWidgets('la conversación ofrece glosarios del par en cualquier sentido', (tester) async {
      final falsos = await _abrir(tester, Rutas.nuevaConversacion);
      await tocar(tester, find.byType(DropdownButton<int?>).first);
      await tocar(tester, find.text('Consulta médica').last);
      await tocar(tester, find.text('Sin glosario'));
      await tocar(tester, find.text('Medicina (EN → ES)').last);
      await tocar(tester, find.text('Iniciar conversación'));
      expect(falsos.conversaciones.creada?.idGlosario, 1);
    });
  });
}
