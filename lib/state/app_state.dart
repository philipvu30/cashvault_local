import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../data/repositories/app_settings_repository.dart';
import '../data/repositories/audit_log_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cash_entries_repository.dart';
import '../data/repositories/cash_sessions_repository.dart';
import '../data/repositories/denomination_presets_repository.dart';
import '../models/cash_entry_model.dart';
import '../models/cash_session_model.dart';
import '../models/cash_summary_model.dart';
import '../models/denomination_preset_model.dart';
import '../services/auth_service.dart';
import '../services/csv_export_service.dart';
import '../services/denomination_preset_service.dart';
import '../services/money_format_service.dart';
import '../services/money_parser_service.dart';
import '../services/password_hash_service.dart';
import '../services/session_service.dart';
import 'cash_entries_state.dart';

class AppState extends ChangeNotifier {
  AppDatabase? _database;

  AppSettingsRepository? _appSettingsRepository;
  AuditLogRepository? _auditLogRepository;
  AuthRepository? _authRepository;
  CashEntriesRepository? _cashEntriesRepository;
  CashSessionsRepository? _cashSessionsRepository;
  DenominationPresetsRepository? _denominationPresetsRepository;

  AuthService? _authService;
  CsvExportService? _csvExportService;
  DenominationPresetService? _denominationPresetService;
  SessionService? _sessionService;

  final MoneyParserService moneyParserService = MoneyParserService();
  final MoneyFormatService moneyFormatService = MoneyFormatService();

  bool isReady = false;
  bool needsOwnerPasswordSetup = false;
  bool isStartingBalanceUnlocked = false;
  bool isSaving = false;

  CashSessionModel? activeSession;
  List<CashEntryDraft> cashRows = <CashEntryDraft>[];
  List<CashEntryDraft> coinRows = <CashEntryDraft>[];
  List<DenominationPresetModel> allPresets = <DenominationPresetModel>[];

  String? lastExportFolder;
  String? databaseCreatedAt;
  String? errorMessage;

  Future<void> initialize() async {
    _database = await AppDatabase.open();
    _appSettingsRepository = AppSettingsRepository(_database!);
    _auditLogRepository = AuditLogRepository(_database!);
    _authRepository = AuthRepository(_database!);
    _cashEntriesRepository = CashEntriesRepository(_database!);
    _cashSessionsRepository = CashSessionsRepository(_database!);
    _denominationPresetsRepository = DenominationPresetsRepository(_database!);

    _authService = AuthService(
      authRepository: _authRepository!,
      auditLogRepository: _auditLogRepository!,
      passwordHashService: PasswordHashService(),
    );
    _denominationPresetService = DenominationPresetService(
      repository: _denominationPresetsRepository!,
      auditLogRepository: _auditLogRepository!,
    );
    _sessionService = SessionService(
      sessionsRepository: _cashSessionsRepository!,
      appSettingsRepository: _appSettingsRepository!,
      auditLogRepository: _auditLogRepository!,
    );
    _csvExportService = CsvExportService(
      appSettingsRepository: _appSettingsRepository!,
      auditLogRepository: _auditLogRepository!,
      moneyFormatService: moneyFormatService,
    );

    await _appSettingsRepository!.ensureDefaultSettings();
    await _auditLogRepository!.log('database_initialized');

    final hasPassword = await _authService!.hasPassword();
    needsOwnerPasswordSetup = !hasPassword;

    activeSession = await _sessionService!.ensureFirstSession();
    await _ensureAustraliaDefaultPresetsIfEmpty();
    await refresh();

    isReady = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    activeSession = await _sessionService!.getActiveSession() ?? activeSession;
    allPresets = await _denominationPresetService!.getAll();

    final exportFolderSetting = await _appSettingsRepository!.getSetting('last_export_folder');
    final databaseCreatedSetting = await _appSettingsRepository!.getSetting('database_created_at');
    lastExportFolder = exportFolderSetting?.value.isNotEmpty == true ? exportFolderSetting!.value : null;
    databaseCreatedAt = databaseCreatedSetting?.value;

    if (activeSession != null) {
      final saved = await _cashEntriesRepository!.getBySessionId(activeSession!.id);
      _buildRowsFromPresetsAndSaved(saved);
    }

    notifyListeners();
  }

