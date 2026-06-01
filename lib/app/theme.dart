import 'package:flutter/material.dart';

ThemeData buildCashVaultTheme() {
  const base = Color(0xFF12343B);
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: base),
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
