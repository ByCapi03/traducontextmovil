import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traducontextmovil/funcionalidades/perfil/dominio/perfil.dart';
import 'package:traducontextmovil/nucleo/archivos/selector_archivos.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

import '../apoyo/falsos.dart';
import '../apoyo/montar_app.dart';

/// PNG válido de 1×1 px.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

Future<Falsos> _abrirPerfil(WidgetTester tester, Falsos falsos) async {
  await montarApp(tester, falsos: falsos);
  await irAPestana(tester, Icons.person_outline);
  return falsos;
}

void main() {
  test('valida formato y tamaño como el backend', () {
    expect(FotoPerfil.validar('yo.png', 100), isNull);
    expect(FotoPerfil.validar('yo.JPEG', 100), isNull);
    expect(FotoPerfil.validar('yo.gif', 100), 'La foto debe ser JPG, PNG o WEBP.');
    expect(FotoPerfil.validar('yo.webp', FotoPerfil.tamanoMaximo + 1), 'La foto no puede superar los 5 MB.');
    expect(FotoPerfil.tipoMime('a.jpg'), 'image/jpeg');
  });

  testWidgets('sube una foto y luego la quita', (tester) async {
    final falsos = Falsos().conSesion();
    falsos.selectorArchivos.archivo = ArchivoSeleccionado(nombre: 'yo.png', bytes: _png);
    await _abrirPerfil(tester, falsos);
    expect(find.text('Quitar foto'), findsNothing);

    await tocar(tester, find.text('Agregar foto'));
    expect(falsos.perfil.eventos.single, 'subir:yo.png:${_png.length}');
    expect(find.text('Foto de perfil actualizada.'), findsOneWidget);
    expect(find.text('Cambiar foto'), findsOneWidget);
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    expect(avatar.foregroundImage, isA<MemoryImage>());

    await tocar(tester, find.text('Quitar foto'));
    expect(falsos.perfil.eventos.last, 'eliminar');
    expect(find.text('Agregar foto'), findsOneWidget);
  });

  testWidgets('rechaza formatos no admitidos sin llamar al backend y muestra el 400', (tester) async {
    final falsos = Falsos().conSesion();
    falsos.selectorArchivos.archivo = const ArchivoSeleccionado(nombre: 'yo.gif', bytes: [1, 2]);
    await _abrirPerfil(tester, falsos);
    await tocar(tester, find.text('Agregar foto'));
    expect(find.text('La foto debe ser JPG, PNG o WEBP.'), findsOneWidget);
    expect(falsos.perfil.eventos, isEmpty);

    falsos.selectorArchivos.archivo = ArchivoSeleccionado(nombre: 'yo.png', bytes: _png);
    falsos.perfil.errorSubir = const ExcepcionApi('formato', codigoEstado: 400);
    await tocar(tester, find.text('Agregar foto'));
    expect(find.text('La imagen no es válida: usa JPG, PNG o WEBP de hasta 5 MB.'), findsOneWidget);
  });

  testWidgets('integraciones sigue como "Próximamente" (requiere OAuth)', (tester) async {
    await _abrirPerfil(tester, Falsos().conSesion());
    await tocar(tester, find.text('Integraciones'));
    expect(find.textContaining('requiere autorizar la cuenta en el navegador'), findsOneWidget);
  });
}
