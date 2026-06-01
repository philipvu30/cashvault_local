import 'package:flutter/material.dart';

ThemeData buildCashVaultTheme() {
  const seed = Color(0xFF1B4D3E);
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
    scaffoldBackgroundColor: const Color(0xFFF3F5F7),
    useMaterial3: true,
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: Color(0xFFDDE3E8)),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
  );
}
