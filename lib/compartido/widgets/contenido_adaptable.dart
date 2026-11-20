import 'package:flutter/material.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Tarjeta centrada con desplazamiento y ancho maximo, para formularios
/// que deben verse bien de 360 px a tablet y con el teclado abierto.
class ContenidoAdaptable extends StatelessWidget {
  const ContenidoAdaptable({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Espaciados.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Anchos.formulario),
            child: Container(
              padding: const EdgeInsets.all(Espaciados.lg),
              decoration: BoxDecoration(
                color: ColoresApp.fondo,
                borderRadius: BorderRadius.circular(Radios.grande),
                boxShadow: Sombras.suave,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
