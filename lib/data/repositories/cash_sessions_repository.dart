import '../../models/cash_session_model.dart';
import '../database.dart';

class CashSessionsRepository {
  const CashSessionsRepository(this._database);

  final AppDatabase _database;

  Future<CashSessionModel?> getById(int id) async {
    final rows = await _database.selectMaps(
      '''
      SELECT id, session_name, business_date, starting_balance_cents, eft_pos_cents, status, created_at, closed_at
      FROM cash_sessions
      WHERE id = ?
      LIMIT 1
      ''',
      <Object?>[id],
    );
    if (rows.isEmpty) return null;
    return _map(rows.first);
  }

  Future<CashSessionModel?> getOpenSession() async {
    final rows = await _database.selectMaps(
      '''
      SELECT id, session_name, business_date, starting_balance_cents, eft_pos_cents, status, created_at, closed_at
      FROM cash_sessions
      WHERE status = 'open'
      ORDER BY created_at DESC
      LIMIT 1
      ''',
    );
    if (rows.isEmpty) return null;
    return _map(rows.first);
  }

  Future<List<CashSessionModel>> getAllSessions() async {
    final rows = await _database.selectMaps(
      '''
      SELECT id, session_name, business_date, starting_balance_cents, eft_pos_cents, status, created_at, closed_at
      FROM cash_sessions
      ORDER BY created_at DESC
      ''',
    );
    return rows.map(_map).toList();
  }

  Future<int> createSession({
    required String sessionName,
    required String businessDate,
    required int startingBalanceCents,
    int eftPosCents = 0,
  }) async {
    return _database.insert(
      '''
      INSERT INTO cash_sessions (
        session_name, business_date, starting_balance_cents, eft_pos_cents, status, created_at, closed_at
      ) VALUES (?, ?, ?, ?, 'open', ?, NULL)
      ''',
      <Object?>[
        sessionName,
        businessDate,
        startingBalanceCents,
        eftPosCents,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  Future<void> closeSession(int sessionId) {
    return _database.execute(
      '''
      UPDATE cash_sessions
      SET status = 'closed', closed_at = ?
      WHERE id = ?
      ''',
      <Object?>[DateTime.now().toIso8601String(), sessionId],
    );
  }

  Future<void> reopenSession(int sessionId) async {
    await _database.execute(
      "UPDATE cash_sessions SET status = 'closed', closed_at = ? WHERE status = 'open'",
      <Object?>[DateTime.now().toIso8601String()],
    );
    await _database.execute(
      "UPDATE cash_sessions SET status = 'open', closed_at = NULL WHERE id = ?",
      <Object?>[sessionId],
    );
  }

  Future<void> updateStartingBalance(int sessionId, int startingBalanceCents) {
    return _database.execute(
      '''
      UPDATE cash_sessions
      SET starting_balance_cents = ?
      WHERE id = ?
      ''',
      <Object?>[startingBalanceCents, sessionId],
    );
  }

  Future<void> updateEftPos(int sessionId, int eftPosCents) {
    return _database.execute(
      '''
      UPDATE cash_sessions
      SET eft_pos_cents = ?
      WHERE id = ?
      ''',
      <Object?>[eftPosCents, sessionId],
    );
  }

  Future<void> updateSessionFields({
    required int sessionId,
    required String sessionName,
    required String businessDate,
    required int startingBalanceCents,
    required int eftPosCents,
  }) {
    return _database.execute(
      '''
      UPDATE cash_sessions
      SET session_name = ?,
          business_date = ?,
          starting_balance_cents = ?,
          eft_pos_cents = ?
      WHERE id = ?
      ''',
      <Object?>[
        sessionName,
        businessDate,
        startingBalanceCents,
        eftPosCents,
        sessionId,
      ],
    );
  }

  CashSessionModel _map(Map<String, Object?> row) {
    return CashSessionModel(
      id: row['id'] as int,
      sessionName: row['session_name'] as String,
      businessDate: row['business_date'] as String,
      startingBalanceCents: row['starting_balance_cents'] as int,
      eftPosCents: (row['eft_pos_cents'] as int?) ?? 0,
      status: row['status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      closedAt: row['closed_at'] == null ? null : DateTime.parse(row['closed_at'] as String),
    );
  }
}
