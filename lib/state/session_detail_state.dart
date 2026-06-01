import '../models/cash_session_model.dart';
import 'cash_entries_state.dart';

enum SessionDetailMode {
  readOnly,
  ownerEdit,
}

class SessionDetailArgs {
  const SessionDetailArgs({
    required this.sessionId,
    this.mode = SessionDetailMode.readOnly,
  });

  final int sessionId;
  final SessionDetailMode mode;
}

class SessionDetailState {
  const SessionDetailState({
    required this.session,
    required this.cashRows,
    required this.coinRows,
    required this.mode,
  });

  final CashSessionModel session;
  final List<CashEntryDraft> cashRows;
  final List<CashEntryDraft> coinRows;
  final SessionDetailMode mode;
}
