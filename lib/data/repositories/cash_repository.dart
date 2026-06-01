import '../../models/cash_entry.dart';
import '../database.dart';

class CashRepository {
  CashRepository(this._database);

  final CashVaultDatabase _database;

  Future<List<CashEntryInput>> getEntries(EntryType type) async {
    final typeValue = type == EntryType.cash ? 'cash' : 'coin';
    final rows = _database.select(
      '''
      SELECT id, entry_type, label, amount, quantity, row_total, comment, created_at, updated_at
      FROM cash_entries
      WHERE entry_type = ?
      ORDER BY id ASC
      ''',
      [typeValue],
    );

    return rows.map(CashEntryInput.fromDb).toList();
  }

  Future<void> replaceAllEntries({
    required List<CashEntryInput> cashRows,
    required List<CashEntryInput> coinRows,
  }) async {
    final now = DateTime.now().toIso8601String();
    _database.transaction(() {
      _database.execute('DELETE FROM cash_entries');
      for (final row in <CashEntryInput>[...cashRows, ...coinRows]) {
        _database.execute(
          '''
          INSERT INTO cash_entries
            (entry_type, label, amount, quantity, row_total, comment, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            row.entryTypeValue,
            row.label,
            row.amountCents / 100.0,
            row.quantity,
            row.rowTotalCents / 100.0,
            row.comment,
            row.createdAt,
            now,
          ],
        );
      }
    });
  }

  Future<void> resetDailyEntries() async {
    _database.execute('DELETE FROM cash_entries');
  }
}