  Future<void> createOwnerPassword(String password, String confirmPassword) async {
    if (password.isEmpty || confirmPassword.isEmpty || password != confirmPassword) {
      throw ArgumentError('Password validation failed');
    }
    await _authService!.createPassword(password);
    needsOwnerPasswordSetup = false;
    notifyListeners();
  }

  Future<bool> verifyOwnerPassword(String password) => _authService!.verifyPassword(password);

  Future<bool> changeOwnerPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.isEmpty || newPassword != confirmPassword) return false;
    return _authService!.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<bool> unlockStartingBalance(String password) async {
    final ok = await verifyOwnerPassword(password);
    if (ok) {
      isStartingBalanceUnlocked = true;
      notifyListeners();
    }
    return ok;
  }

  void lockStartingBalance() {
    isStartingBalanceUnlocked = false;
    notifyListeners();
  }

  void addCustomRow(String entryType) {
    final session = activeSession;
    if (session == null) return;

    final row = CashEntryDraft(
      sessionId: session.id,
      entryType: entryType,
      label: '',
      amountCents: 0,
      quantity: 0,
      comment: '',
      presetId: null,
      isCustom: true,
    );

    if (entryType == 'cash') {
      cashRows = <CashEntryDraft>[...cashRows, row];
    } else {
      coinRows = <CashEntryDraft>[...coinRows, row];
    }
    notifyListeners();
  }

  void removeCustomRow(CashEntryDraft row) {
    if (row.entryType == 'cash') {
      cashRows = cashRows.where((r) => !identical(r, row)).toList();
    } else {
      coinRows = coinRows.where((r) => !identical(r, row)).toList();
    }
    notifyListeners();
  }

  void updateRowQuantity(CashEntryDraft row, int quantity) {
    row.quantity = quantity < 0 ? 0 : quantity;
    notifyListeners();
  }

  void updateRowComment(CashEntryDraft row, String comment) {
    row.comment = comment;
    notifyListeners();
  }

  void updateCustomRowLabel(CashEntryDraft row, String label) {
    row.label = label;
    notifyListeners();
  }

  void updateCustomRowAmount(CashEntryDraft row, int cents) {
    row.amountCents = cents;
    notifyListeners();
  }

  int get totalCashCents => cashRows.fold<int>(0, (sum, row) => sum + row.rowTotalCents);
  int get totalCoinCents => coinRows.fold<int>(0, (sum, row) => sum + row.rowTotalCents);

  int get startingBalanceCents => activeSession?.startingBalanceCents ?? 0;

  CashSummaryModel get summary => CashSummaryModel(
        startingBalanceCents: startingBalanceCents,
        totalCashCents: totalCashCents,
        totalCoinCents: totalCoinCents,
      );

  Future<void> saveSessionData({int? editedStartingBalanceCents}) async {
    final session = activeSession;
    if (session == null || !session.isOpen) return;

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (isStartingBalanceUnlocked && editedStartingBalanceCents != null) {
        if (editedStartingBalanceCents < 0) {
          throw ArgumentError('Starting balance must be non-negative');
        }
        await _sessionService!.updateStartingBalance(
          sessionId: session.id,
          newStartingBalanceCents: editedStartingBalanceCents,
        );
      }

      final merged = <CashEntryDraft>[...cashRows, ...coinRows];
      final validRows = merged
          .where((row) => row.shouldPersist)
          .where(
            (row) => row.label.trim().isNotEmpty && row.quantity > 0 && row.amountCents >= 0,
          )
          .map((row) => row.toModel())
          .toList();

      await _cashEntriesRepository!.replaceForSession(session.id, validRows);
      isStartingBalanceUnlocked = false;
      await refresh();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String> exportCsv({
    required String filenameInput,
    String? folderPath,
  }) async {
    final session = activeSession;
    if (session == null) {
      throw StateError('No active session');
    }
    final targetFolder = folderPath ?? lastExportFolder;
    if (targetFolder == null || targetFolder.trim().isEmpty) {
      throw ArgumentError('Export folder is required');
    }
    final entries = [...cashRows, ...coinRows]
        .where((row) => row.shouldPersist)
        .where((row) => row.label.trim().isNotEmpty && row.quantity > 0)
        .map((row) => row.toModel())
        .toList();
    return _csvExportService!.exportSessionCsv(
      session: session,
      entries: entries,
      summary: summary,
      folderPath: targetFolder,
      filenameInput: filenameInput,
    );
  }

  Future<String?> pickExportFolder() async {
    final picked = await _csvExportService!.pickFolder();
    if (picked != null && picked.isNotEmpty) {
      await _appSettingsRepository!.upsertSetting('last_export_folder', picked);
      lastExportFolder = picked;
      notifyListeners();
    }
    return picked;
  }

  List<DenominationPresetModel> get cashPresets => allPresets.where((p) => p.entryType == 'cash').toList();
  List<DenominationPresetModel> get coinPresets => allPresets.where((p) => p.entryType == 'coin').toList();

  Future<void> createOrUpdatePreset({
    int? id,
    required String entryType,
    required String label,
    required int amountCents,
    required int sortOrder,
    required bool isActive,
  }) async {
    if (id == null) {
      await _denominationPresetService!.createPreset(
        entryType: entryType,
        label: label,
        amountCents: amountCents,
        sortOrder: sortOrder,
        isActive: isActive,
      );
    } else {
      await _denominationPresetService!.updatePreset(
        id: id,
        entryType: entryType,
        label: label,
        amountCents: amountCents,
        sortOrder: sortOrder,
        isActive: isActive,
      );
    }
    await refresh();
  }

  Future<void> setPresetActive({
    required int id,
    required bool isActive,
    required String label,
  }) async {
    await _denominationPresetService!.setActive(
      id: id,
      isActive: isActive,
      label: label,
    );
    await refresh();
  }

  Future<void> deletePreset({
    required int id,
    required String label,
  }) async {
    await _denominationPresetService!.deletePreset(id: id, label: label);
    await refresh();
  }

  Future<void> startNewSession({
    required String sessionName,
    required String businessDate,
    required int startingBalanceCents,
  }) async {
    activeSession = await _sessionService!.startNewSession(
      sessionName: sessionName,
      businessDate: businessDate,
      startingBalanceCents: startingBalanceCents,
    );
    await refresh();
  }

  Future<void> closeCurrentSession() async {
    final session = activeSession;
    if (session == null) return;
    await _sessionService!.closeCurrentSession(session.id);
    await refresh();
  }

  Future<void> reopenSession(int sessionId) async {
    activeSession = await _sessionService!.reopenSession(sessionId);
    await refresh();
  }

  Future<List<CashSessionModel>> allSessions() => _sessionService!.allSessions();

  Future<CashSessionModel?> sessionById(int sessionId) => _cashSessionsRepository!.getById(sessionId);

  Future<List<CashEntryModel>> entriesBySessionId(int sessionId) => _cashEntriesRepository!.getBySessionId(sessionId);

  Future<void> updatePreviousSession({
    required int sessionId,
    required String sessionName,
    required String businessDate,
    required int startingBalanceCents,
    required List<CashEntryModel> entries,
  }) async {
    await _cashSessionsRepository!.updateSessionFields(
      sessionId: sessionId,
      sessionName: sessionName,
      businessDate: businessDate,
      startingBalanceCents: startingBalanceCents,
    );
    await _cashEntriesRepository!.replaceForSession(sessionId, entries);
  }

  Future<void> logAuditAction(String action, {String? details}) {
    return _auditLogRepository!.log(action, details: details);
  }

  Future<String> exportSelectedSessionCsv({
    required int sessionId,
    required String filenameInput,
    required String folderPath,
    String auditAction = 'previous_session_exported',
  }) async {
    final session = await _cashSessionsRepository!.getById(sessionId);
    if (session == null) {
      throw StateError('Session not found');
    }
    final entries = await _cashEntriesRepository!.getBySessionId(sessionId);
    final totalCashCents = entries
        .where((entry) => entry.entryType == 'cash')
        .fold<int>(0, (sum, entry) => sum + entry.rowTotalCents);
    final totalCoinCents = entries
        .where((entry) => entry.entryType == 'coin')
        .fold<int>(0, (sum, entry) => sum + entry.rowTotalCents);
    final summary = CashSummaryModel(
      startingBalanceCents: session.startingBalanceCents,
      totalCashCents: totalCashCents,
      totalCoinCents: totalCoinCents,
    );
    return _csvExportService!.exportSessionCsv(
      session: session,
      entries: entries,
      summary: summary,
      folderPath: folderPath,
      filenameInput: filenameInput,
      auditAction: auditAction,
    );
  }

  Future<void> reopenPreviousSessionWithAudit(int sessionId) async {
    await reopenSession(sessionId);
    await _auditLogRepository!.log('previous_session_reopened', details: 'id=$sessionId');
  }

  void _buildRowsFromPresetsAndSaved(List<CashEntryModel> savedModels) {
    final session = activeSession;
    if (session == null) {
      cashRows = <CashEntryDraft>[];
      coinRows = <CashEntryDraft>[];
      return;
    }

    final savedByPreset = <int, CashEntryDraft>{};
    final customCash = <CashEntryDraft>[];
    final customCoin = <CashEntryDraft>[];

    for (final model in savedModels) {
      final row = CashEntryDraft.fromModel(model);
      if (row.presetId != null) {
        savedByPreset[row.presetId!] = row;
      } else if (row.entryType == 'cash') {
        customCash.add(row);
      } else {
        customCoin.add(row);
      }
    }

    final cashPresetRows = <CashEntryDraft>[];
    final coinPresetRows = <CashEntryDraft>[];

    for (final preset in allPresets.where((p) => p.isActive)) {
      final existing = savedByPreset[preset.id];
      final merged = existing ??
          CashEntryDraft(
            sessionId: session.id,
            presetId: preset.id,
            entryType: preset.entryType,
            label: preset.label,
            amountCents: preset.amountCents,
            quantity: 0,
            comment: '',
            isCustom: false,
          );
      merged.label = preset.label;
      merged.amountCents = preset.amountCents;

      if (preset.entryType == 'cash') {
        cashPresetRows.add(merged);
      } else {
        coinPresetRows.add(merged);
      }
    }

    cashRows = <CashEntryDraft>[...cashPresetRows, ...customCash];
    coinRows = <CashEntryDraft>[...coinPresetRows, ...customCoin];
  }

  Future<void> _ensureAustraliaDefaultPresetsIfEmpty() async {
    final existing = await _denominationPresetService!.getAll();
    if (existing.isNotEmpty) return;

    const defaults = <Map<String, Object>>[
      <String, Object>{'entryType': 'cash', 'label': '\$100 Note', 'amountCents': 10000, 'sortOrder': 1},
      <String, Object>{'entryType': 'cash', 'label': '\$50 Note', 'amountCents': 5000, 'sortOrder': 2},
      <String, Object>{'entryType': 'cash', 'label': '\$20 Note', 'amountCents': 2000, 'sortOrder': 3},
      <String, Object>{'entryType': 'cash', 'label': '\$10 Note', 'amountCents': 1000, 'sortOrder': 4},
      <String, Object>{'entryType': 'cash', 'label': '\$5 Note', 'amountCents': 500, 'sortOrder': 5},
      <String, Object>{'entryType': 'coin', 'label': '\$2 Coin', 'amountCents': 200, 'sortOrder': 1},
      <String, Object>{'entryType': 'coin', 'label': '\$1 Coin', 'amountCents': 100, 'sortOrder': 2},
      <String, Object>{'entryType': 'coin', 'label': '50c Coin', 'amountCents': 50, 'sortOrder': 3},
      <String, Object>{'entryType': 'coin', 'label': '20c Coin', 'amountCents': 20, 'sortOrder': 4},
      <String, Object>{'entryType': 'coin', 'label': '10c Coin', 'amountCents': 10, 'sortOrder': 5},
      <String, Object>{'entryType': 'coin', 'label': '5c Coin', 'amountCents': 5, 'sortOrder': 6},
    ];

    for (final row in defaults) {
      await _denominationPresetService!.createPreset(
        entryType: row['entryType'] as String,
        label: row['label'] as String,
        amountCents: row['amountCents'] as int,
        sortOrder: row['sortOrder'] as int,
        isActive: true,
      );
    }
  }
}
