import '../database.dart';

class AuditLogRepository {
  const AuditLogRepository(this._database);

  final AppDatabase _database;

  Future<void> log(String action, {String? details}) {
    return _database.execute(
      '''
      INSERT INTO audit_log (action, details, created_at)
      VALUES (?, ?, ?)
      ''',
      <Object?>[action, details ?? '', DateTime.now().toIso8601String()],
    );
  }
}
