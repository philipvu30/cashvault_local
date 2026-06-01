import '../data/repositories/auth_repository.dart';
import 'password_hash_service.dart';

class AuthService {
  AuthService({
    required AuthRepository authRepository,
    required PasswordHashService hashService,
  }) : _authRepository = authRepository,
       _hashService = hashService;

  final AuthRepository _authRepository;
  final PasswordHashService _hashService;

  Future<bool> hasOwnerPassword() => _authRepository.hasOwnerPassword();

  Future<void> setupOwnerPassword(String password) async {
    final hash = await _hashService.hashPassword(password);
    await _authRepository.upsertOwnerCredentials(
      hashBase64: hash.hashBase64,
      saltBase64: hash.saltBase64,
    );
    await _authRepository.logAction(
      'owner_password_set',
      'Initial owner password set.',
    );
  }

  Future<bool> verifyOwnerPassword(String password) async {
    final credentials = await _authRepository.getOwnerCredentials();
    if (credentials == null) {
      return false;
    }
    return _hashService.verifyPassword(
      password: password,
      expectedHashBase64: credentials.hashBase64,
      saltBase64: credentials.saltBase64,
    );
  }

  Future<bool> changeOwnerPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final verified = await verifyOwnerPassword(currentPassword);
    if (!verified) {
      return false;
    }

    final newHash = await _hashService.hashPassword(newPassword);
    await _authRepository.upsertOwnerCredentials(
      hashBase64: newHash.hashBase64,
      saltBase64: newHash.saltBase64,
    );
    await _authRepository.logAction(
      'owner_password_changed',
      'Owner password changed.',
    );
    return true;
  }
}
