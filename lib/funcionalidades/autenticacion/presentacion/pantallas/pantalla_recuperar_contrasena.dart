import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/validadores.dart';
import 'package:traducontextmovil/compartido/widgets/boton_con_carga.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/mensaje_formulario.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/datos/repositorios/autenticacion_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/mensajes_error_autenticacion.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/aviso_inicio_sesion.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/espera_reenvio.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/widgets/boton_reenviar_codigo.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/widgets/campo_codigo.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/widgets/campo_contrasena.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

enum _Paso { correo, codigo, nuevaContrasena }

/// HU-03: asistente de 3 pasos (correo, código, nueva contraseña).
///
/// El código validado solo vive en memoria de este State para el paso 3; se
/// borra al terminar, al cancelar y al salir de la pantalla. Nunca se registra
/// ni se guarda.
class PantallaRecuperarContrasena extends ConsumerStatefulWidget {
  const PantallaRecuperarContrasena({super.key});

  @override
  ConsumerState<PantallaRecuperarContrasena> createState() =>
      _PantallaRecuperarContrasenaState();
}

class _PantallaRecuperarContrasenaState extends ConsumerState<PantallaRecuperarContrasena> {
  /// Respuesta neutra: el backend responde igual exista o no la cuenta.
  static const String mensajeEnvioNeutro =
      'Si el correo corresponde a una cuenta activa, te enviamos un código. Revisa tu bandeja de entrada.';

  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _codigo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();

  _Paso _paso = _Paso.correo;
  String? _codigoValidado;
  bool _cargando = false;
  String? _error;
  String? _aviso;

  String get _correoNormalizado => Validadores.normalizarCorreo(_correo.text);

