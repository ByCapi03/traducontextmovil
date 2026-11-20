import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';

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
  bool _ocultarContrasena = true;
  String? _error;

  // Mismo patron basico que valida el backend (LoginSolicitud.correo).
  static final RegExp _patronCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!(_formulario.currentState?.validate() ?? false)) return;

    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref.read(sesionProvider.notifier).iniciarSesion(
            correo: _correo.text,
            contrasena: _contrasena.text,
          );
      // La redireccion la hace go_router al cambiar el estado de sesion.
    } on ExcepcionApi catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider);
    final aviso = sesion is SesionNoAutenticada ? sesion.mensaje : null;
    final mensaje = _error ?? aviso;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Espaciados.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(Espaciados.lg),
                decoration: BoxDecoration(
                  color: ColoresApp.fondo,
                  borderRadius: BorderRadius.circular(Radios.grande),
                  boxShadow: Sombras.suave,
                ),
                child: Form(
                  key: _formulario,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.translate_rounded, size: 48, color: ColoresApp.primario),
                      const SizedBox(height: Espaciados.md),
                      Text('TraduContext', textAlign: TextAlign.center, style: textos.headlineMedium),
                      Text(
                        'Inicia sesion para continuar',
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
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (valor) {
                          final texto = valor?.trim() ?? '';
                          if (texto.isEmpty) return 'Ingresa tu correo.';
                          if (!_patronCorreo.hasMatch(texto)) return 'Correo no valido.';
                          return null;
                        },
                      ),
                      const SizedBox(height: Espaciados.md),
                      TextFormField(
                        controller: _contrasena,
                        enabled: !_cargando,
                        obscureText: _ocultarContrasena,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _enviar(),
                        decoration: InputDecoration(
                          labelText: 'Contrasena',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _ocultarContrasena ? 'Mostrar' : 'Ocultar',
                            icon: Icon(_ocultarContrasena ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _ocultarContrasena = !_ocultarContrasena),
                          ),
                        ),
                        validator: (valor) =>
                            (valor == null || valor.isEmpty) ? 'Ingresa tu contrasena.' : null,
                      ),
                      if (mensaje != null) ...[
                        const SizedBox(height: Espaciados.md),
                        Text(
                          mensaje,
                          textAlign: TextAlign.center,
                          style: textos.bodyMedium?.copyWith(color: ColoresApp.error),
                        ),
                      ],
                      const SizedBox(height: Espaciados.lg),
                      FilledButton(
                        onPressed: _cargando ? null : _enviar,
                        child: _cargando
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: ColoresApp.textoClaro,
                                ),
                              )
                            : const Text('Iniciar sesion'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
