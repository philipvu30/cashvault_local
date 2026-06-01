import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class PasswordHashData {
  const PasswordHashData({required this.hashBase64, required this.saltBase64});

  final String hashBase64;
  final String saltBase64;
}

class PasswordHashService {
  static const int _saltLength = 16;
  static const int _iterations = 120000;
  static const int _bits = 256;

  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iterations,
    bits: _bits,
  );

  Future<PasswordHashData> hashPassword(
    String password, {
    String? saltBase64,
  }) async {
    final salt = saltBase64 != null
        ? base64Decode(saltBase64)
        : _randomBytes(_saltLength);

    final secretKey = await _pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final bytes = await secretKey.extractBytes();

    return PasswordHashData(
      hashBase64: base64Encode(bytes),
      saltBase64: base64Encode(salt),
    );
  }

  Future<bool> verifyPassword({
    required String password,
    required String expectedHashBase64,
    required String saltBase64,
  }) async {
    final hashed = await hashPassword(password, saltBase64: saltBase64);
    return _constantTimeEquals(hashed.hashBase64, expectedHashBase64);
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
