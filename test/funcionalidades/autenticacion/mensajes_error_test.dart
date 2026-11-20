import 'package:flutter_test/flutter_test.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/mensajes_error_autenticacion.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

ExcepcionApi _error(int codigo) => ExcepcionApi('detalle sin tildes del backend', codigoEstado: codigo);

void main() {
  String texto(OperacionAutenticacion operacion, int codigo) =>
      MensajesErrorAutenticacion.para(operacion, _error(codigo));

  test('nunca muestra el detail del backend', () {
    for (final operacion in OperacionAutenticacion.values) {
      for (final codigo in [400, 401, 403, 404, 409, 422, 429, 500, 502, 503]) {
        expect(texto(operacion, codigo), isNot(contains('backend')));
      }
    }
  });

  test('login: 401, 403 (enlace a verificar) y sin conexión', () {
    expect(texto(OperacionAutenticacion.inicioSesion, 401), 'Correo o contraseña incorrectos.');
    expect(texto(OperacionAutenticacion.inicioSesion, 403), 'Tu cuenta no está activa.');
    expect(
      MensajesErrorAutenticacion.esCuentaNoActiva(OperacionAutenticacion.inicioSesion, _error(403)),
      isTrue,
    );
    expect(
      MensajesErrorAutenticacion.para(
        OperacionAutenticacion.inicioSesion,
        const ExcepcionApi('x', sinConexion: true),
      ),
      MensajesErrorAutenticacion.sinConexion,
    );
  });

  test('verificación y reenvío según el código real del backend', () {
    expect(
      texto(OperacionAutenticacion.verificacionCorreo, 400),
      MensajesErrorAutenticacion.codigoVerificacionInvalido,
    );
    expect(texto(OperacionAutenticacion.verificacionCorreo, 403), MensajesErrorAutenticacion.cuentaSuspendida);
    expect(texto(OperacionAutenticacion.reenvioCodigo, 400), MensajesErrorAutenticacion.cuentaYaVerificada);
    expect(texto(OperacionAutenticacion.reenvioCodigo, 404), MensajesErrorAutenticacion.correoSinCuenta);
    expect(texto(OperacionAutenticacion.reenvioCodigo, 502), MensajesErrorAutenticacion.correoNoEnviado);
    expect(texto(OperacionAutenticacion.reenvioCodigo, 429), MensajesErrorAutenticacion.demasiadosIntentos);
  });

  test('registro y recuperación', () {
    expect(texto(OperacionAutenticacion.registro, 409), 'Ya existe una cuenta con ese correo.');
    expect(texto(OperacionAutenticacion.solicitudRecuperacion, 502), MensajesErrorAutenticacion.correoNoEnviado);
    expect(
      texto(OperacionAutenticacion.validacionCodigoRecuperacion, 400),
      'El código no es válido o ya expiró.',
    );
    expect(
      texto(OperacionAutenticacion.restablecimientoContrasena, 422),
      MensajesErrorAutenticacion.contrasenaNoValida,
    );
  });
}
