import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

const String _projectDatabaseKey = 'cashvault_local_internal_key_change_me_2026';

Future<QueryExecutor> openEncryptedExecutor() async {
  final supportDirectory = await getApplicationSupportDirectory();
  await supportDirectory.create(recursive: true);

  final databasePath = p.join(supportDirectory.path, 'cashvault_local.db');
  final key = _projectDatabaseKey;

  final raw = sqlite.sqlite3.open(databasePath);
  final escapedKey = key.replaceAll("'", "''");
  raw.execute("PRAGMA key = '$escapedKey';");
  raw.execute('PRAGMA foreign_keys = ON;');

  return NativeDatabase.opened(raw, logStatements: false);
}
