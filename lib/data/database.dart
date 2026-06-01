import 'package:drift/drift.dart';

import 'database_connection.dart';

class AppDatabase extends GeneratedDatabase {
  AppDatabase._(this._executor) : super(_executor);

  final QueryExecutor _executor;

  static Future<AppDatabase> open() async {
    final executor = await openEncryptedExecutor();
    return AppDatabase._(executor);
  }

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => _bootstrapSchema(),
    onUpgrade: (m, from, to) async => _bootstrapSchema(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
      await _bootstrapSchema();
    },
  );

  @override
  Future<void> close() => _executor.close();

  Future<void> _bootstrapSchema() async {
    await _initialize();
    await _ensureLegacyCompatibility();
  }

  Future<void> _initialize() async {
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
        eft_pos_cents INTEGER NOT NULL DEFAULT 0,
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

    await _createCashEntriesTable();

    await customStatement('''
      CREATE TABLE IF NOT EXISTS audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        details TEXT,
        created_at TEXT NOT NULL
      );
    ''');
  }

  Future<void> _createCashEntriesTable() async {
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
  }

  Future<void> _ensureLegacyCompatibility() async {
    await _ensureCashSessionsEftPosColumn();
    await _migrateCashEntriesWithoutSessionId();
  }

  Future<void> _ensureCashSessionsEftPosColumn() async {
    final columns = await selectMaps("PRAGMA table_info('cash_sessions')");
    if (columns.isEmpty) return;
    final names = columns.map((row) => row['name'] as String).toSet();
    if (!names.contains('eft_pos_cents')) {
      await customStatement(
        'ALTER TABLE cash_sessions ADD COLUMN eft_pos_cents INTEGER NOT NULL DEFAULT 0;',
      );
    }
  }

  Future<void> _migrateCashEntriesWithoutSessionId() async {
    final columns = await selectMaps("PRAGMA table_info('cash_entries')");
    if (columns.isEmpty) return;

    final columnNames = columns.map((row) => row['name'] as String).toSet();
    if (columnNames.contains('session_id')) return;

    if (await _tableExists('cash_entries_legacy')) {
      await customStatement('DROP TABLE cash_entries_legacy;');
    }

    await customStatement('ALTER TABLE cash_entries RENAME TO cash_entries_legacy;');
    await _createCashEntriesTable();

    final sessionId = await _ensureFallbackSession();

    String columnOrLiteral(String column, String fallbackSql) {
      return columnNames.contains(column) ? column : fallbackSql;
    }

    final idExpr = columnOrLiteral('id', 'NULL');
    final presetIdExpr = columnOrLiteral('preset_id', 'NULL');
    final entryTypeExpr = columnOrLiteral('entry_type', "'cash'");
    final labelExpr = columnOrLiteral('label', "'Migrated Entry'");
    final amountExpr = columnOrLiteral('amount_cents', '0');
    final quantityExpr = columnOrLiteral('quantity', '1');
    final rowTotalExpr = columnOrLiteral('row_total_cents', amountExpr);
    final commentExpr = columnOrLiteral('comment', "''");
    final createdExpr = columnOrLiteral('created_at', 'CURRENT_TIMESTAMP');
    final updatedExpr = columnOrLiteral('updated_at', createdExpr);

    await customStatement('''
      INSERT INTO cash_entries (
        id, session_id, preset_id, entry_type, label, amount_cents, quantity,
        row_total_cents, comment, created_at, updated_at
      )
      SELECT
        $idExpr, $sessionId, $presetIdExpr, $entryTypeExpr, $labelExpr, $amountExpr, $quantityExpr,
        $rowTotalExpr, $commentExpr, $createdExpr, $updatedExpr
      FROM cash_entries_legacy;
    ''');

    await customStatement('DROP TABLE cash_entries_legacy;');
  }

  Future<bool> _tableExists(String tableName) async {
    final rows = await selectMaps(
      "SELECT 1 AS ok FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
      <Object?>[tableName],
    );
    return rows.isNotEmpty;
  }

  Future<int> _ensureFallbackSession() async {
    final openSessions = await selectMaps(
      "SELECT id FROM cash_sessions WHERE status = 'open' ORDER BY id DESC LIMIT 1",
    );
    if (openSessions.isNotEmpty) {
      return openSessions.first['id'] as int;
    }

    final now = DateTime.now();
    final businessDate = _formatBusinessDate(now);
    return insert(
      '''
      INSERT INTO cash_sessions (
        session_name, business_date, starting_balance_cents, status, created_at, closed_at
      ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        'Migrated Session',
        businessDate,
        0,
        'open',
        now.toIso8601String(),
        null,
      ],
    );
  }

  String _formatBusinessDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> execute(String sql, [List<Object?> variables = const <Object?>[]]) async {
    await customStatement(sql, variables);
  }

  Future<int> insert(String sql, [List<Object?> values = const <Object?>[]]) {
    final vars = values.map((value) => Variable<Object>(value)).toList();
    return customInsert(sql, variables: vars);
  }

  Future<List<Map<String, Object?>>> selectMaps(
    String sql, [
    List<Object?> values = const <Object?>[],
  ]) async {
    final vars = values.map((value) => Variable<Object>(value)).toList();
    final rows = await customSelect(sql, variables: vars).get();
    return rows.map((row) => row.data).toList();
  }
}
