import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

Future<QueryExecutor> openEncryptedExecutor() async {
  final supportDirectory = await getApplicationSupportDirectory();
  await supportDirectory.create(recursive: true);

  final databasePath = p.join(supportDirectory.path, 'cashvault_local.db');
  final keyPath = p.join(supportDirectory.path, '.cashvault_local.key');
  final key = await _loadOrCreateKey(keyPath);

  final raw = sqlite.sqlite3.open(databasePath);
  final escapedKey = key.replaceAll("'", "''");
  raw.execute("PRAGMA key = '$escapedKey';");
  raw.execute('PRAGMA foreign_keys = ON;');

  return NativeDatabase.opened(raw, logStatements: false);
}

Future<String> _loadOrCreateKey(String keyPath) async {
  final keyFile = File(keyPath);
  if (await keyFile.exists()) {
    return (await keyFile.readAsString()).trim();
  }

  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  final createdKey = base64Url.encode(bytes);
  await keyFile.writeAsString(createdKey, flush: true);
  return createdKey;
}
