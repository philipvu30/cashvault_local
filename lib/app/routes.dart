import 'package:flutter/material.dart';

import '../screens/main_cash_screen.dart';
import '../screens/previous_sessions_page.dart';
import '../screens/session_detail_page.dart';
import '../screens/settings_screen.dart';
import '../state/session_detail_state.dart';

class AppRoutes {
  static const String main = '/';
  static const String settings = '/settings';
  static const String previousSessions = '/previous-sessions';
  static const String sessionDetail = '/session-detail';
}

Route<dynamic> generateAppRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.main:
      return MaterialPageRoute<void>(builder: (_) => const MainCashScreen(), settings: settings);
    case AppRoutes.settings:
      return MaterialPageRoute<void>(builder: (_) => const SettingsScreen(), settings: settings);
    case AppRoutes.previousSessions:
      return MaterialPageRoute<void>(builder: (_) => const PreviousSessionsPage(), settings: settings);
    case AppRoutes.sessionDetail:
      final args = settings.arguments;
      if (args is! SessionDetailArgs) {
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Center(child: Text('Invalid session detail arguments'))),
          settings: settings,
        );
      }
      return MaterialPageRoute<void>(
        builder: (_) => SessionDetailPage(args: args),
        settings: settings,
      );
    default:
      return MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: Text('Route not found'))),
        settings: settings,
      );
  }
}
