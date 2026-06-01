import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/cash_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../models/cash_entry.dart';
import '../services/auth_service.dart';
import '../services/csv_export_service.dart';

class CashVaultController extends ChangeNotifier {
  CashVaultController({
    required SettingsRepository settingsRepository,
    required CashRepository cashRepository,
    required AuthRepository authRepository,
    required AuthService authService,
    required CsvExportService csvExportService,
  }) : _settingsRepository = settingsRepository,
       _cashRepository = cashRepository,
       _authRepository = authRepository,
       _authService = authService,
       _csvExportService = csvExportService;

  final SettingsRepository _settingsRepository;
  final CashRepository _cashRepository;
  final AuthRepository _authRepository;
  final AuthService _authService;
  final CsvExportService _csvExportService;

  bool _initialized = false;
  bool _busy = false;
  String? _lastError;
  bool _needsOwnerSetup = false;

  int startingBalanceCents = 0;
  List<CashEntryInput> cashRows = <CashEntryInput>[];
  List<CashEntryInput> coinRows = <CashEntryInput>[];
  String? databaseCreatedAt;
  String? lastExportPath;
  String? preferredExportDirectory;

  bool get initialized => _initialized;
  bool get busy => _busy;
  String? get lastError => _lastError;
  bool get needsOwnerSetup => _needsOwnerSetup;

  int get totalCashNotesCents =>
      cashRows.fold<int>(0, (sum, row) => sum + row.rowTotalCents);

  int get totalCoinsCents =>
      coinRows.fold<int>(0, (sum, row) => sum + row.rowTotalCents);

  int get finalTotalCents =>
      startingBalanceCents + totalCashNotesCents + totalCoinsCents;

  Future<void> initialize() async {
    _setBusy(true);
    _lastError = null;

    try {
      final hasOwner = await _authService.hasOwnerPassword();
      _needsOwnerSetup = !hasOwner;
      startingBalanceCents = await _settingsRepository
          .getStartingBalanceCents();
      cashRows = await _cashRepository.getEntries(EntryType.cash);
      coinRows = await _cashRepository.getEntries(EntryType.coin);
      databaseCreatedAt = await _settingsRepository.getDatabaseCreatedAt();
      lastExportPath = await _settingsRepository.getLastExportPath();
      preferredExportDirectory = await _settingsRepository
          .getPreferredExportDirectory();
      _initialized = true;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _setBusy(false);
    }
  }

  void addRow(EntryType type) {
    final row = CashEntryInput.empty(type);
    if (type == EntryType.cash) {
      cashRows = <CashEntryInput>[...cashRows, row];
    } else {
      coinRows = <CashEntryInput>[...coinRows, row];
    }
    notifyListeners();
  }

  void updateRow(EntryType type, int index, CashEntryInput row) {
    final target = type == EntryType.cash ? cashRows : coinRows;
    if (index < 0 || index >= target.length) {
      return;
    }

    final updated = row.copyWith(updatedAt: DateTime.now().toIso8601String());
    final copy = <CashEntryInput>[...target]..[index] = updated;

    if (type == EntryType.cash) {
      cashRows = copy;
    } else {
      coinRows = copy;
    }
    notifyListeners();
  }

  void removeRow(EntryType type, int index) {
    final target = type == EntryType.cash ? cashRows : coinRows;
    if (index < 0 || index >= target.length) {
      return;
    }
    final copy = <CashEntryInput>[...target]..removeAt(index);

    if (type == EntryType.cash) {
      cashRows = copy;
    } else {
      coinRows = copy;
    }
    notifyListeners();
  }

  String? validateRows() {
    final all = <CashEntryInput>[...cashRows, ...coinRows];
    for (final row in all) {
      if (row.label.trim().isEmpty) {
        return 'Label cannot be empty.';
      }
      if (row.amountCents < 0) {
        return 'Amount must be 0 or greater.';
      }
      if (row.quantity <= 0) {
        return 'Quantity must be greater than 0.';
      }
    }
    return null;
  }

  Future<String?> saveEntries() async {
    final validation = validateRows();
    if (validation != null) {
      return validation;
    }

    _setBusy(true);
    try {
      await _settingsRepository.setStartingBalanceCents(startingBalanceCents);
      await _cashRepository.replaceAllEntries(
        cashRows: cashRows,
        coinRows: coinRows,
      );
      await _authRepository.logAction(
        'entries_saved',
        'Cash and coin entries saved.',
      );
      return null;
    } catch (error) {
      return error.toString();
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> exportCsv() async {
    final validation = validateRows();
    if (validation != null) {
      return validation;
    }

    _setBusy(true);
    try {
      final filePath = await _csvExportService.export(
        startingBalanceCents: startingBalanceCents,
        cashRows: cashRows,
        coinRows: coinRows,
        totalCashNotesCents: totalCashNotesCents,
        totalCoinsCents: totalCoinsCents,
        finalTotalCents: finalTotalCents,
      );

      if (filePath == null) {
        return 'Export canceled.';
      }

      await _settingsRepository.setLastExportPath(filePath);
      await _authRepository.logAction('export_csv', 'CSV exported: $filePath');
      lastExportPath = filePath;
      notifyListeners();
      return null;
    } catch (error) {
      return error.toString();
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> setupOwnerPassword(String password) async {
    if (password.trim().isEmpty) {
      return false;
    }
    await _authService.setupOwnerPassword(password);
    _needsOwnerSetup = false;
    notifyListeners();
    return true;
  }

  Future<bool> verifyOwnerPassword(String password) {
    return _authService.verifyOwnerPassword(password);
  }

  Future<bool> changeOwnerPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.trim().isEmpty) {
      return false;
    }
    return _authService.changeOwnerPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<bool> updateStartingBalanceWithPassword({
    required String password,
    required int newBalanceCents,
  }) async {
    final verified = await _authService.verifyOwnerPassword(password);
    if (!verified) {
      return false;
    }

    startingBalanceCents = newBalanceCents;
    await _settingsRepository.setStartingBalanceCents(startingBalanceCents);
    await _authRepository.logAction(
      'starting_balance_updated',
      'Starting balance changed to ${startingBalanceCents / 100.0}',
    );
    notifyListeners();
    return true;
  }

  Future<bool> resetDailyEntriesWithPassword(String password) async {
    final verified = await _authService.verifyOwnerPassword(password);
    if (!verified) {
      return false;
    }

    await _cashRepository.resetDailyEntries();
    cashRows = <CashEntryInput>[];
    coinRows = <CashEntryInput>[];
    await _authRepository.logAction(
      'daily_entries_reset',
      'Daily entries reset.',
    );
    notifyListeners();
    return true;
  }

  Future<void> updatePreferredExportDirectory(String directoryPath) async {
    preferredExportDirectory = directoryPath;
    await _settingsRepository.setPreferredExportDirectory(directoryPath);
    notifyListeners();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
