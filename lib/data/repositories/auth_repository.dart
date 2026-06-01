import '../database.dart';

class OwnerAuthRecord {
  const OwnerAuthRecord({
    required this.passwordHash,
    required this.passwordSalt,
  });

  final String passwordHash;
  final String passwordSalt;
}

class AuthRepository {
  const AuthRepository(this._database);

  final AppDatabase _database;

  Future<OwnerAuthRecord?> getOwnerAuth() async {
    final rows = await _database.selectMaps(
      'SELECT password_hash, password_salt FROM owner_auth WHERE id = 1 LIMIT 1',
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return OwnerAuthRecord(
      passwordHash: row['password_hash'] as String,
      passwordSalt: row['password_salt'] as String,
    );
  }

  Future<bool> hasOwnerPassword() async {
    final rows = await _database.selectMaps('SELECT 1 AS ok FROM owner_auth WHERE id = 1 LIMIT 1');
    return rows.isNotEmpty;
  }

  Future<void> saveOwnerPassword({
    required String passwordHash,
    required String passwordSalt,
  }) async {
    await _database.execute(
      '''
      INSERT INTO owner_auth (id, password_hash, password_salt, updated_at)
      VALUES (1, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        password_hash = excluded.password_hash,
        password_salt = excluded.password_salt,
        updated_at = excluded.updated_at;
      ''',
      <Object?>[passwordHash, passwordSalt, DateTime.now().toIso8601String()],
    );
  }
}
