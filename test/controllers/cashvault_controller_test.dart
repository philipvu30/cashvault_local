import 'package:cashvault_local/data/database.dart';
import 'package:cashvault_local/data/repositories/auth_repository.dart';
import 'package:cashvault_local/data/repositories/cash_repository.dart';
import 'package:cashvault_local/data/repositories/settings_repository.dart';
import 'package:cashvault_local/models/cash_entry.dart';
import 'package:cashvault_local/services/auth_service.dart';
import 'package:cashvault_local/services/csv_export_service.dart';
import 'package:cashvault_local/services/password_hash_service.dart';
import 'package:cashvault_local/state/cashvault_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late sqlite.Database rawDb;
  late CashVaultDatabase db;
  late CashVaultController controller;

  setUp(() async {
    rawDb = sqlite.sqlite3.openInMemory();
    db = CashVaultDatabase.fromRaw(rawDb);

    final authRepository = AuthRepository(db);
    final settingsRepository = SettingsRepository(db);
    final cashRepository = CashRepository(db);

    controller = CashVaultController(
      settingsRepository: settingsRepository,
      cashRepository: cashRepository,
      authRepository: authRepository,
      authService: AuthService(
        authRepository: authRepository,
        hashService: PasswordHashService(),
      ),
      csvExportService: CsvExportService(),
    );

    await controller.initialize();
  });

  tearDown(() {
    db.dispose();
  });

  test('starting balance edit blocked with wrong owner password', () async {
    await controller.setupOwnerPassword('owner-123');

    final failed = await controller.updateStartingBalanceWithPassword(
      password: 'wrong-pass',
      newBalanceCents: 5500,
    );

    expect(failed, isFalse);
    expect(controller.startingBalanceCents, 0);

    final success = await controller.updateStartingBalanceWithPassword(
      password: 'owner-123',
      newBalanceCents: 5500,
    );

    expect(success, isTrue);
    expect(controller.startingBalanceCents, 5500);
  });

  test('cash and coin totals plus final total are calculated correctly', () {
    controller.startingBalanceCents = 10000;
    controller.cashRows = [
      CashEntryInput.empty(
        EntryType.cash,
      ).copyWith(label: 'Fifty', amountCents: 5000, quantity: 2),
    ];
    controller.coinRows = [
      CashEntryInput.empty(
        EntryType.coin,
      ).copyWith(label: 'Quarter', amountCents: 25, quantity: 10),
    ];

    expect(controller.cashRows.first.rowTotalCents, 10000);
    expect(controller.coinRows.first.rowTotalCents, 250);
    expect(controller.totalCashNotesCents, 10000);
    expect(controller.totalCoinsCents, 250);
    expect(controller.finalTotalCents, 20250);
  });
}
