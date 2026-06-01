class CashSummaryModel {
  const CashSummaryModel({
    required this.startingBalanceCents,
    required this.totalCashCents,
    required this.totalCoinCents,
  });

  final int startingBalanceCents;
  final int totalCashCents;
  final int totalCoinCents;

  int get finalTotalCents => startingBalanceCents + totalCashCents + totalCoinCents;
}
