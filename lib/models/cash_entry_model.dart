class CashEntryModel {
  const CashEntryModel({
    required this.id,
    required this.sessionId,
    required this.presetId,
    required this.entryType,
    required this.label,
    required this.amountCents,
    required this.quantity,
    required this.rowTotalCents,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.isCustom,
  });

  final int? id;
  final int sessionId;
  final int? presetId;
  final String entryType;
  final String label;
  final int amountCents;
  final int quantity;
  final int rowTotalCents;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCustom;

  CashEntryModel copyWith({
    int? id,
    int? sessionId,
    int? presetId,
    String? entryType,
    String? label,
    int? amountCents,
    int? quantity,
    int? rowTotalCents,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCustom,
  }) {
    return CashEntryModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      presetId: presetId ?? this.presetId,
      entryType: entryType ?? this.entryType,
      label: label ?? this.label,
      amountCents: amountCents ?? this.amountCents,
      quantity: quantity ?? this.quantity,
      rowTotalCents: rowTotalCents ?? this.rowTotalCents,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
