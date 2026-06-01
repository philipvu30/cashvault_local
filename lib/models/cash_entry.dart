enum EntryType { cash, coin }

class CashEntryInput {
  CashEntryInput({
    this.id,
    required this.entryType,
    required this.label,
    required this.amountCents,
    required this.quantity,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final EntryType entryType;
  final String label;
  final int amountCents;
  final int quantity;
  final String? comment;
  final String createdAt;
  final String updatedAt;

  int get rowTotalCents => amountCents * quantity;

  String get entryTypeValue => entryType == EntryType.cash ? 'cash' : 'coin';

  CashEntryInput copyWith({
    int? id,
    EntryType? entryType,
    String? label,
    int? amountCents,
    int? quantity,
    String? comment,
    bool clearComment = false,
    String? createdAt,
    String? updatedAt,
  }) {
    return CashEntryInput(
      id: id ?? this.id,
      entryType: entryType ?? this.entryType,
      label: label ?? this.label,
      amountCents: amountCents ?? this.amountCents,
      quantity: quantity ?? this.quantity,
      comment: clearComment ? null : (comment ?? this.comment),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toDbMap() {
    return <String, Object?>{
      'entry_type': entryTypeValue,
      'label': label,
      'amount': amountCents / 100.0,
      'quantity': quantity,
      'row_total': rowTotalCents / 100.0,
      'comment': comment,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static CashEntryInput fromDb(Map<String, Object?> row) {
    final amount = (row['amount'] as num?)?.toDouble() ?? 0;
    final quantity = (row['quantity'] as num?)?.toInt() ?? 0;
    return CashEntryInput(
      id: (row['id'] as num?)?.toInt(),
      entryType: (row['entry_type'] == 'coin')
          ? EntryType.coin
          : EntryType.cash,
      label: (row['label'] as String?) ?? '',
      amountCents: (amount * 100).round(),
      quantity: quantity,
      comment: row['comment'] as String?,
      createdAt:
          (row['created_at'] as String?) ?? DateTime.now().toIso8601String(),
      updatedAt:
          (row['updated_at'] as String?) ?? DateTime.now().toIso8601String(),
    );
  }

  static CashEntryInput empty(EntryType type) {
    final now = DateTime.now().toIso8601String();
    return CashEntryInput(
      entryType: type,
      label: '',
      amountCents: 0,
      quantity: 1,
      comment: null,
      createdAt: now,
      updatedAt: now,
    );
  }
}
