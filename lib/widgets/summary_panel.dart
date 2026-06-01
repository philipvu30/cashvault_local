import 'dart:ui';

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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _SummaryRow(
          label: 'Starting Balance',
          value: MoneyCalculationService.formatCents(startingBalanceCents),
        ),
        const Divider(height: 24),
        _SummaryRow(
          label: 'Total Cash Notes',
          value: MoneyCalculationService.formatCents(totalCashNotesCents),
        ),
        const Divider(height: 24),
        _SummaryRow(
          label: 'Total Coins',
          value: MoneyCalculationService.formatCents(totalCoinsCents),
        ),
        const Divider(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                'FINAL TOTAL',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Text(
              MoneyCalculationService.formatCents(finalTotalCents),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
