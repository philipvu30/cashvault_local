import 'package:cashvault_local/models/cash_session_model.dart';
import 'package:cashvault_local/state/previous_sessions_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreviousSessionListRow.finalTotalCents', () {
    test('exclude starting balance', () {
      final row = PreviousSessionListRow(
        session: CashSessionModel(
          id: 1,
          sessionName: 'Session 1',
          businessDate: '2026-06-19',
          startingBalanceCents: 20000,
          eftPosText: '0.00',
          status: 'closed',
          createdAt: DateTime.parse('2026-06-19T09:00:00Z'),
          closedAt: DateTime.parse('2026-06-19T17:00:00Z'),
        ),
        totalCashCents: 3400,
        totalCoinCents: 600,
      );

      expect(row.finalTotalCents, 4000);
    });
  });
}
