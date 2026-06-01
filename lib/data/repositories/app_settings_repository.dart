import '../../models/app_setting_model.dart';
import '../database.dart';

class AppSettingsRepository {
  const AppSettingsRepository(this._database);

  final AppDatabase _database;

  Future<AppSettingModel?> getSetting(String key) async {
    final rows = await _database.selectMaps(
      'SELECT key, value, updated_at FROM app_settings WHERE key = ? LIMIT 1',
      <Object?>[key],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return AppSettingModel(
      key: row['key'] as String,
      value: row['value'] as String,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<void> upsertSetting(String key, String value) async {
    final now = DateTime.now().toIso8601String();
    await _database.execute(
      '''
      INSERT INTO app_settings (key, value, updated_at)
      VALUES (?, ?, ?)
      ON CONFLICT(key) DO UPDATE SET
        value = excluded.value,
        updated_at = excluded.updated_at;
      ''',
      <Object?>[key, value, now],
    );
  }

  Future<void> ensureDefaultSettings() async {
    final now = DateTime.now().toIso8601String();
    final defaults = <String, String>{
      'database_created_at': now,
      'last_export_folder': '',
      'active_session_id': '',
      'app_version': '1.0.0',
    };
    for (final entry in defaults.entries) {
      await _database.execute(
        '''
        INSERT OR IGNORE INTO app_settings (key, value, updated_at)
        VALUES (?, ?, ?);
        ''',
        <Object?>[entry.key, entry.value, now],
      );
    }
  }
}
