import '../models/cash_entry_model.dart';

class CashEntryDraft {
  CashEntryDraft({
    this.id,
    required this.sessionId,
    required this.entryType,
    required this.label,
    required this.amountCents,
    required this.quantity,
    required this.comment,
    this.presetId,
    required this.isCustom,
  });

  final int? id;
  final int sessionId;
  final String entryType;
  String label;
  int amountCents;
  int quantity;
  String comment;
  int? presetId;
  final bool isCustom;

  int get rowTotalCents => amountCents * quantity;

  bool get shouldPersist => quantity > 0 || comment.trim().isNotEmpty;

  CashEntryModel toModel() {
    return CashEntryModel(
      id: id,
      sessionId: sessionId,
      presetId: presetId,
      entryType: entryType,
      label: label.trim(),
      amountCents: amountCents,
      quantity: quantity,
      rowTotalCents: rowTotalCents,
      comment: comment.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isCustom: isCustom,
    );
  }

  static CashEntryDraft fromModel(CashEntryModel model) {
    return CashEntryDraft(
      id: model.id,
      sessionId: model.sessionId,
      presetId: model.presetId,
      entryType: model.entryType,
      label: model.label,
      amountCents: model.amountCents,
      quantity: model.quantity,
      comment: model.comment,
      isCustom: model.isCustom,
    );
  }
}

class CashEntriesState {
  const CashEntriesState({
    required this.cashRows,
    required this.coinRows,
  });

  final List<CashEntryDraft> cashRows;
  final List<CashEntryDraft> coinRows;
}
