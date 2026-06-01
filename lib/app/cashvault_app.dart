import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

class CashVaultApp extends StatelessWidget {
  const CashVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CashVault Local',
      theme: buildCashVaultTheme(),
      initialRoute: AppRoutes.main,
      routes: appRoutes,
      debugShowCheckedModeBanner: false,
    );
  }
}
