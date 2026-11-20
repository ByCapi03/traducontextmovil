import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/validadores.dart';
import 'package:traducontextmovil/compartido/widgets/boton_con_carga.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/mensaje_formulario.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/mensajes_error_autenticacion.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/aviso_inicio_sesion.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/widgets/campo_contrasena.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

class PantallaInicioSesion extends ConsumerStatefulWidget {
  const PantallaInicioSesion({super.key});

  @override
  ConsumerState<PantallaInicioSesion> createState() => _PantallaInicioSesionState();
}

class _PantallaInicioSesionState extends ConsumerState<PantallaInicioSesion> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _cargando = false;
  String? _error;

  /// Login con 403: se ofrece ir a verificar el correo.
  bool _cuentaNoActiva = false;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!(_formulario.currentState?.validate() ?? false)) return;

    ref.read(avisoInicioSesionProvider.notifier).limpiar();
    setState(() {
      _cargando = true;
      _error = null;
      _cuentaNoActiva = false;
    });
    try {
      await ref.read(sesionProvider.notifier).iniciarSesion(
            correo: _correo.text,
            contrasena: _contrasena.text,
          );
      // La redireccion la hace go_router al cambiar el estado de sesion.
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(() {
          _error = MensajesErrorAutenticacion.para(OperacionAutenticacion.inicioSesion, error);
          _cuentaNoActiva =
              MensajesErrorAutenticacion.esCuentaNoActiva(OperacionAutenticacion.inicioSesion, error);
        });
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _irAVerificar() {
    final correo = Validadores.normalizarCorreo(_correo.text);
    setState(() {
      _error = null;
      _cuentaNoActiva = false;
    });
    context.push(Rutas.verificarCorreo, extra: correo.isEmpty ? null : correo);
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider);
    final avisoSesion = sesion is SesionNoAutenticada ? sesion.mensaje : null;
    final error = _error ?? avisoSesion;
    final exito = ref.watch(avisoInicioSesionProvider);
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      body: ContenidoAdaptable(
        child: AutofillGroup(
          child: Form(
            key: _formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.translate_rounded, size: 48, color: ColoresApp.primario),
                const SizedBox(height: Espaciados.md),
                Text('TraduContext', textAlign: TextAlign.center, style: textos.headlineMedium),
                Text(
                  'Inicia sesión para continuar',
                  textAlign: TextAlign.center,
                  style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
                ),
                const SizedBox(height: Espaciados.lg),
                TextFormField(
                  controller: _correo,
                  enabled: !_cargando,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: Validadores.correo,
                ),
                const SizedBox(height: Espaciados.md),
                CampoContrasena(
                  controlador: _contrasena,
                  etiqueta: 'Contraseña',
                  habilitado: !_cargando,
                  accion: TextInputAction.done,
                  alEnviar: _enviar,
                  validador: Validadores.contrasenaIngresada,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _cargando ? null : () => context.push(Rutas.recuperarContrasena),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                if (exito != null && error == null) ...[
                  MensajeFormulario(exito, esError: false),
                  const SizedBox(height: Espaciados.sm),
                ],
                if (error != null) ...[
                  MensajeFormulario(error),
                  if (_cuentaNoActiva)
                    TextButton(
                      onPressed: _irAVerificar,
                      child: const Text('¿Aún no verificaste tu correo?'),
                    ),
                  const SizedBox(height: Espaciados.sm),
                ],
                const SizedBox(height: Espaciados.sm),
                BotonConCarga(
                  texto: 'Iniciar sesión',
                  cargando: _cargando,
                  alPresionar: _enviar,
                ),
                const SizedBox(height: Espaciados.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('¿No tienes cuenta?', style: textos.bodyMedium),
                    TextButton(
                      onPressed: _cargando ? null : () => context.push(Rutas.registro),
                      child: const Text('Crear cuenta'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
