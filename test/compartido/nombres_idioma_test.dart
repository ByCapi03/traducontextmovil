import 'package:flutter_test/flutter_test.dart';
import 'package:traducontextmovil/compartido/nombres_idioma.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/dominio/idioma.dart';

void main() {
  test('usa el nombre propio con tildes aunque el backend lo envíe sin ellas', () {
    expect(nombreIdioma('en', respaldo: 'Ingles'), 'Inglés');
    expect(nombreIdioma('ja', respaldo: 'Japones'), 'Japonés');
    expect(nombreIdioma('de'), 'Alemán');
    expect(nombreIdioma('fr'), 'Francés');
    expect(nombreIdioma('it'), 'Italiano');
    expect(nombreIdioma('pt'), 'Portugués');
    expect(nombreIdioma('ko'), 'Coreano');
    expect(nombreIdioma('zh'), 'Chino');
    expect(nombreIdioma('es'), 'Español');
    expect(nombreIdioma('ar'), 'Árabe');
  });

  test('acepta códigos con región y en mayúsculas', () {
    expect(nombreIdioma('pt-BR'), 'Portugués');
    expect(nombreIdioma('zh_CN'), 'Chino');
    expect(nombreIdioma('EN'), 'Inglés');
  });

  test('código desconocido: nombre del backend o el código', () {
    expect(nombreIdioma('xx', respaldo: 'Klingon'), 'Klingon');
    expect(nombreIdioma('xx'), 'XX');
    expect(nombreIdiomaOpcional(null), isNull);
  });

  test('ordena sin que las tildes vayan al final', () {
    final nombres = ['Vietnamita', 'Árabe', 'Alemán', 'Español', 'Inglés']
      ..sort((a, b) => claveOrdenIdioma(a).compareTo(claveOrdenIdioma(b)));
    expect(nombres, ['Alemán', 'Árabe', 'Español', 'Inglés', 'Vietnamita']);
  });

  test('nombreDe usa la tabla si el código no está en el catálogo', () {
    const catalogo = [Idioma(id: 1, nombre: 'Español', codigo: 'es')];
    expect(catalogo.nombreDe('es'), 'Español');
    expect(catalogo.nombreDe('ja'), 'Japonés');
  });
}
