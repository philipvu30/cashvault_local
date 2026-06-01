import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class PasswordHashResult {
  const PasswordHashResult({
    required this.hash,
    required this.salt,
  });

  final String hash;
  final String salt;
}

class PasswordHashService {
  final _algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 120000,
    bits: 256,
  );

  Future<PasswordHashResult> hashPassword(String password) async {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final key = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: saltBytes,
    );
    final hashBytes = await key.extractBytes();
    return PasswordHashResult(
      hash: base64Url.encode(hashBytes),
      salt: base64Url.encode(saltBytes),
    );
  }

  Future<bool> verify({
    required String password,
    required String salt,
    required String expectedHash,
  }) async {
    final key = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: base64Url.decode(salt),
    );
    final hashBytes = await key.extractBytes();
    return base64Url.encode(hashBytes) == expectedHash;
  }
}
