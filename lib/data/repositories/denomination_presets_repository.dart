import '../../models/denomination_preset_model.dart';
import '../database.dart';

class DenominationPresetsRepository {
  const DenominationPresetsRepository(this._database);

  final AppDatabase _database;

  Future<List<DenominationPresetModel>> getAll() async {
    final rows = await _database.selectMaps(
      '''
      SELECT id, entry_type, label, amount_cents, sort_order, is_active, created_at, updated_at
      FROM denomination_presets
      ORDER BY entry_type, sort_order, id
      ''',
    );
    return rows.map(_map).toList();
  }

  Future<List<DenominationPresetModel>> getActiveByType(String entryType) async {
    final rows = await _database.selectMaps(
      '''
      SELECT id, entry_type, label, amount_cents, sort_order, is_active, created_at, updated_at
      FROM denomination_presets
      WHERE entry_type = ? AND is_active = 1
      ORDER BY sort_order, id
      ''',
      <Object?>[entryType],
    );
    return rows.map(_map).toList();
  }

  Future<int> create({
    required String entryType,
    required String label,
    required int amountCents,
    required int sortOrder,
    required bool isActive,
  }) {
    final now = DateTime.now().toIso8601String();
    return _database.insert(
      '''
      INSERT INTO denomination_presets (
        entry_type, label, amount_cents, sort_order, is_active, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        entryType,
        label,
        amountCents,
        sortOrder,
        isActive ? 1 : 0,
        now,
        now,
      ],
    );
  }

  Future<void> updatePreset({
    required int id,
    required String entryType,
    required String label,
    required int amountCents,
    required int sortOrder,
    required bool isActive,
  }) {
    return _database.execute(
      '''
      UPDATE denomination_presets
      SET entry_type = ?,
          label = ?,
          amount_cents = ?,
          sort_order = ?,
          is_active = ?,
          updated_at = ?
      WHERE id = ?
      ''',
      <Object?>[
        entryType,
        label,
        amountCents,
        sortOrder,
        isActive ? 1 : 0,
        DateTime.now().toIso8601String(),
        id,
      ],
    );
  }

  Future<void> setActive({required int id, required bool isActive}) {
    return _database.execute(
      '''
      UPDATE denomination_presets
      SET is_active = ?, updated_at = ?
      WHERE id = ?
      ''',
      <Object?>[isActive ? 1 : 0, DateTime.now().toIso8601String(), id],
    );
  }

  DenominationPresetModel _map(Map<String, Object?> row) {
    return DenominationPresetModel(
      id: row['id'] as int,
      entryType: row['entry_type'] as String,
      label: row['label'] as String,
      amountCents: row['amount_cents'] as int,
      sortOrder: row['sort_order'] as int,
      isActive: (row['is_active'] as int) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
