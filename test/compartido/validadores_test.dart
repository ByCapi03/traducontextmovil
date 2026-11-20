import 'package:flutter_test/flutter_test.dart';
import 'package:traducontextmovil/compartido/validadores.dart';

void main() {
  test('normaliza correo y nombre igual que el backend', () {
    expect(Validadores.normalizarCorreo('  Ana@Correo.COM '), 'ana@correo.com');
    expect(Validadores.normalizarNombre('  Ana   María  '), 'Ana María');
  });

  test('correo', () {
    expect(Validadores.correo(''), 'Ingresa tu correo.');
    expect(Validadores.correo('ana@correo'), 'Correo no válido.');
    expect(Validadores.correo(' Ana@Correo.com '), isNull);
  });

  test('nombre de 2 a 100 caracteres', () {
    expect(Validadores.nombre('  '), 'Ingresa tu nombre.');
    expect(Validadores.nombre('A'), isNotNull);
    expect(Validadores.nombre('Ñu'), isNull);
    expect(Validadores.nombre('a' * 101), isNotNull);
  });

  test('contraseña nueva: 8 a 72, con letra y número', () {
    expect(Validadores.contrasenaNueva('abc123'), contains('al menos 8'));
    expect(Validadores.contrasenaNueva('abcdefgh'), contains('una letra y un número'));
    expect(Validadores.contrasenaNueva('12345678'), contains('una letra y un número'));
    expect(Validadores.contrasenaNueva('ñandú2024'), isNull);
    expect(Validadores.contrasenaNueva('a1' * 37), contains('más de 72'));
  });

  test('confirmación', () {
    final validar = Validadores.confirmacion(() => 'clave1234');
    expect(validar(''), 'Confirma la contraseña.');
    expect(validar('otra1234'), 'Las contraseñas no coinciden.');
    expect(validar('clave1234'), isNull);
  });

  test('código de 6 dígitos', () {
    expect(Validadores.codigo(''), 'Ingresa el código.');
    expect(Validadores.codigo('12345'), 'El código debe tener 6 dígitos.');
    expect(Validadores.codigo('12a456'), isNotNull);
    expect(Validadores.codigo('123456'), isNull);
  });
}
