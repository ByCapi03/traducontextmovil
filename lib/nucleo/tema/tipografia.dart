import 'package:flutter/material.dart';

import 'package:traducontextmovil/nucleo/tema/colores.dart';

/// Tipografia copiada de traducontextfront/src/styles/_tipografia.css.
/// 1rem = 16 px; line-height 1.5.
abstract final class TipografiaApp {
  static const String fuentePrincipal = 'Poppins';
  static const double alturaLinea = 1.5;

  static const TextTheme temaTexto = TextTheme(
    // h1: 2rem / 700
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: alturaLinea, color: ColoresApp.texto),
    // h2: 1.5rem / 600
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: alturaLinea, color: ColoresApp.texto),
    // h3: 1.25rem / 600
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: alturaLinea, color: ColoresApp.texto),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: alturaLinea, color: ColoresApp.texto),
    // p: 1rem / 400
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: alturaLinea, color: ColoresApp.texto),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: alturaLinea, color: ColoresApp.texto),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: alturaLinea, color: ColoresApp.textoSecundario),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: alturaLinea),
  );
}
