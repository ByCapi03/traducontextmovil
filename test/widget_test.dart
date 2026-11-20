import 'package:flutter_test/flutter_test.dart';
import 'package:traducontextmovil/datos/modelos/usuario_actual.dart';
import 'package:traducontextmovil/nucleo/rutas/enrutador.dart';
import 'package:traducontextmovil/nucleo/rutas/rutas.dart';
import 'package:traducontextmovil/presentacion/autenticacion/estado_sesion.dart';

UsuarioActual _usuario(List<String> permisos) => UsuarioActual.desdeJson({
      'id': 1,
      'nombre': 'Prueba',
      'correo': 'prueba@correo.com',
      'estado': 'ACTIVO',
      'rol': {'id': 1, 'nombre': permisos.isEmpty ? 'USUARIO' : 'ADMINISTRADOR'},
      'permisos': permisos,
    });

void main() {
  test('UsuarioActual se construye desde la respuesta de /usuarios/me', () {
    final usuario = _usuario(['ver_dashboard']);
    expect(usuario.rol.nombre, 'ADMINISTRADOR');
    expect(usuario.esAdministrador, isTrue);
    expect(_usuario([]).esAdministrador, isFalse);
  });

  group('redirigirSegunSesion', () {
    test('sin sesion siempre va a /login', () {
      expect(redirigirSegunSesion(const SesionNoAutenticada(), Rutas.inicio), Rutas.login);
      expect(redirigirSegunSesion(const SesionNoAutenticada(), Rutas.login), isNull);
    });

    test('usuario normal entra a /inicio y no puede abrir administracion', () {
      final sesion = SesionAutenticada(_usuario([]));
      expect(redirigirSegunSesion(sesion, Rutas.login), Rutas.inicio);
      expect(redirigirSegunSesion(sesion, Rutas.administracionUsuarios), Rutas.inicio);
    });

    test('admin entra a su primera ruta permitida', () {
      final sesion = SesionAutenticada(_usuario(['ver_dashboard', 'generar_reportes']));
      expect(redirigirSegunSesion(sesion, Rutas.login), Rutas.administracionDashboard);
      expect(redirigirSegunSesion(sesion, Rutas.administracionReportes), isNull);
      expect(
        redirigirSegunSesion(sesion, Rutas.administracionUsuarios),
        Rutas.administracionDashboard,
      );
    });
  });
}
