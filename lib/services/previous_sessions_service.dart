import '../models/cash_entry_model.dart';
import '../models/cash_session_model.dart';
import '../state/previous_sessions_state.dart';

class PreviousSessionsService {
  const PreviousSessionsService();

  List<PreviousSessionListRow> buildRows({
    required List<CashSessionModel> sessions,
    required Map<int, List<CashEntryModel>> entriesBySessionId,
  }) {
    return sessions.map((session) {
      final entries = entriesBySessionId[session.id] ?? const <CashEntryModel>[];
      final totalCashCents = entries
          .where((entry) => entry.entryType == 'cash')
          .fold<int>(0, (sum, entry) => sum + entry.rowTotalCents);
      final totalCoinCents = entries
          .where((entry) => entry.entryType == 'coin')
          .fold<int>(0, (sum, entry) => sum + entry.rowTotalCents);
      return PreviousSessionListRow(
        session: session,
        totalCashCents: totalCashCents,
        totalCoinCents: totalCoinCents,
      );
    }).toList();
  }

  List<PreviousSessionListRow> applyFilters({
    required List<PreviousSessionListRow> rows,
    required String searchTerm,
    required String businessDateFilter,
    required String statusFilter,
  }) {
    final lower = searchTerm.trim().toLowerCase();
    final dateFilter = businessDateFilter.trim();
    final status = statusFilter.trim().toLowerCase();

    return rows.where((row) {
      final matchesSearch = lower.isEmpty || row.session.sessionName.toLowerCase().contains(lower);
      final matchesDate = dateFilter.isEmpty || row.session.businessDate == dateFilter;
      final matchesStatus = status == 'all' || status.isEmpty || row.session.status.toLowerCase() == status;
      return matchesSearch && matchesDate && matchesStatus;
    }).toList();
  }
}
