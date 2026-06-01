import '../data/repositories/auth_repository.dart';
import '../data/repositories/audit_log_repository.dart';
import 'password_hash_service.dart';

class AuthService {
  const AuthService({
    required AuthRepository authRepository,
    required AuditLogRepository auditLogRepository,
    required PasswordHashService passwordHashService,
  })  : _authRepository = authRepository,
        _auditLogRepository = auditLogRepository,
        _passwordHashService = passwordHashService;

  final AuthRepository _authRepository;
  final AuditLogRepository _auditLogRepository;
  final PasswordHashService _passwordHashService;

  Future<bool> hasPassword() => _authRepository.hasOwnerPassword();

  Future<void> createPassword(String password) async {
    final result = await _passwordHashService.hashPassword(password);
    await _authRepository.saveOwnerPassword(
      passwordHash: result.hash,
      passwordSalt: result.salt,
    );
    await _auditLogRepository.log('owner_password_created');
  }

  Future<bool> verifyPassword(String password) async {
    final auth = await _authRepository.getOwnerAuth();
    if (auth == null) return false;
    return _passwordHashService.verify(
      password: password,
      salt: auth.passwordSalt,
      expectedHash: auth.passwordHash,
    );
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final ok = await verifyPassword(currentPassword);
    if (!ok) return false;
    final result = await _passwordHashService.hashPassword(newPassword);
    await _authRepository.saveOwnerPassword(
      passwordHash: result.hash,
      passwordSalt: result.salt,
    );
    await _auditLogRepository.log('owner_password_changed');
    return true;
  }
}
