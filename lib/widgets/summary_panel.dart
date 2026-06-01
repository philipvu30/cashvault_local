import 'package:flutter/material.dart';

import '../models/cash_summary_model.dart';
import '../services/money_format_service.dart';

class SummaryPanel extends StatelessWidget {
  const SummaryPanel({
    super.key,
    required this.summary,
    required this.moneyFormatService,
  });

  final CashSummaryModel summary;
  final MoneyFormatService moneyFormatService;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, int value, {bool bold = false}) {
      final style = bold
          ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
          : Theme.of(context).textTheme.bodyMedium;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label, style: style)),
            Text(moneyFormatService.formatCents(value), style: style),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        row('Starting Balance', summary.startingBalanceCents),
        row('Total Cash Notes', summary.totalCashCents),
        row('Total Coins', summary.totalCoinCents),
        const Divider(),
        row('FINAL TOTAL', summary.finalTotalCents, bold: true),
      ],
    );
  }
}
