class DenominationPresetModel {
  const DenominationPresetModel({
    required this.id,
    required this.entryType,
    required this.label,
    required this.amountCents,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String entryType;
  final String label;
  final int amountCents;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
