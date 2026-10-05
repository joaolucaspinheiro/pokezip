import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A cor de acento vermelha, a mesma da pokebola -- usada como destaque
/// (botoes, icones) em cima do azul claro do resto do app.
const corAcento = Color(0xFFE3350D);

/// O tema principal do app: azul claro, cantos arredondados e uma
/// fonte mais fofa (Fredoka), pra ficar com cara de app infantil.
ThemeData construirTema() {
  const azulCeu = Color(0xFF4FC3F7);

  final esquema = ColorScheme.fromSeed(
    seedColor: azulCeu,
    brightness: Brightness.light,
  );

  final formaArredondada = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: const Color(0xFFEAF6FF),
    textTheme: GoogleFonts.fredokaTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: esquema.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: esquema.primary.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: esquema.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: formaArredondada),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: formaArredondada),
    ),
  );
}
