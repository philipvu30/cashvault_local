import 'package:drift/drift.dart';

import 'database_connection.dart';

class AppDatabase extends DatabaseConnectionUser {
  AppDatabase._(this._executor) : super(_executor);

  final QueryExecutor _executor;

  static Future<AppDatabase> open() async {
    final executor = await openEncryptedExecutor();
    final database = AppDatabase._(executor);
    await database._initialize();
    return database;
  }

  Future<void> close() => _executor.close();

  Future<void> _initialize() async {
    await customStatement('PRAGMA foreign_keys = ON;');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS owner_auth (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS cash_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_name TEXT NOT NULL,
        business_date TEXT NOT NULL,
        starting_balance_cents INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        closed_at TEXT
      );
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS denomination_presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_type TEXT NOT NULL,
        label TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS cash_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        preset_id INTEGER,
        entry_type TEXT NOT NULL,
        label TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        row_total_cents INTEGER NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES cash_sessions(id),
        FOREIGN KEY (preset_id) REFERENCES denomination_presets(id)
      );
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        details TEXT,
        created_at TEXT NOT NULL
      );
    ''');
  }

  Future<void> execute(String sql, [List<Object?> variables = const <Object?>[]]) async {
    await customStatement(sql, variables);
  }

  Future<int> insert(String sql, [List<Object?> values = const <Object?>[]]) {
    final vars = values.map((value) => Variable<Object?>(value)).toList();
    return customInsert(sql, variables: vars);
  }

  Future<List<Map<String, Object?>>> selectMaps(
    String sql, [
    List<Object?> values = const <Object?>[],
  ]) async {
    final vars = values.map((value) => Variable<Object?>(value)).toList();
    final rows = await customSelect(sql, variables: vars).get();
    return rows.map((row) => row.data).toList();
  }
}
