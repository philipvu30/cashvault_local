import 'package:flutter/material.dart';

import '../services/money_format_service.dart';

class SessionTotalsRow extends StatelessWidget {
  const SessionTotalsRow({
    super.key,
    required this.label,
    required this.valueCents,
    required this.moneyFormatService,
    this.isBold = false,
  });

  final String label;
  final int valueCents;
  final MoneyFormatService moneyFormatService;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(moneyFormatService.formatCents(valueCents), style: style),
        ],
      ),
    );
  }
}
