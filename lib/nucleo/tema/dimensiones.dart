import 'package:flutter/material.dart';

/// Variables copiadas de traducontextfront/src/styles/_variables.css.
abstract final class Radios {
  static const double pequeno = 4;
  static const double medio = 8;
  static const double grande = 16;
}

abstract final class Espaciados {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class Sombras {
  /// --sombra-suave: 0 2px 8px rgba(0, 0, 0, 0.08)
  static const List<BoxShadow> suave = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 8),
  ];
}

abstract final class Transiciones {
  /// --transicion: 0.2s ease
  static const Duration duracion = Duration(milliseconds: 200);
  static const Curve curva = Curves.ease;
}
