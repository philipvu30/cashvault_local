import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/cashvault_app.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.initialize();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const CashVaultApp(),
    ),
  );
}
