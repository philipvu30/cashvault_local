import '../database.dart';

class OwnerCredentials {
  const OwnerCredentials({required this.hashBase64, required this.saltBase64});

  final String hashBase64;
  final String saltBase64;
}

class AuthRepository {
  AuthRepository(this._database);

  final CashVaultDatabase _database;

  Future<bool> hasOwnerPassword() async {
    final rows = _database.select(
      'SELECT id FROM owner_auth WHERE id = 1 LIMIT 1',
    );
    return rows.isNotEmpty;
  }

  Future<OwnerCredentials?> getOwnerCredentials() async {
    final rows = _database.select(
      'SELECT password_hash, password_salt FROM owner_auth WHERE id = 1 LIMIT 1',
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    return OwnerCredentials(
      hashBase64: (row['password_hash'] as String?) ?? '',
      saltBase64: (row['password_salt'] as String?) ?? '',
    );
  }

  Future<void> upsertOwnerCredentials({
    required String hashBase64,
    required String saltBase64,
  }) async {
    final now = DateTime.now().toIso8601String();
    _database.execute(
      '''
      INSERT INTO owner_auth (id, password_hash, password_salt, updated_at)
      VALUES (1, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        password_hash = excluded.password_hash,
        password_salt = excluded.password_salt,
        updated_at = excluded.updated_at
      ''',
      [hashBase64, saltBase64, now],
    );
  }

  Future<void> logAction(String action, [String? details]) async {
    final now = DateTime.now().toIso8601String();
    _database.execute(
      'INSERT INTO audit_log (action, details, created_at) VALUES (?, ?, ?)',
      [action, details, now],
    );
  }
}
