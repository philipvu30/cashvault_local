import '../data/repositories/audit_log_repository.dart';
import '../data/repositories/denomination_presets_repository.dart';
import '../models/denomination_preset_model.dart';

class DenominationPresetService {
  const DenominationPresetService({
    required DenominationPresetsRepository repository,
    required AuditLogRepository auditLogRepository,
  })  : _repository = repository,
        _auditLogRepository = auditLogRepository;

  final DenominationPresetsRepository _repository;
  final AuditLogRepository _auditLogRepository;

  Future<List<DenominationPresetModel>> getAll() => _repository.getAll();

  Future<List<DenominationPresetModel>> getActiveByType(String entryType) {
    return _repository.getActiveByType(entryType);
  }

  Future<void> createPreset({
    required String entryType,
    required String label,
    required int amountCents,
    required int sortOrder,
    required bool isActive,
  }) async {
    await _repository.create(
      entryType: entryType,
      label: label,
      amountCents: amountCents,
      sortOrder: sortOrder,
      isActive: isActive,
    );
    await _auditLogRepository.log('denomination_preset_created', details: '$entryType:$label');
  }

  Future<void> updatePreset({
    required int id,
    required String entryType,
    required String label,
    required int amountCents,
    required int sortOrder,
    required bool isActive,
  }) async {
    await _repository.updatePreset(
      id: id,
      entryType: entryType,
      label: label,
      amountCents: amountCents,
      sortOrder: sortOrder,
      isActive: isActive,
    );
    await _auditLogRepository.log('denomination_preset_updated', details: '$id:$label');
  }

  Future<void> setActive({
    required int id,
    required bool isActive,
    required String label,
  }) async {
    await _repository.setActive(id: id, isActive: isActive);
    if (!isActive) {
      await _auditLogRepository.log('denomination_preset_deactivated', details: '$id:$label');
    }
  }
}
