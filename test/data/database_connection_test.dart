import 'dart:io';

import 'package:cashvault_local/data/database_connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deleteDatabaseFiles', () {
    test('delete database main, wal, and shm files when present', () async {
      final supportDirectory = await Directory.systemTemp.createTemp('cashvault_db_files');
      addTearDown(() async {
        if (await supportDirectory.exists()) {
          await supportDirectory.delete(recursive: true);
        }
      });

      final databasePath = await getDatabasePath(supportDirectory: supportDirectory);
      final files = <File>[
        File(databasePath),
        File('$databasePath-wal'),
        File('$databasePath-shm'),
      ];

      for (final file in files) {
        await file.writeAsString('test');
      }

      await deleteDatabaseFiles(supportDirectory: supportDirectory);

      for (final file in files) {
        expect(await file.exists(), isFalse);
      }
    });
  });
}
