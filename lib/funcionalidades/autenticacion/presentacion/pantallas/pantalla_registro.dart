import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/compartido/validadores.dart';
import 'package:traducontextmovil/compartido/widgets/boton_con_carga.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/mensaje_formulario.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/datos/repositorios/autenticacion_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/mensajes_error_autenticacion.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/espera_reenvio.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/widgets/campo_contrasena.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// HU-01: registro. Al terminar lleva a verificar el correo.
class PantallaRegistro extends ConsumerStatefulWidget {
  const PantallaRegistro({super.key});

  @override
  ConsumerState<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends ConsumerState<PantallaRegistro> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!(_formulario.currentState?.validate() ?? false)) return;

    setState(() {
      _cargando = true;
      _error = null;
    });
    final correo = Validadores.normalizarCorreo(_correo.text);
    try {
      await ref.read(autenticacionRepositorioProvider).registrar(
            nombre: _nombre.text,
            correo: correo,
            contrasena: _contrasena.text,
          );
      // El registro ya envia un codigo: arranca la espera de reenvio.
      ref
          .read(esperaReenvioProvider.notifier)
          .registrarEnvio(ControladorEsperaReenvio.claveVerificacion(correo));
      _contrasena.clear();
      _confirmacion.clear();
      if (mounted) context.go(Rutas.verificarCorreo, extra: correo);
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(() => _error = MensajesErrorAutenticacion.para(OperacionAutenticacion.registro, error));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: ContenidoAdaptable(
        child: AutofillGroup(
          child: Form(
            key: _formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Te enviaremos un código a tu correo para activar la cuenta.',
                  textAlign: TextAlign.center,
                  style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
                ),
                const SizedBox(height: Espaciados.lg),
                TextFormField(
                  controller: _nombre,
                  enabled: !_cargando,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: Validadores.nombre,
                ),
                const SizedBox(height: Espaciados.md),
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
                  esNueva: true,
                  validador: Validadores.contrasenaNueva,
                ),
                const SizedBox(height: Espaciados.xs),
                Text(
                  'De 8 a 72 caracteres, con al menos una letra y un número.',
                  style: textos.bodySmall,
                ),
                const SizedBox(height: Espaciados.md),
                CampoContrasena(
                  controlador: _confirmacion,
                  etiqueta: 'Confirmar contraseña',
                  habilitado: !_cargando,
                  esNueva: true,
                  accion: TextInputAction.done,
                  alEnviar: _enviar,
                  validador: Validadores.confirmacion(() => _contrasena.text),
                ),
                if (_error != null) ...[
                  const SizedBox(height: Espaciados.md),
                  MensajeFormulario(_error!),
                ],
                const SizedBox(height: Espaciados.lg),
                BotonConCarga(texto: 'Crear cuenta', cargando: _cargando, alPresionar: _enviar),
                const SizedBox(height: Espaciados.sm),
                TextButton(
                  onPressed: _cargando ? null : () => context.go(Rutas.login),
                  child: const Text('Ya tengo cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
