import '../database.dart';

class SettingsRepository {
  SettingsRepository(this._database);

  final CashVaultDatabase _database;

  Future<String?> getSetting(String key) async {
    final rows = _database.select(
      'SELECT value FROM app_settings WHERE key = ? LIMIT 1',
      [key],
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  Future<void> upsertSetting(String key, String value) async {
    final now = DateTime.now().toIso8601String();
    _database.execute(
      '''
      INSERT INTO app_settings (key, value, updated_at)
      VALUES (?, ?, ?)
      ON CONFLICT(key) DO UPDATE SET
        value = excluded.value,
        updated_at = excluded.updated_at
      ''',
      [key, value, now],
    );
  }

  Future<int> getStartingBalanceCents() async {
    final value = await getSetting('starting_balance');
    final parsed = double.tryParse(value ?? '0') ?? 0;
    return (parsed * 100).round();
  }

  Future<void> setStartingBalanceCents(int cents) {
    return upsertSetting(
      'starting_balance',
      (cents / 100.0).toStringAsFixed(2),
    );
  }

  Future<String?> getDatabaseCreatedAt() => getSetting('database_created_at');

  Future<String?> getLastExportPath() => getSetting('last_export_path');

  Future<void> setLastExportPath(String path) =>
      upsertSetting('last_export_path', path);

  Future<String?> getPreferredExportDirectory() =>
      getSetting('preferred_export_directory');

  Future<void> setPreferredExportDirectory(String directoryPath) {
    return upsertSetting('preferred_export_directory', directoryPath);
  }
}
