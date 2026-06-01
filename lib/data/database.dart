import 'package:sqlite3/sqlite3.dart';

import 'database_connection.dart';

class CashVaultDatabase {
  CashVaultDatabase._(this._db);

  final Database _db;

  static Future<CashVaultDatabase> initialize() async {
    final db = await DatabaseConnection().openEncrypted();
    final wrapper = CashVaultDatabase._(db);
    wrapper._createTables();
    wrapper._seedDefaults();
    return wrapper;
  }

  factory CashVaultDatabase.fromRaw(Database db) {
    final wrapper = CashVaultDatabase._(db);
    wrapper._createTables();
    wrapper._seedDefaults();
    return wrapper;
  }

  Database get raw => _db;

  void dispose() {
    _db.dispose();
  }

  void execute(String sql, [List<Object?> params = const []]) {
    if (params.isEmpty) {
      _db.execute(sql);
      return;
    }

    final statement = _db.prepare(sql);
    try {
      statement.execute(params);
    } finally {
      statement.dispose();
    }
  }

  List<Map<String, Object?>> select(
    String sql, [
    List<Object?> params = const [],
  ]) {
    if (params.isEmpty) {
      return _db
          .select(sql)
          .map((row) => Map<String, Object?>.from(row))
          .toList();
    }

    final statement = _db.prepare(sql);
    try {
      final rows = statement.select(params);
      return rows.map((row) => Map<String, Object?>.from(row)).toList();
    } finally {
      statement.dispose();
    }
  }

  void transaction(void Function() action) {
    _db.execute('BEGIN TRANSACTION;');
    try {
      action();
      _db.execute('COMMIT;');
    } catch (_) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
  }

  void _createTables() {
    execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    execute('''
      CREATE TABLE IF NOT EXISTS cash_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_type TEXT NOT NULL CHECK(entry_type IN ('cash', 'coin')),
        label TEXT NOT NULL,
        amount REAL NOT NULL,
        quantity INTEGER NOT NULL,
        row_total REAL NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    execute('''
      CREATE TABLE IF NOT EXISTS owner_auth (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    execute('''
      CREATE TABLE IF NOT EXISTS audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        details TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  void _seedDefaults() {
    final now = DateTime.now().toIso8601String();
    execute(
      '''
      INSERT OR IGNORE INTO app_settings (key, value, updated_at)
      VALUES (?, ?, ?)
      ''',
      ['starting_balance', '0', now],
    );
    execute(
      '''
      INSERT OR IGNORE INTO app_settings (key, value, updated_at)
      VALUES (?, ?, ?)
      ''',
      ['database_created_at', now, now],
    );
  }
}
