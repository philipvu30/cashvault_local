import 'package:sqlite3/sqlite3.dart';

import 'database_connection.dart';

class CashVaultDatabase {
  static const int _currentSchemaVersion = 2;

  CashVaultDatabase._(this._db);

  final Database _db;

  static Future<CashVaultDatabase> initialize() async {
    final db = await DatabaseConnection().openEncrypted();
    final wrapper = CashVaultDatabase._(db);
    wrapper._initializeSchema();
    return wrapper;
  }

  factory CashVaultDatabase.fromRaw(Database db) {
    final wrapper = CashVaultDatabase._(db);
    wrapper._initializeSchema();
    return wrapper;
  }

  Database get raw => _db;

  void dispose() {
    _db.close();
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
      statement.close();
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
      statement.close();
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

  void _initializeSchema() {
    final schemaVersion = _userVersion;

    if (!_tableExists('cash_entries')) {
      _createTablesV2();
      _seedDefaults();
      _userVersion = _currentSchemaVersion;
      return;
    }

    _createSupportTablesIfMissing();

    if (schemaVersion < _currentSchemaVersion) {
      _migrateLegacySchema();
      _userVersion = _currentSchemaVersion;
    }

    _seedDefaults();
  }

  int get _userVersion {
    final row = _db.select('PRAGMA user_version;').first;
    return (row['user_version'] as int?) ?? 0;
  }

  set _userVersion(int value) {
    _db.execute('PRAGMA user_version = $value;');
  }

  bool _tableExists(String tableName) {
    final rows = select(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table' AND name = ?
      LIMIT 1
      ''',
      [tableName],
    );
    return rows.isNotEmpty;
  }

  List<String> _tableColumns(String tableName) {
    final rows = select('PRAGMA table_info($tableName);');
    return rows
        .map((row) => (row['name'] as String?) ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  void _createSupportTablesIfMissing() {
    execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
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

  void _createTablesV2() {
    _createSupportTablesIfMissing();
    execute('''
      CREATE TABLE IF NOT EXISTS cash_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_type TEXT NOT NULL CHECK(entry_type IN ('cash', 'coin')),
        label TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        row_total_cents INTEGER NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  void _migrateLegacySchema() {
    final columns = _tableColumns('cash_entries');
    if (columns.contains('amount_cents') && columns.contains('row_total_cents')) {
      _migrateStartingBalanceSetting();
      return;
    }

    transaction(() {
      execute('ALTER TABLE cash_entries RENAME TO cash_entries_legacy');
      _createTablesV2();
      execute(
        '''
        INSERT INTO cash_entries (
          id,
          entry_type,
          label,
          amount_cents,
          quantity,
          row_total_cents,
          comment,
          created_at,
          updated_at
        )
        SELECT
          id,
          entry_type,
          label,
          CAST(ROUND(amount * 100.0) AS INTEGER),
          quantity,
          CAST(ROUND(row_total * 100.0) AS INTEGER),
          comment,
          created_at,
          updated_at
        FROM cash_entries_legacy
        ORDER BY id ASC
        ''',
      );
      execute('DROP TABLE cash_entries_legacy');
      _migrateStartingBalanceSetting();
    });
  }

  void _migrateStartingBalanceSetting() {
    final currentValueRow = select(
      'SELECT value FROM app_settings WHERE key = ? LIMIT 1',
      ['starting_balance'],
    );
    if (currentValueRow.isEmpty) {
      return;
    }

    final currentValue = (currentValueRow.first['value'] as String?) ?? '0';
    final nextValue = _normalizeStartingBalanceValue(currentValue);
    if (nextValue == currentValue) {
      return;
    }

    final now = DateTime.now().toIso8601String();
    execute(
      '''
      UPDATE app_settings
      SET value = ?, updated_at = ?
      WHERE key = ?
      ''',
      [nextValue, now, 'starting_balance'],
    );
  }

  String _normalizeStartingBalanceValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '0';
    }

    final integerValue = int.tryParse(trimmed);
    if (integerValue != null) {
      return integerValue.toString();
    }

    final decimalMatch = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(trimmed);
    if (decimalMatch == null) {
      return '0';
    }

    final wholePart = int.parse(decimalMatch.group(1)!);
    final fractionalRaw = decimalMatch.group(2) ?? '';
    final fractionalPart = fractionalRaw.padRight(2, '0');
    return (wholePart * 100 + int.parse(fractionalPart)).toString();
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
