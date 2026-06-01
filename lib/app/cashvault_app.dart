import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cash_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../screens/main_cash_screen.dart';
import '../services/auth_service.dart';
import '../services/csv_export_service.dart';
import '../services/password_hash_service.dart';
import '../state/cashvault_controller.dart';
import 'theme.dart';

class CashVaultRoot extends StatefulWidget {
  const CashVaultRoot({super.key, required this.database});

  final CashVaultDatabase database;

  @override
  State<CashVaultRoot> createState() => _CashVaultRootState();
}

class _CashVaultRootState extends State<CashVaultRoot> {
  late final CashVaultController _controller;
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();

    final authRepository = AuthRepository(widget.database);
    final settingsRepository = SettingsRepository(widget.database);
    final cashRepository = CashRepository(widget.database);
    final authService = AuthService(
      authRepository: authRepository,
      hashService: PasswordHashService(),
    );

    _controller = CashVaultController(
      settingsRepository: settingsRepository,
      cashRepository: cashRepository,
      authRepository: authRepository,
      authService: authService,
      csvExportService: CsvExportService(),
    );

    _bootstrapFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.database.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CashVaultController>.value(
      value: _controller,
      child: MaterialApp(
        title: 'CashVault Local',
        debugShowCheckedModeBanner: false,
        theme: buildCashVaultTheme(),
        home: FutureBuilder<void>(
          future: _bootstrapFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (_controller.lastError != null) {
              return Scaffold(
                body: Center(
                  child: Text(
                    'Initialization failed: ${_controller.lastError}',
                  ),
                ),
              );
            }

            return const MainCashScreen();
          },
        ),
      ),
    );
  }
}
