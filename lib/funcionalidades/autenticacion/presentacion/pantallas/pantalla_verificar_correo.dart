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
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Activa la cuenta con el código enviado al correo. Si no llega el correo
/// (por ejemplo, al venir del login), se puede escribir.
class PantallaVerificarCorreo extends ConsumerStatefulWidget {
  const PantallaVerificarCorreo({super.key, this.correo});

  final String? correo;

  @override
  ConsumerState<PantallaVerificarCorreo> createState() => _PantallaVerificarCorreoState();
}

class _PantallaVerificarCorreoState extends ConsumerState<PantallaVerificarCorreo> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _correo = TextEditingController(text: widget.correo ?? '');
  final _codigo = TextEditingController();
  bool _cargando = false;
  String? _error;
  String? _aviso;

  bool get _correoFijo => (widget.correo ?? '').isNotEmpty;
  String get _correoNormalizado => Validadores.normalizarCorreo(_correo.text);

  @override
  void initState() {
    super.initState();
    // La clave de la espera depende del correo escrito.
    _correo.addListener(_alCambiarCorreo);
  }

  void _alCambiarCorreo() => setState(() {});

  @override
  void dispose() {
    _correo
      ..removeListener(_alCambiarCorreo)
      ..dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    FocusScope.of(context).unfocus();
    if (!(_formulario.currentState?.validate() ?? false)) return;

    setState(() {
      _cargando = true;
      _error = null;
      _aviso = null;
    });
    try {
      await ref
          .read(autenticacionRepositorioProvider)
          .verificarCorreo(correo: _correoNormalizado, codigo: _codigo.text);
      _codigo.clear();
      ref
          .read(avisoInicioSesionProvider.notifier)
          .mostrar('Correo verificado. Ya puedes iniciar sesión.');
      if (mounted) context.go(Rutas.login);
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(
          () => _error =
              MensajesErrorAutenticacion.para(OperacionAutenticacion.verificacionCorreo, error),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<bool> _reenviar() async {
    if (Validadores.correo(_correo.text) != null) {
      _formulario.currentState?.validate();
      return false;
    }
    setState(() {
      _error = null;
      _aviso = null;
    });
    try {
      await ref
          .read(autenticacionRepositorioProvider)
          .reenviarCodigoVerificacion(correo: _correoNormalizado);
      if (mounted) setState(() => _aviso = 'Te enviamos un nuevo código. Revisa tu correo.');
      return true;
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(
          () => _error = MensajesErrorAutenticacion.para(OperacionAutenticacion.reenvioCodigo, error),
        );
      }
      // Ante un 429 tambien se aplica la espera.
      return error.codigoEstado == 429;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar correo')),
      body: ContenidoAdaptable(
        child: AutofillGroup(
          child: Form(
            key: _formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 48, color: ColoresApp.primario),
                const SizedBox(height: Espaciados.md),
                Text(
                  _correoFijo
                      ? 'Escribe el código de 6 dígitos que enviamos a ${widget.correo}.'
                      : 'Escribe tu correo y el código de 6 dígitos que te enviamos.',
                  textAlign: TextAlign.center,
                  style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
                ),
                const SizedBox(height: Espaciados.lg),
                if (!_correoFijo) ...[
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
                ],
                CampoCodigo(controlador: _codigo, habilitado: !_cargando, alEnviar: _verificar),
                if (_error != null) ...[
                  const SizedBox(height: Espaciados.md),
                  MensajeFormulario(_error!),
                ],
                if (_aviso != null) ...[
                  const SizedBox(height: Espaciados.md),
                  MensajeFormulario(_aviso!, esError: false),
                ],
                const SizedBox(height: Espaciados.lg),
                BotonConCarga(texto: 'Verificar', cargando: _cargando, alPresionar: _verificar),
                const SizedBox(height: Espaciados.sm),
                BotonReenviarCodigo(
                  clave: ControladorEsperaReenvio.claveVerificacion(_correoNormalizado),
                  habilitado: !_cargando,
                  alReenviar: _reenviar,
                ),
                TextButton(
                  onPressed: _cargando ? null : () => context.go(Rutas.login),
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
