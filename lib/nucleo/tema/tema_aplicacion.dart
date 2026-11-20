import 'package:flutter/material.dart';

import 'colores.dart';
import 'dimensiones.dart';
import 'tipografia.dart';

abstract final class TemaAplicacion {
  static const ColorScheme _esquema = ColorScheme(
    brightness: Brightness.light,
    primary: ColoresApp.primario,
    onPrimary: ColoresApp.textoClaro,
    secondary: ColoresApp.secundario,
    onSecondary: ColoresApp.textoClaro,
    tertiary: ColoresApp.acento,
    onTertiary: ColoresApp.textoClaro,
    error: ColoresApp.error,
    onError: ColoresApp.textoClaro,
    surface: ColoresApp.fondo,
    onSurface: ColoresApp.texto,
    onSurfaceVariant: ColoresApp.textoSecundario,
    outline: ColoresApp.textoClaroSecundario,
  );

  static final ThemeData claro = ThemeData(
    useMaterial3: true,
    colorScheme: _esquema,
    fontFamily: TipografiaApp.fuentePrincipal,
    textTheme: TipografiaApp.temaTexto,
    scaffoldBackgroundColor: ColoresApp.fondoSecundario,
    appBarTheme: const AppBarTheme(
      backgroundColor: ColoresApp.fondo,
      foregroundColor: ColoresApp.texto,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: TipografiaApp.fuentePrincipal,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ColoresApp.texto,
      ),
    ),
    cardTheme: CardThemeData(
      color: ColoresApp.fondo,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radios.grande)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColoresApp.fondo,
      contentPadding: const EdgeInsets.symmetric(horizontal: Espaciados.md, vertical: Espaciados.md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radios.medio),
        borderSide: const BorderSide(color: ColoresApp.textoClaroSecundario),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radios.medio),
        borderSide: const BorderSide(color: ColoresApp.textoClaroSecundario),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radios.medio),
        borderSide: const BorderSide(color: ColoresApp.primario, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ColoresApp.primario,
        foregroundColor: ColoresApp.textoClaro,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radios.medio)),
        textStyle: const TextStyle(fontFamily: TipografiaApp.fuentePrincipal, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ColoresApp.fondo,
      indicatorColor: ColoresApp.primario.withValues(alpha: 0.12),
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          color: estados.contains(WidgetState.selected) ? ColoresApp.primario : ColoresApp.textoSecundario,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => TextStyle(
          fontFamily: TipografiaApp.fuentePrincipal,
          fontSize: 12,
          fontWeight: estados.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
          color: estados.contains(WidgetState.selected) ? ColoresApp.primario : ColoresApp.textoSecundario,
        ),
      ),
    ),
  );
}
