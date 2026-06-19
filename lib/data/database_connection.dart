import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

const String _projectDatabaseKey = 'cashvault_local_internal_key_change_me_2026';
const String _databaseFilename = 'cashvault_local.db';

Future<String> getDatabasePath({Directory? supportDirectory}) async {
  final resolvedSupportDirectory = supportDirectory ?? await getApplicationSupportDirectory();
  await resolvedSupportDirectory.create(recursive: true);
  return p.join(resolvedSupportDirectory.path, _databaseFilename);
}

Future<void> deleteDatabaseFiles({Directory? supportDirectory}) async {
  final databasePath = await getDatabasePath(supportDirectory: supportDirectory);
  final candidates = <String>[
    databasePath,
    '$databasePath-wal',
    '$databasePath-shm',
  ];

  for (final path in candidates) {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

Future<QueryExecutor> openEncryptedExecutor() async {
  final databasePath = await getDatabasePath();
  const key = _projectDatabaseKey;

  final raw = sqlite.sqlite3.open(databasePath);
  final escapedKey = key.replaceAll("'", "''");
  raw.execute("PRAGMA key = '$escapedKey';");
  raw.execute('PRAGMA foreign_keys = ON;');

  return NativeDatabase.opened(raw, logStatements: false);
}
