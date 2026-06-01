import 'package:flutter/material.dart';

import '../services/money_calculation_service.dart';

class SummaryPanel extends StatelessWidget {
  const SummaryPanel({
    super.key,
    required this.startingBalanceCents,
    required this.totalCashNotesCents,
    required this.totalCoinsCents,
    required this.finalTotalCents,
  });

  final int startingBalanceCents;
  final int totalCashNotesCents;
  final int totalCoinsCents;
  final int finalTotalCents;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line('Starting Balance', startingBalanceCents),
            _line('Total Cash Notes', totalCashNotesCents),
            _line('Total Coins', totalCoinsCents),
            const Divider(),
            _line('Final Total', finalTotalCents, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, int cents, {bool isBold = false}) {
    final style = isBold ? const TextStyle(fontWeight: FontWeight.w700) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(MoneyCalculationService.formatCents(cents), style: style),
        ],
      ),
    );
  }
}
