import 'package:flutter/material.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Contenedor adaptable para todas las pantallas:
/// - por defecto, tarjeta centrada con scroll y ancho máximo de formulario
///   (se ve bien de 360 px a tablet y con el teclado abierto);
/// - [ContenidoAdaptable.lista], solo limita el ancho y centra; el hijo
///   (una lista con su propio scroll) ocupa todo el alto.
class ContenidoAdaptable extends StatelessWidget {
  const ContenidoAdaptable({super.key, required this.child})
      : _esLista = false,
        _anchoMaximo = Anchos.formulario;

  const ContenidoAdaptable.lista({super.key, required this.child})
      : _esLista = true,
        _anchoMaximo = Anchos.contenido;

  final Widget child;
  final bool _esLista;
  final double _anchoMaximo;

  @override
  Widget build(BuildContext context) {
    if (_esLista) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _anchoMaximo),
            child: child,
          ),
        ),
      );
    }
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Espaciados.md),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _anchoMaximo),
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