  @override
  void dispose() {
    _borrarDatosSensibles();
    _correo.dispose();
    _codigo.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  void _borrarDatosSensibles() {
    _codigoValidado = null;
    _codigo.clear();
    _contrasena.clear();
    _confirmacion.clear();
  }

  Future<void> _ejecutar(
    OperacionAutenticacion operacion,
    Future<void> Function() accion,
  ) async {
    FocusScope.of(context).unfocus();
    if (!(_formulario.currentState?.validate() ?? false)) return;
    setState(() {
      _cargando = true;
      _error = null;
      _aviso = null;
    });
    try {
      await accion();
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(() {
          _error = MensajesErrorAutenticacion.para(operacion, error);
          // El código caducó entre el paso 2 y el 3: hay que pedir/escribir otro.
          if (operacion == OperacionAutenticacion.restablecimientoContrasena &&
              error.codigoEstado == 400) {
            _borrarDatosSensibles();
            _paso = _Paso.codigo;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _solicitarCodigo() => _ejecutar(OperacionAutenticacion.solicitudRecuperacion, () async {
        await ref.read(autenticacionRepositorioProvider).solicitarRecuperacion(correo: _correoNormalizado);
        ref
            .read(esperaReenvioProvider.notifier)
            .registrarEnvio(ControladorEsperaReenvio.claveRecuperacion(_correoNormalizado));
        if (mounted) {
          setState(() {
            _paso = _Paso.codigo;
            _aviso = mensajeEnvioNeutro;
          });
        }
      });

  Future<bool> _reenviarCodigo() async {
    setState(() {
      _error = null;
      _aviso = null;
    });
    try {
      await ref.read(autenticacionRepositorioProvider).solicitarRecuperacion(correo: _correoNormalizado);
      if (mounted) setState(() => _aviso = mensajeEnvioNeutro);
      return true;
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(
          () => _error =
              MensajesErrorAutenticacion.para(OperacionAutenticacion.solicitudRecuperacion, error),
        );
      }
      return error.codigoEstado == 429;
    }
  }

  Future<void> _validarCodigo() =>
      _ejecutar(OperacionAutenticacion.validacionCodigoRecuperacion, () async {
        final codigo = _codigo.text.trim();
        await ref
            .read(autenticacionRepositorioProvider)
            .validarCodigoRecuperacion(correo: _correoNormalizado, codigo: codigo);
        if (mounted) {
          setState(() {
            _codigoValidado = codigo;
            _codigo.clear();
            _paso = _Paso.nuevaContrasena;
          });
        }
      });

  Future<void> _restablecer() =>
      _ejecutar(OperacionAutenticacion.restablecimientoContrasena, () async {
        await ref.read(autenticacionRepositorioProvider).restablecerContrasena(
              correo: _correoNormalizado,
              codigo: _codigoValidado ?? '',
              nuevaContrasena: _contrasena.text,
            );
        _borrarDatosSensibles();
        ref
            .read(avisoInicioSesionProvider.notifier)
            .mostrar('Tu contraseña se actualizó. Inicia sesión con la nueva contraseña.');
        if (mounted) context.go(Rutas.login);
      });

  void _cambiarCorreo() {
    setState(() {
      _borrarDatosSensibles();
      _error = null;
      _aviso = null;
      _paso = _Paso.correo;
    });
  }

  void _cancelar() {
    _borrarDatosSensibles();
    context.go(Rutas.login);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final (titulo, descripcion) = switch (_paso) {
      _Paso.correo => ('Paso 1 de 3', 'Escribe el correo de tu cuenta y te enviaremos un código.'),
      _Paso.codigo => ('Paso 2 de 3', 'Escribe el código de 6 dígitos que te enviamos.'),
      _Paso.nuevaContrasena => ('Paso 3 de 3', 'Elige tu nueva contraseña.'),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: ContenidoAdaptable(
        child: AutofillGroup(
          child: Form(
            key: _formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(titulo, textAlign: TextAlign.center, style: textos.titleMedium),
                const SizedBox(height: Espaciados.xs),
                Text(
                  descripcion,
                  textAlign: TextAlign.center,
                  style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
                ),
                const SizedBox(height: Espaciados.lg),
                ..._campos(),
                if (_aviso != null) ...[
                  const SizedBox(height: Espaciados.md),
                  MensajeFormulario(_aviso!, esError: false),
                ],
                if (_error != null) ...[
                  const SizedBox(height: Espaciados.md),
                  MensajeFormulario(_error!),
                ],
                const SizedBox(height: Espaciados.lg),
                ..._acciones(),
                TextButton(
                  onPressed: _cargando ? null : _cancelar,
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _campos() => switch (_paso) {
        _Paso.correo => [
            TextFormField(
              controller: _correo,
              enabled: !_cargando,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              onFieldSubmitted: (_) => _solicitarCodigo(),
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: Validadores.correo,
            ),
          ],
        _Paso.codigo => [
            CampoCodigo(controlador: _codigo, habilitado: !_cargando, alEnviar: _validarCodigo),
          ],
        _Paso.nuevaContrasena => [
            CampoContrasena(
              controlador: _contrasena,
              etiqueta: 'Nueva contraseña',
              habilitado: !_cargando,
              esNueva: true,
              validador: Validadores.contrasenaNueva,
            ),
            const SizedBox(height: Espaciados.xs),
            Text(
              'De 8 a 72 caracteres, con al menos una letra y un número.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Espaciados.md),
            CampoContrasena(
              controlador: _confirmacion,
              etiqueta: 'Confirmar contraseña',
              habilitado: !_cargando,
              esNueva: true,
              accion: TextInputAction.done,
              alEnviar: _restablecer,
              validador: Validadores.confirmacion(() => _contrasena.text),
            ),
          ],
      };

  List<Widget> _acciones() => switch (_paso) {
        _Paso.correo => [
            BotonConCarga(texto: 'Enviar código', cargando: _cargando, alPresionar: _solicitarCodigo),
          ],
        _Paso.codigo => [
            BotonConCarga(texto: 'Validar código', cargando: _cargando, alPresionar: _validarCodigo),
            const SizedBox(height: Espaciados.sm),
            BotonReenviarCodigo(
              clave: ControladorEsperaReenvio.claveRecuperacion(_correoNormalizado),
              habilitado: !_cargando,
              alReenviar: _reenviarCodigo,
            ),
            TextButton(
              onPressed: _cargando ? null : _cambiarCorreo,
              child: const Text('Cambiar correo'),
            ),
          ],
        _Paso.nuevaContrasena => [
            BotonConCarga(texto: 'Cambiar contraseña', cargando: _cargando, alPresionar: _restablecer),
          ],
      };
}
