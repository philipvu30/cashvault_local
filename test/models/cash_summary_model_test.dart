import 'package:cashvault_local/models/cash_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CashSummaryModel.finalTotalCents', () {
    test('exclude starting balance', () {
      const summary = CashSummaryModel(
        startingBalanceCents: 20000,
        totalCashCents: 1500,
        totalCoinCents: 250,
      );

      expect(summary.finalTotalCents, 1750);
    });

    test('sum cash and coin when starting balance zero', () {
      const summary = CashSummaryModel(
        startingBalanceCents: 0,
        totalCashCents: 500,
        totalCoinCents: 50,
      );

      expect(summary.finalTotalCents, 550);
    });

    test('return zero when all inputs zero', () {
      const summary = CashSummaryModel(
        startingBalanceCents: 0,
        totalCashCents: 0,
        totalCoinCents: 0,
      );

      expect(summary.finalTotalCents, 0);
    });
  });
}
