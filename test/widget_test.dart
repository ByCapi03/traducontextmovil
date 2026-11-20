import 'package:flutter_test/flutter_test.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/datos/modelos/usuario_actual_modelo.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/usuario_actual.dart';
import 'package:traducontextmovil/navegacion/enrutador.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';

UsuarioActual _usuario(List<String> permisos) => UsuarioActualModelo.desdeJson({
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

    test('sin sesion deja entrar a las rutas publicas', () {
      for (final ruta in [Rutas.registro, Rutas.verificarCorreo, Rutas.recuperarContrasena]) {
        expect(redirigirSegunSesion(const SesionNoAutenticada(), ruta), isNull);
      }
      expect(redirigirSegunSesion(const SesionNoAutenticada(), Rutas.perfil), Rutas.login);
    });

    test('con sesion las rutas publicas redirigen a la ruta inicial', () {
      final usuario = SesionAutenticada(_usuario([]));
      final admin = SesionAutenticada(_usuario(['gestionar_usuarios']));
      for (final ruta in [Rutas.registro, Rutas.verificarCorreo, Rutas.recuperarContrasena]) {
        expect(redirigirSegunSesion(usuario, ruta), Rutas.inicio);
        expect(redirigirSegunSesion(admin, ruta), Rutas.administracionUsuarios);
      }
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
