import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseConnection {
  static const String _dbFileName = 'cashvault_local.db';
  static const String _keyFileName = 'cashvault_local.key';

  Future<Database> openEncrypted() async {
    final supportDir = await getApplicationSupportDirectory();
    await supportDir.create(recursive: true);

    final key = await _loadOrCreateKey(supportDir);
    final escapedKey = key.replaceAll("'", "''");
    final dbPath = p.join(supportDir.path, _dbFileName);

    final db = sqlite3.open(dbPath);
    db.execute("PRAGMA key = '$escapedKey';");
    db.execute('PRAGMA cipher_compatibility = 4;');
    db.execute('PRAGMA foreign_keys = ON;');
    db.select('SELECT count(*) FROM sqlite_master;');

    return db;
  }

  Future<String> _loadOrCreateKey(Directory supportDir) async {
    final keyFile = File(p.join(supportDir.path, _keyFileName));
    if (await keyFile.exists()) {
      final existing = (await keyFile.readAsString()).trim();
      if (existing.isNotEmpty) {
        return existing;
      }
    }

    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final generatedKey = base64UrlEncode(keyBytes);
    await keyFile.writeAsString(generatedKey, flush: true);
    return generatedKey;
  }
}
