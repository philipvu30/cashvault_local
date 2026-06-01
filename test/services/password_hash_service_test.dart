import 'package:cashvault_local/services/password_hash_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordHashService', () {
    test('hash and verify succeeds for correct password', () async {
      final service = PasswordHashService();
      final hash = await service.hashPassword('owner-secret');

      final ok = await service.verifyPassword(
        password: 'owner-secret',
        expectedHashBase64: hash.hashBase64,
        saltBase64: hash.saltBase64,
      );

      expect(ok, isTrue);
    });

    test('verify fails for wrong password', () async {
      final service = PasswordHashService();
      final hash = await service.hashPassword('owner-secret');

      final ok = await service.verifyPassword(
        password: 'wrong-secret',
        expectedHashBase64: hash.hashBase64,
        saltBase64: hash.saltBase64,
      );

      expect(ok, isFalse);
    });
  });
}
