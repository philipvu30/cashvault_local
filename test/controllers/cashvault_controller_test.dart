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
  late SettingsRepository settingsRepository;
  late CashVaultController controller;

  setUp(() async {
    rawDb = sqlite.sqlite3.openInMemory();
    db = CashVaultDatabase.fromRaw(rawDb);

    final authRepository = AuthRepository(db);
    settingsRepository = SettingsRepository(db);
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

  test('starting balance remains locked with wrong owner password', () async {
    await controller.setupOwnerPassword('owner-123');

    final failed = await controller.unlockStartingBalance('wrong-pass');

    expect(failed, isFalse);
    expect(controller.isStartingBalanceUnlocked, isFalse);
    expect(controller.startingBalanceCents, 0);
  });

  test('starting balance unlocks, saves, and relocks', () async {
    await controller.setupOwnerPassword('owner-123');

    final unlocked = await controller.unlockStartingBalance('owner-123');
    controller.updateStartingBalanceDraft('55.00');
    await controller.saveStartingBalanceDraft();

    expect(unlocked, isTrue);
    expect(controller.isStartingBalanceUnlocked, isFalse);
    expect(controller.startingBalanceCents, 5500);
    expect(controller.startingBalanceDraft, '55.00');
    expect(await settingsRepository.getStartingBalanceCents(), 5500);
  });

  test('canceling starting balance edit leaves stored balance unchanged', () async {
    await controller.setupOwnerPassword('owner-123');

    final unlocked = await controller.unlockStartingBalance('owner-123');
    controller.updateStartingBalanceDraft('12.34');
    controller.cancelStartingBalanceEdit();

    expect(unlocked, isTrue);
    expect(controller.isStartingBalanceUnlocked, isFalse);
    expect(controller.startingBalanceCents, 0);
    expect(controller.startingBalanceDraft, '0.00');
    expect(await settingsRepository.getStartingBalanceCents(), 0);
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

  test('row add update and delete updates totals immediately', () {
    controller.addRow(EntryType.cash);
    expect(controller.cashRows, hasLength(1));

    final updated = controller.cashRows.first.copyWith(
      label: 'Hundred',
      amountCents: 10000,
      quantity: 3,
    );
    controller.updateRow(EntryType.cash, 0, updated);
    expect(controller.totalCashNotesCents, 30000);

    controller.removeRow(EntryType.cash, 0);
    expect(controller.cashRows, isEmpty);
    expect(controller.totalCashNotesCents, 0);
  });
}
