import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/pantallas/pantalla_inicio_sesion.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/pantallas/pantalla_recuperar_contrasena.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/pantallas/pantalla_registro.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/pantallas/pantalla_verificar_correo.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

import '../../apoyo/montar_app.dart';
import '../../apoyo/repositorio_falso.dart';

void main() {
  group('inicio de sesión', () {
    testWidgets('usuario sin verificar va al flujo de verificación sin bloquear la pantalla',
        (tester) async {
      final repositorio = RepositorioFalso()
        ..errores['iniciarSesion'] =
            const ExcepcionApi('La cuenta del usuario no esta activa.', codigoEstado: 403);
      await montarApp(tester, repositorio: repositorio);

      await tester.enterText(campo('Correo'), ' Ana@Correo.com ');
      await tester.enterText(campo('Contraseña'), 'clave1234');
      await tocar(tester, boton('Iniciar sesión'));

      expect(find.text('Tu cuenta no está activa.'), findsOneWidget);
      // La pantalla no queda bloqueada: el botón y los campos siguen activos.
      expect(tester.widget<FilledButton>(boton('Iniciar sesión')).onPressed, isNotNull);
      expect(tester.widget<TextFormField>(campo('Correo')).enabled, isTrue);

      await tocar(tester, find.text('¿Aún no verificaste tu correo?'));
      expect(find.byType(PantallaVerificarCorreo), findsOneWidget);
      expect(find.textContaining('ana@correo.com'), findsOneWidget);
    });

    testWidgets('credenciales incorrectas muestran texto propio con tildes', (tester) async {
      final repositorio = RepositorioFalso()
        ..errores['iniciarSesion'] =
            const ExcepcionApi('Correo o contrasena incorrectos.', codigoEstado: 401);
      await montarApp(tester, repositorio: repositorio);
      await tester.enterText(campo('Correo'), 'ana@correo.com');
      await tester.enterText(campo('Contraseña'), 'mala1234');
      await tocar(tester, boton('Iniciar sesión'));

      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(find.text('¿Aún no verificaste tu correo?'), findsNothing);
    });
  });

  group('registro y verificación', () {
    testWidgets('409 muestra que el correo ya existe', (tester) async {
      final repositorio = RepositorioFalso()
        ..errores['registrar'] =
            const ExcepcionApi('El correo ya se encuentra registrado.', codigoEstado: 409);
      await montarApp(tester, repositorio: repositorio);
      await tocar(tester, find.widgetWithText(TextButton, 'Crear cuenta'));
      await _llenarRegistro(tester);
      await tocar(tester, boton('Crear cuenta'));

      expect(find.text('Ya existe una cuenta con ese correo.'), findsOneWidget);
      expect(find.byType(PantallaRegistro), findsOneWidget);
    });

    testWidgets('registro lleva a verificar y la espera de 60 s sobrevive a salir y volver',
        (tester) async {
      final repositorio = RepositorioFalso();
      final reloj = RelojFalso();
      await montarApp(tester, repositorio: repositorio, reloj: reloj);

      await tocar(tester, find.widgetWithText(TextButton, 'Crear cuenta'));
      await _llenarRegistro(tester);
      await tocar(tester, boton('Crear cuenta'));

      expect(repositorio.llamadasA('registrar').single['correo'], 'ana@correo.com');
      expect(find.byType(PantallaVerificarCorreo), findsOneWidget);
      expect(find.text('Reenviar código en 60 s'), findsOneWidget);

      reloj.avanzar(const Duration(seconds: 20));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Reenviar código en 40 s'), findsOneWidget);

      // Sale al login y vuelve: la espera continúa donde estaba.
      await tocar(tester, find.text('Volver al inicio de sesión'));
      expect(find.byType(PantallaInicioSesion), findsOneWidget);
      reloj.avanzar(const Duration(seconds: 10));
      GoRouter.of(tester.element(find.byType(PantallaInicioSesion)))
          .go(Rutas.verificarCorreo, extra: 'ana@correo.com');
      await tester.pumpAndSettle();
      expect(find.text('Reenviar código en 30 s'), findsOneWidget);

      reloj.avanzar(const Duration(seconds: 30));
      await tester.pump(const Duration(seconds: 1));
      await tocar(tester, find.text('Reenviar código'));
      expect(repositorio.llamadasA('reenviarCodigoVerificacion'), hasLength(1));
      expect(find.text('Reenviar código en 60 s'), findsOneWidget);
    });

    testWidgets('el campo de código solo acepta 6 dígitos y verificar vuelve al login con aviso',
        (tester) async {
      final repositorio = RepositorioFalso();
      await montarApp(tester, repositorio: repositorio);
      GoRouter.of(tester.element(find.byType(PantallaInicioSesion)))
          .go(Rutas.verificarCorreo, extra: 'ana@correo.com');
      await tester.pumpAndSettle();

      await tester.enterText(campo('Código de 6 dígitos'), '12a34567');
      expect(
        tester.widget<TextFormField>(campo('Código de 6 dígitos')).controller!.text,
        '123456',
      );
      await tocar(tester, boton('Verificar'));

      expect(repositorio.llamadasA('verificarCorreo').single['codigo'], '123456');
      expect(find.byType(PantallaInicioSesion), findsOneWidget);
      expect(find.text('Correo verificado. Ya puedes iniciar sesión.'), findsOneWidget);
    });

    testWidgets('código inválido o cuenta suspendida muestran textos propios', (tester) async {
      final repositorio = RepositorioFalso()
        ..errores['verificarCorreo'] =
            const ExcepcionApi('El codigo de verificacion expiro.', codigoEstado: 400)
        ..errores['reenviarCodigoVerificacion'] =
            const ExcepcionApi('La cuenta esta suspendida.', codigoEstado: 403);
      await montarApp(tester, repositorio: repositorio);
      GoRouter.of(tester.element(find.byType(PantallaInicioSesion)))
          .go(Rutas.verificarCorreo, extra: 'ana@correo.com');
      await tester.pumpAndSettle();

      await tester.enterText(campo('Código de 6 dígitos'), '000000');
      await tocar(tester, boton('Verificar'));
      expect(find.textContaining('El código no es válido o ya expiró.'), findsOneWidget);

      await tocar(tester, find.text('Reenviar código'));
      expect(
        find.text('Tu cuenta está suspendida. Contacta con un administrador.'),
        findsOneWidget,
      );
      // Un error no arranca la espera.
      expect(find.text('Reenviar código'), findsOneWidget);
    });
  });

  group('recuperación de contraseña', () {
    testWidgets('tres pasos con mensaje neutro y el código solo pasa al paso 3', (tester) async {
      final repositorio = RepositorioFalso();
      await montarApp(tester, repositorio: repositorio);
      await tocar(tester, find.text('¿Olvidaste tu contraseña?'));
      expect(find.byType(PantallaRecuperarContrasena), findsOneWidget);

      await tester.enterText(campo('Correo'), 'Ana@Correo.com');
      await tocar(tester, boton('Enviar código'));
      expect(find.textContaining('Si el correo corresponde a una cuenta activa'), findsOneWidget);
      expect(find.text('Paso 2 de 3'), findsOneWidget);

      await tester.enterText(campo('Código de 6 dígitos'), '654321');
      await tocar(tester, boton('Validar código'));
      expect(find.text('Paso 3 de 3'), findsOneWidget);
      expect(find.text('654321'), findsNothing);

      await tester.enterText(campo('Nueva contraseña'), 'nueva2024');
      await tester.enterText(campo('Confirmar contraseña'), 'nueva2024');
      await tocar(tester, boton('Cambiar contraseña'));

      expect(repositorio.llamadasA('restablecerContrasena').single, {
        'correo': 'ana@correo.com',
        'codigo': '654321',
      });
      expect(find.byType(PantallaInicioSesion), findsOneWidget);
      expect(
        find.text('Tu contraseña se actualizó. Inicia sesión con la nueva contraseña.'),
        findsOneWidget,
      );
    });

    testWidgets('si el código expira en el paso 3 vuelve al paso 2 con el campo vacío',
        (tester) async {
      final repositorio = RepositorioFalso()
        ..errores['restablecerContrasena'] =
            const ExcepcionApi('El codigo de recuperacion es invalido o expiro.', codigoEstado: 400);
      await montarApp(tester, repositorio: repositorio);
      await tocar(tester, find.text('¿Olvidaste tu contraseña?'));
      await tester.enterText(campo('Correo'), 'ana@correo.com');
      await tocar(tester, boton('Enviar código'));
      await tester.enterText(campo('Código de 6 dígitos'), '654321');
      await tocar(tester, boton('Validar código'));
      await tester.enterText(campo('Nueva contraseña'), 'nueva2024');
      await tester.enterText(campo('Confirmar contraseña'), 'nueva2024');
      await tocar(tester, boton('Cambiar contraseña'));

      expect(find.text('Paso 2 de 3'), findsOneWidget);
      expect(find.text('El código no es válido o ya expiró.'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(campo('Código de 6 dígitos')).controller!.text,
        isEmpty,
      );
    });
  });

  group('sin desbordes', () {
    for (final ancho in [360.0, 420.0]) {
      testWidgets('pantallas de autenticación a $ancho px', (tester) async {
        await montarApp(tester, repositorio: RepositorioFalso(), tamano: Size(ancho, 640));
        final enrutador = GoRouter.of(tester.element(find.byType(PantallaInicioSesion)));
        for (final ruta in [Rutas.registro, Rutas.verificarCorreo, Rutas.recuperarContrasena]) {
          enrutador.go(ruta, extra: ruta == Rutas.verificarCorreo ? 'ana@correo.com' : null);
          await tester.pumpAndSettle();
        }
        enrutador.go(Rutas.login);
        await tester.pumpAndSettle();
        // Cualquier overflow habría hecho fallar el test con un FlutterError.
        expect(tester.takeException(), isNull);
      });
    }
  });
}

Future<void> _llenarRegistro(WidgetTester tester) async {
  await tester.enterText(campo('Nombre'), '  Ana   María ');
  await tester.enterText(campo('Correo'), 'Ana@Correo.com');
  await tester.enterText(campo('Contraseña'), 'clave2024');
  await tester.enterText(campo('Confirmar contraseña'), 'clave2024');
}
