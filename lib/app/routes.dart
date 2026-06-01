import 'package:flutter/material.dart';

import '../screens/main_cash_screen.dart';
import '../screens/settings_screen.dart';

class AppRoutes {
  static const String main = '/';
  static const String settings = '/settings';
}

final Map<String, WidgetBuilder> appRoutes = <String, WidgetBuilder>{
  AppRoutes.main: (_) => const MainCashScreen(),
  AppRoutes.settings: (_) => const SettingsScreen(),
};
