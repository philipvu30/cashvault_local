import '../data/repositories/app_settings_repository.dart';
import '../data/repositories/audit_log_repository.dart';
import '../data/repositories/cash_entries_repository.dart';
import '../data/repositories/cash_sessions_repository.dart';
import '../models/cash_session_model.dart';

class SessionService {
  const SessionService({
    required CashSessionsRepository sessionsRepository,
    required CashEntriesRepository cashEntriesRepository,
    required AppSettingsRepository appSettingsRepository,
    required AuditLogRepository auditLogRepository,
  })  : _sessionsRepository = sessionsRepository,
        _cashEntriesRepository = cashEntriesRepository,
        _appSettingsRepository = appSettingsRepository,
        _auditLogRepository = auditLogRepository;

  final CashSessionsRepository _sessionsRepository;
  final CashEntriesRepository _cashEntriesRepository;
  final AppSettingsRepository _appSettingsRepository;
  final AuditLogRepository _auditLogRepository;

  Future<CashSessionModel?> getActiveSession() async {
    final setting = await _appSettingsRepository.getSetting('active_session_id');
    final rawId = setting?.value.trim() ?? '';
    if (rawId.isNotEmpty) {
      final id = int.tryParse(rawId);
      if (id != null) {
        final session = await _sessionsRepository.getById(id);
        if (session != null) return session;
      }
    }
    return _sessionsRepository.getOpenSession();
  }

  Future<CashSessionModel> ensureFirstSession() async {
    final existing = await getActiveSession();
    if (existing != null) return existing;

    final now = DateTime.now();
    final businessDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final sessionId = await _sessionsRepository.createSession(
      sessionName: "Today's Business Day",
      businessDate: businessDate,
      startingBalanceCents: 0,
    );
    await _appSettingsRepository.upsertSetting('active_session_id', sessionId.toString());
    await _auditLogRepository.log('session_created', details: 'id=$sessionId');
    final created = await _sessionsRepository.getById(sessionId);
    return created!;
  }

  Future<void> updateStartingBalance({
    required int sessionId,
    required int newStartingBalanceCents,
  }) async {
    await _sessionsRepository.updateStartingBalance(sessionId, newStartingBalanceCents);
    await _auditLogRepository.log(
      'starting_balance_changed',
      details: 'session=$sessionId value=$newStartingBalanceCents',
    );
  }

  Future<CashSessionModel> startNewSession({
    required String sessionName,
    required String businessDate,
    required int startingBalanceCents,
  }) async {
    final openSession = await _sessionsRepository.getOpenSession();
    if (openSession != null) {
      await _sessionsRepository.closeSession(openSession.id);
    }

    final sessionId = await _sessionsRepository.createSession(
      sessionName: sessionName,
      businessDate: businessDate,
      startingBalanceCents: startingBalanceCents,
      eftPosCents: 0,
    );
    await _appSettingsRepository.upsertSetting('active_session_id', sessionId.toString());
    await _auditLogRepository.log('session_created', details: 'id=$sessionId');
    final created = await _sessionsRepository.getById(sessionId);
    return created!;
  }

  Future<void> closeCurrentSession(int sessionId) async {
    await _sessionsRepository.closeSession(sessionId);
    await _auditLogRepository.log('session_closed', details: 'id=$sessionId');
  }

  Future<CashSessionModel?> reopenSession(int sessionId) async {
    await _sessionsRepository.reopenSession(sessionId);
    await _appSettingsRepository.upsertSetting('active_session_id', sessionId.toString());
    await _auditLogRepository.log('session_reopened', details: 'id=$sessionId');
    return _sessionsRepository.getById(sessionId);
  }

  Future<List<CashSessionModel>> allSessions() => _sessionsRepository.getAllSessions();

  Future<int> computeNextSessionStartingBalanceCents() async {
    final sessions = await _sessionsRepository.getAllSessions();
    final closed = sessions.where((session) => session.status == 'closed').toList();
    if (closed.isEmpty) {
      return 0;
    }

    final latestClosed = closed.first;
    final entries = await _cashEntriesRepository.getBySessionId(latestClosed.id);
    final coinsTotal = entries
        .where((entry) => entry.entryType == 'coin')
        .fold<int>(0, (sum, entry) => sum + entry.rowTotalCents);
    return 20000 + coinsTotal;
  }
}
