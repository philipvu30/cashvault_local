import '../models/denomination_preset_model.dart';

class DenominationPresetsState {
  const DenominationPresetsState({
    required this.cashPresets,
    required this.coinPresets,
  });

  final List<DenominationPresetModel> cashPresets;
  final List<DenominationPresetModel> coinPresets;
}
