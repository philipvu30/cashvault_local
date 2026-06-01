import '../../models/cash_entry_model.dart';
import '../database.dart';

class CashEntriesRepository {
  const CashEntriesRepository(this._database);

  final AppDatabase _database;

  Future<List<CashEntryModel>> getBySessionId(int sessionId) async {
    final rows = await _database.selectMaps(
      '''
      SELECT id, session_id, preset_id, entry_type, label, amount_cents, quantity,
             row_total_cents, comment, created_at, updated_at
      FROM cash_entries
      WHERE session_id = ?
      ORDER BY id
      ''',
      <Object?>[sessionId],
    );

    return rows
        .map(
          (row) => CashEntryModel(
            id: row['id'] as int,
            sessionId: row['session_id'] as int,
            presetId: row['preset_id'] as int?,
            entryType: row['entry_type'] as String,
            label: row['label'] as String,
            amountCents: row['amount_cents'] as int,
            quantity: row['quantity'] as int,
            rowTotalCents: row['row_total_cents'] as int,
            comment: (row['comment'] as String?) ?? '',
            createdAt: DateTime.parse(row['created_at'] as String),
            updatedAt: DateTime.parse(row['updated_at'] as String),
            isCustom: row['preset_id'] == null,
          ),
        )
        .toList();
  }

  Future<void> replaceForSession(int sessionId, List<CashEntryModel> rows) async {
    await _database.execute('DELETE FROM cash_entries WHERE session_id = ?', <Object?>[sessionId]);
    for (final row in rows) {
      await _database.insert(
        '''
        INSERT INTO cash_entries (
          session_id, preset_id, entry_type, label, amount_cents, quantity,
          row_total_cents, comment, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          sessionId,
          row.presetId,
          row.entryType,
          row.label,
          row.amountCents,
          row.quantity,
          row.rowTotalCents,
          row.comment,
          DateTime.now().toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );
    }
  }
}
