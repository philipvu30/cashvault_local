import 'package:flutter/material.dart';

import 'app/cashvault_app.dart';
import 'data/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await CashVaultDatabase.initialize();
  runApp(CashVaultRoot(database: database));
}
