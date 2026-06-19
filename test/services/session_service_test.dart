import 'package:cashvault_local/data/repositories/app_settings_repository.dart';
import 'package:cashvault_local/data/repositories/audit_log_repository.dart';
import 'package:cashvault_local/data/repositories/cash_entries_repository.dart';
import 'package:cashvault_local/data/repositories/cash_sessions_repository.dart';
import 'package:cashvault_local/models/app_setting_model.dart';
import 'package:cashvault_local/models/cash_entry_model.dart';
import 'package:cashvault_local/models/cash_session_model.dart';
import 'package:cashvault_local/services/session_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAppSettingsRepository extends Fake implements AppSettingsRepository {
  final Map<String, AppSettingModel> settings = <String, AppSettingModel>{};

  @override
  Future<AppSettingModel?> getSetting(String key) async => settings[key];

  @override
  Future<void> upsertSetting(String key, String value) async {
    settings[key] = AppSettingModel(
      key: key,
      value: value,
      updatedAt: DateTime.parse('2026-06-20T00:00:00Z'),
    );
  }
}

class FakeAuditLogRepository extends Fake implements AuditLogRepository {
  final List<String> actions = <String>[];

  @override
  Future<void> log(String action, {String? details}) async {
    actions.add('$action:${details ?? ''}');
  }
}

class FakeCashSessionsRepository extends Fake implements CashSessionsRepository {
  FakeCashSessionsRepository({List<CashSessionModel>? sessions}) : _sessions = sessions ?? <CashSessionModel>[];

  final List<CashSessionModel> _sessions;
  int _nextId = 100;

  @override
  Future<CashSessionModel?> getById(int id) async {
    for (final session in _sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  @override
  Future<CashSessionModel?> getOpenSession() async {
    for (final session in _sessions) {
      if (session.status == 'open') return session;
    }
    return null;
  }

  @override
  Future<List<CashSessionModel>> getAllSessions() async => List<CashSessionModel>.from(_sessions);

  @override
  Future<int> createSession({
    required String sessionName,
    required String businessDate,
    required int startingBalanceCents,
    String eftPosText = '0.00',
  }) async {
    final session = CashSessionModel(
      id: _nextId++,
      sessionName: sessionName,
      businessDate: businessDate,
      startingBalanceCents: startingBalanceCents,
      eftPosText: eftPosText,
      status: 'open',
      createdAt: DateTime.parse('2026-06-20T00:00:00Z'),
      closedAt: null,
    );
    _sessions.insert(0, session);
    return session.id;
  }
}

class FakeCashEntriesRepository extends Fake implements CashEntriesRepository {
  FakeCashEntriesRepository({Map<int, List<CashEntryModel>>? entriesBySessionId})
      : _entriesBySessionId = entriesBySessionId ?? <int, List<CashEntryModel>>{};

  final Map<int, List<CashEntryModel>> _entriesBySessionId;

  @override
  Future<List<CashEntryModel>> getBySessionId(int sessionId) async {
    return List<CashEntryModel>.from(_entriesBySessionId[sessionId] ?? const <CashEntryModel>[]);
  }
}

void main() {
  group('SessionService.computeNextSessionStartingBalanceCents', () {
    test('return 20000 when no closed sessions exist', () async {
      final service = _buildService(
        sessions: <CashSessionModel>[
          _session(id: 1, status: 'open', createdAt: '2026-06-20T09:00:00Z'),
        ],
      );

      expect(await service.computeNextSessionStartingBalanceCents(), 20000);
    });

    test('return 20000 when latest closed session has no coin entries', () async {
      final service = _buildService(
        sessions: <CashSessionModel>[
          _session(id: 2, status: 'closed', createdAt: '2026-06-20T09:00:00Z'),
        ],
        entriesBySessionId: <int, List<CashEntryModel>>{
          2: <CashEntryModel>[
            _entry(sessionId: 2, entryType: 'cash', rowTotalCents: 5000),
          ],
        },
      );

      expect(await service.computeNextSessionStartingBalanceCents(), 20000);
    });

    test('add coin total from latest closed session', () async {
      final service = _buildService(
        sessions: <CashSessionModel>[
          _session(id: 3, status: 'closed', createdAt: '2026-06-20T09:00:00Z'),
        ],
        entriesBySessionId: <int, List<CashEntryModel>>{
          3: <CashEntryModel>[
            _entry(sessionId: 3, entryType: 'cash', rowTotalCents: 5000),
            _entry(sessionId: 3, entryType: 'coin', rowTotalCents: 750),
            _entry(sessionId: 3, entryType: 'coin', rowTotalCents: 25),
          ],
        },
      );

      expect(await service.computeNextSessionStartingBalanceCents(), 20775);
    });

    test('use latest closed session only', () async {
      final service = _buildService(
        sessions: <CashSessionModel>[
          _session(id: 5, status: 'closed', createdAt: '2026-06-20T09:00:00Z'),
          _session(id: 4, status: 'closed', createdAt: '2026-06-19T09:00:00Z'),
        ],
        entriesBySessionId: <int, List<CashEntryModel>>{
          5: <CashEntryModel>[
            _entry(sessionId: 5, entryType: 'coin', rowTotalCents: 300),
          ],
          4: <CashEntryModel>[
            _entry(sessionId: 4, entryType: 'coin', rowTotalCents: 900),
          ],
        },
      );

      expect(await service.computeNextSessionStartingBalanceCents(), 20300);
    });
  });

  group('SessionService.ensureFirstSession', () {
    test('create first session with 20000 starting balance when no history', () async {
      final sessionsRepository = FakeCashSessionsRepository();
      final appSettingsRepository = FakeAppSettingsRepository();
      final auditLogRepository = FakeAuditLogRepository();
      final service = SessionService(
        sessionsRepository: sessionsRepository,
        cashEntriesRepository: FakeCashEntriesRepository(),
        appSettingsRepository: appSettingsRepository,
        auditLogRepository: auditLogRepository,
      );

      final session = await service.ensureFirstSession();

      expect(session.startingBalanceCents, 20000);
      expect(appSettingsRepository.settings['active_session_id']?.value, session.id.toString());
    });
  });
}

SessionService _buildService({
  List<CashSessionModel>? sessions,
  Map<int, List<CashEntryModel>>? entriesBySessionId,
}) {
  return SessionService(
    sessionsRepository: FakeCashSessionsRepository(sessions: sessions),
    cashEntriesRepository: FakeCashEntriesRepository(entriesBySessionId: entriesBySessionId),
    appSettingsRepository: FakeAppSettingsRepository(),
    auditLogRepository: FakeAuditLogRepository(),
  );
}

CashSessionModel _session({
  required int id,
  required String status,
  required String createdAt,
}) {
  return CashSessionModel(
    id: id,
    sessionName: 'Session $id',
    businessDate: '2026-06-20',
    startingBalanceCents: 0,
    eftPosText: '0.00',
    status: status,
    createdAt: DateTime.parse(createdAt),
    closedAt: status == 'closed' ? DateTime.parse(createdAt) : null,
  );
}

CashEntryModel _entry({
  required int sessionId,
  required String entryType,
  required int rowTotalCents,
}) {
  return CashEntryModel(
    id: null,
    sessionId: sessionId,
    presetId: null,
    entryType: entryType,
    label: entryType,
    amountCents: rowTotalCents,
    quantity: 1,
    rowTotalCents: rowTotalCents,
    comment: '',
    createdAt: DateTime.parse('2026-06-20T00:00:00Z'),
    updatedAt: DateTime.parse('2026-06-20T00:00:00Z'),
    isCustom: true,
  );
}
