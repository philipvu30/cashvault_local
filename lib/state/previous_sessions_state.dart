import '../models/cash_session_model.dart';

class PreviousSessionListRow {
  const PreviousSessionListRow({
    required this.session,
    required this.totalCashCents,
    required this.totalCoinCents,
  });

  final CashSessionModel session;
  final int totalCashCents;
  final int totalCoinCents;

  int get finalTotalCents => session.startingBalanceCents + totalCashCents + totalCoinCents;
}

class PreviousSessionsState {
  const PreviousSessionsState({
    required this.rows,
    required this.searchTerm,
    required this.businessDateFilter,
    required this.statusFilter,
  });

  final List<PreviousSessionListRow> rows;
  final String searchTerm;
  final String businessDateFilter;
  final String statusFilter;
}
