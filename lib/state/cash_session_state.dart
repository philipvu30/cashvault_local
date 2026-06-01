import '../models/cash_session_model.dart';

class CashSessionState {
  const CashSessionState({
    required this.activeSession,
    required this.isStartingBalanceUnlocked,
  });

  final CashSessionModel? activeSession;
  final bool isStartingBalanceUnlocked;
}
